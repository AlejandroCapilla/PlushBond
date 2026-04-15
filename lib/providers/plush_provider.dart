import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import '../models/plush_model.dart';
import '../services/firestore_service.dart';
import '../services/action_notification_service.dart';
import 'auth_provider.dart';

final plushProvider = StateNotifierProvider<PlushNotifier, PlushModel?>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final user = ref.watch(userModelProvider).value;
  final actionNotification = ref.watch(actionNotificationServiceProvider);
  return PlushNotifier(firestore, actionNotification, user?.uid);
});

class PlushNotifier extends StateNotifier<PlushModel?> {
  final FirestoreService _firestore;
  final ActionNotificationService _actionNotification;
  final String? _uid;
  StreamSubscription? _subscription;
  Timer? _decayTimer;

  PlushNotifier(this._firestore, this._actionNotification, this._uid) : super(null) {
    if (_uid != null) {
      _listenToUserPlush();
    }
  }

  void _listenToUserPlush() {
    _subscription?.cancel();
    _subscription = _firestore.streamPlushForUser(_uid!).listen((plush) {
      if (plush != null) {
        bool needsUpdate = false;
        PlushModel processedPlush = plush;

        // Calculate decay if it's the first time or if significant time has passed
        if (state == null) {
          processedPlush = _calculateDecay(plush);
          if (processedPlush != plush) {
            needsUpdate = true;
          }
          _startDecayTimer();
        }

        state = processedPlush;

        if (needsUpdate) {
          _syncToFirestore(processedPlush);
        }
      } else {
        state = null;
        _decayTimer?.cancel();
      }
    });
  }
  
  PlushModel _calculateDecay(PlushModel plush) {
    final now = DateTime.now();
    final elapsed = now.difference(plush.lastUpdate);
    final hoursPassed = elapsed.inSeconds / 3600.0;

    if (hoursPassed < 0.01) return plush; // Avoid unnecessary updates for very small intervals

    // Decay rates per hour
    const hungerRate = 4.0;
    const energyRate = 3.5;
    const happinessRate = 3.0;

    final newHunger = (plush.hunger - (hungerRate * hoursPassed)).clamp(0.0, 100.0);
    final newEnergy = (plush.energy - (energyRate * hoursPassed)).clamp(0.0, 100.0);
    final newHappiness = (plush.happiness - (happinessRate * hoursPassed)).clamp(0.0, 100.0);

    return plush.copyWith(
      hunger: newHunger,
      energy: newEnergy,
      happiness: newHappiness,
      lastUpdate: now,
    );
  }

  Future<void> _syncToFirestore(PlushModel plush) async {
    await _firestore.updatePlush(plush);
  }


  void _startDecayTimer() {
    _decayTimer?.cancel();
    // Check for decay every 5 minutes while the app is open
    _decayTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state != null) {
        final decayed = _calculateDecay(state!);
        if (decayed != state) {
          state = decayed;
          // Sync to firestore every hour or so, or just rely on manual interactions
          // For now, let's sync local state, and it will sync to firestore on interaction
          // or next time the app opens.
        }
      }
    });
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _applyInteraction(
      {double? hungerAdd, double? happinessAdd, double? energyAdd, int xpAdd = 0}) async {
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
      xp: state!.xp + xpAdd,
      lastUpdate: now,
      lastInteractionA: isOwnerA ? now : state!.lastInteractionA,
      lastInteractionB: !isOwnerA ? now : state!.lastInteractionB,
    );

    state = newState;
    await _firestore.updatePlush(newState);
  }

  Future<void> feed() async {
    await _applyInteraction(hungerAdd: 20, energyAdd: 10, xpAdd: 15);
  }

  Future<void> play() async {
    await _applyInteraction(happinessAdd: 20, energyAdd: -10, xpAdd: 15);
  }

  Future<void> cuddle() async {
    await _applyInteraction(happinessAdd: 10, energyAdd: 10, xpAdd: 15);
  }

  Future<void> sendNote(String text) async {
    if (state == null || _uid == null) return;
    final now = DateTime.now();
    final note = PlushNote(
      text: text,
      timestamp: now,
      readByPartner: false,
    );
    await _firestore.updateNote(state!.plushId, _uid!, note);
    
    final caller = state!.ownerA == _uid ? 'A' : 'B';
    await _actionNotification.sendSecretNoteNotification(
      plushUid: state!.plushId,
      caller: caller,
    );
  }

  Future<void> squeeze() async {
    if (state == null || _uid == null) return;
    final caller = state!.ownerA == _uid ? 'A' : 'B';
    await _actionNotification.sendSqueezeNotification(
      plushUid: state!.plushId,
      caller: caller,
    );
  }

  Future<void> readNote(String partnerUid) async {
    if (state == null) return;
    await _firestore.markNoteAsRead(state!.plushId, partnerUid);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _decayTimer?.cancel();
    super.dispose();
  }
}
