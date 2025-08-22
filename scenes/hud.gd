extends CanvasLayer

var curr_speed

func _process(delta: float) -> void:
	$Label.text = "SPEED: "+str(curr_speed)
