class_name RestlessHoardEffect
extends EnvironmentEffect
## Vault holder cannot accumulate gold this round — earned gold goes to the bank.

func blocks_vault_holder_gold() -> bool:
	return true
