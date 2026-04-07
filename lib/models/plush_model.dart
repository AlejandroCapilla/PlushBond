import 'package:cloud_firestore/cloud_firestore.dart';

class PlushNote {
  final String text;
  final DateTime timestamp;
  final bool readByPartner;

  PlushNote({
    required this.text,
    required this.timestamp,
    required this.readByPartner,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'readByPartner': readByPartner,
    };
  }

  factory PlushNote.fromMap(Map<String, dynamic> map) {
    return PlushNote(
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      readByPartner: map['readByPartner'] ?? false,
    );
  }

  PlushNote copyWith({
    String? text,
    DateTime? timestamp,
    bool? readByPartner,
  }) {
    return PlushNote(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      readByPartner: readByPartner ?? this.readByPartner,
    );
  }
}

class PlushModel {
  final String plushId;
  final String ownerA;
  final String? ownerB;
  final String? nameA;
  final String? nameB;
  final String? fcmTokenA;
  final String? fcmTokenB;
  final String imageOriginalUrl;
  final String? image2DUrl;
  final String name;
  final int level;
  final double hunger; // 0-100
  final double happiness; // 0-100
  final double energy; // 0-100
  final DateTime createdAt;
  final DateTime lastUpdate;
  final DateTime? lastInteractionA;
  final DateTime? lastInteractionB;
  final String inviteCode;
  final bool isPremium;
  final List<String> customizations;
  final Map<String, PlushNote> notes;

  PlushModel({
    required this.plushId,
    required this.ownerA,
    this.ownerB,
    this.nameA,
    this.nameB,
    this.fcmTokenA,
    this.fcmTokenB,
    required this.imageOriginalUrl,
    this.image2DUrl,
    required this.name,
    this.level = 1,
    this.hunger = 100.0,
    this.happiness = 100.0,
    this.energy = 100.0,
    required this.createdAt,
    required this.lastUpdate,
    this.lastInteractionA,
    this.lastInteractionB,
    required this.inviteCode,
    this.isPremium = false,
    this.customizations = const [],
    this.notes = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'plushId': plushId,
      'ownerA': ownerA,
      'ownerB': ownerB,
      'nameA': nameA,
      'nameB': nameB,
      'fcmTokenA': fcmTokenA,
      'fcmTokenB': fcmTokenB,
      'imageOriginalUrl': imageOriginalUrl,
      'image2DUrl': image2DUrl,
      'name': name,
      'level': level,
      'hunger': hunger,
      'happiness': happiness,
      'energy': energy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdate': Timestamp.fromDate(lastUpdate),
      'lastInteractionA': lastInteractionA != null ? Timestamp.fromDate(lastInteractionA!) : null,
      'lastInteractionB': lastInteractionB != null ? Timestamp.fromDate(lastInteractionB!) : null,
      'inviteCode': inviteCode,
      'isPremium': isPremium,
      'customizations': customizations,
      'notes': notes.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory PlushModel.fromMap(Map<String, dynamic> map, String id) {
    final notesMap = (map['notes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, PlushNote.fromMap(value as Map<String, dynamic>)),
        ) ??
        {};

    return PlushModel(
      plushId: id,
      ownerA: map['ownerA'] ?? '',
      ownerB: map['ownerB'],
      nameA: map['nameA'],
      nameB: map['nameB'],
      fcmTokenA: map['fcmTokenA'],
      fcmTokenB: map['fcmTokenB'],
      imageOriginalUrl: map['imageOriginalUrl'] ?? '',
      image2DUrl: map['image2DUrl'],
      name: map['name'] ?? '',
      level: map['level'] ?? 1,
      hunger: (map['hunger'] ?? 100.0).toDouble(),
      happiness: (map['happiness'] ?? 100.0).toDouble(),
      energy: (map['energy'] ?? 100.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdate: (map['lastUpdate'] as Timestamp? ?? map['createdAt'] as Timestamp).toDate(),
      lastInteractionA: (map['lastInteractionA'] as Timestamp?)?.toDate(),
      lastInteractionB: (map['lastInteractionB'] as Timestamp?)?.toDate(),
      inviteCode: map['inviteCode'] ?? '',
      isPremium: map['isPremium'] ?? false,
      customizations: List<String>.from(map['customizations'] ?? []),
      notes: notesMap,
    );
  }

  PlushModel copyWith({
    String? ownerB,
    String? nameA,
    String? nameB,
    String? fcmTokenA,
    String? fcmTokenB,
    String? image2DUrl,
    String? name,
    double? hunger,
    double? happiness,
    double? energy,
    int? level,
    DateTime? lastUpdate,
    DateTime? lastInteractionA,
    DateTime? lastInteractionB,
    bool? isPremium,
    List<String>? customizations,
    Map<String, PlushNote>? notes,
  }) {
    return PlushModel(
      plushId: this.plushId,
      ownerA: this.ownerA,
      ownerB: ownerB ?? this.ownerB,
      nameA: nameA ?? this.nameA,
      nameB: nameB ?? this.nameB,
      fcmTokenA: fcmTokenA ?? this.fcmTokenA,
      fcmTokenB: fcmTokenB ?? this.fcmTokenB,
      imageOriginalUrl: this.imageOriginalUrl,
      image2DUrl: image2DUrl ?? this.image2DUrl,
      name: name ?? this.name,
      level: level ?? this.level,
      hunger: hunger ?? this.hunger,
      happiness: happiness ?? this.happiness,
      energy: energy ?? this.energy,
      createdAt: this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastInteractionA: lastInteractionA ?? this.lastInteractionA,
      lastInteractionB: lastInteractionB ?? this.lastInteractionB,
      inviteCode: this.inviteCode,
      isPremium: isPremium ?? this.isPremium,
      customizations: customizations ?? this.customizations,
      notes: notes ?? this.notes,
    );
  }
}
