import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin/core/services/authentication_service.dart';
import 'package:pin/core/utils/NavigationMenu/NavigationMenu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/constants.dart';

class LoginForm extends StatefulWidget {
  final Function(String, String) onLogin;

  const LoginForm({super.key, required this.onLogin});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isHoveredRecuperar = false;
  bool _isLoading = false;

  final AuthMethod _authMethod = AuthMethod();

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  // Login Method
  void loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String res = await _authMethod.loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (res == 'success') {
        String userId = _authMethod.getCurrentUser()!.uid;
        await saveUserId(userId);
        await _authMethod.saveUserModel(userId);
        widget.onLogin(_emailController.text, _passwordController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Google Sign-In Method
  void signInWithGoogle() async {
    try {
      String res = await _authMethod.signInWithGoogle();
      if (res == "success") {
        String userId = _authMethod.getCurrentUser()!.uid;
        await saveUserId(userId);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NavigationMenu()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Login Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Iniciar sesión',
                style: TextStyle(fontSize: 24, fontFamily: 'UrbaneMedium', fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 31),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextFormField(
              controller: _emailController,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.w400,
                color: PrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: "Correo electrónico",
                hintStyle: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: PrimaryColor,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0), // Adjust padding to center the icon
                  child: SvgPicture.asset(
                    'icons/mail.svg',
                    height: 35, // Set size to 35px
                    width: 35,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFE3E3E3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Introduce tu correo electrónico' : null,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.w400,
                color: PrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: "Contraseña",
                hintStyle: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: PrimaryColor,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0), // Adjust padding to center the icon
                  child: SvgPicture.asset(
                    'icons/key.svg',
                    height: 35, // Set size to 35px
                    width: 35,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFE3E3E3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Introduce tu contraseña' : null,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: // Recuperar Contraseña Link
            MouseRegion(
              onEnter: (_) {
                setState(() {
                  _isHoveredRecuperar = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isHoveredRecuperar = false;
                });
              },
              child: GestureDetector(
                onTap: () {
                  // Add your onTap logic here
                },
                child: Text(
                  'Ha olvidado la contraseña? Recuperar contraseña',
                  style: TextStyle(
                    color: _isHoveredRecuperar ? Colors.grey : Color(0xFF000000),
                    fontFamily: 'UrbaneMedium',
                    fontSize: 13,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.26,
                  ),
                ),
              ),
            )
          ),
          const SizedBox(height: 40),
          _isLoading
              ? const CircularProgressIndicator()
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              onPressed: loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 30),
              ),
              child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 17, fontFamily: 'UrbaneMedium', fontWeight: FontWeight.w500, color: SecondaryColor)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              onPressed: signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shadowColor: Colors.grey.withOpacity(0.85),
                elevation: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/icons/icons-google.svg', height: 20),
                  const SizedBox(width: 10),
                  const Text(
                      'Iniciar sesión con Google',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
