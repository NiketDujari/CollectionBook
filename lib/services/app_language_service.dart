import 'package:flutter/material.dart';
import 'storage_service.dart';

class AppLanguageService {
  static final AppLanguageService instance = AppLanguageService._internal();
  AppLanguageService._internal();

  final ValueNotifier<String> currentLanguage = ValueNotifier('en');

  void initialize() {
    final String? savedLang = StorageService.get('cb-lang');
    if (savedLang != null) {
      currentLanguage.value = savedLang;
    }
  }

  Future<void> setLanguage(String lang) async {
    currentLanguage.value = lang;
    await StorageService.set('cb-lang', lang);
  }

  String translate(String key) {
    // Basic translation map for native screens
    final Map<String, Map<String, String>> translations = {
      'en': {
        'privacy_policy': 'Privacy Policy',
        'terms_conditions': 'Terms & Conditions',
        'app_sub': 'CREDIT & LEDGER MANAGEMENT',
        'trusted_by': 'TRUSTED BY LOCAL TRADERS',
      },
      'hi': {
        'privacy_policy': 'गोपनीयता नीति',
        'terms_conditions': 'नियम एवं शर्तें',
        'app_sub': 'क्रेडिट और लेजर प्रबंधन',
        'trusted_by': 'स्थानीय व्यापारियों द्वारा विश्वसनीय',
      },
      'bn': {
        'privacy_policy': 'গোপনীয়তা নীতি',
        'terms_conditions': 'শর্তাবলী',
        'app_sub': 'ক্রেডিট এবং লেজার ম্যানেজমেন্ট',
        'trusted_by': 'স্থানীয় ব্যবসায়ীদের দ্বারা বিশ্বস্ত',
      },
      'mr': {
        'privacy_policy': 'गोपनीयता धोरण',
        'terms_conditions': 'नियम आणि अटी',
        'app_sub': 'क्रेडिट आणि लेजर व्यवस्थापन',
        'trusted_by': 'स्थानिक व्यापाऱ्यांकडून विश्वसनीय',
      },
      'ta': {
        'privacy_policy': 'தனியுரிமைக் கொள்கை',
        'terms_conditions': 'விதிமுறைகள் & நிபந்தனைகள்',
        'app_sub': 'கடன் மற்றும் லெட்ஜர் மேலாண்மை',
        'trusted_by': 'உள்ளூர் வணிகர்களால் நம்பப்படுகிறது',
      },
      'te': {
        'privacy_policy': 'గోప్యతా విధానం',
        'terms_conditions': 'నిబంధనలు & షరతులు',
        'app_sub': 'క్రెడిట్ & లెడ్జర్ మేనేజ్‌మెంట్',
        'trusted_by': 'స్థానిక వ్యాపారుల నమ్మకం',
      },
    };

    return (translations[currentLanguage.value]?[key]) ?? translations['en']![key]!;
  }
}
