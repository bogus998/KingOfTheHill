class_name PassDeviceScreenController
extends Panel

signal ready_pressed

@onready var _message_label: Label = $VBox/MessageLabel

func show_for_player(player_name: String) -> void:
	_message_label.text = "Pass device to\n%s" % player_name
	visible = true

func hide_screen() -> void:
	visible = false

func _on_ready_button_pressed() -> void:
	ready_pressed.emit()
	hide_screen()
