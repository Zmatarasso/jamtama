/// Very simple client-side profanity filter.
///
/// First-line defense only — trivially bypassable (unicode lookalikes,
/// other languages, creative spacing). Server-side validation is the
/// proper long-term solution; this just stops the casual offender.
library;

// Curated English list, kept intentionally short. Additions should be
// lowercase, normalized (no punctuation), and represent whole-word matches
// after normalization.
const _blocked = <String>{
  'fuck', 'shit', 'bitch', 'cunt', 'asshole', 'dick', 'pussy',
  'nigger', 'nigga', 'faggot', 'fag', 'retard', 'whore', 'slut',
  'cock', 'twat', 'wanker', 'bastard', 'douche', 'jizz',
};

// Common leet-speak substitutions, applied during normalization so
// "f u c k", "fvck", "fuk", "sh1t" etc. still get caught.
const _leetMap = {
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '4': 'a',
  '5': 's',
  '7': 't',
  '@': 'a',
  '\$': 's',
  '!': 'i',
  '|': 'i',
};

/// Normalize a name for profanity comparison:
/// - lowercase
/// - apply leet-speak substitutions
/// - strip all non-alphabetic chars (spaces, punctuation, digits)
/// - collapse runs of the same letter (fuuuck → fuck)
String _normalize(String s) {
  final buf = StringBuffer();
  String? prev;
  for (final ch in s.toLowerCase().split('')) {
    final mapped = _leetMap[ch] ?? ch;
    if (mapped.codeUnits.first < 0x61 || mapped.codeUnits.first > 0x7a) {
      continue;
    }
    if (mapped == prev) continue;
    buf.write(mapped);
    prev = mapped;
  }
  return buf.toString();
}

bool containsProfanity(String input) {
  if (input.isEmpty) return false;
  final normalized = _normalize(input);
  if (normalized.isEmpty) return false;
  for (final word in _blocked) {
    final collapsed = _normalize(word);
    if (normalized.contains(collapsed)) return true;
  }
  return false;
}
