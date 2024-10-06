extends Node2D


var enemy_count = 0

export(String)var creature_path

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.connect("creature_dead",self,"on_creature_dead")
	Global.connect("spawn_ally_creature",self,"spawn_ally_creature")
	
	randomize()

func _process(delta):
	
	if enemy_count <= 0:
		$Camera2D/Canvas/UI/SpawnTimerLabel.text = str("Next wawe in ",str($Timers/SpawnerTimer.time_left).left(3))
	else:
		$Camera2D/Canvas/UI/SpawnTimerLabel.text = ""
	


func spawn_enemy_wawe(creature_count = 4):
	
	enemy_count = creature_count
	
	for index in creature_count:
		spawn_creature(Vector2(1000,1000).rotated(deg2rad(rand_range(0,360))))
	

func spawn_creature(spawn_position : Vector2, type : int  = 0):
	
	var creature_instance = load(creature_path).instance()
	creature_instance.global_position = spawn_position
	creature_instance.char_type = type
	
	if type == 0:
		creature_instance.get_node("FaceSprite").texture = load("res://sprites/enemy_face.png")
	elif type == 1:
		creature_instance.health = 5
		creature_instance.damage = 2
	add_child(creature_instance)
	


func on_creature_dead():
	
	enemy_count -= 1
	
	if enemy_count <= 0:
		$Timers/SpawnerTimer.start()
	

func _on_SpawnerTimer_timeout():
	print("NEW SPAWN")
	
	Global.emit_signal("wave_start")
	
	spawn_enemy_wawe(8)
	

func spawn_ally_creature(ally_position : Vector2 = Vector2.ZERO):
	
	spawn_creature(ally_position, 1)
