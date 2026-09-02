import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection_book/services/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';


class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static StreamSubscription<DocumentSnapshot>? _subscription;
  static StreamSubscription<QuerySnapshot>? _ledgerSubscription;
  static StreamSubscription<QuerySnapshot>? _sharedLedgerSubscription;

  static Future<void> syncLatestData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(SessionService.businessUid!)
        .get();
  }

  static DocumentReference<Map<String, dynamic>> get _doc {
    final String? businessUid = SessionService.businessUid;

    if (businessUid == null || businessUid.isEmpty) {
      throw StateError('Business session not resolved.');
    }

    return _db.collection('users').doc(businessUid);
  }

  static Future<String> get(
    String key, {
    WebViewController? webViewController,
  }) async {
    if (
    key == 'cb-ledger-v1' &&
        SessionService.isEmployee &&
        SessionService.permissions['view'] != true
    ) {
      return '[]';
    }
    if (key == 'cb-ledger-v1') {
      try {
        final List<Map<String, dynamic>> combinedLedger = [];
        final Set<String> processedIds = {};

        // 1. Fetch Owned Transactions from users/{businessUid}/ledger subcollection
        if (SessionService.businessUid != null &&
            SessionService.businessUid!.isNotEmpty) {
          final QuerySnapshot ownedDocs = await _db
              .collection("users")
              .doc(SessionService.businessUid!)
              .collection("ledger")
              .get();

          for (var doc in ownedDocs.docs) {
            final data = doc.data() as Map<String, dynamic>;
            combinedLedger.add(data);
            if (data.containsKey('id')) {
              processedIds.add(data['id'].toString());
            }
          }
        }

        // 2. Fetch Shared Transactions where current user is Customer
        /*
 * Shared ledger must belong to the ACTIVE BUSINESS.
 *
 * Owner mode:
 *   use logged-in owner's phone.
 *
 * Employee mode:
 *   use employer/business owner's phone.
 */
        String? sharedLedgerPhone;

        if (SessionService.isEmployee) {
          sharedLedgerPhone =
              SessionService.businessOwnerPhone;
        } else {
          sharedLedgerPhone =
              FirebaseAuth
                  .instance
                  .currentUser
                  ?.phoneNumber;
        }

        if (
        sharedLedgerPhone != null &&
            sharedLedgerPhone.isNotEmpty
        ) {
          final String rawPhone =
          sharedLedgerPhone.replaceAll(
            RegExp(r'\D'),
            '',
          );

          final String cleanPhone =
          rawPhone.length > 10
              ? rawPhone.substring(
            rawPhone.length - 10,
          )
              : rawPhone;

          print(
            "DEBUG: Shared ledger query "
                "mode=${SessionService.activeMode}, "
                "businessUid=${SessionService.businessUid}, "
                "phone=$cleanPhone",
          );

          final QuerySnapshot sharedDocs =
          await _db
              .collectionGroup("ledger")
              .where(
            "customerPhone",
            isEqualTo: cleanPhone,
          )
              .get();

          for (final doc in sharedDocs.docs) {
            final data =
            doc.data()
            as Map<String, dynamic>;

            final String id =
                data['id']
                    ?.toString() ??
                    '';

            if (
            id.isNotEmpty &&
                !processedIds.contains(id)
            ) {
              combinedLedger.add(data);
              processedIds.add(id);
            }
          }


          for (var doc in sharedDocs.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String id = data['id']?.toString() ?? '';

            if (id.isNotEmpty && !processedIds.contains(id)) {
              combinedLedger.add(data);
              processedIds.add(id);
            }
          }
        }

        final String jsonResult = jsonEncode(combinedLedger);

        // 3. Inject directly into the passed WebViewController using window.updateLedgerFromFlutter
        if (webViewController != null) {
          // Pass jsonResult directly (do NOT double jsonEncode)
          final String rawJsonString = jsonEncode(jsonResult);

          await webViewController.runJavaScript('''
        (function() {
          function tryInject() {
            try {
              var data = $rawJsonString;
              if (typeof window.updateLedgerFromFlutter === 'function') {
                window.updateLedgerFromFlutter(data);
                console.log("SUCCESS: Ledger pushed from Flutter to JS runtime.");
              } else {
                // Retry after 200ms if JS functions aren't ready yet
                setTimeout(tryInject, 200);
              }
            } catch(e) {
              console.error("Error updating UI from Flutter:", e);
            }
          }
          tryInject();
        })();
      ''');
        }

        return jsonResult;
      } catch (e) {
        print("Error fetching ledger subcollection: $e");
        return "[]";
      }
    }

    if (key == 'cb-profile-v1' && SessionService.isEmployee) {
      return jsonEncode({
        'name': SessionService.employeeName ?? 'Employee',

        'shop': SessionService.businessName ?? '',

        'area': SessionService.businessArea ?? '',

        'gst': SessionService.businessGst ?? '',

        'employeeMode': true,
      });
    }

    // Standard read for all other keys (cb-profile-v1, cb-customers-v1, etc.)
    final snap = await _doc.get();

    if (!snap.exists) return "[]";

    final data = snap.data();

    if (data == null) return "[]";

    final value = data[key];

    if (value == null) return "[]";

    return value.toString();
  }

  static Future<void> set(String key, dynamic value) async {
    print("SET KEY: $key");
    if (key == 'cb-ledger-v1') {
      if (
      SessionService.isEmployee &&
          SessionService.permissions['add'] != true
      ) {
        throw StateError(
          'You do not have permission to add entries.',
        );
      }

      // Existing ledger-save code.
    }
    if (key == 'cb-ledger-v1') {
      try {
        final String? businessUid = SessionService.businessUid;

        if (businessUid == null || businessUid.isEmpty) {
          throw StateError("Business session not resolved.");
        }

        final List<dynamic> ledgerItems = jsonDecode(value.toString());

        final WriteBatch batch = _db.batch();

        int writeCount = 0;

        for (final rawItem in ledgerItems) {
          if (rawItem is! Map) {
            continue;
          }

          final Map<String, dynamic> item = Map<String, dynamic>.from(rawItem);

          final String? entryId = item['id']?.toString();

          if (entryId == null || entryId.isEmpty) {
            print("Skipping ledger entry without id");

            continue;
          }

          final String? existingOwnerUid = item['ownerUid']?.toString();

          /*
         * Shared ledger belonging to another
         * business. Never write/copy it into
         * the active business.
         */
          if (existingOwnerUid != null &&
              existingOwnerUid.isNotEmpty &&
              existingOwnerUid != businessUid) {
            print(
              "Skipping shared ledger $entryId. "
              "Owner=$existingOwnerUid, "
              "activeBusiness=$businessUid",
            );

            continue;
          }

          /*
         * Business owns the ledger,
         * not the employee.
         */
          item['ownerUid'] = businessUid;

          final DocumentReference<Map<String, dynamic>> docRef = _db
              .collection("users")
              .doc(businessUid)
              .collection("ledger")
              .doc(entryId);

          batch.set(docRef, item, SetOptions(merge: true));

          writeCount++;
        }

        if (writeCount > 0) {
          await batch.commit();
        }

        print(
          "Ledger subcollection batch write successful. "
          "Written: $writeCount",
        );
      } catch (e, stackTrace) {
        debugPrint(
          'Ledger batch write error: $e',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );

        rethrow;
      }
    } else {
      /*
     * Keep your existing storage behavior
     * for profile/customers/employees/etc.
     */
      await _doc.set({key: value.toString()}, SetOptions(merge: true));
    }

    /*
   * KEEP THIS BLOCK UNCHANGED FOR NOW.
   *
   * We will replace this employee_lookup
   * synchronization with the transactional
   * employee assignment logic in the later
   * employee-service step.
   */
    if (key == "cb-employees-v1") {
      print("Employee lookup sync started");

      try {
        final List employees =
        jsonDecode(
          value.toString(),
        );

        final lookupCollection =
        FirebaseFirestore.instance
            .collection(
          "employee_lookup",
        );

        final String? ownerUid =
            SessionService.businessUid;

        if (
        ownerUid == null ||
            ownerUid.isEmpty
        ) {
          throw StateError(
            "Business UID not resolved.",
          );
        }

        /*
     * Find all employee lookup records
     * currently belonging to this business.
     */
        final existing =
        await lookupCollection
            .where(
          "ownerUid",
          isEqualTo: ownerUid,
        )
            .get();

        final existingPhones =
        <String>{};

        for (final doc in existing.docs) {
          existingPhones.add(
            doc.id,
          );
        }

        final currentPhones =
        <String>{};

        /*
     * Create/update lookup records.
     *
     * employee_lookup is ONLY responsible
     * for mapping:
     *
     * employee phone -> employer UID
     *
     * Employee name and permissions remain
     * inside cb-employees-v1.
     */
        for (final rawEmployee in employees) {
          if (rawEmployee is! Map) {
            continue;
          }

          final emp =
          Map<String, dynamic>.from(
            rawEmployee,
          );

          final rawPhone =
              emp["phone"]
                  ?.toString()
                  .replaceAll(
                RegExp(r'\D'),
                '',
              ) ??
                  '';

          if (rawPhone.isEmpty) {
            continue;
          }

          final cleanPhone =
          rawPhone.length > 10
              ? rawPhone.substring(
            rawPhone.length - 10,
          )
              : rawPhone;

          if (cleanPhone.length != 10) {
            print(
              "Skipping invalid employee phone: "
                  "$rawPhone",
            );

            continue;
          }

          final phone =
              "+91$cleanPhone";

          currentPhones.add(
            phone,
          );

          /*
       * merge:true preserves employeeUid
       * if the employee has already logged in.
       */
          await lookupCollection
              .doc(phone)
              .set(
            {
              "ownerUid":
              ownerUid,
            },
            SetOptions(
              merge: true,
            ),
          );

          print(
            "Employee lookup synced: "
                "$phone -> $ownerUid",
          );
        }

        /*
     * Employee removed by owner.
     *
     * Remove their global business assignment.
     */
        final removedPhones =
        existingPhones.difference(
          currentPhones,
        );

        for (final phone in removedPhones) {
          await lookupCollection
              .doc(phone)
              .delete();

          print(
            "Employee lookup removed: "
                "$phone",
          );
        }

        print(
          "Employee lookup sync completed.",
        );
      } catch (e, stackTrace) {
        print(
          "Employee lookup sync failed: $e",
        );

        print(stackTrace);
      }
    }
  }

  static Future<void> remove(String key) async {
    await _doc.update({key: FieldValue.delete()});
  }

  static Future<void> clear() async {
    await _doc.delete();
  }

  static Future<void> startRealtimeSync({
    required String companyId,
    required VoidCallback onChanged,
    WebViewController? webViewController,
  }) async {
    /*
   * Shared-ledger identity is the active BUSINESS,
   * not necessarily the authenticated person.
   */
    String? sharedLedgerPhone;

    if (SessionService.isEmployee) {
      sharedLedgerPhone =
          SessionService.businessOwnerPhone;
    } else {
      sharedLedgerPhone =
          FirebaseAuth
              .instance
              .currentUser
              ?.phoneNumber;
    }

    if (
    sharedLedgerPhone == null ||
        sharedLedgerPhone.isEmpty
    ) {
      print(
        "DEBUG: Shared ledger listener not started. "
            "No active business phone.",
      );

      return;
    }

    final String rawPhone =
    sharedLedgerPhone.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final String cleanPhone =
    rawPhone.length > 10
        ? rawPhone.substring(
      rawPhone.length - 10,
    )
        : rawPhone;

    print(
      "DEBUG: Starting shared ledger listener "
          "mode=${SessionService.activeMode}, "
          "businessUid=${SessionService.businessUid}, "
          "phone=$cleanPhone",
    );

    _sharedLedgerSubscription =
        FirebaseFirestore.instance
            .collectionGroup("ledger")
            .where(
          "customerPhone",
          isEqualTo: cleanPhone,
        )
            .snapshots()
            .listen((_) async {
          print(
            "DEBUG: Shared ledger change detected",
          );

          await FirestoreService.get(
            'cb-ledger-v1',
            webViewController:
            webViewController,
          );

          onChanged();
        });
  }

  static Future<void> stopRealtimeSync() async {
    await _subscription?.cancel();
    await _ledgerSubscription?.cancel();
    await _sharedLedgerSubscription?.cancel();

    _subscription = null;
    _ledgerSubscription = null;
    _sharedLedgerSubscription = null;
  }
}
