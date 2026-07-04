import 'package:flutter/material.dart';
import '../../../shared/components/bottom_sheets/de_save_bottom_sheet.dart';
import '../../../models/listing.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class ListingDetailPage extends StatelessWidget {
  final Listing listing;

  const ListingDetailPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DEColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroImage(listing: listing),
          Padding(
            padding: const EdgeInsets.all(DESpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.category,
                  style: const TextStyle(
                    color: DEColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: DEColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: DEColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text("⭐ ${listing.rating}"),
                    const SizedBox(width: 14),
                    Text(listing.price),
                    const SizedBox(width: 14),
                    Text("📍 ${listing.location}"),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionCard(
                  title: "❤️ Why You'll Love It",
                  body:
                      "A memorable experience with beautiful atmosphere, great service, and a strong sense of place.",
                ),
                const SizedBox(height: 16),
                const _PlanYourVisit(),
                const SizedBox(height: 16),
                const _SectionCard(
                  title: "The Experience",
                  body:
                      "Discover what makes this place special, from the setting and atmosphere to the details that make visitors want to come back.",
                ),
                const SizedBox(height: 16),
                const _SectionCard(
                  title: "Know Before You Go",
                  body:
                      "Reservations may be recommended. Check hours before visiting. Bring payment, ID if required, and confirm availability during busy periods.",
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DESpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _BottomButton(
                  label: "📌 Save",
                  onTap: () => showDESaveBottomSheet(context),
                ),
              ),
              const SizedBox(width: DESpacing.sm),
              Expanded(
                child: _BottomButton(
                  label: "✈️ Add to Trip",
                  onTap: () {},
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final Listing listing;

  const _HeroImage({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.network(
          listing.imageUrl,
          height: 360,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          height: 360,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 16,
          child: _CircleAction(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 48,
          right: 70,
          child: _CircleAction(icon: Icons.push_pin_outlined, onTap: () {}),
        ),
        Positioned(
          top: 48,
          right: 16,
          child: _CircleAction(icon: Icons.ios_share_rounded, onTap: () {}),
        ),
        Positioned(
          left: 16,
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(DERadius.pill),
            ),
            child: Text(
              listing.status,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: DEColors.success,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanYourVisit extends StatelessWidget {
  const _PlanYourVisit();

  @override
  Widget build(BuildContext context) {
    final actions = [
      ("Directions", Icons.directions_rounded),
      ("Call", Icons.phone_rounded),
      ("Website", Icons.language_rounded),
      ("Menu", Icons.restaurant_menu_rounded),
    ];

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Plan Your Visit",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions.map((action) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DEColors.background,
                  borderRadius: BorderRadius.circular(DERadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.$2, size: 18, color: DEColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      action.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }).toList(),
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

  const _CircleAction({required this.icon, required this.onTap});

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
          child: Icon(icon, color: DEColors.textPrimary),
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
