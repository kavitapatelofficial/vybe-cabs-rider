import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/vybe_logo.dart';
import '../../../router/app_router.dart';
import '../bloc/auth_bloc.dart';

/// Firebase email + password auth, with a toggle between logging in and
/// creating an account.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bloc = context.read<AuthBloc>();
    if (_isSignUp) {
      bloc.add(
        AuthSignUpRequested(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    } else {
      bloc.add(
        AuthLoginRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == AuthStatus.authenticated,
        listener: (context, state) => Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Center(child: VybeLogo(size: 76)),
                    const SizedBox(height: 40),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Sign up to start booking rides.'
                          : 'Log in to book your next ride.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildForm(),
                    const SizedBox(height: 20),
                    _buildError(),
                    const SizedBox(height: 4),
                    _buildSubmitButton(),
                    const SizedBox(height: 18),
                    _buildModeToggle(),
                    const SizedBox(height: 24),
                    const _TermsNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Animated so switching to sign-up slides the name field in rather
          // than snapping the layout.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _isSignUp
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'Kavita Patel',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: Validators.email,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'rider@vybecabs.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: Validators.password,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      builder: (context, state) {
        if (!state.hasError) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InfoBanner(message: state.errorMessage!),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      builder: (context, state) => LoadingButton(
        label: _isSignUp ? 'Create account' : 'Log in',
        isLoading: state.isSubmitting,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account?' : "New to Vybe Cabs?",
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isSignUp ? 'Log in' : 'Create one',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _TermsNote extends StatelessWidget {
  const _TermsNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'By continuing you agree to the Vybe Cabs Terms of Service and Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
    );
  }
}
