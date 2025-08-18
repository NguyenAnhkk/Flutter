import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projects/constants/routes.dart';
import 'package:projects/services/auth/auth_service.dart';
import 'package:projects/utilities/show_error_dialog.dart';
import 'dart:developer' as devtools show log;
import '../firebase_options.dart';
import 'package:projects/services/auth/auth_exceptions.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                await AuthService.firebase().createUser(
                  email: email,
                  password: password,
                );
                AuthService.firebase().sendEmailVeritication();
                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on WeakPasswordAuthExceptions {
                await showErrorDialog(context, 'Weak password');
              } on EmailAlreadyInUseAuthExceptions {
                await showErrorDialog(context, 'Email is already in use');
              } on InvalidEmailAuthExceptions {
                await showErrorDialog(
                  context,
                  'This is an invalid email address',
                );
              } on GenericAuthExceptions {
                await showErrorDialog(context, 'Faired to register');
              }
            },
            child: const Text('Register'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(loginRoute, (route) => false);
            },
            child: const Text('Already registered? Login here!'),
          ),
        ],
      ),
    );
  }
}
