import 'profanity_filter.dart';

class DisplayNameValidation {
  final bool ok;
  final String? error;
  const DisplayNameValidation.ok() : ok = true, error = null;
  const DisplayNameValidation.err(this.error) : ok = false;
}

const displayNameMinLength = 3;
const displayNameMaxLength = 20;

final _allowed = RegExp(r'^[A-Za-z0-9 _-]+$');

/// Validate a display name. Does NOT check rate limits or uniqueness —
/// only format + profanity. Rate limiting lives in [ProfileNotifier].
DisplayNameValidation validateDisplayName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) {
    return const DisplayNameValidation.err('Please enter a display name.');
  }
  if (name.length < displayNameMinLength) {
    return DisplayNameValidation.err(
      'Must be at least $displayNameMinLength characters.',
    );
  }
  if (name.length > displayNameMaxLength) {
    return DisplayNameValidation.err(
      'Must be at most $displayNameMaxLength characters.',
    );
  }
  if (!_allowed.hasMatch(name)) {
    return const DisplayNameValidation.err(
      'Only letters, numbers, spaces, _ and - allowed.',
    );
  }
  if (name.contains('  ')) {
    return const DisplayNameValidation.err(
      'Cannot contain consecutive spaces.',
    );
  }
  if (containsProfanity(name)) {
    return const DisplayNameValidation.err(
      'Please choose a different name.',
    );
  }
  return const DisplayNameValidation.ok();
}
