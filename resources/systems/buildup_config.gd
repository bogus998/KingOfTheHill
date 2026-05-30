class_name BuildupConfig
extends Resource
## Authorable bundle of accumulation rules for one buildup tracker.
##
## Saved as a `.tres` so designers can tune which events feed a meter and by how
## much without touching code. Consumed by `BuildupTracker`.

@export var rules: Array[AccumulationRule] = []
