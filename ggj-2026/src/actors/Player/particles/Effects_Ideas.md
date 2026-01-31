## ✅ jump particle effect
func create_jump_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "JumpParticles"
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.2

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.color = Color.WHITE

	# Fade out over time
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	_save_scene(particles, "jump_particles.tscn")

## ✅ landing particle effect
func create_land_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "LandParticles"
	particles.amount = 20
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.3

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(0, 0, 0)  # Radial
	material.spread = 180.0  # Full horizontal spread
	material.flatness = 1.0  # Keep it 2D
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 150, 0)
	material.damping_min = 50.0
	material.damping_max = 80.0
	material.scale_min = 3.0
	material.scale_max = 6.0
	material.color = Color(0.8, 0.7, 0.6, 1.0)  # Dust color

	# Fade out
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	_save_scene(particles, "land_particles.tscn")

## wall slide particle effect
func create_wall_slide_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "WallSlideParticles"
	particles.amount = 8
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.5

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(1, 0, 0)
	material.spread = 30.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 1.0
	material.scale_max = 3.0
	material.color = Color(0.9, 0.85, 0.75, 1.0)

	# Fade out
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	_save_scene(particles, "wall_slide_particles.tscn")

##  wall jump particle effect
func create_wall_jump_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "WallJumpParticles"
	particles.amount = 15
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 0.8

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(1, -0.5, 0)
	material.spread = 60.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 2.0
	material.scale_max = 5.0
	material.color = Color(0.7, 0.9, 1.0, 1.0)  # Cyan tint

	# Fade out
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	_save_scene(particles, "wall_jump_particles.tscn")

##  dash burst particle effect
func create_dash_burst_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "DashBurstParticles"
	particles.amount = 24
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.3

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.flatness = 1.0
	material.initial_velocity_min = 150.0
	material.initial_velocity_max = 300.0
	material.gravity = Vector3.ZERO
	material.damping_min = 100.0
	material.damping_max = 150.0
	material.scale_min = 2.0
	material.scale_max = 6.0

	# Cyan to white gradient
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0.8, 1.0, 1.0))
	gradient.add_point(0.5, Color(0.8, 0.95, 1.0, 0.8))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	_save_scene(particles, "dash_burst_particles.tscn")

##  hit impact particle effect
func create_hit_impact_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "HitImpactParticles"
	particles.amount = 16
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0

	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(1, 0, 0)
	material.spread = 120.0
	material.initial_velocity_min = 120.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 3.0
	material.scale_max = 7.0
	material.hue_variation_min = -0.1
	material.hue_variation_max = 0.1

	# Yellow/orange impact flash
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.8, 0.3, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.6, 0.2, 0.8))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	_save_scene(particles, "hit_impact_particles.tscn")
