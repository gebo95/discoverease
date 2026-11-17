import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/business_profile.dart';
import '../../../models/business_analytics.dart';
import '../../../models/destination.dart';
import '../../../repositories/destination_repository.dart';
import '../../../services/firebase_business_service.dart';
import '../../../services/firebase_engagement_service.dart';
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
                final editable = experience.status == 'pending_review' ||
                    experience.status == 'rejected';
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
                              if (experience.reviewNote.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Review feedback: ${experience.reviewNote}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _StatusChip(status: experience.status),
                        if (editable)
                          IconButton(
                            tooltip: experience.status == 'rejected'
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
                                    content: Text(experience.status == 'rejected'
                                        ? 'Updated and resubmitted for review.'
                                        : 'Your changes were saved.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
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
  static const _categories = [
    'Activities', 'Dining', 'Tours', 'Entertainment', 'Shopping', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final experience = widget.experience;
    if (experience != null) {
      _title.text = experience.title;
      _description.text = experience.description;
      _subcategory.text = experience.subcategory;
      _location.text = experience.location;
      _price.text = experience.price;
      _address.text = experience.address;
      _phone.text = experience.phone;
      _website.text = experience.website;
      _bookingUrl.text = experience.bookingUrl;
      _hours.text = experience.hours;
      _schedule.text = experience.schedule;
      _category = experience.category;
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
            (destination) => destination.id == widget.experience!.destinationId,
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
            Text(widget.experience?.status == 'rejected'
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.experience == null
                      ? 'Submit for review'
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
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status == 'pending_review' ? 'Pending' : status),
    visualDensity: VisualDensity.compact,
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
