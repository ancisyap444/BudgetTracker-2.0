// lib/presentation/blocs/auth/auth_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/models/models.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email, password;
  AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email, password, fullName;
  AuthSignUpRequested(
      {required this.email, required this.password, required this.fullName});
  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthGuestRequested extends AuthEvent {}

class _AuthUserChanged extends AuthEvent {
  final User? user;
  _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthBlocState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthBlocState {}

class AuthLoading extends AuthBlocState {}

class AuthAuthenticated extends AuthBlocState {
  final User user;
  final ProfileModel? profile;
  AuthAuthenticated({required this.user, this.profile});
  @override
  List<Object?> get props => [user, profile];
}

class AuthUnauthenticated extends AuthBlocState {}

class AuthError extends AuthBlocState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final BudgetRepository _r;
  StreamSubscription? _sub;

  AuthBloc(this._r) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthGuestRequested>(_onGuestRequested);
    on<_AuthUserChanged>(_onUserChanged);
  }

  Future<void> _onStarted(AuthStarted _, Emitter<AuthBlocState> emit) async {
    final u = _r.me;
    if (u != null) {
      emit(AuthAuthenticated(user: u, profile: await _r.getProfile()));
    } else {
      emit(AuthUnauthenticated());
    }
    _sub = _r.authStream.listen((s) => add(_AuthUserChanged(s.session?.user)));
  }

  Future<void> _onGuestRequested(
      AuthGuestRequested _, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    _r.enableGuestMode();
    final p = await _r.getProfile();
    emit(AuthAuthenticated(user: _r.me!, profile: p));
  }

  Future<void> _onUserChanged(
      _AuthUserChanged e, Emitter<AuthBlocState> emit) async {
    if (_r.isGuestMode) return;
    if (e.user != null) {
      emit(AuthAuthenticated(user: e.user!, profile: await _r.getProfile()));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(
      AuthSignInRequested e, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _r.signIn(email: e.email, password: e.password);
      if (res.user != null) {
        emit(
            AuthAuthenticated(user: res.user!, profile: await _r.getProfile()));
      } else {
        emit(AuthError('Invalid credentials.'));
      }
    } on AuthException catch (err) {
      if (err.message.toLowerCase().contains('email not confirmed')) {
        emit(AuthError(
            'Email not confirmed yet. Click the confirmation link in your Gmail or continue as Guest below.'));
      } else if (err.message
          .toLowerCase()
          .contains('invalid login credentials')) {
        emit(AuthError(
            'Incorrect email or password. Please verify your credentials.'));
      } else {
        emit(AuthError(err.message));
      }
    } catch (err) {
      emit(AuthError(err.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignUp(
      AuthSignUpRequested e, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _r.signUp(
          email: e.email, password: e.password, fullName: e.fullName);
      if (res.session != null && res.user != null) {
        await Future.delayed(const Duration(milliseconds: 700));
        await _r.seedDefaultCategories();
        emit(
            AuthAuthenticated(user: res.user!, profile: await _r.getProfile()));
      } else if (res.user != null) {
        emit(AuthError(
            'Account created! Please check your email to confirm your account before logging in, or continue as Guest.'));
      } else {
        emit(AuthError('Sign-up failed. Try again.'));
      }
    } on AuthException catch (err) {
      if (err.message.toLowerCase().contains('rate limit')) {
        emit(AuthError(
            'Email rate limit reached. Your account was created! Log in directly or continue as Guest below.'));
      } else {
        emit(AuthError(err.message));
      }
    } catch (err) {
      emit(AuthError(err.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested _, Emitter<AuthBlocState> emit) async {
    await _r.signOut();
    emit(AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
