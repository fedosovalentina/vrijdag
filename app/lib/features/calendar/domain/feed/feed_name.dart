enum FeedNameFit { fits, truncated, firstWordOnly }

class FeedNameResult {
  const FeedNameResult({required this.text, required this.fit});

  final String text;
  final FeedNameFit fit;
}

/// Word-boundary ellipsis (spec §9.2). [measure] returns the rendered width.
FeedNameResult fitFeedName(
  String name,
  double maxWidth,
  double Function(String text) measure,
) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || measure(trimmed) <= maxWidth) {
    return FeedNameResult(text: trimmed, fit: FeedNameFit.fits);
  }

  final words = trimmed.split(RegExp(r'\s+'));
  final first = words.first;
  if (measure(first) > maxWidth) {
    return FeedNameResult(text: first, fit: FeedNameFit.firstWordOnly);
  }

  final buffer = StringBuffer(first);
  for (var i = 1; i < words.length; i++) {
    final candidate = '${buffer.toString()} ${words[i]}…';
    if (measure(candidate) > maxWidth) {
      final withEllipsis = '${buffer.toString()}…';
      if (measure(withEllipsis) <= maxWidth) {
        return FeedNameResult(text: withEllipsis, fit: FeedNameFit.truncated);
      }
      return FeedNameResult(text: first, fit: FeedNameFit.firstWordOnly);
    }
    buffer.write(' ${words[i]}');
  }
  return FeedNameResult(text: buffer.toString(), fit: FeedNameFit.fits);
}
