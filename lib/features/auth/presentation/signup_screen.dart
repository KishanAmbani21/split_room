import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/branding/app_branding.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        showAppSnackBar(
          context,
          'Account created. Welcome to ${AppBranding.appName}.',
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, authErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Create account',
      subtitle: 'Start with a secure email account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.length < 3) {
                  return 'Enter your full name.';
                }
                if (!name.contains(' ')) {
                  return 'Enter first and last name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                final passwordError = validatePassword(value);
                if (passwordError != null) {
                  return passwordError;
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(value ?? '') ||
                    !RegExp(r'\d').hasMatch(value ?? '')) {
                  return 'Use letters and numbers in your password.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _loading ? null : _signup(),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              child: _loading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
