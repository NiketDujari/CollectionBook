const {
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");

const {
  onSchedule,
} = require(
  "firebase-functions/v2/scheduler"
);

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  defineSecret,
} = require("firebase-functions/params");

const admin = require("firebase-admin");

const functions = require('firebase-functions');

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

/*
 * ====================================================
 * COLLECTION BOOK ENGAGEMENT NOTIFICATION TEMPLATES
 * ====================================================
 */

const engagementNotifications = [
  {
    title: "Aaj ka hisaab? 👀",
    body:
      "2 minute nikalo aur aaj ka ledger update kar lo 📒",
  },
  {
    title: "Kal pe mat chhodo 😌",
    body:
      "Aaj ka hisaab aaj hi complete kar lo.",
  },
  {
    title:
      "Customer ka 'kal de dunga' yaad hai? 👀",
    body:
      "Pending collections ek baar check kar lo 💰",
  },
  {
    title:
      "Hisaab yaad rakhna mushkil hai? 😵‍💫",
    body:
      "Isliye toh Collection Book hai 😌",
  },
  {
    title:
      "Business busy hai? 📈",
    body:
      "Hisaab messy nahi hona chahiye. Ledger update kar lo.",
  },
  {
    title:
      "Aaj kisne payment kiya? 👀",
    body:
      "Collection Book ko bhi bata do 😄",
  },
  {
    title:
      "Khata check kiya? 📒",
    body:
      "Pending payments ko pending mat rehne do.",
  },
  {
    title:
      "Ek chhota reminder 😌",
    body:
      "Sales aur payments record karna mat bhoolna.",
  },
  {
    title:
      "Calculator ko chhutti do 😎",
    body:
      "Hisaab Collection Book mein update kar lo.",
  },
  {
    title:
      "Business ka memory card 🧠",
    body:
      "Jo yaad nahi rakhna, Collection Book mein likh do.",
  },
  {
    title:
      "Khata updated hai? ✅",
    body:
      "Pending collections ek baar check kar lo.",
  },
  {
    title:
      "Paise yaad rakhne ka kaam humara 😌",
    body:
      "Bas apna ledger updated rakho.",
  },
  {
    title:
      "Khata shaant kyun hai? 👀",
    body:
      "Business update karna reh gaya kya?",
  },
  {
    title:
      "Kisi ka payment pending hai? 💰",
    body:
      "Collection Book kholo aur ek baar check kar lo.",
  },
  {
    title:
      "Hisaab clear, tension clear 😌",
    body:
      "Apna latest ledger update kar lo.",
  },
  {
    title:
      "Kuch record karna reh toh nahi gaya? 👀",
    body:
      "Sales aur payments ek baar verify kar lo.",
  },
  {
    title:
      "Udhaar ka hisaab ready hai? 📒",
    body:
      "Pending entries ko Collection Book mein update kar lo.",
  },
  {
    title:
      "2 minute ka kaam ⏱️",
    body:
      "Ledger update karo aur hisaab tension-free rakho.",
  },
  {
    title:
      "Payment aayi? 💸",
    body:
      "Record kar do, warna baad mein yaad karna padega 😄",
  },
  {
    title:
      "Khata kholne ka time 👀",
    body:
      "Pending dues aur recent payments check kar lo.",
  },
];

function getRandomEngagementNotification(
  lastTitle,
) {
  let candidates =
    engagementNotifications;

  /*
   * Avoid sending the exact same notification
   * title twice in a row to the same user.
   */
  if (lastTitle) {
    candidates =
      engagementNotifications.filter(
        (item) =>
          item.title !== lastTitle,
      );
  }

  /*
   * Defensive fallback.
   */
  if (candidates.length === 0) {
    candidates =
      engagementNotifications;
  }

  const randomIndex =
    Math.floor(
      Math.random() *
      candidates.length
    );

  return candidates[
    randomIndex
  ];
}



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
         * ------------------------------------------------
         * RESOLVE RECEIVER (UID-BASED PREFERRED)
         * ------------------------------------------------
         *
         * Find the registered user either by:
         * 1. Querying accountPhone field (New consolidated structure)
         * 2. Checking document ID (Legacy structure)
         */
        const db = admin.firestore();
        let receiverUid = null;
        let receiverData = null;

        // 1. Try UID document lookup via accountPhone query
        const uidQuerySnapshot = await db
          .collection("users")
          .where("accountPhone", "==", targetPhone)
          .limit(1)
          .get();

        if (!uidQuerySnapshot.empty) {
          const doc = uidQuerySnapshot.docs[0];
          receiverUid = doc.id;
          receiverData = doc.data();
        } else {
          // 2. Fallback to Legacy Phone-keyed document
          const legacyDoc = await db
            .collection("users")
            .doc(targetPhone)
            .get();

          if (legacyDoc.exists) {
            receiverUid = targetPhone;
            receiverData = legacyDoc.data();
          }
        }

        /*
         * Customer B is registered:
         * send the normal FCM notification.
         */
       if (receiverUid && receiverData) {
         const fcmToken =
           receiverData.fcmToken;

         /*
          * ------------------------------------------------
          * SAVE NOTIFICATION FOR IN-APP NOTIFICATION SCREEN
          * ------------------------------------------------
          *
          * Notifications are stored in the receiver's
          * primary document (UID or Phone-legacy).
          */
         const notificationRef =
           db
             .collection("users")
             .doc(receiverUid)
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
                     priority: "high",

                     notification: {
                       channelId:
                         "collection_book_high",

                       priority:
                         "high",

                       defaultSound:
                         true,

                       defaultVibrateTimings:
                         true,
                     },
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
 * ====================================================
 * SCHEDULED ENGAGEMENT NOTIFICATIONS
 * ====================================================
 *
 * Runs in Asia/Kolkata:
 *
 * Monday    - 10:00 AM
 * Wednesday - 7:00 PM
 * Saturday  - 6:00 PM
 *
 * These are engagement pushes only. They are not saved
 * in the user's in-app notification history.
 */

async function sendEngagementNotifications() {
  const db =
    admin.firestore();

  console.log(
    "Starting scheduled engagement notifications",
  );

  const usersSnapshot =
    await db
      .collection("users")
      .get();

  if (usersSnapshot.empty) {
    console.log(
      "No Collection Book users found.",
    );

    return;
  }

  let successCount = 0;
  let failureCount = 0;
  let skippedCount = 0;
  let invalidTokenCount = 0;

  for (
    const userDocument
    of usersSnapshot.docs
  ) {
    const user =
      userDocument.data();

    /*
     * Avoid double-notifying if both legacy (phone-keyed)
     * and consolidated (UID-keyed) documents exist.
     */
    const isLegacy = userDocument.id.startsWith("+");
    if (isLegacy) {
      const consolidatedSnapshot = await db
        .collection("users")
        .where("accountPhone", "==", userDocument.id)
        .limit(1)
        .get();

      if (!consolidatedSnapshot.empty) {
        skippedCount++;
        continue;
      }
    }

    /*
     * Explicit opt-out.
     *
     * Missing field currently means enabled.
     */
    if (
      user.engagementNotificationsEnabled ===
        false
    ) {
      skippedCount++;

      continue;
    }

    const fcmToken =
      user.fcmToken;

    /*
     * Skip users without a usable FCM token.
     */
    if (
      !fcmToken ||
      typeof fcmToken !== "string"
    ) {
      skippedCount++;

      continue;
    }

    /*
     * Avoid repeating the user's previous
     * engagement notification.
     */
    const selectedNotification =
      getRandomEngagementNotification(
        user.lastEngagementNotificationTitle,
      );

    try {
      await admin
        .messaging()
        .send({
          token:
            fcmToken,

          notification: {
            title:
              selectedNotification.title,

            body:
              selectedNotification.body,
          },

          data: {
            type:
              "engagement",

            source:
              "scheduled",
          },

         android: {
           priority:
             "high",

           notification: {
             channelId:
               "collection_book_engagement_v1",

             priority:
               "high",

             visibility:
               "public",

             defaultSound:
               true,

             defaultVibrateTimings:
               true,
           },
         },
        });

      /*
       * Save the last notification so that the
       * next run does not immediately repeat it.
       */
      await userDocument.ref.set(
        {
          lastEngagementNotificationTitle:
            selectedNotification.title,

          lastEngagementNotificationAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        },
        {
          merge: true,
        },
      );

      successCount++;

      console.log(
        "Engagement notification sent:",
        userDocument.id,
      );
    } catch (error) {
      failureCount++;

      console.error(
        "Scheduled notification failed:",
        userDocument.id,
        error,
      );

      const errorCode =
        error?.code || "";

      /*
       * Remove FCM tokens that Firebase says are
       * no longer valid.
       */
      const invalidToken =
        errorCode ===
          "messaging/registration-token-not-registered" ||
        errorCode ===
          "messaging/invalid-registration-token" ||
        errorCode ===
          "messaging/invalid-argument";

      if (invalidToken) {
        invalidTokenCount++;

        await userDocument.ref.update({
          fcmToken:
            admin.firestore
              .FieldValue
              .delete(),

          fcmUpdatedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        });

        console.log(
          "Removed invalid FCM token:",
          userDocument.id,
        );
      }
    }
  }

  console.log(
    "Scheduled notification run completed",
    {
      totalUsers:
        usersSnapshot.size,

      success:
        successCount,

      failed:
        failureCount,

      skipped:
        skippedCount,

      invalidTokensRemoved:
        invalidTokenCount,
    },
  );
}

/*
 * ====================================================
 * DAILY ENGAGEMENT NOTIFICATION
 * ====================================================
 *
 * Every day at 7:00 PM IST.
 */
exports.sendDailyEngagementNotification =
  onSchedule(
    {
      schedule:
        "30 11,17 * * *",

      timeZone:
        "Asia/Kolkata",

      region:
        "asia-south1",
    },

    async () => {
      await sendEngagementNotifications();
    },
  );

  /**
   * Helper to check if a user has created any ledger entries.
   * Connects the phone-number document to the UID document where the ledger subcollection lives.
   */
  async function userHasLedgerEntries(db, uid) {
    try {
      const ledgerSnapshot = await db
        .collection("users")
        .doc(uid)
        .collection("ledger")
        .limit(1)
        .get();

      return !ledgerSnapshot.empty;
    } catch (error) {
      console.error(
        "Error checking ledger entries for UID:",
        uid,
        error,
      );

      return false;
    }
  }

  /**
   * 1. HOURLY ONBOARDING NUDGE (~1 Hour Post-Registration)
   * Runs every hour to catch users registered between 60 and 119 minutes ago.
   */
  exports.sendHourlyOnboardingNudge = onSchedule(
    {
      schedule: "0 * * * *",
      timeZone: "Asia/Kolkata",
      region: "asia-south1",
    },
    async () => {
      const db = admin.firestore();
      console.log("Starting hourly onboarding nudge run");

      const now = new Date();
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
      const twoHoursAgo = new Date(now.getTime() - 120 * 60 * 1000);

      const usersSnapshot = await db
        .collection("users")
        .where("legalAcceptedAt", "<=", oneHourAgo)
        .where("legalAcceptedAt", ">", twoHoursAgo)
        .get();

      if (usersSnapshot.empty) {
        console.log("No new users found in the 1-2 hour window.");
        return;
      }

      let successCount = 0;
      let failureCount = 0;
      let skippedCount = 0;
      let invalidTokenCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const user = userDoc.data();
        const fcmToken = user.fcmToken;
        const phoneNumber = user.accountPhone || userDoc.id;

        if (!fcmToken || typeof fcmToken !== "string") {
          skippedCount++;
          continue;
        }

        const isLegacy =
          /^\+91\d{10}$/.test(
            userDoc.id,
          );

        if (isLegacy) {
          skippedCount++;
          continue;
        }

        // Check if they have already added a ledger entry
      const hasLedger =
        await userHasLedgerEntries(
          db,
          userDoc.id,
        );
        if (hasLedger) {
          skippedCount++;
          continue;
        }

        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "Add your first ledger ⏱️",
              body: "Add your first contact and record their pending balance in just 30 seconds.",
            },
            data: {
              route: "new_entry",
              type: "onboarding",
              timing: "hourly",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "collection_book_engagement_v1",
                priority: "high",
                visibility: "public",
                defaultSound: true,
                defaultVibrateTimings: true,
              },
            },
          });

          successCount++;
          console.log("Hourly onboarding notification sent:", phoneNumber);
        } catch (error) {
          failureCount++;
          console.error("Hourly onboarding notification failed:", phoneNumber, error);

          const errorCode = error?.code || "";
          const invalidToken =
            errorCode === "messaging/registration-token-not-registered" ||
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/invalid-argument";

          if (invalidToken) {
            invalidTokenCount++;
            await userDoc.ref.update({
              fcmToken: admin.firestore.FieldValue.delete(),
              fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log("Removed invalid FCM token for phone:", phoneNumber);
          }
        }
      }

      console.log("Hourly onboarding run completed", {
        totalFound: usersSnapshot.size,
        success: successCount,
        failed: failureCount,
        skipped: skippedCount,
        invalidTokensRemoved: invalidTokenCount,
      });
    }
  );

  /**
   * 2. DAILY ONBOARDING REMINDERS (Day 1, Day 3, Day 7)
   * Runs once a day at 01:00 PM IST.
   */
  exports.sendDailyOnboardingReminders = onSchedule(
    {
      schedule: "0 13 * * *",
      timeZone: "Asia/Kolkata",
      region: "asia-south1",
    },
    async () => {
      const db = admin.firestore();
      console.log("Starting daily onboarding reminders run");

      const today = new Date();
      const targetDays = [1, 3, 7];

      for (const daysAgo of targetDays) {
        const targetDate = new Date(today);
        targetDate.setDate(today.getDate() - daysAgo);

        const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
        const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

        const usersSnapshot = await db
          .collection("users")
          .where("legalAcceptedAt", ">=", startOfDay)
          .where("legalAcceptedAt", "<=", endOfDay)
          .get();

        if (usersSnapshot.empty) {
          console.log(`No users found for Day ${daysAgo} milestone.`);
          continue;
        }

        let title = "";
        let body = "";

        if (daysAgo === 1) {
          title = "Start your first ledger 📊";
          body = "Don't let your dues pile up. Add your first contact and record their pending balance.";
        } else if (daysAgo === 3) {
          title = "Keep your accounts organized 📝";
          body = "Collection Book remembers so you don't have to. Tap here to set up your first ledger.";
        } else if (daysAgo === 7) {
          title = "Ready to start your Collection Book? 🚀";
          body = "Start tracking your sales and payments today to keep your business cash flow organized.";
        }

        let successCount = 0;
        let failureCount = 0;
        let skippedCount = 0;
        let invalidTokenCount = 0;

        for (const userDoc of usersSnapshot.docs) {
          const user = userDoc.data();
          const fcmToken = user.fcmToken;
          const phoneNumber = user.accountPhone || userDoc.id;

          if (!fcmToken || typeof fcmToken !== "string") {
            skippedCount++;
            continue;
          }

          const isLegacy =
            /^\+91\d{10}$/.test(
              userDoc.id,
            );

          if (isLegacy) {
            skippedCount++;
            continue;
          }

          const hasLedger =
            await userHasLedgerEntries(
              db,
              userDoc.id,
            );
          if (hasLedger) {
            skippedCount++;
            continue;
          }

          try {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: title,
                body: body,
              },
              data: {
                route: "new_entry",
                type: "onboarding",
                timing: `day_${daysAgo}`,
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "collection_book_engagement_v1",
                  priority: "high",
                  visibility: "public",
                  defaultSound: true,
                  defaultVibrateTimings: true,
                },
              },
            });

            successCount++;
            console.log(`Day ${daysAgo} onboarding notification sent:`, phoneNumber);
          } catch (error) {
            failureCount++;
            console.error(`Day ${daysAgo} onboarding notification failed:`, phoneNumber, error);

            const errorCode = error?.code || "";
            const invalidToken =
              errorCode === "messaging/registration-token-not-registered" ||
              errorCode === "messaging/invalid-registration-token" ||
              errorCode === "messaging/invalid-argument";

            if (invalidToken) {
              invalidTokenCount++;
              await userDoc.ref.update({
                fcmToken: admin.firestore.FieldValue.delete(),
                fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
              console.log("Removed invalid FCM token for phone:", phoneNumber);
            }
          }
        }

        console.log(`Day ${daysAgo} onboarding run completed`, {
          totalFound: usersSnapshot.size,
          success: successCount,
          failed: failureCount,
          skipped: skippedCount,
          invalidTokensRemoved: invalidTokenCount,
        });
      }
    }
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