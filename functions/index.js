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

/*
 * ====================================================
 * COLLECTION BOOK LOCALIZED ENGAGEMENT TEMPLATES
 * ====================================================
 */

const engagementNotifications = {
  en: [
    { title: "Aaj ka hisaab? 👀", body: "2 minute nikalo aur aaj ka ledger update kar lo 📒" },
    { title: "Kal pe mat chhodo 😌", body: "Aaj ka hisaab aaj hi complete kar lo." },
    { title: "Customer ka 'kal de dunga' yaad hai? 👀", body: "Pending collections ek baar check kar lo 💰" },
    { title: "Hisaab yaad rakhna mushkil hai? 😵‍💫", body: "Isliye toh Collection Book hai 😌" },
    { title: "Business busy hai? 📈", body: "Hisaab messy nahi hona chahiye. Ledger update kar lo." },
    { title: "Aaj kisne payment kiya? 👀", body: "Collection Book ko bhi bata do 😄" },
    { title: "Khata check kiya? 📒", body: "Pending payments ko pending mat rehne do." },
    { title: "Ek chhota reminder 😌", body: "Sales aur payments record karna mat bhoolna." },
    { title: "Calculator ko chhutti do 😎", body: "Hisaab Collection Book mein update kar lo." },
    { title: "Business ka memory card 🧠", body: "Jo yaad nahi rakhna, Collection Book mein likh do." },
    { title: "Khata updated hai? ✅", body: "Pending collections ek baar check kar lo." },
    { title: "Paise yaad rakhne ka kaam humara 😌", body: "Bas apna ledger updated rakho." },
    { title: "Khata shaant kyun hai? 👀", body: "Business update karna reh gaya kya?" },
    { title: "Kisi ka payment pending hai? 💰", body: "Collection Book kholo aur ek baar check kar lo." },
    { title: "Hisaab clear, tension clear 😌", body: "Apna latest ledger update kar lo." },
    { title: "Kuch record karna reh toh nahi gaya? 👀", body: "Sales aur payments ek baar verify kar lo." },
    { title: "Udhaar ka hisaab ready hai? 📒", body: "Pending entries ko Collection Book mein update kar lo." },
    { title: "2 minute ka kaam ⏱️", body: "Ledger update karo aur hisaab tension-free rakho." },
    { title: "Payment aayi? 💸", body: "Record kar do, warna baad mein yaad karna padega 😄" },
    { title: "Khata kholne ka time 👀", body: "Pending dues aur recent payments check kar lo." }
  ],
  hi: [
    { title: "आज का हिसाब? 👀", body: "2 मिनट निकालो और आज का लेजर अपडेट कर लो 📒" },
    { title: "कल पे मत छोड़ो 😌", body: "आज का हिसाब आज ही पूरा कर लें।" },
    { title: "पेमेंट मिली? 💸", body: "अभी रिकॉर्ड करें, वरना बाद में याद करना पड़ेगा 😄" },
    { title: "खाता अपडेट है? ✅", body: "बकाया कलेक्शन एक बार चेक कर लें।" },
    { title: "बिजनेस का मेमोरी कार्ड 🧠", body: "जो याद नहीं रखना, कलेक्शन बुक में लिख दें।" },
    { title: "उधार का हिसाब तैयार? 📒", body: "पेंडिंग एंट्रीज को आज ही अपडेट करें।" },
    { title: "कैलकुलेटर को छुट्टी दो 😎", body: "हिसाब कलेक्शन बुक में सुरक्षित रखें।" },
    { title: "हिसाब क्लियर, टेंशन क्लियर 😌", body: "अपना लेटेस्ट लेजर अपडेट कर लें।" },
    { title: "आज किसने पेमेंट किया? 👀", body: "कलेक्शन बुक को भी बता दो 😄" },
    { title: "बिजी दिन रहा? 📈", body: "हिसाब गड़बड़ नहीं होना चाहिए। लेजर देख लें।" },
    { title: "कस्टमर का वादा याद है? 👀", body: "पेंडिंग कलेक्शन चेक करें।" },
    { title: "किताबें बंद करने का समय 📒", body: "आज की सारी सेल और पेमेंट रिकॉर्ड कर लें।" },
    { title: "छोटा सा रिमाइंडर 😌", body: "अपनी उधारी और वसूली का हिसाब रखें।" },
    { title: "हिसाब याद रखना मुश्किल है? 😵‍💫", body: "इसलिए तो कलेक्शन बुक है 😌" },
    { title: "आज की कमाई का रिकॉर्ड 💰", body: "लेजर अपडेट करें और रिलैक्स करें।" },
    { title: "आपका डिजिटल मुनीम 🧠", body: "हिसाब-किताब अब उंगलियों पर।" },
    { title: "पैसों का हिसाब, पक्का हिसाब ✅", body: "कलेक्शन बुक में एंट्री करना न भूलें।" },
    { title: "लेजर चेक किया? 👀", body: "आज की पेंडिंग ड्यूज़ और पेमेंट देख लें।" },
    { title: "सिर्फ 2 मिनट का काम ⏱️", body: "लेजर अपडेट करें और बेफिक्र हो जाएं।" },
    { title: "बिजनेस बढ़ेगा, जब हिसाब रहेगा सही 🚀", body: "आज की एंट्रीज पूरी करें।" }
  ],
  bn: [
    { title: "আজকের হিসাব? 👀", body: "২ মিনিট সময় দিন এবং আজকের লেজার আপডেট করুন 📒" },
    { title: "বকেয়া চেক করেছেন? 📒", body: "পেন্ডিং পেমেন্টগুলো একবার দেখে নিন।" },
    { title: "পেমেন্ট পেয়েছেন? 💸", body: "এখনই রেকর্ড করুন, নাহলে পরে মনে রাখা কঠিন হবে 😄" },
    { title: "হিসাব ক্লিয়ার, টেনশন ক্লিয়ার 😌", body: "আপনার লেজারটি আপডেট রাখুন।" },
    { title: "ব্যবসায় ব্যস্ত? 📈", body: "হিসাব যেন এলোমেলো না হয়। লেজার আপডেট করুন।" },
    { title: "কালকের জন্য ফেলে রাখবেন না 😌", body: "আজকের হিসাব আজই শেষ করুন।" },
    { title: "কাস্টমারের কথা মনে আছে? 👀", body: "বকেয়া টাকা আদায়ের জন্য লেজার দেখুন।" },
    { title: "ব্যবসায়ের মেমরি কার্ড 🧠", body: "যা মনে রাখতে চান না, কালেকশন বুক-এ লিখে রাখুন।" },
    { title: "ক্যালকুলেটরকে ছুটি দিন 😎", body: "সব হিসাব কালেকশন বুক-এ রেকর্ড করুন।" },
    { title: "আজ কে পেমেন্ট করল? 👀", body: "কালেকশন বুক-কেও জানিয়ে দিন 😄" },
    { title: "উধারের হিসাব কি তৈরি? 📒", body: "পেন্ডিং এন্ট্রিগুলো আজই আপডেট করুন।" },
    { title: "মাত্র ২ মিনিটের কাজ ⏱️", body: "লেজার আপডেট করে নিশ্চিন্ত থাকুন।" },
    { title: "হিসাব মনে রাখা কঠিন? 😵‍💫", body: "আপনার জন্য আছে কালেকশন বুক 😌" },
    { title: "হিসাব ঠিক তো বিজনেস ঠিক ✅", body: "আজকের এন্ট্রিগুলো সেরে ফেলুন।" },
    { title: "বিকেলের চা আর লেজার আপডেট ☕", body: "আজকের সব লেনদেন রেকর্ড করুন।" },
    { title: "ডিজিটাল খাতা চেক করুন 👀", body: "বকেয়া আর পেমেন্টগুলো যাচাই করে নিন।" },
    { title: "আজকের ইনকাম রেকর্ড করুন 💰", body: "কালেকশন বুক আপডেট রাখুন।" },
    { title: "সহজ হিসাব, সহজ ব্যবসা 🚀", body: "লেজার আপডেট করে ফেলুন।" }
  ],
  mr: [
    { title: "आजचा हिशोब? 👀", body: "२ मिनिटे काढा आणि आजचा लेजर अपडेट करा 📒" },
    { title: "पेमेंट मिळाले? 💸", body: "आत्ताच रेकॉर्ड करा, नाहीतर नंतर लक्षात ठेवावे लागेल 😄" },
    { title: "खाते अपडेट आहे का? ✅", body: "थकीत येणे एकदा तपासून घ्या।" },
    { title: "हिशोब क्लिअर, टेन्शन क्लिअर 😌", body: "तुमचा लेजर अपडेट ठेवा।" },
    { title: "व्यवसायात व्यस्त आहात? 📈", body: "हिशोब विस्कळीत होऊ देऊ नका. लेजर अपडेट करा।" },
    { title: "उद्यावर टाकू नका 😌", body: "आजचा हिशोब आजच पूर्ण करा।" },
    { title: "ग्राहकाचे आश्वासन आठवतेय? 👀", body: "थकीत वसुलीसाठी लेजर चेक करा।" },
    { title: "व्यवसायाचे मेमरी कार्ड 🧠", body: "जे लक्षात ठेवायचे नाही, ते कलेक्शन बुकमध्ये लिहा।" },
    { title: "कॅल्क्युलेटरला सुट्टी द्या 😎", body: "सर्व हिशोब कलेक्शन बुकमध्ये सुरक्षित ठेवा।" },
    { title: "आज कोणी पेमेंट केले? 👀", body: "कलेक्शन बुकला पण सांगा 😄" },
    { title: "उधारीचा हिशोब तयार आहे का? 📒", body: "प्रलंबित नोंदी आजच पूर्ण करा।" },
    { title: "फक्त २ मिनिटांचे काम ⏱️", body: "लेजर अपडेट करा आणि निर्धास्त व्हा।" },
    { title: "हिशोब लक्षात ठेवणे कठीण आहे? 😵‍💫", body: "त्यासाठीच कलेक्शन बुक आहे 😌" },
    { title: "हिशोब पक्का, व्यवसाय नक्की ✅", body: "आजच्या नोंदी पूर्ण करा।" },
    { title: "डिजिटल लेजर तपासा 👀", body: "आजचे येणे आणि देणे तपासून घ्या।" },
    { title: "आजची कमाई रेकॉर्ड करा 💰", body: "लेजर अपडेट ठेवा।" },
    { title: "व्यवसाय वाढवा, हिशोब ठेवा 🚀", body: "आजच्या नोंदी अपडेट करा।" }
  ],
  ta: [
    { title: "இன்றைய கணக்கு? 👀", body: "2 நிமிடம் ஒதுக்கி இன்றைய லெட்ஜரை அப்டேட் செய்யவும் 📒" },
    { title: "வசூல் நிலுவையில் உள்ளதா? 💰", body: "நிலுவையில் உள்ள வசூல்களை ஒருமுறை சரிபார்க்கவும்." },
    { title: "பணம் கிடைத்ததா? 💸", body: "உடனடியாகப் பதிவு செய்யுங்கள், இல்லையெனில் பிறகு நினைவில் வைக்க வேண்டியிருக்கும் 😄" },
    { title: "வியாபாரத்தின் நினைவக அட்டை 🧠", body: "நினைவில் வைக்க விரும்பாததை கலெக்ஷன் புக்கில் எழுதி விடுங்கள்." },
    { title: "கணக்கு சரியாக இருந்தால் நிம்மதி 😌", body: "உங்கள் லெட்ஜரை அப்டேட் செய்யுங்கள்." },
    { title: "நாளைக்கு என்று தள்ளிப்போடாதீர்கள் 😌", body: "இன்றைய கணக்கை இன்றே முடியுங்கள்." },
    { title: "வாடிக்கையாளரின் வாக்குறுதி நினைவிருக்கிறதா? 👀", body: "நிலுவையில் உள்ள வசூலைச் சரிபார்க்கவும்." },
    { title: "கால்குலேட்டருக்கு விடுமுறை கொடுங்கள் 😎", body: "கணக்குகளை கலெக்ஷன் புக்கில் சேமிக்கவும்." },
    { title: "இன்று யார் பணம் செலுத்தினார்கள்? 👀", body: "கலெக்ஷன் புக்கிலும் பதிவு செய்யுங்கள் 😄" },
    { title: "வியாபாரத்தில் பிஸியா? 📈", body: "கணக்கு குழப்பமாக இருக்கக்கூடாது. லெட்ஜரை அப்டேட் செய்யுங்கள்." },
    { title: "கடன்கணக்கு தயாரா? 📒", body: "நிலுவையில் உள்ள பதிவுகளை இன்று அப்டேட் செய்யவும்." },
    { title: "வெறும் 2 நிமிட வேலை ⏱️", body: "லெட்ஜரை அப்டேட் செய்து கவலையின்றி இருங்கள்." },
    { title: "கணக்குகளை நினைவில் வைப்பது கடினமா? 😵‍💫", body: "அதற்காகத்தான் கலெக்ஷன் புக் 😌" },
    { title: "டிஜிட்டல் லெட்ஜரைச் சரிபார்க்கவும் 👀", body: "இன்றைய வரவு செலவுகளைப் பாருங்கள்." },
    { title: "இன்றைய லாபத்தைப் பதிவு செய்யுங்கள் 💰", body: "லெட்ஜரை அப்டேட் செய்யுங்கள்." },
    { title: "சரியான கணக்கு, சிறந்த வியாபாரம் ✅", body: "இன்றைய எண்ட்ரிகளை முடிக்கவும்." },
    { title: "உங்கள் வணிக முனீம் 🧠", body: "கணக்குகள் இப்போது உங்கள் விரல் நுனியில்." }
  ],
  te: [
    { title: "ఈరోజు లెక్కలు? 👀", body: "2 నిమిషాలు కేటాయించి ఈరోజు లెడ్జర్‌ని అప్‌డేట్ చేయండి 📒" },
    { title: "బకాయిలు ఉన్నాయా? 💰", body: "పెండింగ్ వసూళ్లను ఒకసారి తనిఖీ చేయండి." },
    { title: "డబ్బులు అందాయా? 💸", body: "వెంటనే రికార్డ్ చేయండి, లేదంటే తర్వాత గుర్తుంచుకోవడం కష్టం 😄" },
    { title: "వ్యాపార మెమరీ కార్డ్ 🧠", body: "గుర్తుంచుకోలేని వాటిని కలెక్షన్ బుక్ లో రాసుకోండి." },
    { title: "లెక్క క్లియర్, టెన్షన్ క్లియర్ 😌", body: "మీ లేటెస్ట్ లెడ్జర్ ని అప్‌డేట్ చేయండి." },
    { title: "రేపటి వరకు ఆగకండి 😌", body: "ఈరోజు లెక్క ఈరోజే పూర్తి చేయండి." },
    { title: "కస్టమర్ మాట గుర్తుందా? 👀", body: "పెండింగ్ వసూళ్ల కోసం లెడ్జర్ చూడండి." },
    { title: "క్యాలిక్యులేటర్ కు సెలవు ఇవ్వండి 😎", body: "అన్ని లెక్కలు కలెక్షన్ బుక్ లో భద్రపరుచుకోండి." },
    { title: "ఈరోజు ఎవరు పేమెంట్ చేశారు? 👀", body: "కలెక్షన్ బుక్ లో కూడా ఎంట్రీ చేయండి 😄" },
    { title: "వ్యాపారంలో బిజీగా ఉన్నారా? 📈", body: "లెక్కలు అస్తవ్యస్తం కాకూడదు. లెడ్జర్ ని అప్‌డేట్ చేయండి." },
    { title: "ఉధారి లెక్క రెడీగా ఉందా? 📒", body: "పెండింగ్ ఎంట్రీలను ఈరోజే పూర్తి చేయండి." },
    { title: "కేవలం 2 నిమిషాల పని ⏱️", body: "లెడ్జర్ ని అప్‌డేట్ చేసి ప్రశాంతంగా ఉండండి." },
    { title: "లెక్కలు గుర్తుంచుకోవడం కష్టమా? 😵‍💫", body: "అందుకే మీ కోసం కలెక్షన్ బుక్ 😌" },
    { title: "డిజిటల్ లెడ్జర్ ని చెక్ చేయండి 👀", body: "ఈరోజు లావాదేవీలను ఒకసారి చూడండి." },
    { title: "ఈరోజు ఆదాయాన్ని రికార్డ్ చేయండి 💰", body: "లెడ్జర్ ని అప్‌డేట్ చేసుకోండి." },
    { title: "లెక్క పక్కా, వ్యాపారం పక్కా ✅", body: "ఈరోజు ఎంట్రీలు పూర్తి చేయండి." },
    { title: "మీ డిజిటల్ అకౌంటెంట్ 🧠", body: "లెక్కలన్నీ ఇక మీ వేలి చివర." }
  ]
};

function getRandomEngagementNotification(lang, lastTitle) {
  const candidates = engagementNotifications[lang] || engagementNotifications['en'];
  let filtered = candidates;

  if (lastTitle) {
    filtered = candidates.filter(item => item.title !== lastTitle);
  }

  if (filtered.length === 0) filtered = candidates;

  const randomIndex = Math.floor(Math.random() * filtered.length);
  return filtered[randomIndex];
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
    const userLang = user['cb-lang'] || 'en';
    const selectedNotification =
      getRandomEngagementNotification(
        userLang,
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
 * Triggers twice daily at random-looking odd times:
 * 1. Morning Window: 11:00 AM - 2:00 PM IST
 * 2. Evening Window: 5:00 PM - 8:30 PM IST
 *
 * The function runs frequently and selects one deterministic
 * "random odd" slot for each window based on the current date.
 */
exports.sendDailyEngagementNotification =
  onSchedule(
    {
      schedule: "7,23,37,53 11-13,17-20 * * *",
      timeZone: "Asia/Kolkata",
      region: "asia-south1",
    },

    async () => {
      const now = new Date();
      // IST is UTC + 5.5 hours
      const ist = new Date(now.getTime() + (5.5 * 60 * 60 * 1000));
      const hour = ist.getUTCHours();
      const minute = ist.getUTCMinutes();

      const dateKey = getIndiaDateKey(now);

      // Deterministic seed for today to ensure a single stable selection per day
      let hash = 0;
      for (let i = 0; i < dateKey.length; i++) {
        hash = ((hash << 5) - hash) + dateKey.charCodeAt(i);
        hash |= 0;
      }
      const seed = Math.abs(hash);

      const targetMins = [7, 23, 37, 53];

      // Morning Window (11:00 - 14:00): 12 potential slots (4 per hour * 3 hours)
      const morningSlotIndex = seed % 12;
      const morningHour = 11 + Math.floor(morningSlotIndex / 4);
      const morningMin = targetMins[morningSlotIndex % 4];

      // Evening Window (17:00 - 20:30): 14 potential slots (4 per hour * 3.5 hours)
      const eveningSlotIndex = (seed >> 4) % 14;
      const eveningHour = 17 + Math.floor(eveningSlotIndex / 4);
      const eveningMin = targetMins[eveningSlotIndex % 4];

      if (
        (hour === morningHour && minute === morningMin) ||
        (hour === eveningHour && minute === eveningMin)
      ) {
        console.log(`Triggering daily engagement for today's slot: ${hour}:${minute}`);
        await sendEngagementNotifications();
      } else {
        // Quiet skip for other intervals
      }
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