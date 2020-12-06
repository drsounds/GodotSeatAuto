extends Node

var scenes = [
	"assets/Godot_Seat_Auto/scenes/Demo/Demo",
	"assets/Godot_Seat_Auto/scenes/Demo/Demo"
]

func get_pos():
	return self.get_gui().get_pos()



# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func get_gui():
	return get_parent().get_node('GUI')

# Called when the node enters the scene tree for the first time.
func _ready():
	set_pos(1)
	set_duration(scenes.size() - 1)

func set_duration(duration):
	pass #get_gui().set_duration(duration)

func set_pos(index, notified=false):
	var scene_name = scenes[index]
	set_scene(scene_name)
	if not notified and false:
		get_gui().set_pos(index)

func set_scene(name):
	var root = self
	if root.get_child_count() > 0:
		root.remove_child(root.get_child(0))
	# Add the next level
	var next_level_resource = load("res://" + name + ".tscn")
	var next_level = next_level_resource.instance()
	root.add_child(next_level)

func _on_GUI_position_changed(pos):
	set_pos(pos, false)

func next_scene():
	if get_pos() < get_gui().get_duration():
		set_pos(get_pos() + 1)
	
func previous_scene():
	if get_pos() > 0:
		set_pos(get_pos() - 1)

func new_game():
	set_pos(1)
