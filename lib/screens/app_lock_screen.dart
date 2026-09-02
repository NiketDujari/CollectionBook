import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<AppLockScreen> createState() =>
      _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
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

  static const Color madder =
  Color(0xFFA63D40);

  final TextEditingController _pinController =
  TextEditingController();

  final FocusNode _pinFocusNode =
  FocusNode();

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  bool _checkingBiometric = false;
  bool _unlocking = false;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();

    super.dispose();
  }

  Future<void> _initialize() async {
    final biometricAvailable =
    await BiometricService.isAvailable();

    final biometricEnabled =
    await AppLockService
        .isBiometricEnabled();

    if (!mounted) return;

    setState(() {
      _biometricAvailable =
          biometricAvailable;

      _biometricEnabled =
          biometricEnabled;
    });

    if (
    biometricAvailable &&
        biometricEnabled
    ) {
      await _unlockWithBiometric();
    } else {
      _focusPin();
    }
  }

  void _focusPin() {
    Future.delayed(
      const Duration(milliseconds: 250),
          () {
        if (!mounted) return;

        _pinFocusNode.requestFocus();
      },
    );
  }

  Future<void> _unlockWithBiometric() async {
    if (_checkingBiometric) {
      return;
    }

    setState(() {
      _checkingBiometric = true;
      _errorText = null;
    });

    final success =
    await BiometricService.authenticate();

    if (!mounted) return;

    setState(() {
      _checkingBiometric = false;
    });

    if (success) {
      widget.onUnlocked();
      return;
    }

    _focusPin();
  }

  Future<void> _verifyPin() async {
    if (_unlocking) {
      return;
    }

    final pin =
    _pinController.text.trim();

    if (pin.length < 4) {
      setState(() {
        _errorText =
        'Enter your app PIN.';
      });

      return;
    }

    setState(() {
      _unlocking = true;
      _errorText = null;
    });

    final success =
    await AppLockService
        .verifyPin(pin);

    if (!mounted) return;

    if (success) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _unlocking = false;
      _errorText =
      'Incorrect PIN. Please try again.';
    });

    _pinController.clear();

    _focusPin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khadi,

      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context)
              .unfocus();
        },

        child: SafeArea(
          child: LayoutBuilder(
            builder: (
                context,
                constraints,
                ) {
              return SingleChildScrollView(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  28,
                ),

                child: ConstrainedBox(
                  constraints:
                  BoxConstraints(
                    minHeight:
                    constraints
                        .maxHeight -
                        52,
                  ),

                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildBrandHeader(),

                        const Spacer(),

                        _buildLockCard(),

                        const Spacer(),

                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,

          decoration:
          BoxDecoration(
            shape:
            BoxShape.circle,

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

            border:
            Border.all(
              color:
              turmeric,
              width:
              2,
            ),

            boxShadow:
            const [
              BoxShadow(
                color:
                Color(
                  0x24000000,
                ),

                blurRadius:
                12,

                offset:
                Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),

          child:
          const Icon(
            Icons
                .menu_book_outlined,

            color:
            turmeric,

            size:
            28,
          ),
        ),

        const SizedBox(
          height:
          14,
        ),

        const Text(
          'Collection Book',

          style:
          TextStyle(
            color:
            indigoDeep,

            fontSize:
            25,

            fontWeight:
            FontWeight
                .w700,

            letterSpacing:
            .1,
          ),
        ),

        const SizedBox(
          height:
          3,
        ),

        const Text(
          'CREDIT & LEDGER MANAGEMENT',

          style:
          TextStyle(
            color:
            turmeric,

            fontSize:
            10.5,

            fontWeight:
            FontWeight
                .w700,

            letterSpacing:
            1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildLockCard() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),

      decoration:
      BoxDecoration(
        color:
        paper,

        borderRadius:
        BorderRadius.circular(
          22,
        ),

        border:
        Border.all(
          color:
          khadiLine,
        ),

        boxShadow:
        const [
          BoxShadow(
            color:
            Color(
              0x16000000,
            ),

            blurRadius:
            18,

            offset:
            Offset(
              0,
              7,
            ),
          ),
        ],
      ),

      child: Column(
        children: [
          Container(
            width:
            66,
            height:
            66,

            decoration:
            BoxDecoration(
              color:
              indigo.withOpacity(
                .08,
              ),

              shape:
              BoxShape.circle,

              border:
              Border.all(
                color:
                indigo.withOpacity(
                  .12,
                ),
              ),
            ),

            child:
            const Icon(
              Icons
                  .lock_outline_rounded,

              size:
              31,

              color:
              indigo,
            ),
          ),

          const SizedBox(
            height:
            16,
          ),

          const Text(
            'Collection Book Locked',

            textAlign:
            TextAlign.center,

            style:
            TextStyle(
              color:
              indigoDeep,

              fontSize:
              21,

              fontWeight:
              FontWeight
                  .w700,
            ),
          ),

          const SizedBox(
            height:
            6,
          ),

          const Text(
            'Enter your app PIN to continue to your ledger.',

            textAlign:
            TextAlign.center,

            style:
            TextStyle(
              color:
              muted,

              fontSize:
              13.5,

              height:
              1.4,
            ),
          ),

          const SizedBox(
            height:
            24,
          ),

          _buildPinField(),

          if (_errorText != null) ...[
            const SizedBox(
              height:
              9,
            ),

            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,

              children: [
                const Icon(
                  Icons
                      .error_outline_rounded,

                  color:
                  madder,

                  size:
                  16,
                ),

                const SizedBox(
                  width:
                  6,
                ),

                Flexible(
                  child:
                  Text(
                    _errorText!,

                    textAlign:
                    TextAlign
                        .center,

                    style:
                    const TextStyle(
                      color:
                      madder,

                      fontSize:
                      12.5,

                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height:
            20,
          ),

          SizedBox(
            width:
            double.infinity,

            child:
            ElevatedButton(
              onPressed:
              _unlocking
                  ? null
                  : _verifyPin,

              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                indigo,

                foregroundColor:
                Colors.white,

                disabledBackgroundColor:
                indigo.withOpacity(
                  .55,
                ),

                elevation:
                0,

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
                    13,
                  ),
                ),
              ),

              child:
              _unlocking
                  ? const SizedBox(
                width:
                21,
                height:
                21,

                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,

                  color:
                  Colors.white,
                ),
              )
                  : const Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,

                children: [
                  Icon(
                    Icons
                        .lock_open_rounded,

                    size:
                    19,
                  ),

                  SizedBox(
                    width:
                    8,
                  ),

                  Text(
                    'Unlock',

                    style:
                    TextStyle(
                      fontSize:
                      15,

                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (
          _biometricAvailable &&
              _biometricEnabled
          ) ...[
            const SizedBox(
              height:
              17,
            ),

            Row(
              children: [
                const Expanded(
                  child:
                  Divider(
                    color:
                    khadiLine,
                  ),
                ),

                Padding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal:
                    12,
                  ),

                  child:
                  Text(
                    'OR',

                    style:
                    TextStyle(
                      color:
                      muted.withOpacity(
                        .8,
                      ),

                      fontSize:
                      10.5,

                      fontWeight:
                      FontWeight
                          .w700,

                      letterSpacing:
                      .8,
                    ),
                  ),
                ),

                const Expanded(
                  child:
                  Divider(
                    color:
                    khadiLine,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
              15,
            ),

            SizedBox(
              width:
              double.infinity,

              child:
              OutlinedButton.icon(
                onPressed:
                _checkingBiometric
                    ? null
                    : _unlockWithBiometric,

                icon:
                _checkingBiometric
                    ? const SizedBox(
                  width:
                  20,
                  height:
                  20,

                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,

                    color:
                    turmeric,
                  ),
                )
                    : const Icon(
                  Icons
                      .fingerprint,

                  size:
                  25,
                ),

                label:
                Text(
                  _checkingBiometric
                      ? 'Checking biometrics…'
                      : 'Use Biometrics',
                ),

                style:
                OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  indigo,

                  side:
                  const BorderSide(
                    color:
                    khadiLine,
                  ),

                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical:
                    14,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),

                  textStyle:
                  const TextStyle(
                    fontSize:
                    14,

                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinField() {
    return TextField(
      controller:
      _pinController,

      focusNode:
      _pinFocusNode,

      keyboardType:
      TextInputType.number,

      textInputAction:
      TextInputAction.done,

      obscureText:
      true,

      obscuringCharacter:
      '●',

      maxLength:
      6,

      textAlign:
      TextAlign.center,

      style:
      const TextStyle(
        color:
        indigoDeep,

        fontSize:
        24,

        fontWeight:
        FontWeight
            .w700,

        letterSpacing:
        11,
      ),

      decoration:
      InputDecoration(
        counterText:
        '',

        hintText:
        '••••',

        hintStyle:
        TextStyle(
          color:
          muted.withOpacity(
            .35,
          ),

          letterSpacing:
          11,

          fontSize:
          24,
        ),

        filled:
        true,

        fillColor:
        khadi,

        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal:
          18,

          vertical:
          17,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
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
            14,
          ),

          borderSide:
          const BorderSide(
            color:
            khadiLine,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),

          borderSide:
          const BorderSide(
            color:
            turmeric,

            width:
            1.6,
          ),
        ),
      ),

      onChanged:
          (_) {
        if (_errorText != null) {
          setState(() {
            _errorText = null;
          });
        }
      },

      onSubmitted:
          (_) {
        _verifyPin();
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,

          children: [
            Icon(
              Icons
                  .shield_outlined,

              size:
              15,

              color:
              muted.withOpacity(
                .75,
              ),
            ),

            const SizedBox(
              width:
              6,
            ),

            Text(
              'Protected locally on this device',

              style:
              TextStyle(
                color:
                muted.withOpacity(
                  .85,
                ),

                fontSize:
                11.5,

                fontWeight:
                FontWeight
                    .w500,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
          6,
        ),

        Text(
          'Your ledger data remains linked to your Collection Book account.',

          textAlign:
          TextAlign.center,

          style:
          TextStyle(
            color:
            muted.withOpacity(
              .65,
            ),

            fontSize:
            10.5,
          ),
        ),
      ],
    );
  }
}