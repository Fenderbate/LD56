extends RigidBody2D
class_name Creature

signal dead

enum TYPE {ENEMY = 0, ALLY = 1}


export(TYPE) var char_type 
export(float)var speed = 10
export(int)var vision_range = 1024


export(int) var health = 3
var max_health = 5


export(int) var damage = 1
export(int)var knockback = 500

export(bool)var dead = false
	
var consumed : bool = false


export(int)var levels : int = 0
var leftover_upgrades : int = 0

var sprite_anim_offset = 8
var texture_anim_offset = 8



var target

var direction : Vector2

var motion : Vector2

var sprite_array : PoolVector2Array

# Called when the node enters the scene tree for the first time.
func _ready():
	
	Global.connect("wave_start",self,"on_wave_start")
	
	$UIHolder/Control/Container/LevelContainer/Level1Texture.texture = AtlasTexture.new()
	$UIHolder/Control/Container/LevelContainer/Level2Texture.texture = AtlasTexture.new()
	$UIHolder/Control/Container/LevelContainer/Level3Texture.texture = AtlasTexture.new()
	$UIHolder/Control/Container/LevelContainer/Level4Texture.texture = AtlasTexture.new()
	
	$UIHolder/Control/Container/LevelContainer/Level1Texture.texture.atlas = load("res://sprites/level_indicator.png")
	$UIHolder/Control/Container/LevelContainer/Level2Texture.texture.atlas = load("res://sprites/level_indicator.png")
	$UIHolder/Control/Container/LevelContainer/Level3Texture.texture.atlas = load("res://sprites/level_indicator.png")
	$UIHolder/Control/Container/LevelContainer/Level4Texture.texture.atlas = load("res://sprites/level_indicator.png")
	
	$Shape.shape = $Shape.shape.duplicate()
	$AttackArea/AttackShape.shape = $AttackArea/AttackShape.shape.duplicate()
	
	sprite_array = $Polygon2D.polygon
	
	match char_type:
		TYPE.ENEMY:
			$Polygon2D.modulate = Color("F94144")
		TYPE.ALLY:
			$Polygon2D.modulate = Color("F9C74F")
	
	$VisionArea/VisionShape.shape.radius = vision_range
	
	update_level(0)
	

func _process(delta):
		
		if !self.dead:
			$AttackArea/AttackShape.shape.radius = $Shape.shape.radius + 16
			
			for body in $AttackArea.get_overlapping_bodies():
				if body is RigidBody2D and !body.consumed and body.char_type != self.char_type:
					attack(body)
		
		if dead and !is_in_group("dead_creature"):
			add_to_group("dead_creature")
			if self.char_type == TYPE.ENEMY:
				$FaceSprite.texture = load("res://sprites/enemy_face_dead.png")
			else:
				$FaceSprite.texture = load("res://sprites/ally_face_dead.png")
			return
		
		
		
		


func _integrate_forces(state):
		
		rotation = 0
		
		if self.dead:
			return
		
		if !target or (target.get_ref() and is_instance_valid(target) and target.get_ref().consumed):
			move(Vector2.ZERO, true)
			
			if !find_target():
				find_snacks()
				
				
			
		else:
			if target and target.get_ref():
				move(target.get_ref().global_position)
				
				
		
		
	

func find_snacks():
	
	var distance = 10000000
	var consume_target = null
	
	for body in $DeadCheckArea.get_overlapping_bodies():
		if is_instance_valid(body) and body.dead and !body.consumed and self.char_type != body.char_type:
			if global_position.distance_to(body.global_position) < distance:
				distance = global_position.distance_to(body.global_position)
				consume_target = weakref(body)
	
	if consume_target:
		target = consume_target
		move(target.get_ref().global_position)
	

func move(target_position : Vector2, recenter : bool = false):
	
	direction = global_position.direction_to(target_position)
	
	if (global_position.distance_to(target_position) > ($Shape.shape as CircleShape2D).radius + 16) if !recenter else global_position.distance_to(target_position) > 480:
		
		linear_velocity = linear_velocity + (direction * speed * get_physics_process_delta_time() if linear_velocity.length() < (direction * speed).length() * 2 else Vector2.ZERO)
		
	else:
		if target and target.get_ref():
			attack(target.get_ref())
	

func find_target():
	var distance := 1000000000
	
	var new_target = null
	
	var bodies = $VisionArea.get_overlapping_bodies()
	
	for body in bodies:
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < distance and !body.dead and !body.consumed:
			if self.char_type != body.char_type:
				distance = global_position.distance_to(body.global_position)
				new_target = body
	if new_target:
		target = weakref(new_target)
		return true
	
	return false

func attack(target_node):
	
	if target_node is StaticBody2D:
		return
	
	if self.char_type == target_node.char_type or self.dead or self.consumed:
		return
	
	if $AttackTimer.time_left <= 0 and target_node:
			$AttackTimer.start()
			if !target_node.dead:
				target_node.apply_central_impulse(global_position.direction_to(target_node.global_position)* knockback)
				target_node.hurt(damage,self)
				$HitSounds.get_children()[randi() % $HitSounds.get_child_count()].play()
				$Animations/AnimationPlayer.play("attack")
			elif target_node.dead:
				consume(target_node)
	

func hurt(damage : int, hurt_by : RigidBody2D = null):
	
	health -= damage
	
	if health <= 0:
		
		add_to_group("dead_creature")
		dead = true
		$AnimTimer.stop()
		$DeathSounds.get_children()[randi() % $DeathSounds.get_child_count()].play()
		Global.emit_signal("creature_dead",char_type)
		if self.char_type == TYPE.ENEMY:
			$FaceSprite.texture = load("res://sprites/enemy_face_dead.png")
		else:
			$FaceSprite.texture = load("res://sprites/ally_face_dead.png")
		$Animations/AnimationPlayer.play("dead")
		

func consume(consume_target):
	
	if consume_target.consumed:
		consume_target.remove_from_group("dead_creature")
		target = null
		return
	
	consume_target.consumed = true
	consume_target.remove_from_group("dead_creature")
	target = null
	
	consume_target.get_node("DeathTimer").start()
	consume_target.get_node("Animations/AnimationPlayer").play("consumed")
	consume_target.collision_layer = 0
	consume_target.collision_mask = 0
	consume_target.input_pickable = false
	
	
	$EatSounds.get_children()[randi() % $EatSounds.get_child_count()].play()
	
	if self.char_type == TYPE.ALLY:
		health += 1 if health != max_health else 0
		update_level(1)#return consume_target.levels if levels > 0 else 1
	
func update_level(levels_to_add : int):
	
	if self.char_type == TYPE.ENEMY:
		return
	
	update_info_label("")
	
	levels += levels_to_add
	
	if levels == 4 or (levels_to_add <= 0 and levels >= 4):
		update_upgrade_display()
		
	elif levels < 4:
		update_upgrade_display(true)
	
	var empt = Rect2(0,0,32,64)
	var full = Rect2(32,0,32,64)
	
	$UIHolder/Control/Container/LevelContainer/Level1Texture.texture.region = full if levels >= 1 else empt
	$UIHolder/Control/Container/LevelContainer/Level2Texture.texture.region = full if levels >= 2 else empt
	$UIHolder/Control/Container/LevelContainer/Level3Texture.texture.region = full if levels >= 3 else empt
	$UIHolder/Control/Container/LevelContainer/Level4Texture.texture.region = full if levels >= 4 else empt
	
	leftover_upgrades = int(levels / 4)
	
	if levels_to_add < 0:
		$Animations/AnimationPlayer.play("upgrade")
		$LevelUpSounds.get_children()[randi() % $LevelUpSounds.get_child_count()].play()
		
		#$UpgradeParticles.emission_sphere_radius = $Shape.shape.radius
		#$UpgradeParticles.restart()
		#$UpgradeParticles.emitting = true
		#yield(get_tree().create_timer(0.5), "timeout")
		#$UpgradeParticles.emitting = false

func update_upgrade_display(hide : bool = false):
	
	for child in $UIHolder/Control/Container/UpgradeButtonContainer.get_children():
		child.hide()
	
	if hide or self.char_type == TYPE.ENEMY or levels < 4:
		return

	show_upgrade()
	show_upgrade()
	
	pass

func show_upgrade():
	var ug = $UIHolder/Control/Container/UpgradeButtonContainer.get_children()[randi() % 4]
	
	if ug.visible:
		show_upgrade()
	else:
		ug.show()

func apply_random_upgrade(upgrade_index):
	
	match upgrade_index:
		1:
			upgrade_size()
		2:
			upgrade_damage()
		3:
			upgrade_duplicate()
	

func upgrade_size():
	
	#for index in sprite_array.size():
	#	sprite_array[index] += sprite_array[index] / 4
	
	#$Polygon2D.polygon = new_poly
	
	$Shape.shape.radius += 32
	$AttackArea/AttackShape.shape.radius = $Shape.shape.radius + 16
	$FaceSprite.offset.y += 8
	texture_anim_offset += 2
	weight += 1
	
	max_health += 3
	health += 3
	
	speed = speed -1 if speed > 1 else 1
	
	_on_AnimTimer_timeout()
	
	linear_velocity = Vector2(1,0)
	
	update_level(-4)
	

func upgrade_damage():
	
	if self.char_type == TYPE.ALLY:
		$FaceSprite.texture = load("res://sprites/ally_face_damage.png")
	else:
		$FaceSprite.texture = load("res://sprites/enemy_face_damage.png")
	#sprite_anim_offset += 4
	damage += 1
	knockback += 100
	
	update_level(-4)
	

func upgrade_duplicate():
	
	#get_parent().add_child(self.duplicate())
	#print("make visual change, don't allow more dupes")
	
	update_level(-4)
	
	Global.emit_signal("spawn_creature",global_position,char_type)

func upgrade_heal():
	
	health = max_health
	
	update_level(-4)
	




func _on_AttackTimer_timeout():
	pass # Replace with function body.


func _on_DeathTimer_timeout():
	queue_free()


func _on_VisionArea_body_entered(body):
	if is_instance_valid(body) and !target and body.char_type != self.char_type:
		
		
		move(body.global_position)
		target = weakref(body)

func on_wave_start():
	target = null

func update_info_label(new_text = ""):
	
	if new_text == "":
		$UIHolder/Control/Container/InfoContainer/Label.hide()
	else:
		$UIHolder/Control/Container/InfoContainer/Label.show()
		$UIHolder/Control/Container/InfoContainer/Label.text = new_text
	

func _on_AnimTimer_timeout():
	
	var pols = sprite_array
	
	for index in sprite_array.size():
		pols[index] = sprite_array[index].normalized() * ($Shape.shape.radius + 16) + Vector2(rand_range(-sprite_anim_offset,sprite_anim_offset),rand_range(-sprite_anim_offset,sprite_anim_offset))
	
	$Polygon2D.polygon = pols
	$Polygon2D.texture_offset = Vector2(rand_range(-texture_anim_offset,texture_anim_offset),rand_range(-texture_anim_offset,texture_anim_offset))
	


func _on_Creature_body_entered(body):
	return
	attack(body)


func _on_EatTimer_timeout():
	return
	if !target:
		find_target()


func _on_Creature_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		hurt(999)


func _on_TargetValidatorTimer_timeout():
	
	var cols = get_colliding_bodies()
	
	if !cols or $AttackTimer.time_left <= 0:
		return
	
	for body in cols:
		if body is RigidBody2D and body.char_type != self.char_type:
			_on_Creature_body_entered(body)
	
	target = null


func _on_SizeButton_mouse_entered():
	update_info_label("+ Size\n+ Health")


func _on_DMGButton_mouse_entered():
	update_info_label("+ Damage\n+ Horns")


func _on_SpawnButton_mouse_entered():
	update_info_label("+ Clone")


func _on_HealButton_mouse_entered():
	update_info_label("Heal self")


func reset_label_info():
	update_info_label("")


func _on_AttackArea_body_entered(body):
	return
	attack(body)
