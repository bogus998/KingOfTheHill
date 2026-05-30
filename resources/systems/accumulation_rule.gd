class_name AccumulationRule
extends Resource
## One data-driven mapping from a named event to the amount it contributes.
##
## A consumer reports named events; each matching rule's `amount` is added to the
## meter (multiplied by the reported count). Pure data — no logic, no game terms.

@export var event_id: StringName = &""
@export var amount: int = 0
