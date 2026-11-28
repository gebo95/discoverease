/// A business an admin added that its owner can claim. Only the name and a
/// masked hint of the contact are public; the real contact stays private.
class ClaimableBusiness {
  const ClaimableBusiness({
    required this.id,
    required this.name,
    this.category = '',
    this.destinationId = '',
    this.emailHint = '',
    this.phoneHint = '',
  });

  final String id;
  final String name;
  final String category;
  final String destinationId;

  /// For example "ow***@cafe.com".
  final String emailHint;

  /// For example "***67".
  final String phoneHint;

  /// Null when the record has no name, so a broken record is skipped.
  static ClaimableBusiness? fromJson(String id, Map<String, Object?> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    return ClaimableBusiness(
      id: id,
      name: name,
      category: json['category'] as String? ?? '',
      destinationId: json['destinationId'] as String? ?? '',
      emailHint: json['emailHint'] as String? ?? '',
      phoneHint: json['phoneHint'] as String? ?? '',
    );
  }

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        category.toLowerCase().contains(needle);
  }
}

/// An owner who could not get the code and asked an admin to review.
class ClaimRequest {
  const ClaimRequest({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.accountEmail,
    required this.contact,
    required this.note,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String accountEmail;
  final String contact;
  final String note;
  final DateTime? createdAt;

  static ClaimRequest? fromJson(String id, Map<String, Object?> json) {
    final businessId = json['businessId'] as String? ?? '';
    if (id.isEmpty || businessId.isEmpty) return null;
    DateTime? created;
    try {
      final value = (json['createdAt'] as dynamic)?.toDate();
      if (value is DateTime) created = value;
    } catch (_) {}
    return ClaimRequest(
      id: id,
      businessId: businessId,
      businessName: json['businessName'] as String? ?? '',
      accountEmail: json['accountEmail'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: created,
    );
  }
}

/// A business that was claimed, shown to admins so ownership can be taken back.
class ClaimedBusiness {
  const ClaimedBusiness({
    required this.id,
    required this.name,
    required this.email,
    required this.ownerUid,
  });

  final String id;
  final String name;
  final String email;
  final String ownerUid;

  static ClaimedBusiness? fromJson(String id, Map<String, Object?> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    if (id.isEmpty || json['claimStatus'] != 'claimed') return null;
    return ClaimedBusiness(
      id: id,
      name: name.isEmpty ? 'Unnamed business' : name,
      email: json['email'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
    );
  }
}
