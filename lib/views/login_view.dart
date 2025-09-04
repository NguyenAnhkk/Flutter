import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projects/constants/routes.dart';
import 'package:projects/services/auth/auth_service.dart';
import 'package:projects/services/auth/bloc/auth_event.dart';
import 'package:projects/services/auth/bloc/auth_state.dart';
import 'package:projects/utilities/dialogs/loading_dialog.dart';
import '../firebase_options.dart';
import 'dart:developer' as devtools show log;

import '../services/auth/auth_exceptions.dart';
import '../services/auth/bloc/auth_bloc.dart';
import '../utilities/dialogs/error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.title});

  final String title;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedOut) {
          if (state.exception is UserNotFoundAuthException) {
            await showErrorDialog(
              context,
              'Cannot find a user with the entered credentials!',
            );
          } else if (state.exception is WrongPasswordAuthExceptions) {
            await showErrorDialog(context, 'Wrong credentials');
          } else if (state.exception is GenericAuthExceptions) {
            await showErrorDialog(context, 'Authentication error');
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Colors.deepOrange, Colors.orange, Colors.orangeAccent],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 80),
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Welcome Back",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(60),
                                topRight: Radius.circular(60),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                children: <Widget>[
                                  SizedBox(height: 60),
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromRGBO(
                                            225,
                                            95,
                                            27,
                                            .3,
                                          ),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          child: TextField(
                                            controller: _email,
                                            enableSuggestions: false,
                                            autocorrect: false,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              hintText: "Enter your email",
                                              hintStyle: TextStyle(
                                                color: Colors.grey,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            cursorColor: Colors.teal,
                                          ),
                                        ),
                                        Container(
                                          child: TextField(
                                            controller: _password,
                                            obscureText: true,
                                            enableSuggestions: false,
                                            autocorrect: false,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter your password',
                                              border: InputBorder.none,
                                              hintStyle: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            cursorColor: Colors.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextButton(
                                    onPressed: () {
                                      context.read<AuthBloc>().add(
                                        const AuthEventForgotPassword(),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final email = _email.text;
                                        final password = _password.text;
                                        context.read<AuthBloc>().add(
                                          AuthEventLogIn(email, password),
                                        );
                                      },
                                      child: const Text('Login'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.read<AuthBloc>().add(
                                        const AuthEventShouldRegister(),
                                      );
                                    },
                                    child: const Text(
                                      'Not registered yet? Register here!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
}
