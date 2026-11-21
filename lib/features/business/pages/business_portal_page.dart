import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/business_profile.dart';
import '../../../models/business_analytics.dart';
import '../../../models/destination.dart';
import '../../../repositories/destination_repository.dart';
import '../../../services/experience_photo_service.dart';
import '../../../services/firebase_business_service.dart';
import '../../../services/firebase_engagement_service.dart';
import '../../../shared/utils/photo_files.dart';
import '../../../shared/utils/web_link.dart';

class BusinessPortalPage extends StatelessWidget {
  const BusinessPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage a business profile.')),
      );
    }
    final businesses = context.read<FirebaseBusinessService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Business portal')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: businesses.watchBusiness(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CenteredMessage(
              'Could not load your business profile. Check your connection and Firestore rules.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final document = snapshot.data!;
          if (!document.exists) {
            return _BusinessSetupForm(user: user);
          }
          final profile = BusinessProfile.fromJson(
            Map<String, Object?>.from(document.data()!),
          );
          return _BusinessDashboard(profile: profile, uid: user.uid);
        },
      ),
    );
  }
}

class _BusinessSetupForm extends StatefulWidget {
  const _BusinessSetupForm({required this.user});
  final User user;

  @override
  State<_BusinessSetupForm> createState() => _BusinessSetupFormState();
}

class _BusinessSetupFormState extends State<_BusinessSetupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _instagram.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Register your business',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Submit your business details for review. You can submit experiences while the profile is pending.',
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_name, 'Business name', required: true),
              _field(_email, 'Contact email', required: true,
                  keyboardType: TextInputType.emailAddress),
              _field(_phone, 'Phone number', keyboardType: TextInputType.phone),
              _field(_website, 'Website (optional)', keyboardType: TextInputType.url),
              _field(_instagram, 'Instagram (optional)'),
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
              : const Text('Submit for review'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'This field is required.';
        }
        if (label == 'Contact email' &&
            value != null &&
            !RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())) {
          return 'Enter a valid email address.';
        }
        return null;
      },
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<FirebaseBusinessService>().createBusiness(
        uid: widget.user.uid,
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        website: _website.text,
        instagram: _instagram.text,
      );
    } catch (error) {
      _showMessage(error is StateError
          ? error.message.toString()
          : 'Could not submit your business. Check your connection and Firestore rules.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BusinessDashboard extends StatelessWidget {
  const _BusinessDashboard({required this.profile, required this.uid});
  final BusinessProfile profile;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final businesses = context.read<FirebaseBusinessService>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(profile.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(profile.email),
        const SizedBox(height: 16),
        _ReviewStatus(status: profile.status),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Your experiences',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            FilledButton.icon(
              onPressed: () async {
                final submitted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessExperienceFormPage(uid: uid),
                  ),
                );
                if (submitted == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submitted for review.')),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: businesses.watchExperiences(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _CenteredMessage('Could not load your submissions.');
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('You have not submitted any experiences yet.'),
              );
            }
            return Column(
              children: docs.map((doc) {
                final experience = BusinessExperience.fromJson(
                  Map<String, Object?>.from(doc.data()),
                );
                final live = experience.status == 'published';
                final editable = experience.status == 'pending_review' ||
                    experience.status == 'rejected' ||
                    live;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.local_activity_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(experience.title,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text('${experience.destination} · ${experience.category}'),
                              if (live && _availabilityNote(experience) != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _availabilityNote(experience)!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              if (experience.reviewNote.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Review feedback: ${experience.reviewNote}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                              if (experience.hasPendingRevision ||
                                  experience.hasRejectedRevision)
                                _RevisionBanner(
                                  experience: experience,
                                  onWithdraw: () => _withdrawRevision(
                                    context,
                                    businesses,
                                    uid,
                                    experience.id,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _StatusChip(
                          status: experience.status,
                          availability: live ? experience.availability : 'live',
                        ),
                        if (editable)
                          IconButton(
                            tooltip: live
                                ? 'Edit (changes are reviewed first)'
                                : experience.status == 'rejected'
                                ? 'Edit and resubmit'
                                : 'Edit submission',
                            onPressed: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BusinessExperienceFormPage(
                                    uid: uid,
                                    experience: experience,
                                  ),
                                ),
                              );
                              if (updated == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(live
                                        ? 'Changes sent for review. The current version stays live until they are approved.'
                                        : experience.status == 'rejected'
                                        ? 'Updated and resubmitted for review.'
                                        : 'Your changes were saved.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        _ExperienceMenu(
                          experience: experience,
                          uid: uid,
                          service: businesses,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        _BusinessPerformanceSection(
          uid: uid,
          service: businesses,
          engagement: context.read<FirebaseEngagementService>(),
        ),
      ],
    );
  }
}

Future<void> _withdrawRevision(
  BuildContext context,
  FirebaseBusinessService service,
  String uid,
  String experienceId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await service.withdrawRevision(uid: uid, experienceId: experienceId);
    messenger.showSnackBar(
      const SnackBar(content: Text('Changes removed. The live version is unchanged.')),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not remove the changes. Try again.')),
    );
  }
}

class _RevisionBanner extends StatelessWidget {
  const _RevisionBanner({required this.experience, required this.onWithdraw});
  final BusinessExperience experience;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final rejected = experience.hasRejectedRevision;
    final color = rejected
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rejected
                ? 'Changes not approved: ${experience.revisionNote}'
                : 'Changes under review. The current version stays live until they are approved.',
            style: TextStyle(color: color),
          ),
          TextButton(
            onPressed: onWithdraw,
            child: Text(rejected ? 'Discard changes' : 'Withdraw changes'),
          ),
        ],
      ),
    );
  }
}

class _BusinessPerformanceSection extends StatefulWidget {
  const _BusinessPerformanceSection({
    required this.uid,
    required this.service,
    required this.engagement,
  });
  final String uid;
  final FirebaseBusinessService service;
  final FirebaseEngagementService engagement;

  @override
  State<_BusinessPerformanceSection> createState() =>
      _BusinessPerformanceSectionState();
}

class _BusinessPerformanceSectionState extends State<_BusinessPerformanceSection> {
  late final Future<bool> _ready;
  int _days = 7;

  @override
  void initState() {
    super.initState();
    _ready = widget.engagement.analyticsAvailable();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Performance', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      const Text('Counts are from recorded in-app activity.'),
      const SizedBox(height: 12),
      FutureBuilder<bool>(
        future: _ready,
        builder: (context, readiness) {
          if (readiness.connectionState == ConnectionState.waiting ||
              (!readiness.hasError && readiness.data == true)) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'View and share tracking needs the callable backend and App Check. '
              'Available likes and saves will still appear below.',
            ),
          );
        },
      ),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 7, label: Text('7 days')),
          ButtonSegment(value: 30, label: Text('30 days')),
          ButtonSegment(value: 90, label: Text('90 days')),
        ],
        selected: {_days},
        onSelectionChanged: (selection) => setState(() => _days = selection.first),
      ),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.service.watchExperiences(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Could not load performance data.');
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final experiences = snapshot.data!.docs
              .map((doc) => BusinessExperience.fromJson({
                    ...Map<String, Object?>.from(doc.data()),
                    'id': doc.id,
                  }))
              .where((experience) => experience.status == 'published')
              .toList(growable: false);
          if (experiences.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Performance will appear after an experience is published.'),
            );
          }
          return Column(
            children: experiences
                .map((experience) => _ExperiencePerformanceCard(
                      key: ValueKey('${experience.id}-$_days'),
                      businessId: widget.uid,
                      experience: experience,
                      days: _days,
                      service: widget.service,
                    ))
                .toList(),
          );
        },
      ),
    ],
  );
}

class _ExperiencePerformanceCard extends StatelessWidget {
  const _ExperiencePerformanceCard({
    super.key,
    required this.businessId,
    required this.experience,
    required this.days,
    required this.service,
  });

  final String businessId;
  final BusinessExperience experience;
  final int days;
  final FirebaseBusinessService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.watchDailyAnalytics(
      businessId: businessId,
      listingId: experience.id,
      days: days,
    ),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Card(
          child: ListTile(
            title: Text(experience.title),
            subtitle: const Text('Analytics could not be loaded. Check Firestore rules.'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      var summary = const BusinessDailyAnalytics();
      for (final doc in snapshot.data!.docs) {
        summary += BusinessDailyAnalytics.fromJson(
          Map<String, Object?>.from(doc.data()),
        );
      }
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(experience.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(label: 'Views', value: summary.views),
                  _MetricPill(label: 'Likes', value: summary.likes),
                  _MetricPill(label: 'Shares', value: summary.shares),
                  _MetricPill(label: 'Saves', value: summary.saves),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: service.watchAnalyticsSummary(
                      businessId: businessId,
                      listingId: experience.id,
                    ),
                    builder: (context, summarySnapshot) => _MetricPill(
                      label: 'People sharing (all time)',
                      value: BusinessAnalyticsSummary.fromJson(
                        summarySnapshot.data?.data() ??
                            const <String, Object?>{},
                      ).uniqueSharers,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: CircleAvatar(child: Text('$value', style: const TextStyle(fontSize: 11))),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class BusinessExperienceFormPage extends StatefulWidget {
  const BusinessExperienceFormPage({
    super.key,
    required this.uid,
    this.experience,
  });
  final String uid;
  final BusinessExperience? experience;

  @override
  State<BusinessExperienceFormPage> createState() =>
      _BusinessExperienceFormPageState();
}

class _BusinessExperienceFormPageState extends State<BusinessExperienceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _subcategory = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _bookingUrl = TextEditingController();
  final _hours = TextEditingController();
  final _schedule = TextEditingController();
  String _category = 'Activities';
  Destination? _destination;
  bool _busy = false;

  /// Photos in order, cover first. Entries are private upload paths for new
  /// photos and public addresses for approved ones.
  final List<String> _photos = [];
  final Map<String, Uint8List> _previews = {};
  bool _uploading = false;
  late final String _experienceId;
  static const _categories = [
    'Activities', 'Dining', 'Tours', 'Entertainment', 'Shopping', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final experience = widget.experience;
    // A new experience gets its id up front so photos can be uploaded to its
    // own folder before it is submitted.
    _experienceId =
        experience?.id ??
        context.read<FirebaseBusinessService>().newExperienceId(widget.uid);
    if (experience != null) {
      // Editing a live experience starts from its proposed changes, if any.
      final source =
          experience.revision ?? ExperienceRevision.fromExperience(experience);
      _photos.addAll(source.photos);
      _title.text = source.title;
      _description.text = source.description;
      _subcategory.text = source.subcategory;
      _location.text = source.location;
      _price.text = source.price;
      _address.text = source.address;
      _phone.text = source.phone;
      _website.text = source.website;
      _bookingUrl.text = source.bookingUrl;
      _hours.text = source.hours;
      _schedule.text = source.schedule;
      _category = source.category;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _subcategory.dispose();
    _location.dispose();
    _price.dispose();
    _address.dispose();
    _phone.dispose();
    _website.dispose();
    _bookingUrl.dispose();
    _hours.dispose();
    _schedule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = context.read<DestinationRepository>().getAll();
    _destination ??= widget.experience == null
        ? destinations.first
        : destinations.firstWhere(
            (destination) =>
                destination.id ==
                (widget.experience!.revision?.destinationId ??
                    widget.experience!.destinationId),
            orElse: () => destinations.first,
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.experience == null
            ? 'Submit an experience'
            : 'Edit an experience'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.experience?.status == 'published'
                ? 'Changes to a live experience are reviewed before travelers see them. The current version stays live until then.'
                : widget.experience?.status == 'rejected'
                ? 'Update the requested details and resubmit for review.'
                : 'Submissions are reviewed before they appear in DiscoverEase.'),
            const SizedBox(height: 16),
            _requiredField(_title, 'Experience name'),
            _requiredField(_description, 'Description', maxLines: 4),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((category) => DropdownMenuItem(
                      value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Destination>(
              initialValue: _destination,
              decoration: const InputDecoration(labelText: 'Destination'),
              items: destinations
                  .map((destination) => DropdownMenuItem(
                      value: destination,
                      child: Text('${destination.name}, ${destination.country}')))
                  .toList(),
              onChanged: (value) => setState(() => _destination = value),
              validator: (value) => value == null ? 'Choose a destination.' : null,
            ),
            const SizedBox(height: 12),
            _requiredField(_location, 'Area or neighborhood'),
            _plainField(_subcategory, 'Subcategory (optional)'),
            _plainField(_price, 'Price range (optional)'),
            const SizedBox(height: 8),
            Text(
              'Details travelers will see (all optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _plainField(
              _address,
              'Street address',
              validator: _maxLength(200),
            ),
            _plainField(
              _phone,
              'Phone number',
              keyboardType: TextInputType.phone,
              validator: _maxLength(40),
            ),
            _plainField(
              _website,
              'Website',
              keyboardType: TextInputType.url,
              validator: _linkValidator,
            ),
            _plainField(
              _bookingUrl,
              'Booking or ticket link',
              keyboardType: TextInputType.url,
              validator: _linkValidator,
            ),
            _plainField(
              _hours,
              'Hours (for example Mon-Sat 9am-5pm)',
              maxLines: 2,
              validator: _maxLength(300),
            ),
            _plainField(
              _schedule,
              'When it happens (for example Fri and Sat 8pm)',
              maxLines: 2,
              validator: _maxLength(300),
            ),
            const SizedBox(height: 24),
            _PhotoEditor(
              photos: _photos,
              previews: _previews,
              uploading: _uploading,
              isLive: widget.experience?.status == 'published',
              service: context.read<ExperiencePhotoService>(),
              onAdd: _addPhotos,
              onRemove: (index) => setState(() => _photos.removeAt(index)),
              onMakeCover: (index) => setState(() {
                _photos.insert(0, _photos.removeAt(index));
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy || _uploading ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.experience == null
                      ? 'Submit for review'
                      : widget.experience!.status == 'published'
                          ? 'Send changes for review'
                          : widget.experience!.status == 'rejected'
                          ? 'Save and resubmit'
                          : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requiredField(TextEditingController controller, String label,
          {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'This field is required.'
              : null,
        ),
      );

  Widget _plainField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    ),
  );

  String? _linkValidator(String? value) {
    if (value == null || value.trim().isEmpty || isValidWebLink(value)) {
      return null;
    }
    return 'Enter a full web address, for example https://example.com.';
  }

  String? Function(String?) _maxLength(int limit) =>
      (value) => (value ?? '').trim().length > limit
      ? 'Keep this under $limit characters.'
      : null;

  Future<void> _addPhotos() async {
    final remaining = maxExperiencePhotos - _photos.length;
    if (remaining <= 0 || _uploading) return;
    final messenger = ScaffoldMessenger.of(context);
    final photoService = context.read<ExperiencePhotoService>();
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      // The picker only accepts a limit of 2 or more, so the last free slot
      // uses the single-photo picker.
      picked = remaining >= 2
          ? await picker.pickMultiImage(
              maxWidth: 1920,
              imageQuality: 85,
              limit: remaining,
            )
          : [
              ?await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1920,
                imageQuality: 85,
              ),
            ];
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open your photos.')),
      );
      return;
    }
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    for (final file in picked.take(remaining)) {
      try {
        final bytes = await file.readAsBytes();
        final path = await photoService.uploadPending(
          businessId: widget.uid,
          experienceId: _experienceId,
          bytes: bytes,
          fileName: file.name,
        );
        if (!mounted) return;
        setState(() {
          _photos.add(path);
          _previews[path] = bytes;
        });
      } on StateError catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not upload ${file.name}. Try again.')),
        );
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _destination == null) return;
    setState(() => _busy = true);
    try {
      final service = context.read<FirebaseBusinessService>();
      final existing = widget.experience;
      if (existing == null) {
        await service.submitExperience(
          uid: widget.uid,
          title: _title.text,
          description: _description.text,
          category: _category,
          subcategory: _subcategory.text,
          destinationId: _destination!.id,
          destination: _destination!.name,
          location: _location.text,
          price: _price.text,
          imageUrl: '',
          address: _address.text,
          website: _website.text,
          bookingUrl: _bookingUrl.text,
          phone: _phone.text,
          hours: _hours.text,
          schedule: _schedule.text,
          photos: List.of(_photos),
          id: _experienceId,
        );
      } else if (existing.status == 'published') {
        final revision = ExperienceRevision(
          title: _title.text,
          description: _description.text,
          category: _category,
          subcategory: _subcategory.text,
          destinationId: _destination!.id,
          destination: _destination!.name,
          location: _location.text,
          price: _price.text,
          imageUrl: existing.imageUrl,
          address: _address.text,
          website: _website.text,
          bookingUrl: _bookingUrl.text,
          phone: _phone.text,
          hours: _hours.text,
          schedule: _schedule.text,
          photos: List.of(_photos),
        ).normalized();
        // Choosing a different cover among photos that are already approved
        // takes effect right away; it never goes through review.
        final coverOnly =
            _photos.isNotEmpty &&
            samePhotoSet(existing.photos, _photos) &&
            !samePhotoOrder(existing.photos, _photos);
        if (coverOnly) {
          await service.setCoverPhoto(
            uid: widget.uid,
            experienceId: existing.id,
            photoUrl: _photos.first,
          );
        }
        if (revision.changesFrom(existing).isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  coverOnly
                      ? 'Cover photo updated. It is live now.'
                      : 'Nothing has changed yet.',
                ),
              ),
            );
            if (coverOnly) Navigator.pop(context);
          }
          return;
        }
        await service.submitRevision(
          uid: widget.uid,
          experienceId: existing.id,
          revision: revision,
        );
      } else {
        await service.updateExperience(
          uid: widget.uid,
          experience: BusinessExperience(
            id: existing.id,
            title: _title.text,
            description: _description.text,
            category: _category,
            subcategory: _subcategory.text,
            destinationId: _destination!.id,
            destination: _destination!.name,
            location: _location.text,
            price: _price.text,
            imageUrl: existing.imageUrl,
            status: existing.status,
            reviewNote: existing.reviewNote,
            address: _address.text,
            website: _website.text,
            bookingUrl: _bookingUrl.text,
            phone: _phone.text,
            hours: _hours.text,
            schedule: _schedule.text,
            photos: List.of(_photos),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit. Check your connection and Firestore rules.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending_review';
    final published = status == 'published';
    return Card(
      child: ListTile(
        leading: Icon(
          pending
              ? Icons.hourglass_top
              : published
              ? Icons.verified_outlined
              : Icons.info_outline,
        ),
        title: Text(
          pending
              ? 'Business review pending'
              : published
              ? 'Business approved'
              : 'Business status: $status',
        ),
        subtitle: Text(
          pending
              ? 'Your profile is not publicly listed until approved.'
              : published
              ? 'Your profile is visible to travelers. Each experience is reviewed separately.'
              : 'Your profile status is managed by DiscoverEase review.',
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.availability = 'live'});
  final String status;
  final String availability;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      availability == 'hidden'
          ? 'Hidden'
          : availability == 'ended'
          ? 'Ended'
          : status == 'pending_review'
          ? 'Pending'
          : status,
    ),
    visualDensity: VisualDensity.compact,
  );
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

/// One line under a live experience about its visibility and end date.
String? _availabilityNote(BusinessExperience experience) {
  if (experience.hasEnded) {
    return 'Ended${experience.endsAt == null ? '' : ' on ${_formatDate(experience.endsAt!)}'}. '
        'Travelers who saved it see it as no longer available.';
  }
  if (experience.isHidden) {
    return 'Hidden from travelers. People who saved it see it as temporarily unavailable.';
  }
  if (experience.endsAt != null) {
    return 'Ends ${_formatDate(experience.endsAt!)}';
  }
  return null;
}

enum _ExperienceAction { hide, show, setEnd, clearEnd, delete }

class _ExperienceMenu extends StatelessWidget {
  const _ExperienceMenu({
    required this.experience,
    required this.uid,
    required this.service,
  });

  final BusinessExperience experience;
  final String uid;
  final FirebaseBusinessService service;

  @override
  Widget build(BuildContext context) {
    final live = experience.status == 'published';
    return PopupMenuButton<_ExperienceAction>(
      tooltip: 'More actions',
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => [
        if (live && experience.availability == 'live')
          const PopupMenuItem(
            value: _ExperienceAction.hide,
            child: Text('Hide from travelers'),
          ),
        if (live && experience.isHidden)
          const PopupMenuItem(
            value: _ExperienceAction.show,
            child: Text('Show again'),
          ),
        if (live)
          PopupMenuItem(
            value: _ExperienceAction.setEnd,
            child: Text(
              experience.hasEnded
                  ? 'Run again with a new end date'
                  : experience.endsAt == null
                  ? 'Set an end date'
                  : 'Change end date',
            ),
          ),
        if (live && experience.endsAt != null && !experience.hasEnded)
          const PopupMenuItem(
            value: _ExperienceAction.clearEnd,
            child: Text('Remove end date'),
          ),
        const PopupMenuItem(
          value: _ExperienceAction.delete,
          child: Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _run(BuildContext context, _ExperienceAction action) async {
    final messenger = ScaffoldMessenger.of(context);
    Future<void> attempt(Future<void> Function() work, String done) async {
      try {
        await work();
        messenger.showSnackBar(SnackBar(content: Text(done)));
      } on StateError catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not update this. Try again.')),
        );
      }
    }

    switch (action) {
      case _ExperienceAction.hide:
        final note = await _askForNotice(
          context,
          title: 'Hide "${experience.title}"?',
          body:
              'It leaves the public list right away, with no review needed. '
              'People who saved it will see it as temporarily unavailable. '
              'You can show it again whenever you like.',
          confirmLabel: 'Hide',
        );
        if (note == null) return;
        await attempt(
          () => service.hideExperience(
            uid: uid,
            experienceId: experience.id,
            message: note,
          ),
          'Hidden. Travelers who saved it can see it is unavailable.',
        );
      case _ExperienceAction.show:
        await attempt(
          () => service.showExperience(uid: uid, experienceId: experience.id),
          'It is showing to travelers again.',
        );
      case _ExperienceAction.setEnd:
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now().add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          helpText: 'Last day this is offered',
        );
        if (picked == null) return;
        // The whole chosen day counts, in the owner's own time zone.
        final endsAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        await attempt(
          () => service.setEndDate(
            uid: uid,
            experienceId: experience.id,
            endsAt: endsAt,
          ),
          experience.hasEnded
              ? 'Running again until ${_formatDate(endsAt)}.'
              : 'It will end after ${_formatDate(endsAt)}.',
        );
      case _ExperienceAction.clearEnd:
        await attempt(
          () => service.setEndDate(
            uid: uid,
            experienceId: experience.id,
            endsAt: null,
          ),
          'End date removed.',
        );
      case _ExperienceAction.delete:
        final wasLive = experience.status == 'published';
        final note = await _askForNotice(
          context,
          title: 'Delete "${experience.title}"?',
          body: wasLive
              ? 'This cannot be undone. People who saved it will see it as no '
                    'longer available. To pause it instead, choose Hide.'
              : 'This cannot be undone.',
          confirmLabel: 'Delete',
          destructive: true,
          askForNote: wasLive,
        );
        if (note == null) return;
        await attempt(
          () => service.deleteExperience(
            uid: uid,
            experienceId: experience.id,
            message: note,
          ),
          'Deleted.',
        );
    }
  }
}

/// Asks the owner to confirm, with an optional note travelers will see.
/// Returns null if cancelled, otherwise the note (possibly empty).
Future<String?> _askForNotice(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
  bool askForNote = true,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            if (askForNote) ...[
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 280,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message to people who saved it (optional)',
                  helperText:
                      'For example why you are pausing, or when you will be back. '
                      'No web addresses please.',
                  helperMaxLines: 3,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

/// Photo section of the experience form: thumbnails with the cover first, a
/// way to choose a different cover, remove a photo, or add more.
class _PhotoEditor extends StatelessWidget {
  static const _newNote =
      'Up to $maxExperiencePhotos photos (JPEG, PNG or WebP, under 5 MB each). '
      'The first one is the cover. New photos are reviewed before travelers '
      'see them.';
  static const _liveNote =
      'Up to $maxExperiencePhotos photos (JPEG, PNG or WebP, under 5 MB each). '
      'The first one is the cover. New photos are reviewed before travelers '
      'see them, and your current photos stay up until then. Choosing a '
      'different cover from photos that are already approved takes effect '
      'right away.';

  const _PhotoEditor({
    required this.photos,
    required this.previews,
    required this.uploading,
    required this.isLive,
    required this.service,
    required this.onAdd,
    required this.onRemove,
    required this.onMakeCover,
  });

  final List<String> photos;
  final Map<String, Uint8List> previews;
  final bool uploading;
  final bool isLive;
  final ExperiencePhotoService service;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index) onMakeCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = photos.length < maxExperiencePhotos && !uploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          isLive ? _liveNote : _newNote,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < photos.length; i++)
              _PhotoTile(
                key: ValueKey(photos[i]),
                entry: photos[i],
                preview: previews[photos[i]],
                service: service,
                isCover: i == 0,
                onMakeCover: () => onMakeCover(i),
                onRemove: () => onRemove(i),
              ),
            if (photos.length < maxExperiencePhotos)
              SizedBox(
                width: 112,
                height: 112,
                child: OutlinedButton(
                  onPressed: canAdd ? onAdd : null,
                  child: uploading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined),
                            SizedBox(height: 4),
                            Text('Add photos'),
                          ],
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatefulWidget {
  const _PhotoTile({
    super.key,
    required this.entry,
    required this.preview,
    required this.service,
    required this.isCover,
    required this.onMakeCover,
    required this.onRemove,
  });

  final String entry;
  final Uint8List? preview;
  final ExperiencePhotoService service;
  final bool isCover;
  final VoidCallback onMakeCover;
  final VoidCallback onRemove;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  late final Future<String> _url = widget.service.urlFor(widget.entry);

  @override
  Widget build(BuildContext context) {
    const broken = ColoredBox(
      color: Color(0x11000000),
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
    final Widget image = widget.preview != null
        ? Image.memory(widget.preview!, fit: BoxFit.cover)
        : FutureBuilder<String>(
            future: _url,
            builder: (context, snapshot) {
              if (snapshot.hasError) return broken;
              if (!snapshot.hasData) {
                return const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Image.network(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => broken,
              );
            },
          );
    return SizedBox(
      width: 112,
      height: 136,
      child: Column(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: image,
                ),
                if (widget.isCover)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton.filledTonal(
                    tooltip: 'Remove photo',
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: widget.isCover
                ? const SizedBox.shrink()
                : TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: widget.onMakeCover,
                    child: const Text(
                      'Make cover',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
