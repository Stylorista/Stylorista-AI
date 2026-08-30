import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stylorista_theme.dart';

enum _AuthMode { signIn, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn ? _AuthMode.register : _AuthMode.signIn;
      _loading = false;
    });
    _formKey.currentState?.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_mode == _AuthMode.register && !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and privacy policy.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    widget.onAuthenticated();
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password recovery will be connected with production authentication.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _BackdropPainter()),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1060),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final desktop = constraints.maxWidth >= 820;
                        return desktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: _EditorialPanel()),
                                  const SizedBox(width: 44),
                                  SizedBox(
                                    width: 430,
                                    child: _buildAuthCard(context),
                                  ),
                                ],
                              )
                            : ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: _buildAuthCard(context),
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final signingIn = _mode == _AuthMode.signIn;
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey(_mode),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCFB).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF351329).withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FashionFigurePainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 34, 38, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandLockup(),
                    const SizedBox(height: 34),
                    Text(
                      signingIn ? 'Welcome back' : 'Create your profile',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        fontSize: 38,
                        height: 1,
                        color: Color(0xFF6D6168),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      signingIn
                          ? 'Continue your personal style journey.'
                          : 'One profile for your fit, colors, and seasons.',
                      style: TextStyle(
                        color: StyloristaColors.ink.withValues(alpha: 0.62),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!signingIn) ...[
                      _EditorialField(
                        controller: _nameController,
                        label: 'Full name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _EditorialField(
                      controller: _emailController,
                      label: 'Email address',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    if (!signingIn) ...[
                      const SizedBox(height: 16),
                      _EditorialField(
                        controller: _phoneController,
                        label: 'Phone number · optional',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _EditorialField(
                        controller: _locationController,
                        label: 'City or region · optional',
                        icon: Icons.location_on_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _EditorialField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: signingIn
                          ? const [AutofillHints.password]
                          : const [AutofillHints.newPassword],
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (signingIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(letterSpacing: 1.2, fontSize: 12),
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          value: _acceptTerms,
                          onChanged: (value) =>
                              setState(() => _acceptTerms = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: const Text(
                            'I agree to the terms and privacy policy.',
                            style: TextStyle(fontSize: 12, height: 1.35),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _GradientActionButton(
                      label: signingIn ? 'LOG IN' : 'CREATE ACCOUNT',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 26),
                    OutlinedButton(
                      onPressed: _loading ? null : _switchMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD51A70),
                        side: const BorderSide(
                          color: Color(0xFFD51A70),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        signingIn ? 'CREATE NEW ACCOUNT' : 'SIGN IN',
                        style: const TextStyle(
                          letterSpacing: 2.2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: StyloristaColors.ink.withValues(alpha: 0.46),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Local demo · credentials are not stored',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: StyloristaColors.ink.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B258D), Color(0xFFF01872)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Stylorista',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: '·AI',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD51A70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorialField extends StatelessWidget {
  const _EditorialField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    const border = UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFD9C9D1)),
    );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 14, letterSpacing: 0.7),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFD51A70)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.42),
        border: border,
        enabledBorder: border,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD51A70), width: 1.6),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70228F), Color(0xFFF01872)],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD51A70).withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 52,
            child: Center(
              child: loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 3,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialPanel extends StatelessWidget {
  const _EditorialPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 650,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 46,
            child: Container(
              width: 355,
              height: 535,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF351329).withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const CustomPaint(
                painter: _FashionFigurePainter(prominent: true),
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fit\nColor\nSeason',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 52,
                    height: 0.92,
                    color: Color(0xFF81777D),
                  ),
                ),
                const SizedBox(height: 22),
                Container(width: 74, height: 2, color: const Color(0xFFD51A70)),
                const SizedBox(height: 14),
                const Text(
                  'Style that begins with you.',
                  style: TextStyle(
                    color: Color(0xFF7B315D),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 34,
            bottom: 92,
            child: SizedBox(
              width: 230,
              child: Text(
                'Understand your proportions, discover your palette, and dress for the climate around you.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF554A50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF9F5F5),
    );
    final plum = Paint()..color = const Color(0xFF9E4B96);
    final lilac = Paint()..color = const Color(0xFFB299C4);
    final pink = Paint()..color = const Color(0xFFF07FB2);
    final berry = Paint()..color = const Color(0xFFB34C92);

    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.27, 0)
        ..lineTo(size.width * 0.68, size.height)
        ..lineTo(size.width * 0.47, size.height)
        ..close(),
      plum,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.18, 0)
        ..lineTo(size.width * 0.39, 0)
        ..lineTo(size.width, size.height * 0.73)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * 0.86, size.height)
        ..close(),
      lilac,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.08)
        ..lineTo(size.width, size.height * 0.82)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * 0.88, size.height)
        ..lineTo(0, size.height * 0.27)
        ..close(),
      pink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.58, 0)
        ..lineTo(size.width * 0.72, 0)
        ..lineTo(size.width, size.height * 0.2)
        ..lineTo(size.width, size.height * 0.39)
        ..close(),
      berry,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FashionFigurePainter extends CustomPainter {
  const _FashionFigurePainter({this.prominent = false});

  final bool prominent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 430, size.height / 650);
    final line = Paint()
      ..color = const Color(
        0xFF7E6974,
      ).withValues(alpha: prominent ? 0.34 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = prominent ? 1.7 : 1.25
      ..strokeCap = StrokeCap.round;
    final wash = Paint()
      ..color = const Color(
        0xFFEAA4C6,
      ).withValues(alpha: prominent ? 0.20 : 0.08)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(
      size.width * (prominent ? 0.36 : 0.27),
      size.height * 0.09,
    );
    canvas.scale(scale, scale);

    final dress = Path()
      ..moveTo(132, 150)
      ..cubicTo(94, 205, 94, 260, 76, 354)
      ..cubicTo(53, 465, 20, 535, 8, 565)
      ..cubicTo(98, 612, 235, 610, 327, 558)
      ..cubicTo(280, 470, 246, 369, 225, 274)
      ..cubicTo(214, 222, 202, 180, 178, 151)
      ..close();
    canvas.drawPath(dress, wash);
    canvas.drawPath(dress, line);

    canvas.drawOval(const Rect.fromLTWH(134, 36, 58, 76), line);
    canvas.drawPath(
      Path()
        ..moveTo(137, 66)
        ..cubicTo(146, 39, 171, 26, 193, 52)
        ..cubicTo(182, 47, 171, 59, 166, 76)
        ..cubicTo(156, 70, 147, 68, 137, 66),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(163, 111)
        ..lineTo(163, 135)
        ..moveTo(184, 108)
        ..lineTo(188, 138)
        ..moveTo(126, 152)
        ..cubicTo(139, 137, 156, 134, 176, 140)
        ..cubicTo(195, 142, 211, 153, 224, 174)
        ..moveTo(129, 154)
        ..cubicTo(99, 176, 78, 225, 55, 291)
        ..moveTo(224, 174)
        ..cubicTo(245, 220, 257, 268, 278, 323)
        ..moveTo(117, 196)
        ..cubicTo(138, 230, 191, 232, 214, 195)
        ..moveTo(110, 260)
        ..cubicTo(150, 278, 202, 276, 234, 256)
        ..moveTo(76, 354)
        ..cubicTo(134, 391, 222, 390, 261, 350)
        ..moveTo(56, 431)
        ..cubicTo(127, 474, 243, 462, 289, 419)
        ..moveTo(35, 510)
        ..cubicTo(131, 553, 267, 538, 316, 496),
      line,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FashionFigurePainter oldDelegate) =>
      oldDelegate.prominent != prominent;
}
