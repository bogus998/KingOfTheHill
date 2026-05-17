class_name SmokeBombEffect
extends CardEffect
## Charge-based card. Charges are tracked by CardEffectHandler, which seeds the
## count on purchase and decrements them via use_smoke_bomb_charge().

@export var charges: int = 3

func _init(p_charges: int = 3) -> void:
	charges = p_charges
