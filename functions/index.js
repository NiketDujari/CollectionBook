const {
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  defineSecret,
} = require("firebase-functions/params");

const admin = require("firebase-admin");

admin.initializeApp();

const msg91AuthKey = defineSecret(
  "MSG91_AUTH_KEY",
);

const msg91WhatsAppNumber = defineSecret(
  "MSG91_WHATSAPP_NUMBER",
);

const whatsappConfig = {
  integratedNumber: "918910050168",
  templateName: "collection_book_invitation_2",
  languageCode: "en",
  namespace: "213795ad_86bc_4371_9765_533f2a21dbde",
};

async function sendWhatsAppAppInvitation({
  targetPhone,
  senderName,
  requestId,
}) {
  const mobileDigits =
    normalizeIndianMobile(targetPhone);

  if (!mobileDigits) {
    throw new Error(
      "Invalid WhatsApp destination number.",
    );
  }

  const response = await fetch(
    "https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/",
    {
      method: "POST",

      headers: {
        "Content-Type": "application/json",
        authkey: msg91AuthKey.value(),
      },

      body: JSON.stringify({
        integrated_number:
          whatsappConfig.integratedNumber,

        content_type: "template",

        CRQID: requestId,

        payload: {
          messaging_product: "whatsapp",
          type: "template",

          template: {
            name:
              whatsappConfig.templateName,

            language: {
              code:
                whatsappConfig.languageCode,
              policy: "deterministic",
            },

            namespace:
              whatsappConfig.namespace,

            to_and_components: [
              {
                to: [mobileDigits],

                components: {
                  body_1: {
                    type: "text",
                    value:
                      senderName ||
                      "A Collection Book user",
                  },
                },
              },
            ],
          },
        },
      }),
    },
  );

  const responseText = await response.text();

  let result;

  try {
    result = JSON.parse(responseText);
  } catch (_) {
    result = {
      rawResponse: responseText,
    };
  }

  if (!response.ok) {
    console.error(
      "MSG91 WhatsApp request failed:",
      {
        status: response.status,
        result,
      },
    );

    throw new Error(
      `MSG91 WhatsApp failed with HTTP ${response.status}`,
    );
  }

  console.log(
    "MSG91 WhatsApp invitation accepted:",
    {
      requestId,
      targetPhone: `******${mobileDigits.slice(-4)}`,
    },
  );

  return result;
}

function getIndiaDateKey(date = new Date()) {
  const parts =
    new Intl.DateTimeFormat(
      "en-GB",
      {
        timeZone: "Asia/Kolkata",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      },
    ).formatToParts(date);

  const values = {};

  for (const part of parts) {
    if (part.type !== "literal") {
      values[part.type] =
        part.value;
    }
  }

  return (
    values.year +
    "-" +
    values.month +
    "-" +
    values.day
  );
}


/*
 * Ledger notification function
 */
exports.sendLedgerNotification =
  onDocumentCreated(
    {
      document:
        "notification_requests/{requestId}",

      region: "asia-south1",

      secrets: [msg91AuthKey,  msg91WhatsAppNumber],
    },

    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const request = snapshot.data();

      const targetPhone =
        firestorePhoneNumber(
          request.targetPhone,
        );

      const message = String(
        request.message || "",
      ).trim();

      const senderUid = String(
        request.senderUid || "",
      ).trim();

      const senderName = String(
        request.senderName ||
        "A Collection Book user",
      ).trim();

const notificationKey = String(
  request.notificationKey || "",
).trim();

const notificationParams =
  request.params &&
  typeof request.params === "object" &&
  !Array.isArray(request.params)
    ? request.params
    : {};

      const whatsappConsent =
        request.whatsappConsent === true;

      if (
        !targetPhone ||
        !message ||
        !senderUid
      ) {
        await snapshot.ref.update({
          status: "failed",
          error:
            "Invalid notification request",
        });

        return;
      }

      try {
        /*
         * Check whether Customer B is registered.
         */
        const receiverSnapshot =
          await admin
            .firestore()
            .collection("users")
            .doc(targetPhone)
            .get();

        /*
         * Customer B is registered:
         * send the normal FCM notification.
         */
       if (receiverSnapshot.exists) {
         const receiver =
           receiverSnapshot.data();

         const fcmToken =
           receiver.fcmToken;

         /*
          * ------------------------------------------------
          * SAVE NOTIFICATION FOR IN-APP NOTIFICATION SCREEN
          * ------------------------------------------------
          *
          * Notifications belong to the PERSON,
          * therefore they are stored using the
          * authenticated phone number.
          */
         const notificationRef =
           admin
             .firestore()
             .collection("users")
             .doc(targetPhone)
             .collection("notifications")
             .doc(event.params.requestId);

        const strippedMessage = message.startsWith(senderName)
          ? message.substring(senderName.length).trim()
          : message;

        const displayMessage =
          strippedMessage.length > 0
            ? strippedMessage.charAt(0).toUpperCase() +
              strippedMessage.slice(1)
            : strippedMessage;

         await notificationRef.set(
           {
             title: senderName,

             message: displayMessage,

             notificationKey:
               notificationKey,

             params:
               notificationParams,

             type: "ledger_entry",

             senderUid: senderUid,

             senderName: senderName,

             read: false,

             createdAt:
               admin.firestore
                 .FieldValue
                 .serverTimestamp(),

             requestId:
               event.params.requestId,
           },
           {
             merge: true,
           },
         );

         console.log(
           "In-app notification saved:",
           notificationRef.path,
         );

         /*
          * ------------------------------------------------
          * SEND PUSH NOTIFICATION
          * ------------------------------------------------
          */

         if (fcmToken) {
           try {
             const response =
               await admin
                 .messaging()
                 .send({
                   token:
                     fcmToken,

                   notification: {
                     title:
                       senderName,

                     body:
                       displayMessage,
                   },

                   data: {
                     type:
                       "ledger_entry",

                     senderUid:
                       senderUid,

                     requestId:
                       event.params.requestId,
                   },

                   android: {
                     priority:
                       "high",
                   },
                 });

             console.log(
               "FCM notification sent:",
               response,
             );

             await snapshot.ref.update({
               status:
                 "sent",

               channel:
                 "fcm",

               sentAt:
                 admin.firestore
                   .FieldValue
                   .serverTimestamp(),
             });
           } catch (fcmError) {
             /*
              * In-app notification has already
              * been stored, so don't lose the
              * notification history just because
              * push delivery failed.
              */
             console.error(
               "FCM send failed:",
               fcmError,
             );

             await snapshot.ref.update({
               status:
                 "sent",

               channel:
                 "in_app",

               pushError:
                 String(fcmError),

               sentAt:
                 admin.firestore
                   .FieldValue
                   .serverTimestamp(),
             });
           }
         } else {
           /*
            * User is registered but this device
            * currently has no FCM token.
            *
            * Still keep the notification in the
            * in-app Notifications screen.
            */
           console.log(
             "Receiver has no FCM token; " +
             "in-app notification stored only.",
           );

           await snapshot.ref.update({
             status:
               "sent",

             channel:
               "in_app",

             sentAt:
               admin.firestore
                 .FieldValue
                 .serverTimestamp(),
           });
         }

         return;
       }

        /*
         * Customer B is not registered.
         */
        if (!whatsappConsent) {
          await snapshot.ref.update({
            status: "skipped",
            channel: "whatsapp",
            error:
              "WhatsApp consent was not provided",
          });

          return;
        }

        /*
         * Use one invite document per destination.
         *
         * Remove "+" because using plain digits gives
         * cleaner Firestore document IDs.
         */
        /*
         * Normalize the recipient number.
         */
        const mobileDigits =
          normalizeIndianMobile(
            targetPhone,
          );

        if (!mobileDigits) {
          await snapshot.ref.update({
            status: "failed",
            channel: "whatsapp",
            error:
              "Invalid WhatsApp phone number",
          });

          return;
        }

        /*
         * Use the Indian calendar date because
         * Firebase servers usually operate in UTC.
         */
        const inviteDate =
          getIndiaDateKey();

        /*
         * One document per phone number per day.
         *
         * Example:
         * 9674230811_2026-08-20
         */
        const inviteDocumentId =
          mobileDigits +
          "_" +
          inviteDate;

        const inviteReference =
          admin
            .firestore()
            .collection(
              "whatsapp_app_invites",
            )
            .doc(inviteDocumentId);

        /*
         * Atomically reserve today's invitation.
         *
         * This also prevents two simultaneous
         * requests from sending two messages.
         */
        const shouldSend =
          await admin
            .firestore()
            .runTransaction(
              async (transaction) => {
                const existing =
                  await transaction.get(
                    inviteReference,
                  );

                const existingStatus =
                  existing.exists
                    ? existing.data()?.status
                    : null;

                /*
                 * Block another message today when
                 * an earlier request is processing
                 * or was successfully submitted.
                 *
                 * Allow retry if the earlier request
                 * definitively failed.
                 */
                if (
                  existing.exists &&
                  existingStatus !==
                    "failed"
                ) {
                  return false;
                }

                transaction.set(
                  inviteReference,
                  {
                    phoneNumber:
                      targetPhone,

                    phoneDigits:
                      mobileDigits,

                    inviteDate:
                      inviteDate,

                    status:
                      "processing",

                    senderUid:
                      senderUid,

                    senderName:
                      senderName,

                    requestId:
                      event.params.requestId,

                    createdAt:
                      admin.firestore
                        .FieldValue
                        .serverTimestamp(),

                    updatedAt:
                      admin.firestore
                        .FieldValue
                        .serverTimestamp(),
                  },
                  {
                    merge: true,
                  },
                );

                return true;
              },
            );

        if (!shouldSend) {
          console.log(
            "Daily WhatsApp limit reached:",
            {
              phoneDigits:
                mobileDigits,

              inviteDate:
                inviteDate,

              inviteDocumentId:
                inviteDocumentId,
            },
          );

          await snapshot.ref.update({
            status: "sent",
            channel: "whatsapp",

            inviteDate:
              inviteDate,

            inviteDocumentId:
              inviteDocumentId,

            sentAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          });

          return;
        }

        try {
          const msg91Result =
            await sendWhatsAppAppInvitation({
              targetPhone,
              senderName,
              requestId:
                event.params.requestId,
            });

          await inviteReference.set(
            {
              status: "sent",

              inviteDate:
                inviteDate,

              templateName:
                whatsappConfig.templateName,

              sentAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),

              msg91ResponseType:
                String(
                  msg91Result?.type ||
                  msg91Result?.status ||
                  "",
                ),
            },
            {
              merge: true,
            },
          );

          await snapshot.ref.update({
            status: "sent",
            channel: "whatsapp",

            sentAt: admin.firestore
              .FieldValue
              .serverTimestamp(),
          });
        } catch (error) {
          await inviteReference.set(
            {
              status: "failed",
              error: String(error),

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },

            {
              merge: true,
            },
          );

          throw error;
        }
      } catch (error) {
        console.error(
          "Notification delivery failed:",
          error,
        );

        await snapshot.ref.update({
          status: "failed",
          error: String(error),
        });
      }
    },
  );

/*
 * Converts a valid Indian mobile number to:
 * 919205676949
 */
function normalizeIndianMobile(value) {
  if (
    typeof value !== "string" &&
    typeof value !== "number"
  ) {
    return null;
  }

  let digits = String(value).replace(
    /\D/g,
    "",
  );

  if (
    digits.length === 10 &&
    /^[6-9]\d{9}$/.test(digits)
  ) {
    digits = `91${digits}`;
  }

  if (/^91[6-9]\d{9}$/.test(digits)) {
    return digits;
  }

  return null;
}

/*
 * MSG91 may return the verified mobile number under
 * different fields depending on the widget/API version.
 *
 * This searches only the MSG91 verified response.
 */
function extractVerifiedMobile(response) {
  const visited = new Set();

  function search(value) {
    const directMobile =
      normalizeIndianMobile(value);

    if (directMobile) {
      return directMobile;
    }

    if (
      !value ||
      typeof value !== "object" ||
      visited.has(value)
    ) {
      return null;
    }

    visited.add(value);

    const preferredFields = [
      "identifier",
      "mobile",
      "mobileNumber",
      "mobile_number",
      "phone",
      "phoneNumber",
      "phone_number",
      "number",
    ];

    for (const field of preferredFields) {
      if (
        Object.prototype.hasOwnProperty.call(
          value,
          field,
        )
      ) {
        const mobile = search(
          value[field],
        );

        if (mobile) {
          return mobile;
        }
      }
    }

    const containerFields = [
      "data",
      "message",
      "result",
      "response",
      "details",
      "user",
    ];

    for (const field of containerFields) {
      if (
        Object.prototype.hasOwnProperty.call(
          value,
          field,
        )
      ) {
        const mobile = search(
          value[field],
        );

        if (mobile) {
          return mobile;
        }
      }
    }

    return null;
  }

  return search(response);
}

/*
 * Produces a safe description of a response.
 *
 * It logs field names and value types only.
 * It does not log mobile numbers or tokens.
 */
function responseShape(value) {
  if (Array.isArray(value)) {
    return value.length
      ? [responseShape(value[0])]
      : [];
  }

  if (
    value &&
    typeof value === "object"
  ) {
    return Object.fromEntries(
      Object.entries(value).map(
        ([key, nestedValue]) => [
          key,
          responseShape(nestedValue),
        ],
      ),
    );
  }

  return typeof value;
}

function firestorePhoneNumber(value) {
  const digits = normalizeIndianMobile(value);

  return digits ? `+${digits}` : null;
}

/*
 * Exchanges an MSG91 access token for a Firebase
 * custom authentication token.
 */
exports.exchangeMsg91Token = onCall(
  {
    region: "asia-south1",
    secrets: [msg91AuthKey],
  },
  async (request) => {
    const accessToken =
      request.data?.accessToken;

    if (
      typeof accessToken !== "string" ||
      accessToken.length < 20 ||
      accessToken.length > 5000
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A valid MSG91 access token is required.",
      );
    }

    let msg91Response;

    try {
      msg91Response = await fetch(
        "https://api.msg91.com/api/v5/widget/verifyAccessToken",
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            authkey: msg91AuthKey.value(),
          },

          body: JSON.stringify({
            "access-token": accessToken,
          }),
        },
      );
    } catch (error) {
      console.error(
        "Unable to connect to MSG91:",
        error,
      );

      throw new HttpsError(
        "unavailable",
        "Unable to connect to MSG91.",
      );
    }

    let msg91Result;

    try {
      msg91Result =
        await msg91Response.json();
    } catch (error) {
      console.error(
        "MSG91 returned invalid JSON:",
        {
          status: msg91Response.status,
        },
      );

      throw new HttpsError(
        "unauthenticated",
        "MSG91 returned an invalid response.",
      );
    }

    if (!msg91Response.ok) {
      console.error(
        "MSG91 verification failed:",
        {
          status: msg91Response.status,
          shape: responseShape(
            msg91Result,
          ),
        },
      );

      throw new HttpsError(
        "unauthenticated",
        "MSG91 verification failed.",
      );
    }

    /*
     * Reject the response if MSG91 explicitly
     * reports a non-success result.
     */
    if (
      msg91Result?.type &&
      String(msg91Result.type)
        .toLowerCase() !== "success"
    ) {
      console.error(
        "MSG91 rejected access token:",
        {
          type: msg91Result.type,
          shape: responseShape(
            msg91Result,
          ),
        },
      );

      throw new HttpsError(
        "unauthenticated",
        "MSG91 rejected the access token.",
      );
    }

    /*
     * Extract the phone only from MSG91's
     * server-verified response.
     */
    const mobileDigits =
      extractVerifiedMobile(msg91Result);

    if (!mobileDigits) {
      console.error(
        "MSG91 mobile number missing. Response shape:",
        JSON.stringify(
          responseShape(msg91Result),
        ),
      );

      throw new HttpsError(
        "unauthenticated",
        "Verified mobile number was not returned.",
      );
    }

    const firebasePhoneNumber =
      `+${mobileDigits}`;

    let user;

    try {
      /*
       * Preserve the existing Firebase UID when the
       * number was previously registered through
       * Firebase Phone Authentication.
       */
      user = await admin
        .auth()
        .getUserByPhoneNumber(
          firebasePhoneNumber,
        );
    } catch (error) {
      if (
        error.code !==
        "auth/user-not-found"
      ) {
        console.error(
          "Firebase user lookup failed:",
          error,
        );

        throw new HttpsError(
          "internal",
          "Unable to locate the Firebase account.",
        );
      }

      /*
       * Create an account only when this phone number
       * does not already exist in Firebase Auth.
       */
      try {
        user = await admin
          .auth()
          .createUser({
            phoneNumber:
              firebasePhoneNumber,
          });
      } catch (error) {
        console.error(
          "Firebase user creation failed:",
          error,
        );

        throw new HttpsError(
          "internal",
          "Unable to create the Firebase account.",
        );
      }
    }

    let firebaseCustomToken;

    try {
      firebaseCustomToken = await admin
        .auth()
        .createCustomToken(
          user.uid,
          {
            phone_verified_by: "msg91",
          },
        );
    } catch (error) {
      console.error(
        "Custom token creation failed:",
        error,
      );

      throw new HttpsError(
        "internal",
        "Unable to create the Firebase login token.",
      );
    }

    return {
      firebaseCustomToken,
      phoneNumber: firebasePhoneNumber,
    };
  },
);