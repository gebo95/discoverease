import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/business_profile.dart';
import '../../../services/experience_photo_service.dart';
import '../../../services/firebase_admin_review_service.dart';
import '../../../shared/utils/photo_files.dart';
import 'admin_claims_page.dart';
import 'admin_plans_page.dart';

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  late final Future<bool> _authorized;
  String? _working;

  @override
  void initState() {
    super.initState();
    _authorized = context.read<FirebaseAdminReviewService>().isAdmin(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final review = context.read<FirebaseAdminReviewService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin review'),
        actions: [
          IconButton(
            tooltip: 'Claims',
            icon: const Icon(Icons.how_to_reg_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminClaimsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Business plans',
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPlansPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _authorized,
        builder: (context, authorization) {
          if (!authorization.hasData) {
            if (authorization.hasError) return const _Message('Could not verify admin access.');
            return const Center(child: CircularProgressIndicator());
          }
          if (authorization.data != true) return const _Message('This account does not have admin access.');
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Businesses'),
                    Tab(text: 'Experiences'),
                    Tab(text: 'Live edits'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ReviewStream(
                        stream: review.watchPendingBusinesses(),
                        emptyMessage: 'No business profiles need review.',
                        itemBuilder: (context, document) => _businessCard(document, review),
                      ),
                      _ReviewStream(
                        stream: review.watchPendingExperiences(),
                        emptyMessage: 'No experiences need review.',
                        itemBuilder: (context, document) => _experienceCard(document, review),
                      ),
                      _ReviewStream(
                        stream: review.watchPendingRevisions(),
                        emptyMessage: 'No edits to live experiences need review.',
                        itemBuilder: (context, document) => _revisionCard(document, review),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _businessCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    FirebaseAdminReviewService review,
  ) {
    final profile = BusinessProfile.fromJson(Map<String, Object?>.from(document.data()));
    final details = [profile.email, profile.phone, profile.website, profile.instagram]
        .where((value) => value.trim().isNotEmpty).join('\n');
    return _ReviewCard(
      title: profile.name,
      details: details,
      working: _working == 'business:${document.id}',
      onApprove: () => _runReview(
        key: 'business:${document.id}',
        title: 'Approve ${profile.name}?',
        action: (_) => review.reviewBusiness(document.id, approve: true),
      ),
      onReject: () => _runReview(
        key: 'business:${document.id}',
        title: 'Reject ${profile.name}?',
        action: (_) => review.reviewBusiness(document.id, approve: false),
      ),
    );
  }

  Widget _experienceCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    FirebaseAdminReviewService review,
  ) {
    final businessId = document.reference.parent.parent?.id;
    if (businessId == null) return const SizedBox.shrink();
    final experience = BusinessExperience.fromJson({
      ...Map<String, Object?>.from(document.data()),
      'id': document.id,
    });
    final details = [
      '${experience.destination} · ${experience.category}',
      experience.location,
      if (experience.address.isNotEmpty) 'Address: ${experience.address}',
      if (experience.latitude != null && experience.longitude != null)
        'Map pin: ${pinText(experience.latitude, experience.longitude)}',
      if (experience.phone.isNotEmpty) 'Phone: ${experience.phone}',
      if (experience.website.isNotEmpty) 'Website: ${experience.website}',
      if (experience.bookingUrl.isNotEmpty) 'Booking: ${experience.bookingUrl}',
      if (experience.hours.isNotEmpty) 'Hours: ${experience.hours}',
      if (experience.schedule.isNotEmpty) 'Schedule: ${experience.schedule}',
      if (experience.subcategory.isNotEmpty) 'Type: ${experience.subcategory}',
      if (experience.price.isNotEmpty) 'Price: ${experience.price}',
      if (experience.highlight.isNotEmpty) 'Highlight: ${experience.highlight}',
      if (experience.perfectFor.isNotEmpty)
        'Perfect for: ${experience.perfectFor.join(', ')}',
      if (experience.features.isNotEmpty)
        'Special: ${experience.features.join(', ')}',
      if (experience.whyYoullLoveIt.isNotEmpty)
        "Why you'll love it: ${experience.whyYoullLoveIt}",
      'Business ID: $businessId',
      experience.description,
    ].where((value) => value.trim().isNotEmpty).join('\n');
    return _ReviewCard(
      title: experience.title,
      details: details,
      reviewNote: experience.reviewNote,
      extra: experience.photos.isEmpty
          ? null
          : _PhotoStrip(label: 'Photos (first is the cover)', entries: experience.photos),
      working: _working == 'experience:${document.id}',
      onApprove: () => _runReview(
        key: 'experience:${document.id}',
        title: 'Publish ${experience.title}?',
        action: (_) => review.reviewExperience(
          businessId: businessId,
          experience: experience,
          approve: true,
        ),
      ),
      onReject: () => _runReview(
        key: 'experience:${document.id}',
        title: 'Reject ${experience.title}?',
        requireNote: true,
        action: (note) => review.reviewExperience(
          businessId: businessId,
          experience: experience,
          approve: false,
          reviewNote: note ?? '',
        ),
      ),
    );
  }

  Widget _revisionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    FirebaseAdminReviewService review,
  ) {
    final businessId = document.reference.parent.parent?.id;
    if (businessId == null) return const SizedBox.shrink();
    final experience = BusinessExperience.fromJson({
      ...Map<String, Object?>.from(document.data()),
      'id': document.id,
    });
    final revision = experience.revision;
    if (revision == null) return const SizedBox.shrink();
    String shown(String value) => value.isEmpty ? '(empty)' : value;
    final changes = revision.changesFrom(experience);
    final details = [
      'Live now: ${experience.title} (${experience.destination})',
      'Business ID: $businessId',
      if (changes.isEmpty) 'No differences from the live version.',
      for (final change in changes)
        '${change.label}\n  Now: ${shown(change.before)}\n  Proposed: ${shown(change.after)}',
    ].join('\n\n');
    final photosChanged = !samePhotoSet(experience.photos, revision.photos);
    return _ReviewCard(
      title: '${experience.title} (edit)',
      details: details,
      extra: !photosChanged
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoStrip(label: 'Photos now', entries: experience.photos),
                _PhotoStrip(
                  label: 'Proposed photos (first is the cover)',
                  entries: revision.photos,
                ),
              ],
            ),
      working: _working == 'revision:${document.id}',
      onApprove: () => _runReview(
        key: 'revision:${document.id}',
        title: 'Apply these changes to ${experience.title}?',
        action: (_) => review.reviewRevision(
          businessId: businessId,
          experienceId: document.id,
          approve: true,
        ),
      ),
      onReject: () => _runReview(
        key: 'revision:${document.id}',
        title: 'Reject these changes?',
        requireNote: true,
        action: (note) => review.reviewRevision(
          businessId: businessId,
          experienceId: document.id,
          approve: false,
          note: note ?? '',
        ),
      ),
    );
  }

  Future<void> _runReview({
    required String key,
    required String title,
    required Future<void> Function(String? note) action,
    bool requireNote = false,
  }) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This decision changes what the business and travelers can see.'),
              if (requireNote) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection',
                    hintText: 'Tell the business what to update.',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: requireNote && noteController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _working = key);
    try {
      await action(requireNote ? note : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review decision saved.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is StateError
            ? error.message.toString()
            : 'Could not save the review decision. Check your admin claim and Firestore rules.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }
}

class _ReviewStream extends StatelessWidget {
  const _ReviewStream({
    required this.stream,
    required this.emptyMessage,
    required this.itemBuilder,
  });
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyMessage;
  final Widget Function(BuildContext, QueryDocumentSnapshot<Map<String, dynamic>>) itemBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const _Message('Could not load review submissions. Check Firestore rules and connection.');
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final documents = snapshot.data!.docs;
      if (documents.isEmpty) return _Message(emptyMessage);
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) => itemBuilder(context, documents[index]),
      );
    },
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.details,
    this.reviewNote = '',
    this.extra,
    required this.working,
    required this.onApprove,
    required this.onReject,
  });
  final String title;
  final String details;
  final String reviewNote;

  /// Optional content shown under the details, such as photos.
  final Widget? extra;
  final bool working;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(details.isEmpty ? 'No additional contact details provided.' : details),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
          if (reviewNote.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Previous review feedback: $reviewNote'),
          ],
          const SizedBox(height: 16),
          if (working)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.close), label: const Text('Reject')),
                const SizedBox(width: 10),
                FilledButton.icon(onPressed: onApprove, icon: const Icon(Icons.check), label: const Text('Approve')),
              ],
            ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)),
  );
}

/// A row of photo thumbnails for reviewers. Not-yet-approved photos come from
/// the private upload folder, which reviewers are allowed to read.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.label, required this.entries});

  final String label;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final service = context.read<ExperiencePhotoService>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            const Text('(none)')
          else
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _ReviewPhoto(
                  entry: entries[index],
                  service: service,
                  badge: index == 0 ? 'Cover' : (isPendingPhoto(entries[index]) ? 'New' : null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewPhoto extends StatefulWidget {
  const _ReviewPhoto({required this.entry, required this.service, this.badge});

  final String entry;
  final ExperiencePhotoService service;
  final String? badge;

  @override
  State<_ReviewPhoto> createState() => _ReviewPhotoState();
}

class _ReviewPhotoState extends State<_ReviewPhoto> {
  late final Future<String> _url = widget.service.urlFor(widget.entry);

  @override
  Widget build(BuildContext context) {
    const broken = ColoredBox(
      color: Color(0x11000000),
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<String>(
              future: _url,
              builder: (context, snapshot) {
                if (snapshot.hasError) return broken;
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                return Image.network(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => broken,
                );
              },
            ),
          ),
          if (widget.badge != null)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
