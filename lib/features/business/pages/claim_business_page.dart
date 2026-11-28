import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/claimable_business.dart';
import '../../../services/firebase_claim_service.dart';

/// Find a business an admin added and prove it is yours with a code sent to
/// the contact already on file. Pops with true once the business is claimed.
class ClaimBusinessPage extends StatefulWidget {
  const ClaimBusinessPage({super.key});

  @override
  State<ClaimBusinessPage> createState() => _ClaimBusinessPageState();
}

class _ClaimBusinessPageState extends State<ClaimBusinessPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseClaimService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Claim your business')),
      body: StreamBuilder<List<ClaimableBusiness>>(
        stream: service.watchClaimable(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load businesses. Check your connection.'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final shown = [
            for (final business in all)
              if (business.matches(_query)) business,
          ];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Find your business, then we will send a code to the contact '
                'we already have for it.',
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search by business name',
                ),
              ),
              const SizedBox(height: 12),
              if (all.isEmpty)
                const Text(
                  'No businesses are waiting to be claimed yet. You can '
                  'register your business instead.',
                )
              else if (shown.isEmpty)
                const Text('No business matches that name.'),
              for (final business in shown)
                Card(
                  child: ListTile(
                    title: Text(business.name),
                    subtitle: Text(
                      [
                        if (business.category.isNotEmpty) business.category,
                        if (business.emailHint.isNotEmpty)
                          'Code goes to ${business.emailHint}',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final claimed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClaimCodePage(business: business),
                        ),
                      );
                      if (claimed == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Ask for a code, type it, or ask an admin for help.
class ClaimCodePage extends StatefulWidget {
  const ClaimCodePage({super.key, required this.business});

  final ClaimableBusiness business;

  @override
  State<ClaimCodePage> createState() => _ClaimCodePageState();
}

class _ClaimCodePageState extends State<ClaimCodePage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() work) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await work();
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
    final sentTo = await context.read<FirebaseClaimService>().requestCode(
      widget.business.id,
    );
    if (mounted) setState(() => _sentTo = sentTo);
  });

  Future<void> _confirm() => _run(() async {
    final service = context.read<FirebaseClaimService>();
    await service.confirmCode(
      businessId: widget.business.id,
      code: _code.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You now manage ${widget.business.name}.')),
    );
    Navigator.pop(context, true);
  });

  Future<void> _askForHelp() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _HelpDialog(business: widget.business),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent. We will review it and get back to you.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    return Scaffold(
      appBar: AppBar(title: Text(business.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_sentTo == null) ...[
            Text(
              business.emailHint.isEmpty
                  ? 'We will email a code to the contact on file for this business.'
                  : 'We will email a code to ${business.emailHint}.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: const Text('Send code'),
            ),
          ] else ...[
            Text('We sent a 6-digit code to $_sentTo. It works for 15 minutes.'),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: const Text('Confirm'),
            ),
            TextButton(
              onPressed: _busy ? null : _send,
              child: const Text('Send a new code'),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Divider(height: 40),
          const Text('Cannot get the code? That email may be old or no longer yours.'),
          TextButton(
            onPressed: _busy ? null : _askForHelp,
            child: const Text('I can\'t get the code'),
          ),
        ],
      ),
    );
  }
}

class _HelpDialog extends StatefulWidget {
  const _HelpDialog({required this.business});

  final ClaimableBusiness business;

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog> {
  final _contact = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contact.text.trim().isEmpty) {
      setState(() => _error = 'Enter an email or phone number we can reach you at.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<FirebaseClaimService>().submitRequest(
        businessId: widget.business.id,
        contact: _contact.text,
        note: _note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send your request. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ask for help'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us how to reach you and how you are connected to '
              '${widget.business.name}. We will check before giving access.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contact,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Your email or phone'),
            ),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Anything that helps us check (optional)'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Send request'),
        ),
      ],
    );
  }
}
