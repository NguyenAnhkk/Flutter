import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projects/constants/routes.dart';
import 'package:projects/services/auth/auth_service.dart';
import 'package:projects/services/auth/bloc/auth_bloc.dart';
import 'package:projects/services/auth/bloc/auth_event.dart';
import 'package:projects/services/auth/bloc/auth_state.dart';
import 'dart:developer' as devtools show log;
import '../firebase_options.dart';
import 'package:projects/services/auth/auth_exceptions.dart';

import '../utilities/dialogs/error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
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
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateRegistering) {
          if (state.exception is WeakPasswordAuthExceptions) {
            await showErrorDialog(context, 'Weak password');
          } else if (state.exception is EmailAlreadyInUseAuthExceptions) {
            await showErrorDialog(context, 'Email is already in use');
          } else if (state.exception is GenericAuthExceptions) {
            await showErrorDialog(context, 'Failed to register');
          } else if (state.exception is InvalidEmailAuthExceptions) {
            await showErrorDialog(context, 'Invalid email');
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6A11CB),
                  Color(0xFF2575FC),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo/Icon section
                          Flexible(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(top: 40, bottom: 20),
                              child: const Icon(
                                Icons.person_add_alt_1,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Form section
                          Flexible(
                            flex: 3,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    const Text(
                                      'Enter your details to create your account',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    TextFormField(
                                      controller: _email,
                                      focusNode: _emailFocusNode,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'Enter your email',
                                        prefixIcon: const Icon(Icons.email),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: _password,
                                      focusNode: _passwordFocusNode,
                                      obscureText: true,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'Enter your password',
                                        prefixIcon: const Icon(Icons.lock),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password should be at least 6 characters';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) {
                                        _register();
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Register button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2575FC),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 5,
                                        ),
                                        child: const Text(
                                          'Register',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Already registered? Login here
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            context.read<AuthBloc>().add(const AuthEventLogOut());
                                          },
                                          child: const Text(
                                            'Login here',
                                            style: TextStyle(
                                              color: Color(0xFF2575FC),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bottom spacing
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0
                              ? MediaQuery.of(context).viewInsets.bottom + 20
                              : 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      final email = _email.text;
      final password = _password.text;
      context.read<AuthBloc>().add(
        AuthEventRegister(email, password),
      );
    }
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
}