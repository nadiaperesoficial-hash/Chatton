import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFB347),
              Color(0xFFFF6B6B),
              Color(0xFFFF2D55),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seu\nTelefone',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vamos enviar um código de verificação\npara o seu número.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          child: Row(
                            children: [
                              const Text('🇧🇷',
                                  style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Text('+55',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  )),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  color: Colors.orange.shade700, size: 20),
                            ],
                          ),
                        ),
                        Container(
                            width: 1, height: 28, color: Colors.grey.shade200),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: '(00) 00000-0000',
                              hintStyle:
                                  TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendCode,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFF2D55)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D55).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Enviar código',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um número válido')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // TODO: FirebaseAuth.instance.verifyPhoneNumber(
    //   phoneNumber: '+55$phone',
    //   codeSent: (verificationId, _) {
    //     Navigator.push(context, MaterialPageRoute(
    //       builder: (_) => OtpScreen(verificationId: verificationId),
    //     ));
    //   },
    // );
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OtpScreen(verificationId: 'dummy'),
        ),
      );
    }
  }
}

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required
