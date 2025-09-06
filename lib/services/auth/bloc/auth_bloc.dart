import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projects/services/auth/bloc/auth_event.dart';
import 'package:projects/services/auth/bloc/auth_state.dart';
import 'package:projects/services/auth/auth_provider.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
    : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(exception: null, isLoading: false));
    });

    on<AuthEventForgotPassword>((event, emit) async {
      emit(
        const AuthStateForgotPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: false,
        ),
      );

      final email = event.email;
      if (email == null) {
        return;
      }

      emit(
        const AuthStateForgotPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: true,
        ),
      );
      bool didSendEmail;
      Exception? exception;
      try {
        await provider.sendPasswordReset(toEmail: email);
        exception = null;
        didSendEmail = true;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = e;
      }
      emit(
        AuthStateForgotPassword(
          exception: exception,
          hasSentEmail: didSendEmail,
          isLoading: false,
        ),
      );
    });

    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVeritication();
      emit(state);
    });
    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(email: email, password: password);
        await provider.sendEmailVeritication();
        emit(const AuthStateNeedsVerifitication(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });
    on<AuthEvetInitialize>((event, emit) async {
      await provider.initialize();
      final user = provider.currentUser;
      if (user == null) {
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerifitication(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(user: user, isLoading: false));
      }
    });
    on<AuthEventLogIn>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while I log you in',
        ),
      );
      final email = event.email;
      final password = event.password;
      try {
        final user = await provider.logIn(email: email, password: password);
        if (!user.isEmailVerified) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(const AuthStateNeedsVerifitication(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });
    on<AuthEventLogOut>((event, emit) async {
      try {
        await provider.logOut();
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });
  }
}
