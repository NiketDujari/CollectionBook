import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/biometric_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({
    super.key,
  });

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends State<SecuritySettingsScreen> {
  static const Color indigo =
  Color(0xFF2B3A67);

  static const Color indigoDeep =
  Color(0xFF182449);

  static const Color turmeric =
  Color(0xFFC98A2D);

  static const Color khadi =
  Color(0xFFEFE7D6);

  static const Color khadiLine =
  Color(0xFFD8CCB0);

  static const Color paper =
  Color(0xFFFBF8F1);

  static const Color muted =
  Color(0xFF77705F);

  static const Color charcoal =
  Color(0xFF2A2622);

  static const Color sage =
  Color(0xFF5C7A5E);

  static const Color madder =
  Color(0xFFA63D40);

  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin =
    await AppLockService.hasPin();

    final biometricEnabled =
    await AppLockService
        .isBiometricEnabled();

    final biometricAvailable =
    await BiometricService
        .isAvailable();

    if (!mounted) return;

    setState(() {
      _hasPin = hasPin;
      _biometricEnabled =
          biometricEnabled;

      _biometricAvailable =
          biometricAvailable;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khadi,

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
        indigoDeep,

        foregroundColor:
        Colors.white,

        titleSpacing: 0,

        title: const Text(
          'Security & App Lock',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: _loading
            ? const Center(
          child:
          CircularProgressIndicator(
            color: indigo,
          ),
        )
            : SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            32,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .stretch,

            children: [
              _buildHeroCard(),

              const SizedBox(
                height: 18,
              ),

              _buildSecuritySection(),

              if (_hasPin) ...[
                const SizedBox(
                  height: 18,
                ),

                _buildBiometricSection(),

                const SizedBox(
                  height: 18,
                ),

                _buildDangerSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding:
      const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,

          end:
          Alignment.bottomRight,

          colors: [
            indigo,
            indigoDeep,
          ],
        ),

        borderRadius:
        BorderRadius.circular(
          20,
        ),

        boxShadow: const [
          BoxShadow(
            color:
            Color(0x22000000),

            blurRadius: 14,

            offset:
            Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [
          Container(
            width: 58,
            height: 58,

            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,

              color:
              Colors.white
                  .withOpacity(
                .10,
              ),

              border: Border.all(
                color:
                turmeric,
                width: 1.5,
              ),
            ),

            child:
            const Icon(
              Icons
                  .lock_outline_rounded,

              color:
              turmeric,

              size: 30,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                const Text(
                  'Protect your ledger',
                  style:
                  TextStyle(
                    color:
                    Colors.white,

                    fontSize: 20,

                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  _hasPin
                      ? 'App Lock is enabled. Your ledger is protected with a PIN.'
                      : 'Add an app PIN to prevent unauthorized access to Collection Book.',

                  style:
                  TextStyle(
                    color:
                    Colors.white
                        .withOpacity(
                      .78,
                    ),

                    fontSize: 13,

                    height: 1.4,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration:
                  BoxDecoration(
                    color:
                    _hasPin
                        ? sage.withOpacity(
                      .18,
                    )
                        : turmeric.withOpacity(
                      .18,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      999,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Icon(
                        _hasPin
                            ? Icons
                            .verified_user_outlined
                            : Icons
                            .shield_outlined,

                        color:
                        _hasPin
                            ? const Color(
                          0xFFB7D7B9,
                        )
                            : turmeric,

                        size: 15,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Text(
                        _hasPin
                            ? 'App Lock Enabled'
                            : 'App Lock Disabled',

                        style:
                        TextStyle(
                          color:
                          _hasPin
                              ? const Color(
                            0xFFD6E9D7,
                          )
                              : const Color(
                            0xFFFFE0AA,
                          ),

                          fontSize: 12,

                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _sectionCard(
      title:
      'App PIN',

      subtitle:
      'Use a PIN whenever Collection Book is locked.',

      icon:
      Icons.pin_outlined,

      children: [
        _settingsTile(
          icon:
          _hasPin
              ? Icons
              .key_outlined
              : Icons
              .add_moderator_outlined,

          title:
          _hasPin
              ? 'Change App PIN'
              : 'Set App PIN',

          subtitle:
          _hasPin
              ? 'Update your current security PIN.'
              : 'Create a 4 to 6 digit PIN to secure the app.',

          trailing:
          const Icon(
            Icons.chevron_right_rounded,
            color: muted,
          ),

          onTap:
          _showSetPinDialog,
        ),
      ],
    );
  }

  Widget _buildBiometricSection() {
    final disabledReason =
    !_biometricAvailable
        ? 'Biometric authentication is not available on this device.'
        : 'Unlock faster using your fingerprint or device biometrics.';

    return _sectionCard(
      title:
      'Biometric Unlock',

      subtitle:
      disabledReason,

      icon:
      Icons.fingerprint,

      children: [
        Container(
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 4,
          ),

          child:
          SwitchListTile(
            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 10,
              vertical: 2,
            ),

            activeColor:
            turmeric,

            secondary:
            Container(
              width: 42,
              height: 42,

              decoration:
              BoxDecoration(
                color:
                indigo.withOpacity(
                  .08,
                ),

                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),

              child:
              const Icon(
                Icons
                    .fingerprint,

                color:
                indigo,
              ),
            ),

            title:
            const Text(
              'Use biometrics',
              style:
              TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight
                    .w700,
                color:
                charcoal,
              ),
            ),

            subtitle:
            Text(
              _biometricAvailable
                  ? 'Use fingerprint or supported biometric authentication.'
                  : 'Not supported on this device.',

              style:
              const TextStyle(
                fontSize: 12.5,
                color: muted,
                height: 1.35,
              ),
            ),

            value:
            _biometricEnabled,

            onChanged:
            _biometricAvailable
                ? _toggleBiometric
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return Container(
      decoration:
      BoxDecoration(
        color: paper,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color:
          madder.withOpacity(
            .35,
          ),
        ),
      ),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),

        onTap:
        _confirmDisableLock,

        child: Padding(
          padding:
          const EdgeInsets.all(
            16,
          ),

          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                BoxDecoration(
                  color:
                  madder.withOpacity(
                    .10,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child:
                const Icon(
                  Icons
                      .lock_open_outlined,

                  color:
                  madder,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Text(
                      'Disable App Lock',
                      style:
                      TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight
                            .w700,
                        color:
                        madder,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Remove the PIN and biometric protection from this device.',
                      style:
                      TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color:
                        muted,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: madder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget>
    children,
  }) {
    return Container(
      decoration:
      BoxDecoration(
        color: paper,

        borderRadius:
        BorderRadius.circular(
          18,
        ),

        border:
        Border.all(
          color:
          khadiLine,
        ),

        boxShadow: const [
          BoxShadow(
            color:
            Color(0x10000000),
            blurRadius: 10,
            offset:
            Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets
                .fromLTRB(
              16,
              16,
              16,
              12,
            ),

            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration:
                  BoxDecoration(
                    color:
                    indigo.withOpacity(
                      .08,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),

                  child:
                  Icon(
                    icon,
                    color:
                    indigo,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [
                      Text(
                        title,

                        style:
                        const TextStyle(
                          fontSize: 15,

                          fontWeight:
                          FontWeight
                              .w700,

                          color:
                          indigoDeep,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        subtitle,

                        style:
                        const TextStyle(
                          fontSize: 12.5,

                          color:
                          muted,

                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color:
            khadiLine,
          ),

          ...children,
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback
    onTap,
  }) {
    return InkWell(
      onTap:
      onTap,

      child: Padding(
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration:
              BoxDecoration(
                color:
                turmeric.withOpacity(
                  .11,
                ),

                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),

              child:
              Icon(
                icon,
                color:
                turmeric,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  Text(
                    title,

                    style:
                    const TextStyle(
                      fontSize: 15,

                      fontWeight:
                      FontWeight
                          .w700,

                      color:
                      charcoal,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    subtitle,

                    style:
                    const TextStyle(
                      fontSize: 12.5,

                      color:
                      muted,

                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _showSetPinDialog()
  async {
    final pinController =
    TextEditingController();

    final confirmController =
    TextEditingController();

    bool obscurePin = true;
    bool obscureConfirm = true;

    String? errorText;

    final result =
    await showModalBottomSheet<
        bool>(
      context: context,

      isScrollControlled: true,

      backgroundColor:
      Colors.transparent,

      builder: (context) {
        return StatefulBuilder(
          builder:
              (
              context,
              setModalState,
              ) {
            return Padding(
              padding:
              EdgeInsets.only(
                bottom:
                MediaQuery.of(
                  context,
                )
                    .viewInsets
                    .bottom,
              ),

              child: Container(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  20,
                  18,
                  20,
                  26,
                ),

                decoration:
                const BoxDecoration(
                  color:
                  paper,

                  borderRadius:
                  BorderRadius
                      .vertical(
                    top:
                    Radius.circular(
                      24,
                    ),
                  ),
                ),

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [
                    Container(
                      width: 42,
                      height: 4,

                      decoration:
                      BoxDecoration(
                        color:
                        khadiLine,

                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,

                          decoration:
                          BoxDecoration(
                            color:
                            indigo.withOpacity(
                              .08,
                            ),

                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),

                          child:
                          const Icon(
                            Icons
                                .pin_outlined,

                            color:
                            indigo,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              Text(
                                _hasPin
                                    ? 'Change App PIN'
                                    : 'Set App PIN',

                                style:
                                const TextStyle(
                                  fontSize:
                                  20,

                                  fontWeight:
                                  FontWeight
                                      .w700,

                                  color:
                                  indigoDeep,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              const Text(
                                'Choose a 4 to 6 digit PIN.',
                                style:
                                TextStyle(
                                  color:
                                  muted,

                                  fontSize:
                                  13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    TextField(
                      controller:
                      pinController,

                      obscureText:
                      obscurePin,

                      keyboardType:
                      TextInputType
                          .number,

                      maxLength: 6,

                      decoration:
                      InputDecoration(
                        labelText:
                        'New PIN',

                        prefixIcon:
                        const Icon(
                          Icons
                              .lock_outline,
                        ),

                        suffixIcon:
                        IconButton(
                          icon:
                          Icon(
                            obscurePin
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),

                          onPressed:
                              () {
                            setModalState(
                                  () {
                                obscurePin =
                                !obscurePin;
                              },
                            );
                          },
                        ),

                        filled:
                        true,

                        fillColor:
                        khadi,

                        counterText:
                        '',

                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),

                          borderSide:
                          const BorderSide(
                            color:
                            khadiLine,
                          ),
                        ),

                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),

                          borderSide:
                          const BorderSide(
                            color:
                            khadiLine,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                      confirmController,

                      obscureText:
                      obscureConfirm,

                      keyboardType:
                      TextInputType
                          .number,

                      maxLength: 6,

                      decoration:
                      InputDecoration(
                        labelText:
                        'Confirm PIN',

                        prefixIcon:
                        const Icon(
                          Icons
                              .verified_user_outlined,
                        ),

                        suffixIcon:
                        IconButton(
                          icon:
                          Icon(
                            obscureConfirm
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),

                          onPressed:
                              () {
                            setModalState(
                                  () {
                                obscureConfirm =
                                !obscureConfirm;
                              },
                            );
                          },
                        ),

                        errorText:
                        errorText,

                        filled:
                        true,

                        fillColor:
                        khadi,

                        counterText:
                        '',

                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),

                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),

                          borderSide:
                          const BorderSide(
                            color:
                            khadiLine,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                          OutlinedButton(
                            onPressed:
                                () =>
                                Navigator.pop(
                                  context,
                                  false,
                                ),

                            style:
                            OutlinedButton
                                .styleFrom(
                              foregroundColor:
                              charcoal,

                              side:
                              const BorderSide(
                                color:
                                khadiLine,
                              ),

                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical:
                                15,
                              ),

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),

                            child:
                            const Text(
                              'Cancel',
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                          ElevatedButton(
                            onPressed:
                                () {
                              final pin =
                              pinController
                                  .text
                                  .trim();

                              final confirm =
                              confirmController
                                  .text
                                  .trim();

                              if (
                              pin.length <
                                  4
                              ) {
                                setModalState(
                                      () {
                                    errorText =
                                    'PIN must be at least 4 digits.';
                                  },
                                );

                                return;
                              }

                              if (
                              pin !=
                                  confirm
                              ) {
                                setModalState(
                                      () {
                                    errorText =
                                    'PINs do not match.';
                                  },
                                );

                                return;
                              }

                              Navigator.pop(
                                context,
                                true,
                              );
                            },

                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              indigo,

                              foregroundColor:
                              Colors.white,

                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical:
                                15,
                              ),

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),

                            child:
                            const Text(
                              'Save PIN',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    await AppLockService.setPin(
      pinController.text.trim(),
    );

    await _loadSettings();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
        Text(
          'App PIN updated successfully.',
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(
      bool enabled,
      ) async {
    if (enabled) {
      final success =
      await BiometricService
          .authenticate();

      if (!success) {
        return;
      }
    }

    await AppLockService
        .setBiometricEnabled(
      enabled,
    );

    await _loadSettings();
  }

  Future<void> _confirmDisableLock()
  async {
    final confirmed =
    await showDialog<bool>(
      context: context,

      builder:
          (context) {
        return AlertDialog(
          backgroundColor:
          paper,

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),

          title:
          const Text(
            'Disable App Lock?',
            style:
            TextStyle(
              color:
              indigoDeep,

              fontWeight:
              FontWeight.w700,
            ),
          ),

          content:
          const Text(
            'Your Collection Book will no longer require a PIN or biometric authentication when opening the app.',
            style:
            TextStyle(
              color:
              muted,
              height:
              1.4,
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () =>
                  Navigator.pop(
                    context,
                    false,
                  ),

              child:
              const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed:
                  () =>
                  Navigator.pop(
                    context,
                    true,
                  ),

              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                madder,

                foregroundColor:
                Colors.white,
              ),

              child:
              const Text(
                'Disable',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _disableLock();
  }

  Future<void> _disableLock()
  async {
    await AppLockService
        .removePin();

    await AppLockService
        .setBiometricEnabled(
      false,
    );

    await _loadSettings();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
        Text(
          'App Lock disabled.',
        ),
      ),
    );
  }
}