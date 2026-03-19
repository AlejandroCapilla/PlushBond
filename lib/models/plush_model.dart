import 'package:cloud_firestore/cloud_firestore.dart';

class PlushModel {
  final String plushId;
  final String ownerA;
  final String? ownerB;
  final String imageOriginalUrl;
  final String? image2DUrl;
  final String name;
  final int level;
  final double hunger; // 0-100
  final double happiness; // 0-100
  final double energy; // 0-100
  final DateTime createdAt;
  final DateTime? lastInteractionA;
  final DateTime? lastInteractionB;
  final String inviteCode;
  final bool isPremium;
  final List<String> customizations;

  PlushModel({
    required this.plushId,
    required this.ownerA,
    this.ownerB,
    required this.imageOriginalUrl,
    this.image2DUrl,
    required this.name,
    this.level = 1,
    this.hunger = 100.0,
    this.happiness = 100.0,
    this.energy = 100.0,
    required this.createdAt,
    this.lastInteractionA,
    this.lastInteractionB,
    required this.inviteCode,
    this.isPremium = false,
    this.customizations = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'plushId': plushId,
      'ownerA': ownerA,
      'ownerB': ownerB,
      'imageOriginalUrl': imageOriginalUrl,
      'image2DUrl': image2DUrl,
      'name': name,
      'level': level,
      'hunger': hunger,
      'happiness': happiness,
      'energy': energy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastInteractionA': lastInteractionA != null ? Timestamp.fromDate(lastInteractionA!) : null,
      'lastInteractionB': lastInteractionB != null ? Timestamp.fromDate(lastInteractionB!) : null,
      'inviteCode': inviteCode,
      'isPremium': isPremium,
      'customizations': customizations,
    };
  }

  factory PlushModel.fromMap(Map<String, dynamic> map, String id) {
    return PlushModel(
      plushId: id,
      ownerA: map['ownerA'] ?? '',
      ownerB: map['ownerB'],
      imageOriginalUrl: map['imageOriginalUrl'] ?? '',
      image2DUrl: map['image2DUrl'],
      name: map['name'] ?? '',
      level: map['level'] ?? 1,
      hunger: (map['hunger'] ?? 100.0).toDouble(),
      happiness: (map['happiness'] ?? 100.0).toDouble(),
      energy: (map['energy'] ?? 100.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastInteractionA: (map['lastInteractionA'] as Timestamp?)?.toDate(),
      lastInteractionB: (map['lastInteractionB'] as Timestamp?)?.toDate(),
      inviteCode: map['inviteCode'] ?? '',
      isPremium: map['isPremium'] ?? false,
      customizations: List<String>.from(map['customizations'] ?? []),
    );
  }

  PlushModel copyWith({
    String? ownerB,
    String? image2DUrl,
    String? name,
    double? hunger,
    double? happiness,
    double? energy,
    int? level,
    DateTime? lastInteractionA,
    DateTime? lastInteractionB,
    bool? isPremium,
    List<String>? customizations,
  }) {
    return PlushModel(
      plushId: this.plushId,
      ownerA: this.ownerA,
      ownerB: ownerB ?? this.ownerB,
      imageOriginalUrl: this.imageOriginalUrl,
      image2DUrl: image2DUrl ?? this.image2DUrl,
      name: name ?? this.name,
      level: level ?? this.level,
      hunger: hunger ?? this.hunger,
      happiness: happiness ?? this.happiness,
      energy: energy ?? this.energy,
      createdAt: this.createdAt,
      lastInteractionA: lastInteractionA ?? this.lastInteractionA,
      lastInteractionB: lastInteractionB ?? this.lastInteractionB,
      inviteCode: this.inviteCode,
      isPremium: isPremium ?? this.isPremium,
      customizations: customizations ?? this.customizations,
    );
  }
}
