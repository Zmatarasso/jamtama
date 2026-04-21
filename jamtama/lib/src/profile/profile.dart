/// Public profile data for a user.
///
/// Lives in its own Firestore collection (`profiles/{uid}`) separate from
/// private game data so other players can read it for multiplayer UI
/// (opponent avatar/name, leaderboards) without exposing game state.
class Profile {
  final String uid;
  final String? displayName;
  final String? avatarCosmeticId;
  final DateTime? lastDisplayNameChangeAt;
  final DateTime? createdAt;

  const Profile({
    required this.uid,
    this.displayName,
    this.avatarCosmeticId,
    this.lastDisplayNameChangeAt,
    this.createdAt,
  });

  static const empty = Profile(uid: '');

  Profile copyWith({
    String? uid,
    String? displayName,
    String? avatarCosmeticId,
    DateTime? lastDisplayNameChangeAt,
    DateTime? createdAt,
  }) =>
      Profile(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        avatarCosmeticId: avatarCosmeticId ?? this.avatarCosmeticId,
        lastDisplayNameChangeAt:
            lastDisplayNameChangeAt ?? this.lastDisplayNameChangeAt,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        if (displayName != null) 'displayName': displayName,
        if (avatarCosmeticId != null) 'avatarCosmeticId': avatarCosmeticId,
        if (lastDisplayNameChangeAt != null)
          'lastDisplayNameChangeAt':
              lastDisplayNameChangeAt!.millisecondsSinceEpoch,
        if (createdAt != null)
          'createdAt': createdAt!.millisecondsSinceEpoch,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        uid: (j['uid'] as String?) ?? '',
        displayName: j['displayName'] as String?,
        avatarCosmeticId: j['avatarCosmeticId'] as String?,
        lastDisplayNameChangeAt: _asDate(j['lastDisplayNameChangeAt']),
        createdAt: _asDate(j['createdAt']),
      );
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is DateTime) return v;
  return null;
}
