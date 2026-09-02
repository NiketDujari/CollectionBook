import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection_book/widgets/splash_content.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../services/session_service.dart';
import '../services/webview_bridge.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import '../services/meta_analytics_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:path_provider/path_provider.dart';

import 'login_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  late WebViewBridge bridge;
  final currentUser = FirebaseAuth.instance.currentUser;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;

  bool _webViewReady = false;
  bool _showStartupSplash = true;

  static const MethodChannel pdfChannel = MethodChannel("collection_book/pdf");

  @override
  void initState() {
    super.initState();
    MetaAnalyticsService.initialize();
    controller = WebViewController()
      ..setBackgroundColor(const Color(0xFFEFE7D6))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            print(
              "DEBUG: Current Customer Phone -> ${currentUser?.phoneNumber}",
            );

            await controller.runJavaScript("""
            window.currentUserUid = "${currentUser?.uid ?? ''}";
            window.currentUserPhone = "${currentUser?.phoneNumber ?? ''}";
           
            window.flutterSession = {
    mode:
        "${SessionService.activeMode}",

    isEmployee:
        ${SessionService.isEmployee},

    hasEmployment:
        ${SessionService.hasEmployment},

    hasOwnerBusiness:
        ${SessionService.hasOwnerBusiness},

    canSwitchRole:
        ${SessionService.canSwitchRole},

    authUid:
        "${currentUser?.uid ?? ''}",

    userPhone:
        "${currentUser?.phoneNumber ?? ''}",

    employeePhone:
        "${SessionService.employeePhone ?? ''}",

    employeeName:
        ${jsonEncode(SessionService.employeeName ?? '')},

    /*
     * THIS is the UID that owns all ledger data
     * in the selected mode.
     */
    businessOwnerUid:
        "${SessionService.businessUid ?? ''}",

    ownerId:
        "${SessionService.businessUid ?? ''}",

    businessName:
        ${jsonEncode(SessionService.businessName ?? '')},

    businessOwnerName:
        ${jsonEncode(SessionService.businessOwnerName ?? '')},

    ownerPhone:
        ${jsonEncode(SessionService.businessOwnerPhone ?? '')},

    businessArea:
        ${jsonEncode(SessionService.businessArea ?? '')},

    businessGst:
        ${jsonEncode(SessionService.businessGst ?? '')},

    permissions: {
        add:
            ${SessionService.permissions["add"] == true},

        view:
            ${SessionService.permissions["view"] == true},
            
             manageContacts:
        ${SessionService.permissions["manageContacts"] == true},

        del:
            ${SessionService.permissions["del"] == true}
    }
};

            console.log("Flutter Session Injected", window.flutterSession);

           if (typeof applyEmployeeAccessControls === 'function') {
    applyEmployeeAccessControls();
}

if (typeof updateRoleModeUI === 'function') {
    updateRoleModeUI();
}
            """);
            _webViewReady = true;

            await _startAllRealtimeListeners();

            if (mounted) {
              await FirestoreService.get(
                'cb-ledger-v1',
                webViewController: controller,
              );
            }

            /*
 * Give the HTML one frame to render after
 * profile/session/ledger data has been injected.
 */
            await Future.delayed(const Duration(milliseconds: 100));

            if (mounted) {
              setState(() {
                _showStartupSplash = false;
              });
            }
          },
        ),
      );
    bridge = WebViewBridge(controller);

    controller.addJavaScriptChannel(
      "StorageBridge",

      onMessageReceived: (message) {
        bridge.handleMessage(message.message);
      },
    );

    controller.addJavaScriptChannel(
      "NativeBridge",

      onMessageReceived: (message) async {
        final data = message.message;

        if (data.startsWith('META_EVENT:')) {
          final event = data
              .replaceFirst(
            'META_EVENT:',
            '',
          )
              .trim();

          switch (event) {
            case 'CUSTOMER_ADDED':
              await MetaAnalyticsService
                  .logCustomerAdded();
              break;

            case 'LEDGER_ENTRY_CREATED':
              await MetaAnalyticsService
                  .logLedgerEntryCreated();

              await MetaAnalyticsService
                  .logFirstLedgerCreated();

              break;

            case 'PAYMENT_RECORDED':
              await MetaAnalyticsService
                  .logPaymentRecorded();
              break;

            case 'LEDGER_SHARED':
              await MetaAnalyticsService
                  .logLedgerShared();
              break;

            case 'REPORT_GENERATED':
              await MetaAnalyticsService
                  .logReportGenerated();
              break;

            default:
              debugPrint(
                'Unknown Meta event: $event',
              );
          }

        } else if (data.startsWith("CALL:")) {
          final phone = data.replaceFirst("CALL:", "");

          await launchUrl(Uri.parse("tel:$phone"));
        } else if (data.startsWith("WHATSAPP:")) {
          final payload = data.replaceFirst("WHATSAPP:", "");

          final parts = payload.split("|");

          if (parts.length >= 2) {
            final phone = parts[0];
            final message = parts.sublist(1).join("|");

            final uri = Uri.parse(
              "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}",
            );

            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else if (data.startsWith("SAVEPDF:")) {
          final payload = data.replaceFirst("SAVEPDF:", "");

          final separator = payload.indexOf("|");

          if (separator == -1) return;

          final filename = payload.substring(0, separator);

          final base64Pdf = payload.substring(separator + 1);

          try {
            final bytes = base64Decode(base64Pdf);

            final success = await pdfChannel.invokeMethod<bool>("savePdf", {
              "filename": filename,
              "bytes": bytes,
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success == true ? "Saved to Downloads" : "Failed to save PDF",
                ),
              ),
            );
          } catch (e) {
            debugPrint(e.toString());
          }
        } else if (data.startsWith("SHAREPDF:")) {
          final payload = data.replaceFirst("SHAREPDF:", "");

          final separator = payload.indexOf("|");

          if (separator == -1) return;

          final filename = payload.substring(0, separator);

          final base64Pdf = payload.substring(separator + 1);

          try {
            final bytes = base64Decode(base64Pdf);

            final tempDir = await getTemporaryDirectory();

            final file = File("${tempDir.path}/$filename");

            await file.writeAsBytes(bytes);

            await Share.shareXFiles(
              [XFile(file.path)],
              subject: filename,
              text: "Please find the attached ledger statement.",
            );
          } catch (e) {
            debugPrint("Share PDF Error: $e");
          }
        } else if (
        data == 'RESET_ACCOUNT'
        ) {
          try {

            await _stopAllRealtimeListeners();

            await _resetCurrentAccount();

            if (!mounted) {
              return;
            }

            Navigator.of(context)
                .pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) =>
                const LoginScreen(),
              ),
                  (route) => false,
            );

          } catch (
          error,
          stackTrace
          ) {

            debugPrint(
              'RESET_ACCOUNT failed: $error',
            );

            debugPrintStack(
              stackTrace:
              stackTrace,
            );

            try {
              await controller.runJavaScript('''
        (function () {
          var button = document.getElementById('resetBtn');

          if (button) {
            button.disabled = false;
            button.textContent = 'Reset my data on this device';
          }

          if (typeof showToast === 'function') {
            showToast('Reset failed. Please try again.');
          }
        })();
        ''');
            } catch (javascriptError) {
              debugPrint(
                'Could not report reset failure to WebView: $javascriptError',
              );
            }
          }
        } else if (data == "LOGOUT") {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else if (data == 'SYNC_CONTACTS') {
          await fetchAndSendContacts(controller);
        } // Inside your WebView setup where you listen to NativeBridge.postMessage
        else if (data.startsWith("CHECK_EMPLOYEE:")) {
          final payload = data.replaceFirst("CHECK_EMPLOYEE:", "");
          final phoneToCheck = payload;

          final bool existsGlobally = await checkIfEmployeeExistsGlobally(
            phoneToCheck,
          );

          if (existsGlobally) {
            // 1. Show a native Flutter SnackBar guaranteed to be on top
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This number is already registered as an employee with another business.',
                ),
                backgroundColor: Colors.red,
                behavior:
                    SnackBarBehavior.floating, // Floats above bottom sheets
                margin: EdgeInsets.only(
                  bottom: 20,
                  left: 10,
                  right: 10,
                ), // Adjust if needed
              ),
            );

            // 2. Tell JavaScript to fail quietly (stop loading spinners, etc.)
            // We send an empty string so the web app doesn't show its own hidden error
            controller.runJavaScript(
              "window.onEmployeeValidationResult(false, '');",
            );
          } else {
            // Tell JavaScript it is safe to proceed
            controller.runJavaScript(
              "window.onEmployeeValidationResult(true, 'Safe to add');",
            );
          }
        } else if (
        data.startsWith(
          'SEND_NOTIFICATION:',
        )
        ) {
          try {
            final payload = data.replaceFirst(
              'SEND_NOTIFICATION:',
              '',
            );

            final decoded =
            jsonDecode(payload);

            if (decoded is! Map) {
              debugPrint(
                'Invalid notification payload.',
              );

              return;
            }

            var targetPhone =
            decoded['targetPhone']
                ?.toString()
                .trim();

            final senderName =
                decoded['senderName']
                    ?.toString()
                    .trim() ??
                    'Collection Book';

            final message =
                decoded['message']
                    ?.toString()
                    .trim() ??
                    '';

            final notificationKey =
                decoded['notificationKey']
                    ?.toString()
                    .trim() ??
                    '';

            final whatsappConsent =
                decoded['whatsappConsent'] ==
                    true;

            final rawParams =
            decoded['params'];

            final Map<String, dynamic>
            notificationParams =
            rawParams is Map
                ? Map<String, dynamic>.from(
              rawParams,
            )
                : <String, dynamic>{};

            if (
            targetPhone == null ||
                targetPhone.isEmpty ||
                message.isEmpty ||
                notificationKey.isEmpty
            ) {
              debugPrint(
                'Incomplete notification payload.',
              );

              return;
            }

            final digits =
            targetPhone.replaceAll(
              RegExp(r'\D'),
              '',
            );

            if (digits.length == 10) {
              targetPhone = '+91$digits';
            } else if (
            digits.length == 12 &&
                digits.startsWith('91')
            ) {
              targetPhone = '+$digits';
            } else {
              debugPrint(
                'Invalid target phone: '
                    '$targetPhone',
              );

              return;
            }

            final currentUser =
                FirebaseAuth
                    .instance
                    .currentUser;

            if (currentUser == null) {
              return;
            }

            final now =
            DateTime.now();

            await FirebaseFirestore.instance
                .collection(
              'notification_requests',
            )
                .add({
              'targetPhone':
              targetPhone,

              /*
       * English fallback used for:
       * - push notification
       * - WhatsApp
       * - older application versions
       */
              'message':
              message,

              'senderUid':
              currentUser.uid,

              'senderName':
              senderName,

              /*
       * Used by the in-app screen to
       * translate static notification text.
       */
              'notificationKey':
              notificationKey,

              'params':
              notificationParams,

              'whatsappConsent':
              whatsappConsent,

              'status':
              'pending',

              'createdAt':
              FieldValue.serverTimestamp(),

              'expireAt':
              Timestamp.fromDate(
                now.add(
                  const Duration(
                    days: 5,
                  ),
                ),
              ),
            });
          } catch (
          error,
          stackTrace
          ) {
            debugPrint(
              'SEND_NOTIFICATION failed: '
                  '$error',
            );

            debugPrintStack(
              stackTrace:
              stackTrace,
            );
          }} else if (data.startsWith('SEND_PUSH:')) {
          final payload = data.replaceFirst('SEND_PUSH:', '');

          final parts = payload.split('|');

          if (parts.length < 4) {
            debugPrint('Invalid SEND_PUSH payload: $payload');

            return;
          }

          var targetPhone = parts[0].trim();

          final senderName = parts[1].trim();

          final whatsappConsent = parts[2].trim().toLowerCase() == 'true';

          /*
   * Join remaining portions so a "|" character in
   * the message does not truncate the notification.
   */
          final pushBody = parts.sublist(3).join('|').trim();

          var digits = targetPhone.replaceAll(RegExp(r'\D'), '');
          final now = DateTime.now();

          if (digits.length == 10) {
            targetPhone = '+91$digits';
          } else if (digits.length == 12 && digits.startsWith('91')) {
            targetPhone = '+$digits';
          } else {
            debugPrint('Invalid target phone: $targetPhone');

            return;
          }

          final currentUser = FirebaseAuth.instance.currentUser;

          if (currentUser == null || pushBody.isEmpty) {
            return;
          }

          await FirebaseFirestore.instance
              .collection('notification_requests')
              .add({
                'targetPhone': targetPhone,
                'message': pushBody,
                'senderUid': currentUser.uid,
                'senderName': senderName,
                'whatsappConsent': whatsappConsent,
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
                'expireAt': Timestamp.fromDate(
                  now.add(const Duration(days: 5)),
                ),
              });
        } else if (data.startsWith("DELETE_ENTRY:")) {
          final entryId = data.replaceFirst("DELETE_ENTRY:", "").trim();
          final user = FirebaseAuth.instance.currentUser;

          if (entryId.isEmpty) {
            debugPrint("DELETE_ENTRY ignored: empty entry ID");
            return;
          }

          if (user == null) {
            debugPrint("DELETE_ENTRY failed: no authenticated user");
            return;
          }

          try {
            final String? businessUid = SessionService.businessUid;

            if (businessUid == null || businessUid.isEmpty) {
              debugPrint(
                'DELETE_ENTRY failed: '
                'businessUid not resolved.',
              );

              return;
            }

            /*
 * Employee must have delete permission.
 */
            if (SessionService.isEmployee &&
                SessionService.permissions['del'] != true) {
              debugPrint(
                'DELETE_ENTRY blocked: '
                'employee does not have delete permission.',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You do not have permission '
                      'to delete entries.',
                    ),
                  ),
                );
              }

              return;
            }
            final documentReference = FirebaseFirestore.instance
                .collection('users')
                .doc(businessUid)
                .collection('ledger')
                .doc(entryId);

            final documentSnapshot = await documentReference.get();

            if (!documentSnapshot.exists) {
              debugPrint(
                "DELETE_ENTRY failed: document does not exist "
                "at users/${user.uid}/ledger/$entryId",
              );
              return;
            }

            await documentReference.delete();

            debugPrint(
              "DELETE_ENTRY success: users/${user.uid}/ledger/$entryId",
            );
          } catch (e, stackTrace) {
            debugPrint("DELETE_ENTRY error for $entryId: $e");
            debugPrintStack(stackTrace: stackTrace);
          }
        } else if (data.startsWith("SAVE_CUSTOMERS:")) {
          final customersJson = data.replaceFirst("SAVE_CUSTOMERS:", "");

          try {
            final businessUid =
                SessionService.businessUid;

            if (
            businessUid == null ||
                businessUid.isEmpty
            ) {
              debugPrint(
                'SAVE_CUSTOMERS failed: '
                    'businessUid not resolved.',
              );

              return;
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(businessUid)
                .set(
              {
                'cb-customers-v1':
                customersJson,
              },
              SetOptions(
                merge: true,
              ),
            );

            debugPrint("Customers synced successfully.");
          } catch (e) {
            debugPrint("SAVE_CUSTOMERS Error: $e");
          }
        } else if (data.startsWith("CONFIRM_SHARED_ENTRY:")) {
          final payload = data.replaceFirst("CONFIRM_SHARED_ENTRY:", "");

          final parts = payload.split("|");

          if (parts.length != 2) return;

          final ownerUid = parts[0];
          final entryId = parts[1];

          try {
            final ref = FirebaseFirestore.instance
                .collection('users')
                .doc(ownerUid)
                .collection('ledger')
                .doc(entryId);

            await ref.update({'isConfirmed': true});

            debugPrint("Confirmed shared entry $entryId for owner $ownerUid");
          } catch (e) {
            debugPrint("CONFIRM_SHARED_ENTRY failed: $e");
          }
        } else if (data.startsWith("CONFIRM_SHARED_PAYMENT:")) {
          final payload = data.replaceFirst("CONFIRM_SHARED_PAYMENT:", "");

          final parts = payload.split("|");

          if (parts.length != 3) return;

          final ownerUid = parts[0];
          final entryId = parts[1];
          final paymentId = parts[2];

          try {
            final ref = FirebaseFirestore.instance
                .collection('users')
                .doc(ownerUid)
                .collection('ledger')
                .doc(entryId);

            await FirebaseFirestore.instance.runTransaction((
              transaction,
            ) async {
              final snapshot = await transaction.get(ref);

              if (!snapshot.exists) {
                throw Exception("Ledger entry not found");
              }

              final data = snapshot.data();

              final payments = List<Map<String, dynamic>>.from(
                (data?['payments'] as List? ?? []).map(
                  (item) => Map<String, dynamic>.from(item),
                ),
              );

              final index = payments.indexWhere(
                (payment) => payment['id']?.toString() == paymentId,
              );

              if (index == -1) {
                throw Exception("Payment not found");
              }

              payments[index]['isConfirmed'] = true;

              transaction.update(ref, {'payments': payments});
            });

            debugPrint("Confirmed payment $paymentId in ledger $entryId");
          } catch (e) {
            debugPrint("CONFIRM_SHARED_PAYMENT failed: $e");
          }
        } else if (data.startsWith("DELETE_CUSTOMER_LEDGER:")) {
          final customerId = data.replaceFirst("DELETE_CUSTOMER_LEDGER:", "");

          try {
            final businessUid =
                SessionService.businessUid;

            if (
            businessUid == null ||
                businessUid.isEmpty
            ) {
              debugPrint(
                'DELETE_CUSTOMER_LEDGER failed: '
                    'businessUid not resolved.',
              );

              return;
            }

            final snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(businessUid)
                .collection('ledger')
                .where(
              'customerId',
              isEqualTo:
              customerId,
            )
                .get();

            final batch = FirebaseFirestore.instance.batch();

            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }

            await batch.commit();

            debugPrint("Deleted ${snapshot.docs.length} ledger entries.");
          } catch (e) {
            debugPrint("DELETE_CUSTOMER_LEDGER Error: $e");
          }
        } else if (data == 'OPEN_PRIVACY_POLICY') {
          if (!mounted) return;

          Navigator.pushNamed(context, '/privacy-policy');
        } else if (data == 'OPEN_TERMS') {
          if (!mounted) return;

          Navigator.pushNamed(context, '/terms');
        } else if (data.startsWith("EMAIL_SUPPORT:")) {
          final email = data.replaceFirst("EMAIL_SUPPORT:", "");

          final uri = Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: {'subject': 'Collection Book Support'},
          );

          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Email launch error: $e');

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open an email app.')),
            );
          }
        } else if (data.startsWith('DELETE_NOTIFICATIONS:')) {
          final payload = data.replaceFirst('DELETE_NOTIFICATIONS:', '');

          try {
            final decoded = jsonDecode(payload);

            if (decoded is! List) {
              return;
            }

            final ids = decoded
                .map((e) => e.toString().trim())
                .where((id) => id.isNotEmpty)
                .toList();

            if (ids.isEmpty) {
              return;
            }

            final phone = FirebaseAuth.instance.currentUser?.phoneNumber;

            if (phone == null || phone.isEmpty) {
              return;
            }

            final firestore = FirebaseFirestore.instance;

            final batch = firestore.batch();

            for (final id in ids) {
              final ref = firestore
                  .collection('users')
                  .doc(phone)
                  .collection('notifications')
                  .doc(id);

              batch.delete(ref);
            }

            await batch.commit();

            debugPrint('Deleted ${ids.length} notifications');

            /*
     * Tell HTML to remove the selected
     * notifications immediately.
     */
            final idsJson = jsonEncode(ids);

            await controller.runJavaScript('''
      if (
          typeof window.onNotificationsDeleted ===
          'function'
      ) {
          window.onNotificationsDeleted(
              $idsJson
          );
      }
      ''');
          } catch (e) {
            debugPrint('DELETE_NOTIFICATIONS error: $e');
          }
        } else if (data == 'LOAD_NOTIFICATIONS') {
          final user = FirebaseAuth.instance.currentUser;

          final phone = user?.phoneNumber;

          if (phone == null || phone.isEmpty) {
            return;
          }

          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(phone)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .get();
            debugPrint(
              'NOTIFICATION PATH = '
              'users/$phone/notifications',
            );

            debugPrint(
              'NOTIFICATIONS FOUND = '
              '${snapshot.docs.length}',
            );

            for (final doc in snapshot.docs) {
              debugPrint(
                'NOTIFICATION ${doc.id} = '
                '${doc.data()}',
              );
            }
            final notifications = snapshot.docs.map((doc) {
              final d = doc.data();

              final timestamp = d['createdAt'];

              return {
                'id':
                doc.id,

                'title':
                d['title'] ??
                    'Collection Book',

                /*
   * English fallback for old notifications
   * and unknown translation keys.
   */
                'message':
                d['message'] ??
                    '',

                'type':
                d['type'] ??
                    '',

                /*
   * New localization fields.
   */
                'notificationKey':
                d['notificationKey'] ??
                    '',

                'params':
                d['params'] is Map
                    ? Map<String, dynamic>.from(
                  d['params'],
                )
                    : <String, dynamic>{},

                'read':
                d['read'] == true,

                'createdAt':
                timestamp is Timestamp
                    ? timestamp
                    .toDate()
                    .toIso8601String()
                    : '',
              };
            }).toList();

            final json = jsonEncode(notifications);

            await controller.runJavaScript(
              'window.onNotificationsLoaded($json);',
            );

            // Opening Notifications marks them as read.
            final batch = FirebaseFirestore.instance.batch();

            var unreadCount = 0;

            for (final doc in snapshot.docs) {
              if (doc.data()['read'] != true) {
                unreadCount++;

                batch.update(doc.reference, {'read': true});
              }
            }

            if (unreadCount > 0) {
              await batch.commit();
            }

            await controller.runJavaScript('window.setNotificationBadge(0);');
          } catch (e) {
            debugPrint('LOAD_NOTIFICATIONS error: $e');
          }
        } else if (data == 'LOAD_NOTIFICATION_COUNT') {
          final phone = FirebaseAuth.instance.currentUser?.phoneNumber;

          if (phone == null) {
            return;
          }

          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(phone)
                .collection('notifications')
                .where('read', isEqualTo: false)
                .get();

            final count = snapshot.docs.length;

            await controller.runJavaScript(
              'window.setNotificationBadge($count);',
            );
          } catch (e) {
            debugPrint('Notification count error: $e');
          }
        } else if (data == 'OPEN_SECURITY_SETTINGS') {
          if (!mounted) return;

          Navigator.pushNamed(context, '/security-settings');
        } else if (data.startsWith('SWITCH_ROLE:')) {
          final targetMode = data.replaceFirst('SWITCH_ROLE:', '').trim();

          try {
            await SessionService.switchMode(targetMode);

            /*
     * Stop old-business listeners.
     */
            await _stopAllRealtimeListeners();

            /*
     * Reload same WebView.
     *
     * onPageFinished() injects the newly
     * selected SessionService values.
     */
            await controller.reload();
          } catch (e) {
            debugPrint('Role switch failed: $e');

            if (!mounted) return;

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
    );

    loadHtml();
  }

  Future<void> _startAllRealtimeListeners() async {
    await FirestoreService.stopRealtimeSync();

    _startLedgerListener();
    _startNotificationListener();

    final businessUid =
        SessionService.businessUid;

    if (
    businessUid == null ||
        businessUid.isEmpty
    ) {
      return;
    }

    await FirestoreService.startRealtimeSync(
      companyId: businessUid,
      webViewController: controller,
      onChanged: () async {
        if (!_webViewReady) {
          return;
        }

        await controller.runJavaScript(
          'window.refreshFromFlutter();',
        );
      },
    );
  }

  void _startLedgerListener() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("Ledger listener not started: user is null");
      return;
    }

    _ledgerSubscription?.cancel();

    final String? businessUid = SessionService.businessUid;

    if (businessUid == null || businessUid.isEmpty) {
      debugPrint(
        'Cannot start ledger listener: '
        'businessUid is not resolved.',
      );

      return;
    }

    debugPrint(
      'Starting owned ledger listener: '
      'authUid=${user.uid}, '
      'businessUid=$businessUid, '
      'mode=${SessionService.activeMode}',
    );

    _ledgerSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(businessUid)
        .collection('ledger')
        .snapshots()
        .listen(
          (snapshot) async {
            debugPrint(
              "Owned ledger changed: "
              "${snapshot.docs.length} documents",
            );

            if (!_webViewReady) {
              debugPrint(
                "WebView not ready; "
                "skipping realtime refresh",
              );

              return;
            }

            try {
              /*
         * IMPORTANT:
         *
         * Do NOT push snapshot.docs directly
         * into JavaScript.
         *
         * This snapshot contains ONLY ledgers
         * owned by the active business.
         *
         * FirestoreService.get() reconstructs
         * the complete ledger:
         *
         * owned ledgers
         * +
         * shared ledgers
         */
              await FirestoreService.get(
                'cb-ledger-v1',
                webViewController: controller,
              );

              debugPrint(
                "Combined ledger refreshed "
                "after owned-ledger change",
              );
            } catch (e) {
              debugPrint("Failed to refresh combined ledger: $e");
            }
          },
          onError: (error) {
            debugPrint(
              "Realtime owned ledger listener error: "
              "$error",
            );
          },
        );
  }

  Future<void>
  _stopAllRealtimeListeners() async {

    _webViewReady = false;

    await _ledgerSubscription?.cancel();
    _ledgerSubscription = null;

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    await FirestoreService
        .stopRealtimeSync();

    debugPrint(
      'All realtime listeners stopped.',
    );
  }

  void _startNotificationListener() {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (phone == null || phone.isEmpty) {
      debugPrint(
        'Notification listener not started: '
        'phone unavailable',
      );

      return;
    }

    _notificationSubscription?.cancel();

    debugPrint(
      'Starting realtime notification listener: '
      'users/$phone/notifications',
    );

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) async {
            final count = snapshot.docs.length;

            debugPrint('Realtime unread notifications = $count');

            if (!_webViewReady) {
              return;
            }

            try {
              await controller.runJavaScript('''
          if (
              typeof window.setNotificationBadge ===
              'function'
          ) {
              window.setNotificationBadge($count);
          }
          ''');
            } catch (e) {
              debugPrint('Failed to update notification badge: $e');
            }
          },
          onError: (error) {
            debugPrint('Notification listener error: $error');
          },
        );
  }

  Future<void> loadHtml() async {
    controller.loadFlutterAsset('assets/collection18.html');
    // await FirestoreService.startRealtimeSync(
    //   companyId: SessionService.businessUid!,
    //   webViewController: controller,
    //   onChanged: () async {
    //     await controller.runJavaScript("window.refreshFromFlutter();");
    //   },
    // );
  }

  Future<void> _refreshData() async {
    await FirestoreService.syncLatestData();

    await controller.runJavaScript("""

window.refreshFromFlutter();

""");
  }

  Future<void> fetchAndSendContacts(WebViewController controller) async {
    // 1. Request permission using the v2 API
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (status == PermissionStatus.granted) {
      // 2. Fetch contacts with phone numbers using FlutterContacts.getAll()
      List<Contact> contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );

      // 3. Format into JSON array expected by collection13.html
      List<Map<String, String>> contactList = [];
      for (var contact in contacts) {
        if (contact.phones.isNotEmpty) {
          contactList.add({
            'name': ?contact.displayName,
            'phone': contact.phones.first.number.replaceAll(RegExp(r'\D'), ''),
          });
        }
      }

      String jsonString = jsonEncode(contactList);

      // 4. Send back to JavaScript callback in collection13.html
      await controller.runJavaScript('''
      if (typeof window.receiveAllDeviceContacts === 'function') {
        window.receiveAllDeviceContacts($jsonString);
      }
    ''');
    } else {
      // Permission denied callback
      await controller.runJavaScript('''
      if (typeof window.contactsPermissionDenied === 'function') {
        window.contactsPermissionDenied();
      }
    ''');
    }
  }

  Future<bool> checkIfEmployeeExistsGlobally(String phoneNumber) async {
    try {
      // 1. Format the phone number to match your Document IDs
      // Assuming 'phoneNumber' coming from HTML is just 10 digits, we add +91
      // If it already has +91, you can skip this step.
      String formattedPhone = phoneNumber.startsWith('+91')
          ? phoneNumber
          : '+91$phoneNumber';

      // 2. Perform a direct document lookup (No indexes needed!)
      final docSnapshot = await FirebaseFirestore.instance
          .collection('employee_lookup')
          .doc(formattedPhone)
          .get();

      // 3. If the document exists, the employee is already registered to someone
      return docSnapshot.exists;
    } catch (e) {
      print("Error checking global employee status: $e");
      // Failsafe: block the addition if the database check fails
      return true;
    }
  }

  Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 400;

    while (true) {
      final snapshot = await collection.limit(batchSize).get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();

      if (snapshot.docs.length < batchSize) {
        break;
      }
    }
  }

  Future<void> _resetCurrentAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final firestore = FirebaseFirestore.instance;
    final userReference = firestore.collection('users').doc(user.uid);
    final phone =
        user.phoneNumber;

    DocumentReference<
        Map<String, dynamic>
    >? phoneUserReference;

    if (
    phone != null &&
        phone.isNotEmpty
    ) {
      phoneUserReference =
          firestore
              .collection('users')
              .doc(phone);
    }

    // Delete only ledger entries owned/stored under this user.
    //
    // Shared entries created by another user are stored under that other
    // user's document, so they are not deleted.
    await _deleteCollectionInBatches(userReference.collection('ledger'));


    final employeeLookups =
    await FirebaseFirestore.instance
        .collection('employee_lookup')
        .where(
      'ownerUid',
      isEqualTo: user.uid,
    )
        .get();

    final batch =
    FirebaseFirestore.instance.batch();

    for (final document
    in employeeLookups.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();

    // Delete the main user document.
    //
    // This removes fields such as:
    // cb-profile-v1
    // cb-customers-v1
    // cb-employees-v1
    // cb-role-mode-v1
    // and any other profile-level fields.
    await userReference.delete();

    // Clear the local Hive-backed WebView cache.
    final box = Hive.box('collectionBook');

    await box.delete('cb-profile-v1');
    await box.delete('cb-customers-v1');
    await box.delete('cb-ledger-v1');
    await box.delete('cb-employees-v1');
    await box.delete('cb-role-mode-v1');
    await box.delete('cb-lang');
    await box.delete(
      'cb-active-role-v2-${user.uid}',
    );
    if (phoneUserReference != null) {

      await _deleteCollectionInBatches(
        phoneUserReference
            .collection(
          'notifications',
        ),
      );

      /*
   * Delete the phone-index document too
   * if it only contains FCM/account metadata.
   */
      await phoneUserReference.delete();
    }
    // Sign out only after all deletion operations succeed.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        try {
          final jsResult = await controller.runJavaScriptReturningResult('''
          (function() {
            if (typeof window.handleAndroidBack === 'function') {
              return window.handleAndroidBack();
            }

            return 'exit';
          })();
          ''');

          final backResult = jsResult.toString().replaceAll('"', '').trim();

          if (backResult == 'exit') {
            // Close the Android app instead of popping the Flutter route.
            await SystemNavigator.pop();
          }
        } catch (e) {
          debugPrint('Back handling error: $e');

          // If JavaScript back handling fails, close the app safely.
          await SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,

          // ALWAYS WHITE
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,

          // Bottom remains light
          systemNavigationBarColor: Color(0xFFF7F7F7),
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Color(0xFFF7F7F7),
        ),

        child: Scaffold(
          backgroundColor: const Color(0xFFEFE7D6),

          body: Stack(
            children: [
              /*
     * WebView loads underneath.
     */
              Positioned.fill(child: WebViewWidget(controller: controller)),

              /*
     * Splash remains on top until
     * WebView startup is complete.
     */
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_showStartupSplash,

                  child: AnimatedOpacity(
                    opacity: _showStartupSplash ? 1.0 : 0.0,

                    duration: const Duration(milliseconds: 180),

                    child: SplashContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    _webViewReady = false;

    _ledgerSubscription?.cancel();
    _notificationSubscription?.cancel();

    FirestoreService
        .stopRealtimeSync();

    super.dispose();
  }
}
