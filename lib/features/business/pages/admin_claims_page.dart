import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/claimable_business.dart';
import '../../../models/destination.dart';
import '../../../repositories/destination_repository.dart';
import '../../../services/firebase_claim_service.dart';

/// Admin only: add a business with the contact details on file so its owner
/// can claim it, and review "I can't get the code" requests. The server checks
/// that the caller is an admin.
class AdminClaimsPage extends StatefulWidget {
  const AdminClaimsPage({super.key});

  @override
  State<AdminClaimsPage> createState() => _AdminClaimsPageState();
}

class _AdminClaimsPageState extends State<AdminClaimsPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _category = TextEditingController();
  Destination? _destination;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final destination =
        _destination ?? context.read<DestinationRepository>().getAll().first;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await context.read<FirebaseClaimService>().createClaimable(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        category: _category.text,
        destinationId: destination.id,
      );
      if (!mounted) return;
      setState(() => _message = '${_name.text.trim()} can now be claimed.');
      _name.clear();
      _email.clear();
      _phone.clear();
      _category.clear();
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not add it. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(ClaimRequest request, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<FirebaseClaimService>().reviewRequest(
        requestId: request.id,
        approve: approve,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(approve ? 'Approved. Access given.' : 'Rejected.')),
      );
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the decision. Try again.')),
      );
    }
  }

  Future<void> _revoke(ClaimedBusiness business) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<FirebaseClaimService>();
    // null means cancelled; otherwise the (possibly empty) reason.
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RevokeDialog(name: business.name),
    );
    if (reason == null) return;
    try {
      await service.revokeOwnership(businessId: business.id, reason: reason);
      messenger.showSnackBar(
        SnackBar(content: Text('${business.name} can be claimed again.')),
      );
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not take it back. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = context.read<DestinationRepository>().getAll();
    final selected = _destination ?? destinations.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Claims')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Add a business to be claimed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'The code is emailed to the address below, which the owner never '
            'sees in full. Use an address you trust belongs to the business.',
          ),
          TextField(
            controller: _name,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Business name'),
          ),
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Contact email'),
          ),
          TextField(
            controller: _phone,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
          ),
          TextField(
            controller: _category,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Category (optional)'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Destination>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Destination'),
            items: [
              for (final destination in destinations)
                DropdownMenuItem(value: destination, child: Text(destination.name)),
            ],
            onChanged: _busy ? null : (value) => setState(() => _destination = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _add,
            child: const Text('Add business'),
          ),
          if (_message != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Divider(height: 40),
          Text('Requests for help', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          StreamBuilder<List<ClaimRequest>>(
            stream: context.read<FirebaseClaimService>().watchPendingRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Could not load requests.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final requests = snapshot.data!;
              if (requests.isEmpty) return const Text('No requests waiting.');
              return Column(
                children: [
                  for (final request in requests)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.businessName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('Reach them at: ${request.contact}'),
                            if (request.accountEmail.isNotEmpty)
                              Text('Signed in as: ${request.accountEmail}'),
                            if (request.note.isNotEmpty) Text('Note: ${request.note}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: () => _review(request, true),
                                  child: const Text('Approve'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _review(request, false),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(height: 40),
          Text('Claimed businesses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          StreamBuilder<List<ClaimedBusiness>>(
            stream: context.read<FirebaseClaimService>().watchClaimedBusinesses(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text('Could not load businesses.');
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final claimed = snapshot.data!;
              if (claimed.isEmpty) return const Text('No claimed businesses yet.');
              return Column(
                children: [
                  for (final business in claimed)
                    Card(
                      child: ListTile(
                        title: Text(business.name),
                        subtitle: Text(
                          business.email.isEmpty ? 'No contact on file' : business.email,
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => _revoke(business),
                          child: const Text('Take back'),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RevokeDialog extends StatefulWidget {
  const _RevokeDialog({required this.name});

  final String name;

  @override
  State<_RevokeDialog> createState() => _RevokeDialogState();
}

class _RevokeDialogState extends State<_RevokeDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Take ${widget.name} back?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The owner loses access right away, the business\'s live Pulses '
            'end, and it goes back up for claiming. Its listings and any paid '
            'plan are not touched.',
          ),
          TextField(
            controller: _reason,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Reason (kept in the log)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          child: const Text('Take it back'),
        ),
      ],
    );
  }
}
