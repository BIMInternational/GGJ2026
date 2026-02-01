class_name AttackData
extends Resource

## Enumération des types d'éléments possibles
enum ElementType {
	NONE,
	FIRE,
	GAS,
	WATER,	ICE,	ELECTRIC,
	WIND,
	FROZEN_GAS
}

## Type d'élément de l'attaque
@export var element_type: ElementType = ElementType.NONE

## Dégâts infligés par l'attaque
@export var damage: float = 10.0

## Distance d'apparition par rapport au joueur
@export var range_distance: float = 50.0

## Durée de vie de la zone d'attaque (en secondes)
@export var dissipation_time: float = 3.0

## Temps de recharge avant de pouvoir réutiliser l'attaque
@export var cooldown: float = 1.0

## Vitesse de déplacement (0 = statique, >0 = projectile)
@export var speed: float = 0.0

## Inverser la direction de l'attaque (va vers l'arrière au lieu de l'avant)
@export var reverse_direction: bool = false

## Rayon de la zone de collision
@export var collision_radius: float = 20.0

## L'attaque s'étend progressivement jusqu'à sa taille maximale
@export var expand_over_time: bool = false

## Ignorer l'axe Y (touche sur toute la hauteur, pour beat'em up)
@export var ignore_y_axis: bool = false

## Attaque à spawner en trainée (pour les projectiles qui laissent une trace)
@export var trail_attack_data: AttackData = null

## Distance entre chaque spawn de trainée (en pixels)
@export var trail_spawn_distance: float = 30.0

## Utiliser un système de particules GPU pour la trainée (plus performant)
@export var use_particle_trail: bool = false

## Effet de particules pour la trainée (GPUParticles2D)
@export var trail_particle_effect: PackedScene = null

## Jouer un son lors du spawn de l'attaque (false pour les zones statiques/trainées)
@export var play_sound: bool = true

## Effet visuel (particules/sprites)
@export var visual_effect: PackedScene = null
