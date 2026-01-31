# Guide d'ajout de nouvelles réactions chimiques

Ce système modulaire permet d'ajouter facilement de nouvelles interactions entre éléments.

## Structure du système

### 1. Créer l'AttackData pour le nouvel élément

**Exemple: Créer une attaque WATER**

Fichier: `src/combat/data/water_attack.tres`
```tres
[gd_resource type="Resource" script_class="AttackData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/combat/attack_data.gd" id="1_water"]

[resource]
script = ExtResource("1_water")
element_type = 3  # WATER
damage = 10.0
range_distance = 50.0
dissipation_time = 5.0
cooldown = 1.0
speed = 80.0
collision_radius = 20.0
visual_effect = null
```

### 2. Créer l'AttackData pour le résultat de la réaction

**Exemple: WATER + ELECTRIC = Choc électrique étendu**

Fichier: `src/combat/data/electric_shock.tres`
```tres
[resource]
script = ExtResource("1_shock")
element_type = 4  # ELECTRIC
damage = 30.0
dissipation_time = 3.0
speed = 0.0
collision_radius = 80.0  # Zone plus grande!
visual_effect = null
```

### 3. Ajouter la règle dans ChemistryManager

Ouvrir `src/autoload/chemistry_manager.gd` et ajouter dans `_setup_reaction_rules()`:

```gdscript
# WATER + ELECTRIC = ELECTRIC_SHOCK (zone élargie)
reaction_rules.append(ReactionRule.new(
    AttackData.ElementType.WATER,
    AttackData.ElementType.ELECTRIC,
    "res://src/combat/data/electric_shock.tres",
    "WATER_ELECTRIC_SHOCK"
))
```

## Exemples de réactions possibles

### Réaction avec modification (ne détruit pas les éléments)

```gdscript
# WIND + FIRE = Accélère le feu (ne détruit pas le vent)
var rule = ReactionRule.new(
    AttackData.ElementType.WIND,
    AttackData.ElementType.FIRE,
    "res://src/combat/data/fast_fire.tres",
    "WIND_FIRE_BOOST",
    false  # Ne détruit pas les deux attaques
)
reaction_rules.append(rule)
```

### Réaction en chaîne

```gdscript
# GAS + GAS = POISON_CLOUD
reaction_rules.append(ReactionRule.new(
    AttackData.ElementType.GAS,
    AttackData.ElementType.GAS,
    "res://src/combat/data/poison_cloud.tres",
    "GAS_FUSION"
))
```

### Réaction asymétrique

```gdscript
# WATER + FIRE = Steam (vapeur qui annule les deux)
reaction_rules.append(ReactionRule.new(
    AttackData.ElementType.WATER,
    AttackData.ElementType.FIRE,
    "res://src/combat/data/steam.tres",  # Peut être juste un nuage inoffensif
    "WATER_FIRE_STEAM"
))
```

## Types d'éléments disponibles

```gdscript
enum ElementType {
    NONE = 0,
    FIRE = 1,
    GAS = 2,
    WATER = 3,
    ELECTRIC = 4,
    WIND = 5
}
```

## Propriétés importantes de l'AttackData

- `element_type`: Type d'élément (voir enum ci-dessus)
- `damage`: Dégâts infligés
- `dissipation_time`: Durée de vie
- `speed`: 0 = immobile, >0 = projectile
- `collision_radius`: Taille de la zone d'effet
- `collision_radius` élevé = réactions plus faciles à déclencher

## Conseils de design

1. **Explosions**: `dissipation_time` court (1-2s) + `collision_radius` grand (60-80)
2. **Nuages/Zones**: `speed = 0` + `dissipation_time` long (5-10s)
3. **Projectiles**: `speed > 0` + `collision_radius` petit (15-25)
4. **Réactions en chaîne**: Résultat avec même type qu'un réactif (ex: FIRE+GAS=FIRE permet FIRE+GAS à nouveau)
