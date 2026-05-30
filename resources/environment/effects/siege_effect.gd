class_name SiegeEffect
extends EnvironmentEffect
## Outside players need 1 extra Claw to enter the Vault this round.

func vault_entry_surcharge() -> int:
	return 1
