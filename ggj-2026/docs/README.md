# Game Jam 2026 - Structure du Projet

## Arborescence

```
ggj-2026/
├── assets/          # Tous les assets du jeu
│   ├── sprites/     # Images et sprites
│   ├── sounds/      # Effets sonores
│   ├── music/       # Musiques de fond
│   └── fonts/       # Polices de caractères
├── publish/         # Fichiers de publication
├── src/             # Sources
│   ├── scenes/      # Scènes principales du jeu
│   ├── levels/      # Niveaux du jeu
│   ├── scripts/     # Scripts réutilisables (player, enemy, etc.)
│   ├── ui/          # Interfaces utilisateur (menus, HUD)
│   ├── autoload/    # Scripts singleton (GameManager, etc.)
└── project.godot    # Configuration du projet
```

## Managers (Autoloads)

✅ **GameManager** - Gestion de l'état du jeu, score, signaux
✅ **AudioManager** - Musique et effets sonores avec fade
✅ **SceneManager** - Changement de scènes avec transitions
✅ **InputManager** - Détection gamepad/clavier

## Composants Réutilisables

- **HealthComponent** - Système de santé modulaire
- **StateMachine** - Machine à états pour IA et personnages
- **Camera2D** - Caméra avec smooth follow et shake

## UI Prête

- **MainMenu** - Menu principal avec boutons
- **HUD** - Score et timer
- **PauseMenu** - Menu pause avec ESC

## Quick Start

1. Ouvrir le projet dans Godot
2. La scène de démarrage est `src/ui/main_menu.tscn`
3. Utiliser les managers : `GameManager.start_game()`, `AudioManager.play_music()`, etc.
4. Ajouter le HUD et PauseMenu dans vos scènes de jeu

## Exemples d'Utilisation

```gdscript
# Démarrer le jeu
GameManager.start_game()

# Jouer de la musique
AudioManager.play_music(preload("res://assets/music/theme.ogg"))

# Changer de scène
SceneManager.change_scene(GameConstants.NAME_OF_THE_SCENE)

# Ajouter un composant de santé
var health = $HealthComponent
health.take_damage(10)
```
