extends Node2D

#song URL
#https://www.beepbox.co/#9n31s0k0l00e0ft2ca7g0fj07r1i0o432T1v1uc0f10l7q011d23A4F3B5Q0506Pd474E361963279T1v1uf1f1102q0z10v321d07A1F0B0Q1845Pe354E4bj61362463aT1v1uc5f0q8111d23A0F0B3Q5000Pf800E0T4v1u04f0qwx10n611z6666ji8k8k3jSBKSJJAArriiiiii07JCABrzrrrrrrr00YrkqHrsrrrrjr005zrAqzrjzrrqr1jRjrqGGrrzsrsA099ijrABJJJIAzrrtirqrqjqixzsrAjrqjiqaqqysttAJqjikikrizrHtBJJAzArzrIsRCITKSS099ijrAJS____Qg99habbCAYrDzh00E1b6b0000018i4x8z8Ocz8Oc010004x8i4x80014h8y8y8xgp22uFHY5ljkqZQ3duyERUaA2CzV4th7ihOx70CLohRqN7ohQAtxMtx7ohPnAOeEUeAzG8VQZp7os65dvWAHU4WvmFduKIRM9HFB0yCwUCwFEatUFwiCEFEaqyCEFGaq2CPalgFjagkR5d1jBkkV1jkkQ5cRW2CwXA0

var enemy_count = 0

var ally_count = 3

var wave_count = 0

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
	
	$NewWavePlayer.play()
	
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
