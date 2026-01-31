class_name WaveData
extends Resource

## Defines a complete phase (multiple subwaves + optional boss)

## List of subwaves in this phase
@export var subwaves: Array[SubwaveData] = []

## Boss scene to spawn after all subwaves cleared (null = no boss)
@export var boss_scene: PackedScene

## X position where the progress gate blocks the player
@export var gate_x_position: float = 500.0

## Show reward screen after boss defeated?
@export var show_reward_after_boss: bool = true
