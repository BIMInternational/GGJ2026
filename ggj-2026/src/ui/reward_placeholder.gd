extends CanvasLayer

class_name RewardPlaceholder

## Temporary reward screen - just a continue button for now


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _on_continue_pressed() -> void:
	WaveManager.on_reward_continue()
