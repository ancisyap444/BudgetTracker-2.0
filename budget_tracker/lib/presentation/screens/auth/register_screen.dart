// lib/presentation/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fk = GlobalKey<FormState>();
  final _nc = TextEditingController();
  final _ec = TextEditingController();
  final _pc = TextEditingController();
  final _cc = TextEditingController();
  bool _obs = true;

  @override
  void dispose() {
    _nc.dispose();
    _ec.dispose();
    _pc.dispose();
    _cc.dispose();
    super.dispose();
  }

  void _submit() {
    if (_fk.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthSignUpRequested(
          email: _ec.text.trim(),
          password: _pc.text,
          fullName: _nc.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context))),
      body: BlocListener<AuthBloc, AuthBlocState>(
        listener: (ctx, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.expense));
          }
          if (state is AuthAuthenticated) {
            Navigator.popUntil(ctx, (r) => r.isFirst);
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
                    Text('Create Account',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 6),
                    Text('Start tracking your budget today',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    TextFormField(
                        controller: _nc,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline,
                                color: context.txtMuted, size: 20)),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name required'
                            : null),
                    const SizedBox(height: 14),
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
                        }),
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
                          if (v == null || v.isEmpty) {
                            return 'Password required';
                          }
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        }),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: _cc,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline,
                                color: context.txtMuted, size: 20)),
                        validator: (v) {
                          if (v != _pc.text) return 'Passwords do not match';
                          return null;
                        }),
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
                            : const Text('Create Account'),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
