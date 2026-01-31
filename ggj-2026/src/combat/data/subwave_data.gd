class_name SubwaveData
extends Resource

## Defines a single subwave of enemies

## Enemy scene to spawn
@export var enemy_scene: PackedScene

## Number of enemies in this subwave
@export var enemy_count: int = 3

## Time between each enemy spawn (seconds)
@export var spawn_delay: float = 0.5

## Wait time after this subwave is cleared before next subwave (seconds)
@export var delay_after_cleared: float = 1.5
