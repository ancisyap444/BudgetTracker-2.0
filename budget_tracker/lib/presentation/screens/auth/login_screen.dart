// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _fk = GlobalKey<FormState>();
  final _ec = TextEditingController();
  final _pc = TextEditingController();
  bool _obs = true;

  @override
  void dispose() {
    _ec.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _submit() {
    if (_fk.currentState?.validate() ?? false) {
      context
          .read<AuthBloc>()
          .add(AuthSignInRequested(email: _ec.text.trim(), password: _pc.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthBlocState>(
        listener: (ctx, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.expense));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _fk,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Center(
                        child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ],
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 40),
                    )),
                    const SizedBox(height: 20),
                    Center(
                        child: Text('Budget Tracker App',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: context.txtPrimary))),
                    const SizedBox(height: 6),
                    Center(
                        child: Text('Track smarter, save better',
                            style: TextStyle(
                                color: context.txtSecondary, fontSize: 14))),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _ec,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: context.txtMuted, size: 20)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _pc,
                      obscureText: _obs,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: context.txtMuted, size: 20),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _obs
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: context.txtMuted,
                                  size: 20),
                              onPressed: () => setState(() => _obs = !_obs))),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    BlocBuilder<AuthBloc, AuthBlocState>(
                      builder: (ctx, state) => ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submit,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Continue as Guest (Offline Mode)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthGuestRequested()),
                    ),
                    const SizedBox(height: 18),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account?",
                          style: TextStyle(color: context.txtSecondary)),
                      TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                      value: context.read<AuthBloc>(),
                                      child: const RegisterScreen()))),
                          child: const Text('Sign Up',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
