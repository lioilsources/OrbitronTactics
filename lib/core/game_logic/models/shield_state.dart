class ShieldState {
  final bool isActive;
  final int cooldownRemainingMs;
  final int activeRemainingMs;

  const ShieldState({
    this.isActive = false,
    this.cooldownRemainingMs = 0,
    this.activeRemainingMs = 0,
  });

  bool get isOnCooldown => cooldownRemainingMs > 0;
  bool get canActivate => !isActive && !isOnCooldown;

  ShieldState copyWith({
    bool? isActive,
    int? cooldownRemainingMs,
    int? activeRemainingMs,
  }) {
    return ShieldState(
      isActive: isActive ?? this.isActive,
      cooldownRemainingMs: cooldownRemainingMs ?? this.cooldownRemainingMs,
      activeRemainingMs: activeRemainingMs ?? this.activeRemainingMs,
    );
  }
}
