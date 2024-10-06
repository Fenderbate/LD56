extends Node2D


var enemy_count = 0

var ally_count = 3

var wave_count = 50

export(String)var creature_path

var tile1 = preload("res://sprites/grass_tile.png")
var tile2 = preload("res://sprites/grass_tile_2.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.connect("creature_dead",self,"on_creature_dead")
	Global.connect("spawn_creature",self,"spawn_creature")
	Global.connect("game_over",self,"on_game_over")
	
	randomize()

func _process(delta):
	
	if enemy_count <= 0:
		$Camera2D/Canvas/UI/SpawnTimerLabel.text = str("Next wawe in ",str($Timers/SpawnerTimer.time_left).left(3))
	else:
		$Camera2D/Canvas/UI/SpawnTimerLabel.text = str("Wave ",wave_count)
	


func spawn_enemy_wawe(creature_count = 4):
	
	for index in creature_count:
		spawn_creature(Vector2(1000,1000).rotated(deg2rad(rand_range(0,360))))
	

func spawn_creature(spawn_position : Vector2, type : int  = 0):
	
	var creature_instance = load(creature_path).instance()
	creature_instance.global_position = spawn_position
	creature_instance.char_type = type
	
	if type == 0:
		creature_instance.get_node("FaceSprite").texture = load("res://sprites/enemy_face.png")
		enemy_count += 1
	elif type == 1:
		creature_instance.health = 5
		creature_instance.damage = 2
		ally_count += 1
	
	add_child(creature_instance)
	
	if type == 1:
		return
	
	if randi()%51 < wave_count:
		print("Upgrade")
		for index in randi() % 5:
			creature_instance.apply_random_upgrade(randi() % 4)
			print("added")
	


func on_creature_dead(type : int):
	
	
	
	if type == 0:
		enemy_count -= 1
	elif type == 1:
		ally_count -= 1
		print(ally_count)
	
	
	
	if ally_count <= 0:
		Global.emit_signal("game_over")
		return
	
	if enemy_count <= 0:
		$Timers/SpawnerTimer.start()
	

func on_game_over():
	
	$Camera2D/Canvas/UI/GameOver.show()

func _on_SpawnerTimer_timeout():
	print("NEW SPAWN")
	
	Global.emit_signal("wave_start")
	
	wave_count += 1
	
	spawn_enemy_wawe(3 + wave_count / 2)
	



func _on_AnimTimer_timeout():
	$Polygon2D.texture_offset = Vector2(rand_range(-4,4),rand_range(-4,4))
	
	
	
	if $Polygon2D.texture == tile1:
		$Polygon2D.texture = tile2
	else:
		$Polygon2D.texture = tile1
	
	


func _on_Button_button_down():
	get_tree().reload_current_scene()
