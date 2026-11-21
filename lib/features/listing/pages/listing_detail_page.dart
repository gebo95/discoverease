import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/listing.dart';
import '../../../repositories/listing_repository.dart';
import '../../../repositories/saved_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../services/firebase_engagement_service.dart';
import '../../../shared/components/bottom_sheets/de_plan_experience_sheet.dart';
import '../../../shared/components/feedback/de_toast.dart';
import '../../../shared/components/sections/de_traveler_tips_section.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';
import '../../../shared/utils/web_link.dart';

class ListingDetailPage extends StatefulWidget {
  final Listing listing;

  const ListingDetailPage({super.key, required this.listing});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  Listing get listing => widget.listing;

  @override
  void initState() {
    super.initState();
    final isSignedIn = FirebaseAuth.instance.currentUser != null;
    final isBusinessListing = listing.businessId != null;
    if (kDebugMode) {
      debugPrint(
        '[DiscoverEase analytics] Detail opened: '
        'businessListing=$isBusinessListing, signedIn=$isSignedIn',
      );
    }
    if (isBusinessListing && isSignedIn && !listing.isUnavailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            context
                .read<FirebaseEngagementService>()
                .recordView(listing.id)
                .catchError((Object _) {}),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingRepository = context.read<ListingRepository>();
    final savedRepository = context.watch<SavedRepository>();
    final isSaved = savedRepository.isSaved(listing.id);

    final relatedListingIds = <String>{listing.id};
    final pairedListings = listing.pairedListingIds
        .map(listingRepository.getById)
        .whereType<Listing>()
        .where((item) => !item.isUnavailable && relatedListingIds.add(item.id))
        .take(2)
        .toList();

    final continueDayListings = listing.continueDayIds
        .map(listingRepository.getById)
        .whereType<Listing>()
        .where((item) => !item.isUnavailable && relatedListingIds.add(item.id))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: DEColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroGallery(
            listing: listing,
            isSaved: isSaved,
            onSave: listing.isUnavailable && !isSaved
                ? () {}
                : () => _toggleSaved(context, savedRepository),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DESpacing.md,
              DESpacing.md,
              DESpacing.md,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.unavailability != null) ...[
                  _UnavailableBanner(unavailability: listing.unavailability!),
                  const SizedBox(height: DESpacing.md),
                ],
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    color: DEColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  listing.subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: DEColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FactPill(
                      icon: listing.rating == null
                          ? Icons.rate_review_outlined
                          : Icons.star_rounded,
                      label: listing.rating == null || listing.reviewCount == 0
                          ? 'No reviews yet'
                          : '${listing.rating!.toStringAsFixed(1)} '
                              '· ${listing.reviewCount} reviews',
                      iconColor: Colors.amber.shade800,
                    ),
                    _FactPill(
                      icon: Icons.sell_outlined,
                      label: listing.price,
                    ),
                    _FactPill(
                      icon: Icons.location_on_outlined,
                      label: listing.location,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${listing.category} · ${listing.destination}',
                  style: const TextStyle(
                    color: DEColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (listing.businessId != null) ...[
                  const SizedBox(height: 8),
                  _LikeAction(listing: listing),
                ],
                if ((listing.pulse ?? "").isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(DESpacing.md),
                    decoration: BoxDecoration(
                      color: DEColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(DERadius.large),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: DEColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Listing update',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                listing.pulse!,
                                style: const TextStyle(
                                  color: DEColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'About this experience',
                  body: listing.description,
                ),
                if (listing.whyYoullLoveIt.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: "Why you'll love it",
                    body: listing.whyYoullLoveIt,
                  ),
                ],
                if (listing.perfectFor.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ChipSection(title: 'Perfect for', values: listing.perfectFor),
                ],
                if (listing.features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ChipSection(
                    title: 'What makes it special',
                    values: listing.features,
                  ),
                ],
                const SizedBox(height: 12),
                _KnowBeforeYouGo(listing: listing),
                if (listing.reviews.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DETravelerTipsSection(
                    reviews: listing.reviews,
                    reviewCount: listing.reviewCount,
                  ),
                ],

                if (pairedListings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PairItWithSection(listings: pairedListings),
                ],

                if (continueDayListings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ContinueYourDaySection(
                    currentListing: listing,
                    listings: continueDayListings,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: listing.isUnavailable
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DESpacing.md),
                child: OutlinedButton.icon(
                  onPressed: isSaved
                      ? () => _toggleSaved(context, savedRepository)
                      : null,
                  icon: const Icon(Icons.favorite_border),
                  label: Text(isSaved ? 'Remove from saved' : 'Not available'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DEColors.textPrimary,
                    side: const BorderSide(color: DEColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            )
          : SafeArea(
        child: Container(
          padding: const EdgeInsets.all(DESpacing.md),
          decoration: BoxDecoration(
            color: DEColors.background,
            border: Border(
              top: BorderSide(color: DEColors.border.withValues(alpha: 0.7)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _toggleSaved(context, savedRepository),
                  icon: Icon(
                    isSaved ? Icons.favorite_rounded : Icons.favorite_border,
                    color: isSaved ? Colors.redAccent : DEColors.textPrimary,
                  ),
                  label: Text(isSaved ? 'Saved' : 'Save'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DEColors.textPrimary,
                    side: const BorderSide(color: DEColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: DESpacing.xs),
              IconButton.filledTonal(
                tooltip: 'Share experience',
                onPressed: () => _shareListing(context),
                icon: const Icon(Icons.ios_share_outlined),
              ),
              const SizedBox(width: DESpacing.sm),
              Expanded(
                flex: 3,
                child: _BottomButton(
                  label: 'Add to trip',
                  onTap: () => _openPlanSheet(context),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareListing(BuildContext context) async {
    // Resolve before any await so analytics still record if the page closes mid-share.
    final engagement = context.read<FirebaseEngagementService>();
    final shareText = [
      listing.title,
      if (listing.location.trim().isNotEmpty) listing.location,
      if (listing.description.trim().isNotEmpty) listing.description,
    ].join('\n');
    try {
      // The browser share API is not available in every desktop browser. Copy
      // directly from the button's user gesture instead of first awaiting the
      // share plugin, which can consume the browser's clipboard permission.
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (kDebugMode) {
          debugPrint('[DiscoverEase analytics] Web share fallback: copied to clipboard');
        }
        if (listing.businessId != null &&
            FirebaseAuth.instance.currentUser != null) {
          try {
            await engagement.recordShare(listing.id);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Details copied, but analytics could not be recorded.'),
                ),
              );
            }
            return;
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Experience details copied to clipboard.')),
          );
        }
        return;
      }

      final result = await SharePlus.instance.share(
        ShareParams(
          title: listing.title,
          text: shareText,
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[DiscoverEase analytics] Share sheet completed: '
          'status=${result.status}, '
          'businessListing=${listing.businessId != null}, '
          'signedIn=${FirebaseAuth.instance.currentUser != null}',
        );
      }
      if (result.status == ShareResultStatus.unavailable) {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (listing.businessId != null &&
            FirebaseAuth.instance.currentUser != null) {
          try {
            await engagement.recordShare(listing.id);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Details copied, but analytics could not be recorded.'),
                ),
              );
            }
            return;
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Experience details copied to clipboard.')),
          );
        }
        return;
      }
      if (result.status == ShareResultStatus.success &&
          listing.businessId != null &&
          FirebaseAuth.instance.currentUser != null) {
        try {
          await engagement.recordShare(listing.id);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shared, but analytics could not be recorded.'),
              ),
            );
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[DiscoverEase analytics] Share flow failed: $error');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share this experience.')),
        );
      }
    }
  }

  void _toggleSaved(BuildContext context, SavedRepository repository) {
    final saved = repository.isSaved(listing.id);
    if (saved) {
      repository.remove(listing.id);
    } else {
      repository.save(listingId: listing.id, destination: listing.destination);
    }
    showDEToast(
      context,
      title: saved ? 'Removed from saved' : 'Saved for later',
      message: listing.title,
    );
  }

  void _openPlanSheet(BuildContext context) {
    final tripRepository = context.read<TripRepository>();
    final trip = tripRepository.getCurrentTrip();
    if (trip.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a trip before adding experiences.')),
      );
      return;
    }

    showDEPlanExperienceSheet(
      context,
      experienceTitle: listing.title,
      days: trip.days.map((day) => day.title).toList(),
      dayWarning: (index) => listing.endWarning(dayDate: trip.days[index].date),
      onPlan: (dayIndex, section, {
        time,
        closingTime,
        travelMinutes,
        reservation,
        estimatedCost,
        notes,
      }) {
        tripRepository.planExperience(
          listingId: listing.id,
          dayIndex: dayIndex,
          section: section,
          time: time,
          closingTime: closingTime,
          travelMinutes: travelMinutes,
          reservation: reservation,
          estimatedCost: estimatedCost,
          notes: notes,
        );
        if (!context.mounted) return;
        showDEToast(
          context,
          title: 'Added to your trip',
          message: '${listing.title} · ${trip.days[dayIndex].title}',
        );
      },
    );
  }
}

class _LikeAction extends StatefulWidget {
  const _LikeAction({required this.listing});
  final Listing listing;

  @override
  State<_LikeAction> createState() => _LikeActionState();
}

class _LikeActionState extends State<_LikeAction> {
  late Future<bool> _liked;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _liked = context.read<FirebaseEngagementService>().isLiked(widget.listing.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _liked,
    builder: (context, snapshot) {
      final liked = snapshot.data ?? false;
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _busy ? null : () => _toggle(liked),
          icon: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(liked ? Icons.favorite : Icons.favorite_border),
          label: Text(liked ? 'Liked' : 'Like this experience'),
        ),
      );
    },
  );

  Future<void> _toggle(bool liked) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like this experience.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<FirebaseEngagementService>().setLiked(
        widget.listing.id,
        liked: !liked,
      );
      if (mounted) setState(() => _liked = Future.value(!liked));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your like. Check your connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _HeroGallery extends StatefulWidget {
  final Listing listing;
  final bool isSaved;
  final VoidCallback onSave;

  const _HeroGallery({
    required this.listing,
    required this.isSaved,
    required this.onSave,
  });

  @override
  State<_HeroGallery> createState() => _HeroGalleryState();
}

class _HeroGalleryState extends State<_HeroGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<String> get _images {
    final images = <String>[widget.listing.imageUrl, ...widget.listing.gallery];

    return images.where((image) => image.trim().isNotEmpty).toSet().toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final image = Image.network(
                images[index],
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: DEColors.border,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 42,
                        color: DEColors.textSecondary,
                      ),
                    ),
                  );
                },
              );

              return image;
            },
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.45, 1],
                    colors: [
                      Colors.black.withValues(alpha: 0.38),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 48,
            left: 16,
            child: _CircleAction(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: 48,
            right: 16,
            child: _CircleAction(
              icon: widget.isSaved
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: widget.isSaved
                  ? Colors.redAccent
                  : DEColors.textPrimary,
              onTap: widget.onSave,
            ),
          ),

          if (widget.listing.status.isNotEmpty)
            Positioned(
              left: 16,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(DERadius.pill),
                ),
                child: Text(
                  widget.listing.status,
                  style: const TextStyle(
                    color: DEColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isSelected = index == _currentPage;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isSelected ? 28 : 10,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(DERadius.pill),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _FactPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _FactPill({
    required this.icon,
    required this.label,
    this.iconColor = DEColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _KnowBeforeYouGo extends StatelessWidget {
  final Listing listing;

  const _KnowBeforeYouGo({required this.listing});

  @override
  Widget build(BuildContext context) {
    final website = parseWebLink(listing.website);
    final booking = parseWebLink(listing.bookingUrl);
    final phoneDigits = listing.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final rows = <({IconData icon, String label, String value, VoidCallback? onTap})>[
      (icon: Icons.place_outlined, label: 'Area', value: listing.location, onTap: null),
      if (listing.address.trim().isNotEmpty)
        (icon: Icons.signpost_outlined, label: 'Address', value: listing.address.trim(), onTap: null),
      (icon: Icons.category_outlined, label: 'Type', value: listing.subcategory, onTap: null),
      (icon: Icons.payments_outlined, label: 'Price', value: listing.price, onTap: null),
      if (listing.hours.trim().isNotEmpty)
        (icon: Icons.schedule_outlined, label: 'Hours', value: listing.hours.trim(), onTap: null),
      if (listing.schedule.trim().isNotEmpty)
        (icon: Icons.event_outlined, label: 'Schedule', value: listing.schedule.trim(), onTap: null),
      if (listing.phone.trim().isNotEmpty)
        (
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: listing.phone.trim(),
          onTap: phoneDigits.isEmpty
              ? null
              : () => _openLink(context, Uri(scheme: 'tel', path: phoneDigits)),
        ),
      if (website != null)
        (
          icon: Icons.language_outlined,
          label: 'Website',
          value: listing.website.trim(),
          onTap: () => _openLink(context, website),
        ),
      if (booking != null)
        (
          icon: Icons.confirmation_number_outlined,
          label: 'Booking',
          value: listing.bookingUrl.trim(),
          onTap: () => _openLink(context, booking),
        ),
      if (listing.endsAt != null)
        (
          icon: Icons.event_busy_outlined,
          label: 'Ends',
          value: Listing.shortDate(listing.endsAt!),
          onTap: null,
        ),
      if (listing.endsAt == null && listing.status.trim().isNotEmpty)
        (icon: Icons.info_outline_rounded, label: 'Status', value: listing.status, onTap: null),
    ];
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Know before you go',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++)
            _InfoRow(
              icon: rows[i].icon,
              label: rows[i].label,
              value: rows[i].value,
              onTap: rows[i].onTap,
              isLast: i == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

Future<void> _openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open that link on this device.')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DEColors.primary),
          const SizedBox(width: 9),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: DEColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? null : DEColors.primary,
                  decoration: onTap == null ? null : TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _SectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: DEColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final List<String> values;

  const _ChipSection({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: DEColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DERadius.pill),
                  border: Border.all(
                    color: DEColors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: DEColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: child,
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.iconColor = DEColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _PairItWithSection extends StatelessWidget {
  final List<Listing> listings;

  const _PairItWithSection({required this.listings});

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "✨ Pair It With",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            "Build a better day around this experience.",
            style: TextStyle(color: DEColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...listings.map(
            (paired) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(DERadius.large),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailPage(listing: paired),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DEColors.background,
                    borderRadius: BorderRadius.circular(DERadius.large),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DERadius.large),
                        child: Image.network(
                          paired.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paired.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              paired.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DEColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "📍 ${paired.location}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: DEColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueYourDaySection extends StatelessWidget {
  final Listing currentListing;
  final List<Listing> listings;

  const _ContinueYourDaySection({
    required this.currentListing,
    required this.listings,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🧭 Continue Your Day",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            "A few great ideas to keep exploring "
            "${currentListing.destination}.",
            style: const TextStyle(color: DEColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),

          ...List.generate(listings.length, (index) {
            final suggestion = listings[index];

            return Column(
              children: [
                _ContinueDayItem(
                  listing: suggestion,
                  purposeLabel: _purposeFor(suggestion),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailPage(listing: suggestion),
                      ),
                    );
                  },
                ),

                if (index != listings.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: DEColors.border),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _purposeFor(Listing listing) {
    final category = listing.category.toLowerCase();
    final subcategory = listing.subcategory.toLowerCase();
    final features = listing.features
        .map((feature) => feature.toLowerCase())
        .toList();

    if (listing.perfectFor.contains("Sunset") ||
        category.contains("sunset") ||
        subcategory.contains("viewpoint")) {
      return "🌅 Catch Sunset";
    }

    if (category.contains("dining") ||
        subcategory.contains("restaurant") ||
        subcategory.contains("food")) {
      return "🍝 Grab a Meal";
    }

    if (category.contains("bar") ||
        subcategory.contains("bar") ||
        features.contains("wine")) {
      return "🍷 Unwind";
    }

    if (category.contains("live music") || features.contains("live music")) {
      return "🎵 Find the Atmosphere";
    }

    if (category.contains("coffee") ||
        subcategory.contains("café") ||
        subcategory.contains("cafe")) {
      return "☕ Take a Break";
    }

    if (category.contains("nightlife")) {
      return "🌙 Keep the Night Going";
    }

    if (category.contains("tour")) {
      return "🧭 Keep Exploring";
    }

    return "✨ Discover Next";
  }
}

class _ContinueDayItem extends StatelessWidget {
  final Listing listing;
  final String purposeLabel;
  final VoidCallback onTap;

  const _ContinueDayItem({
    required this.listing,
    required this.purposeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DERadius.large),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DERadius.large),
              child: Image.network(
                listing.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const SizedBox(
                    width: 76,
                    height: 76,
                    child: ColoredBox(
                      color: DEColors.border,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: DEColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purposeLabel,
                    style: const TextStyle(
                      color: DEColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DEColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (listing.rating != null) const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      if (listing.rating != null) const SizedBox(width: 3),
                      Text(
                        listing.rating?.toStringAsFixed(1) ?? 'New',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          "📍 ${listing.location}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DEColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: DEColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _BottomButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? DEColors.primary : Colors.white,
        foregroundColor: isPrimary ? Colors.white : DEColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DERadius.pill),
        ),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner({required this.unavailability});

  final ListingUnavailability unavailability;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DERadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unavailability.label,
            style: const TextStyle(
              color: DEColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unavailability.explanation,
            style: const TextStyle(color: DEColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
