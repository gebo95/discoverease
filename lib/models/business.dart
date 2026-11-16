class Business {
  final String id;
  final String name;
  final String logoUrl;
  final String email;
  final String phone;
  final String website;
  final String instagram;
  final String subscriptionTier;
  final bool verified;

  const Business({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.email,
    required this.phone,
    required this.website,
    required this.instagram,
    required this.subscriptionTier,
    this.verified = false,
  });
}
