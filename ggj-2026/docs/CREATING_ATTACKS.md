# Guide de Création d'Attaques

Ce guide explique comment créer de nouveaux types d'attaques dans le système de combat chimique.

## Structure du Système

Le système d'attaque est composé de :
- **AttackData** : Resource définissant les propriétés d'une attaque
- **attack_instance** : Scène gérant le comportement d'une attaque en jeu
- **ChemistryManager** : Autoload gérant les réactions entre attaques

## Créer une Nouvelle Attaque

### Étape 1 : Créer la Resource AttackData

1. Dans l'éditeur Godot, navigue vers `src/combat/data/`
2. Clic droit → **New Resource**
3. Cherche et sélectionne **AttackData**
4. Sauvegarde avec un nom descriptif (ex: `water_attack.tres`)

### Étape 2 : Configurer les Paramètres

Ouvre ta nouvelle resource et configure les propriétés :

#### Types d'Éléments Disponibles
```gdscript
enum ElementType {
    NONE,      # Pas d'élément (explosions, effets neutres)
    FIRE,      # Feu
    GAS,       # Gaz
    WATER,     # Eau
    ELECTRIC,  # Électricité
    WIND       # Vent
}
```

#### Paramètres Principaux

| Propriété | Type | Description | Exemple |
|-----------|------|-------------|---------|
| `element_type` | ElementType | Type d'élément de l'attaque | FIRE, GAS, WATER |
| `damage` | float | Dégâts infligés | 15.0 |
| `speed` | float | Vitesse de déplacement (0 = statique) | 100.0 |
| `collision_radius` | float | Rayon de la zone de collision | 20.0 |
| `dissipation_time` | float | Durée de vie en secondes | 3.0 |
| `expand_over_time` | bool | L'attaque s'étend progressivement | true/false |
| `range_distance` | float | Distance d'apparition (obsolète) | 0.0 |
| `cooldown` | float | Temps de recharge | 1.5 |
| `visual_effect` | PackedScene | Scène d'effet visuel personnalisé | null |

### Étape 3 : Exemples de Configurations

#### Projectile Rapide (Boule de Feu)
```
element_type: FIRE
damage: 15.0
speed: 100.0
collision_radius: 20.0
dissipation_time: 3.0
expand_over_time: false
```

#### Zone Statique (Nuage de Gaz)
```
element_type: GAS
damage: 5.0
speed: 0.0
collision_radius: 40.0
dissipation_time: 10.0
expand_over_time: false
```

#### Explosion Progressive
```
element_type: FIRE (ou NONE si ne doit pas réagir)
damage: 25.0
speed: 0.0
collision_radius: 60.0
dissipation_time: 1.5
expand_over_time: true
```

## Utiliser l'Attaque dans le Code

### Depuis le Player ou un Ennemi

```gdscript
# Charger la resource
var my_attack_data: AttackData = preload("res://src/combat/data/water_attack.tres")

# Spawner l'attaque
func shoot_attack() -> void:
    var spawn_position = global_position + direction * offset
    ChemistryManager.spawn_attack(my_attack_data, spawn_position, direction)
```

### Paramètres de spawn_attack()

```gdscript
ChemistryManager.spawn_attack(
    attack_data,      # AttackData : La resource d'attaque
    spawn_position,   # Vector2 : Position de spawn dans le monde
    direction         # Vector2 : Direction de mouvement (normalisée)
)
```

## Créer des Réactions Chimiques

Pour qu'une attaque réagisse avec d'autres, ajoute une règle dans `chemistry_manager.gd` :

```gdscript
func _setup_reaction_rules() -> void:
    # WATER + ELECTRIC = ELECTRIFIED_WATER
    reaction_rules.append(ReactionRule.new(
        AttackData.ElementType.WATER,     # Élément A
        AttackData.ElementType.ELECTRIC,  # Élément B
        "res://src/combat/data/electrified_water.tres",  # Attaque résultante
        "WATER_ELECTRIC_SHOCK",           # Nom de la réaction
        true,   # Détruire WATER
        true,   # Détruire ELECTRIC
        true,   # Marquer WATER comme ayant réagi
        true    # Marquer ELECTRIC comme ayant réagi
    ))
```

### Contrôle Fin des Réactions

Les 4 derniers paramètres booléens contrôlent :
1. **destroy_elem_a** : Détruire l'élément A après réaction
2. **destroy_elem_b** : Détruire l'élément B après réaction
3. **mark_elem_a_reacted** : Empêcher A de réagir à nouveau
4. **mark_elem_b_reacted** : Empêcher B de réagir à nouveau

**Exemple** : Feu traverse le gaz
```gdscript
ReactionRule.new(
    AttackData.ElementType.FIRE,
    AttackData.ElementType.GAS,
    "res://src/combat/data/explosion_attack.tres",
    "FIRE_GAS_EXPLOSION",
    false,  # Le feu continue sa route
    true,   # Le gaz est consommé
    false,  # Le feu peut réagir avec d'autres gaz
    true    # Le gaz ne réagit qu'une fois
)
```

## Effets Visuels Personnalisés

### Option 1 : Visuel par Défaut
Si `visual_effect` est `null`, le système crée automatiquement un sprite coloré selon l'élément :
- FIRE : Orange/Rouge
- GAS : Vert semi-transparent
- WATER : Bleu
- ELECTRIC : Jaune
- WIND : Gris clair

### Option 2 : Scène Personnalisée
1. Crée une scène avec des Sprite2D, GPUParticles2D, etc.
2. Assigne-la à `visual_effect`
3. Elle sera automatiquement instanciée et ajoutée à l'attack_instance

## Conseils de Game Design

### Projectiles
- `speed` : 80-150 pour projectiles rapides
- `dissipation_time` : 2-4 secondes
- `collision_radius` : 15-25

### Zones Statiques
- `speed` : 0
- `dissipation_time` : 5-15 secondes
- `collision_radius` : 30-50

### Explosions
- `speed` : 0
- `expand_over_time` : true
- `dissipation_time` : 1-2 secondes (détermine la vitesse d'expansion)
- `collision_radius` : 50-80 (taille finale)

## Fichiers Importants

- `src/combat/attack_data.gd` : Définition de la classe AttackData
- `src/combat/components/attack_instance.gd` : Comportement des attaques
- `src/combat/data/` : Dossier contenant toutes les resources d'attaques
- `src/autoload/chemistry_manager.gd` : Gestion des réactions
