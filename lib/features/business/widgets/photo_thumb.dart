import 'package:flutter/material.dart';

import '../../../services/experience_photo_service.dart';

/// A small square preview of an experience's cover photo. [entry] is either a
/// public web address or a private upload path (resolved for the owner).
/// Shows a plain icon when there is no photo or it cannot be loaded.
class PhotoThumb extends StatefulWidget {
  const PhotoThumb({
    super.key,
    required this.entry,
    required this.service,
    this.size = 56,
  });

  final String entry;
  final ExperiencePhotoService service;
  final double size;

  @override
  State<PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<PhotoThumb> {
  Future<String>? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PhotoThumb old) {
    super.didUpdateWidget(old);
    if (old.entry != widget.entry) _load();
  }

  void _load() {
    _url = widget.entry.isEmpty ? null : widget.service.urlFor(widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.local_activity_outlined)),
    );
    return SizedBox.square(
      dimension: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _url == null
            ? placeholder
            : FutureBuilder<String>(
                future: _url,
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) return placeholder;
                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    // Decoded at thumbnail size, not full resolution.
                    cacheWidth: (widget.size * 2).round(),
                    errorBuilder: (_, _, _) => placeholder,
                  );
                },
              ),
      ),
    );
  }
}
