import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import 'auth_service.dart';

class SessionService {
  static String get _roleKey {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw StateError(
        'User is not authenticated.',
      );
    }

    return 'cb-active-role-v2-$uid';
  }

  /// Currently selected business context.
  ///
  /// Owner mode:
  /// authenticated user's UID.
  ///
  /// Employee mode:
  /// employer/business owner's UID.
  static String? businessUid;

  /// Authenticated Firebase identity.
  static String? authUid;
  static String? authPhone;

  /// Current role: owner / employee.
  static String activeMode = 'owner';

  /// Whether this user owns a configured business.
  static bool hasOwnerBusiness = false;

  /// Whether this user currently has an employer.
  static bool hasEmployment = false;

  /// Employer's UID when employment exists.
  static String? employmentOwnerUid;

  /// Employee's 10-digit number.
  static String? employeePhone;

  static String? employeeName;

  /// Business identity of whichever business is active.
  static String? businessName;
  static String? businessOwnerName;
  static String? businessOwnerPhone;
  static String? businessArea;
  static String? businessGst;

  static Map<String, dynamic> permissions = {
    'add': true,
    'view': true,
    'manageContacts': true,
    'del': true,
  };

  static bool get isEmployee =>
      activeMode == 'employee';

  static bool get canSwitchRole =>
      hasEmployment;

  static String _normalizePhone(
      String value,
      ) {
    final digits = value.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (digits.length <= 10) {
      return '+91$digits';
    }

    return '+${digits.substring(
      digits.length - 12,
    )}';
  }

  static Map<String, dynamic> _parseProfile(
      dynamic raw,
      ) {
    if (raw == null) {
      return {};
    }

    try {
      if (raw is Map) {
        return Map<String, dynamic>.from(
          raw,
        );
      }

      return Map<String, dynamic>.from(
        jsonDecode(raw.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> resolveBusiness() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError(
        'Firebase user not logged in.',
      );
    }

    authUid = user.uid;
    authPhone = user.phoneNumber;

    if (
    authPhone == null ||
        authPhone!.isEmpty
    ) {
      throw StateError(
        'Authenticated user has no phone number.',
      );
    }

    final firestore =
        FirebaseFirestore.instance;

    final phone =
    _normalizePhone(authPhone!);

    /*
     * -------------------------------------------------
     * CHECK USER'S OWN BUSINESS
     * -------------------------------------------------
     */

    final ownRef =
    firestore
        .collection('users')
        .doc(user.uid);

    final ownDoc =
    await _getDocumentWithRetry(
      ownRef,
    );

    final ownData =
    ownDoc.data();

    final ownProfile =
    _parseProfile(
      ownData?['cb-profile-v1'],
    );

    hasOwnerBusiness = ownProfile['shop']?.toString().trim().isNotEmpty ?? false;

    /*
     * Keep business owner's authenticated phone
     * available on their UID document.
     *
     * This does NOT modify any existing fields.
     */
    await ownRef.set(
      {
        'accountPhone': phone,
      },
      SetOptions(
        merge: true,
      ),
    );

    /*
     * -------------------------------------------------
     * CHECK EMPLOYMENT
     * -------------------------------------------------
     */

    final employmentRef =
    firestore
        .collection(
      'employee_lookup',
    )
        .doc(phone);

    final employmentDoc =
    await _getDocumentWithRetry(
      employmentRef,
    );

    final employmentData =
    employmentDoc.data();


    final employerUid =
    employmentData?['ownerUid']
        ?.toString()
        .trim();

    hasEmployment =
        employmentDoc.exists &&
            employerUid != null &&
            employerUid.isNotEmpty;

    employmentOwnerUid = null;
    employeePhone = null;
    employeeName = null;

    Map<String, dynamic>
    employmentPermissions = {
      'add': false,
      'view': false,
      'manageContacts': false,
      'del': false,
    };

    if (hasEmployment) {
      /*
   * employee_lookup only tells us which
   * business this person works for.
   */
      employmentOwnerUid =
          employerUid;
      final employeeDigits =
      phone.replaceAll(
        RegExp(r'\D'),
        '',
      );

      final cleanEmployeePhone =
      employeeDigits.length > 10
          ? employeeDigits.substring(
        employeeDigits.length - 10,
      )
          : employeeDigits;

      employeePhone =
          cleanEmployeePhone;

      /*
   * ------------------------------------------------
   * LOAD EMPLOYEE CONFIGURATION FROM OWNER DOCUMENT
   * ------------------------------------------------
   *
   * cb-employees-v1 remains the authoritative
   * source for:
   *
   * - employee name
   * - permissions
   */
      final ownerDoc =
      await _getDocumentWithRetry(
        firestore
            .collection('users')
            .doc(employerUid),
      );

      final ownerData =
      ownerDoc.data();

      final rawEmployees =
      ownerData?['cb-employees-v1'];

      List<dynamic> employees = [];

      if (rawEmployees != null) {
        try {
          if (rawEmployees is String) {
            final decoded =
            jsonDecode(rawEmployees);

            if (decoded is List) {
              employees = decoded;
            }
          } else if (rawEmployees is List) {
            employees = rawEmployees;
          }
        } catch (e) {
          print(
            'Failed to decode '
                'cb-employees-v1: $e',
          );
        }
      }

      /*
   * Find THIS employee using phone number.
   */
      Map<String, dynamic>?
      currentEmployee;

      for (final rawEmployee in employees) {
        if (rawEmployee is! Map) {
          continue;
        }

        final emp =
        Map<String, dynamic>.from(
          rawEmployee,
        );

        final rawEmpPhone =
            emp['phone']
                ?.toString()
                .replaceAll(
              RegExp(r'\D'),
              '',
            ) ??
                '';

        final cleanEmpPhone =
        rawEmpPhone.length > 10
            ? rawEmpPhone.substring(
          rawEmpPhone.length - 10,
        )
            : rawEmpPhone;

        if (
        cleanEmpPhone ==
            cleanEmployeePhone
        ) {
          currentEmployee = emp;
          break;
        }
      }

      /*
   * employee_lookup says the person belongs
   * to this business, but they must ALSO
   * still exist in cb-employees-v1.
   */
      if (currentEmployee == null) {
        print(
          'Employee lookup exists but employee '
              'was not found in cb-employees-v1.',
        );

        hasEmployment = false;
        employmentOwnerUid = null;
        employeePhone = null;
        employeeName = null;

        employmentPermissions = {
          'add': false,
          'view': false,
          'manageContacts': false,
          'del': false,
        };
      } else {
        employeeName =
            currentEmployee['name']
                ?.toString()
                .trim();

        final rawPermissions =
        currentEmployee['permissions'];

        if (rawPermissions is Map) {
          final permissionMap =
          Map<String, dynamic>.from(
            rawPermissions,
          );

          employmentPermissions = {
            'add':
            permissionMap['add'] ==
                true,

            'view':
            permissionMap['view'] ==
                true,
            'manageContacts':
            permissionMap['manageContacts'] == true,
            'del':
            permissionMap['del'] ==
                true,
          };
        }

        print(
          'EMPLOYEE FOUND = '
              '$currentEmployee',
        );

        print(
          'EMPLOYEE NAME = '
              '$employeeName',
        );

        print(
          'EMPLOYMENT PERMISSIONS = '
              '$employmentPermissions',
        );

        /*
     * Link registered Firebase account to
     * employee assignment.
     */
        final existingEmployeeUid =
        employmentData?['employeeUid']
            ?.toString()
            .trim();

        if (
        existingEmployeeUid == null ||
            existingEmployeeUid.isEmpty
        ) {
          await employmentRef.set(
            {
              'employeeUid':
              user.uid,
            },
            SetOptions(
              merge: true,
            ),
          );
        }
      }
    }

    /*
     * -------------------------------------------------
     * DETERMINE ROLE
     * -------------------------------------------------
     */

    final box =
    Hive.box('collectionBook');

    final savedRole =
    box.get(_roleKey)
        ?.toString();

/*
 * First-time employee:
 * default to employee mode.
 *
 * If the user explicitly switches to owner,
 * savedRole becomes "owner" and we must
 * respect that even if they do not yet have
 * an owner business/profile.
 */
    if (
    hasEmployment &&
        savedRole != 'owner'
    ) {
      activeMode = 'employee';
    } else {
      activeMode = 'owner';
    }
    print(
      'EMPLOYMENT DOC = '
          '${employmentDoc.data()}',
    );

    print(
      'EMPLOYMENT PERMISSIONS = '
          '$employmentPermissions',
    );

    await _applyMode(
      mode: activeMode,
      ownProfile: ownProfile,
      employmentPermissions:
      employmentPermissions,
    );

    /*
     * FCM belongs to the PERSON/device,
     * not the selected role.
     */
    final authService =
    AuthService();

    await authService.saveDeviceToken(
      phone,
      activeMode,
    );
  }

  static Future<void> switchMode(
      String mode,
      ) async {

    if (
    mode != 'owner' &&
        mode != 'employee'
    ) {
      throw ArgumentError(
        'Invalid role: $mode',
      );
    }

    /*
   * Employee mode requires employment.
   */
    if (
    mode == 'employee' &&
        !hasEmployment
    ) {
      throw StateError(
        'User is not an employee.',
      );
    }

    /*
   * DO NOT check hasOwnerBusiness here.
   *
   * A first-time employee is allowed to
   * switch to owner mode before creating
   * their owner profile.
   */

    final box =
    Hive.box('collectionBook');

    await box.put(
      _roleKey,
      mode,
    );

    /*
   * Re-resolves active mode and,
   * through _applyMode(), switches
   * businessUid appropriately.
   */
    await resolveBusiness();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>>
  _getDocumentWithRetry(
      DocumentReference<Map<String, dynamic>> ref,
      ) async {

    const maxAttempts = 4;

    for (
    var attempt = 1;
    attempt <= maxAttempts;
    attempt++
    ) {
      try {
        return await ref.get();
      } on FirebaseException catch (e) {

        final retryable =
            e.code == 'unavailable' ||
                e.code == 'deadline-exceeded';

        if (
        !retryable ||
            attempt == maxAttempts
        ) {
          rethrow;
        }

        await Future.delayed(
          Duration(
            milliseconds:
            500 * attempt,
          ),
        );
      }
    }

    throw StateError(
      'Unable to load Firestore document.',
    );
  }

  static Future<void> _applyMode({
    required String mode,
    required Map<String, dynamic> ownProfile,
    required Map<String, dynamic> employmentPermissions,
  }) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError(
        'Firebase user not logged in.',
      );
    }

    /*
   * ===============================================
   * OWNER MODE
   * ===============================================
   */
    if (mode == 'owner') {

      /*
     * Owner mode always operates on the
     * authenticated user's own UID.
     */
      businessUid =
          user.uid;

      businessOwnerPhone =
          user.phoneNumber;

      businessOwnerName =
          ownProfile['name']
              ?.toString()
              .trim();

      businessName =
          ownProfile['shop']
              ?.toString()
              .trim();

      businessArea =
          ownProfile['area']
              ?.toString()
              .trim();

      businessGst =
          ownProfile['gst']
              ?.toString()
              .trim();

      permissions = {
        'add': true,
        'view': true,
        'manageContacts': true,
        'del': true,
      };

      print(
        'MODE APPLIED = OWNER | '
            'businessUid=$businessUid | '
            'authUid=${user.uid}',
      );

      return;
    }


    /*
   * ===============================================
   * EMPLOYEE MODE
   * ===============================================
   */
    if (mode == 'employee') {

      if (
      !hasEmployment ||
          employmentOwnerUid == null ||
          employmentOwnerUid!.isEmpty
      ) {
        throw StateError(
          'Employee business not resolved.',
        );
      }

      /*
     * Employee mode operates on the
     * employer's business UID.
     */
      businessUid =
          employmentOwnerUid;

      permissions =
      Map<String, dynamic>.from(
        employmentPermissions,
      );

      final ownerDoc =
      await _getDocumentWithRetry(
        FirebaseFirestore.instance
            .collection('users')
            .doc(employmentOwnerUid),
      );

      final ownerData =
      ownerDoc.data();

      final employerProfile =
      _parseProfile(
        ownerData?['cb-profile-v1'],
      );

      businessName =
          employerProfile['shop']
              ?.toString()
              .trim();

      businessOwnerName =
          employerProfile['name']
              ?.toString()
              .trim();

      businessArea =
          employerProfile['area']
              ?.toString()
              .trim();

      businessGst =
          employerProfile['gst']
              ?.toString()
              .trim();

      businessOwnerPhone =
          ownerData?['accountPhone']
              ?.toString()
              .trim();

      print(
        'MODE APPLIED = EMPLOYEE | '
            'businessUid=$businessUid | '
            'employmentOwnerUid=$employmentOwnerUid',
      );

      return;
    }

    throw StateError(
      'Unknown active mode: $mode',
    );
  }
}