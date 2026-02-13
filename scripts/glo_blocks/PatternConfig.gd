extends Resource
class_name PatternConfig

@export var tier_distribution: Dictionary = {
	1: 0.56,
	2: 0.3,
	3: 0.14,
}
@export var symmetrical: bool = true

func sample_tier(rng: RandomNumberGenerator, supported_tiers: PackedInt32Array) -> int:
	var available: Array[int] = []
	for tier in supported_tiers:
		available.append(int(tier))
	if available.is_empty():
		available = [1]
	var total: float = 0.0
	for tier in available:
		total += max(0.0, float(tier_distribution.get(tier, 0.0)))
	if total <= 0.0:
		return available[rng.randi_range(0, available.size() - 1)]
	var roll: float = rng.randf() * total
	var acc: float = 0.0
	for tier in available:
		acc += max(0.0, float(tier_distribution.get(tier, 0.0)))
		if roll <= acc:
			return tier
	return available.back()
