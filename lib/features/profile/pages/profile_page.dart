import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/firebase_account_service.dart';
import '../../../services/account_sync_coordinator.dart';
import '../../business/pages/business_portal_page.dart';
import '../../business/pages/admin_review_page.dart';
import '../../../services/firebase_admin_review_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<FirebaseAccountService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<User?>(
        stream: accounts.authStateChanges,
        initialData: accounts.currentUser,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Message('Could not check your account status.');
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          return user == null
              ? const _AccountForm()
              : _SignedInProfile(user: user);
        },
      ),
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<AccountSyncCoordinator>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.displayName?.isNotEmpty == true ? user.displayName! : 'Traveler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text(user.email ?? '')),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_syncLabel(sync.state),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(sync.errorMessage ??
                    'Trips and saved places sync to this account. Guest demo data stays separate.'),
                if (sync.state == AccountSyncState.error) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: sync.retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessPortalPage()),
          ),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Business portal'),
        ),
        const _AdminReviewLink(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _runAction(context, () async {
            await context.read<FirebaseAccountService>().signOut();
          }),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _AdminReviewLink extends StatefulWidget {
  const _AdminReviewLink();

  @override
  State<_AdminReviewLink> createState() => _AdminReviewLinkState();
}

class _AdminReviewLinkState extends State<_AdminReviewLink> {
  late final Future<bool> _isAdmin;

  @override
  void initState() {
    super.initState();
    _isAdmin = context.read<FirebaseAdminReviewService>().isAdmin(refresh: true);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _isAdmin,
    builder: (context, snapshot) {
      if (snapshot.data != true) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminReviewPage()),
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Admin review'),
        ),
      );
    },
  );
}

String _syncLabel(AccountSyncState state) => switch (state) {
  AccountSyncState.guest => 'Signed out',
  AccountSyncState.loading => 'Loading your cloud data…',
  AccountSyncState.synced => 'Cloud sync is ready',
  AccountSyncState.syncing => 'Syncing changes…',
  AccountSyncState.error => 'Cloud sync needs attention',
};

class _AccountForm extends StatefulWidget {
  const _AccountForm();

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Text(
          _creating ? 'Create your account' : 'Welcome back',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(_creating
            ? 'Save your DiscoverEase profile in the development project.'
            : 'Sign in to your DiscoverEase account.'),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (_creating) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email address.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value == null || value.length < 6
                    ? 'Use at least 6 characters.'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_creating ? 'Create account' : 'Sign in'),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _creating = !_creating),
          child: Text(_creating
              ? 'Already have an account? Sign in'
              : 'New to DiscoverEase? Create an account'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final accounts = context.read<FirebaseAccountService>();
    try {
      if (_creating) {
        await accounts.createAccount(
          email: _email.text,
          password: _password.text,
          name: _name.text,
        );
      } else {
        await accounts.signIn(email: _email.text, password: _password.text);
      }
    } on FirebaseAuthException catch (error) {
      _showError(_authError(error));
    } catch (_) {
      _showError('Account request failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _authError(FirebaseAuthException error) => switch (error.code) {
    'email-already-in-use' => 'An account already exists for this email.',
    'invalid-email' => 'That email address is not valid.',
    'invalid-credential' || 'wrong-password' || 'user-not-found' =>
      'Email or password is incorrect.',
    'weak-password' => 'Choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' => 'Network unavailable. Check your connection.',
    _ => error.message ?? 'Account request failed. Please try again.',
  };
}

class _Message extends StatelessWidget {
  const _Message(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

Future<void> _runAction(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Try again.')),
      );
    }
  }
}
