extends Node
## Centralized constants for the game
## Holds all hardcoded values like scene paths, audio bus names, etc.

# Scene paths
const SCENE_MAIN_MENU: String = "res://src/ui/main_menu.tscn"
const SCENE_SETTINGS_MENU: String = "res://src/ui/settings_menu.tscn"
const SCENE_CONTROLS_SETTINGS: String = "res://src/ui/controls_settings.tscn"
const SCENE_CREDITS_MENU: String = "res://src/ui/credits_menu.tscn"
const SCENE_GAME_OVER: String = "res://src/ui/game_over.tscn"
const SCENE_PAUSE_MENU: String = "res://src/ui/pause_menu.tscn"
const SCENE_MAIN_GAME: String = "res://src/scenes/main/main.tscn"

# Collision Layers (Physics 2D)
const LAYER_PLAYER: int = 1 # Bit 0
const LAYER_ENEMY: int = 2 # Bit 1
const LAYER_ENVIRONMENT: int = 4 # Bit 2
const LAYER_COLLECTIBLE: int = 8 # Bit 3
const LAYER_HAZARD: int = 16 # Bit 4

# Audio bus names (already hardcoded in your code)
const AUDIO_BUS_MASTER: String = "Master"
const AUDIO_BUS_MUSIC: String = "Music"
const AUDIO_BUS_SFX: String = "SFX"

# Audio Music files
const MUSIC_LOGO: String = "res://assets/music/BranquesInteractive.ogg"

# Audio Effects files
const PLAYER_WALK: String = "res://assets/sounds/swim.ogg"

# Game settings
const GAME_DURATION: float = 180.0 # 3 minutes (en secondes)
