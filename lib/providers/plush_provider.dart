import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import '../models/plush_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final plushProvider = StateNotifierProvider<PlushNotifier, PlushModel?>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final user = ref.watch(userModelProvider).value;
  return PlushNotifier(firestore, user?.uid);
});

class PlushNotifier extends StateNotifier<PlushModel?> {
  final FirestoreService _firestore;
  final String? _uid;
  StreamSubscription? _subscription;
  Timer? _decayTimer;

  PlushNotifier(this._firestore, this._uid) : super(null) {
    if (_uid != null) {
      _listenToUserPlush();
    }
  }

  void _listenToUserPlush() {
    _subscription?.cancel();
    _subscription = _firestore.streamPlushForUser(_uid!).listen((plush) {
      if (plush != null) {
        if (state == null) {
          // First time we get a plush, start the decay timer
          _startDecayTimer();
        }
        state = plush;
      } else {
        state = null;
        _decayTimer?.cancel();
      }
    });
  }


  void _startDecayTimer() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state != null) {
        // Simple decay logic: hunger and energy decrease over time
        final newHunger = (state!.hunger - 0.5).clamp(0.0, 100.0);
        final newEnergy = (state!.energy - 0.3).clamp(0.0, 100.0);
        final newHappiness = (state!.happiness - 0.2).clamp(0.0, 100.0);
        
        state = state!.copyWith(
          hunger: newHunger,
          energy: newEnergy,
          happiness: newHappiness,
        );
        
        // Optionally sync to Firestore occasionally or on important changes
      }
    });
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _applyInteraction(
      {double? hungerAdd, double? happinessAdd, double? energyAdd}) async {
    if (state == null || _uid == null) return;

    final now = DateTime.now();
    final isOwnerA = state!.ownerA == _uid;
    final myLastInteraction = isOwnerA ? state!.lastInteractionA : state!.lastInteractionB;
    final partnerLastInteraction = isOwnerA ? state!.lastInteractionB : state!.lastInteractionA;

    double bonus = 0;
    // Apply bonus if partner interacted today and I haven't interacted yet today
    if (!_isSameDay(myLastInteraction, now) && _isSameDay(partnerLastInteraction, now)) {
      bonus = 10.0;
    }

    final newState = state!.copyWith(
      hunger: (state!.hunger + (hungerAdd ?? 0)).clamp(0.0, 100.0),
      happiness: (state!.happiness + (happinessAdd ?? 0) + bonus).clamp(0.0, 100.0),
      energy: (state!.energy + (energyAdd ?? 0)).clamp(0.0, 100.0),
      lastInteractionA: isOwnerA ? now : state!.lastInteractionA,
      lastInteractionB: !isOwnerA ? now : state!.lastInteractionB,
    );

    state = newState;
    await _firestore.updatePlush(newState);
  }

  Future<void> feed() async {
    await _applyInteraction(hungerAdd: 20);
  }

  Future<void> play() async {
    await _applyInteraction(happinessAdd: 15, energyAdd: -10);
  }

  Future<void> cuddle() async {
    await _applyInteraction(happinessAdd: 10);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _decayTimer?.cancel();
    super.dispose();
  }
}
