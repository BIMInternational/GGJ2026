# Guide des Attaques et Interactions - GGJ2026

## 🎭 Masques et Attaques Principales

### 🔥 FIRE (Feu)
- **Dégâts**: 15.0
- **Vitesse**: 400.0 (très rapide)
- **Portée**: 60.0
- **Cooldown**: 1.5s
- **Type**: Projectile rapide

### 💨 GAS (Gaz)
- **Dégâts**: 8.0
- **Vitesse**: 50.0 (très lent)
- **Portée**: 80.0
- **Cooldown**: 0.4s
- **Type**: Projectile lent inversé (va vers l'arrière)
- **Trainée**: Laisse du gaz statique tous les 20 pixels

### 💧 WATER (Eau)
- **Dégâts**: 8.0
- **Vitesse**: 400.0 (très rapide)
- **Portée**: 60.0
- **Cooldown**: 1.5s
- **Type**: Projectile rapide
- **Trainée**: Laisse de l'eau statique tous les 25 pixels

### ❄️ ICE (Glace)
- **Dégâts**: 12.0
- **Vitesse**: 300.0
- **Portée**: 100.0
- **Cooldown**: 2.0s
- **Type**: Projectile moyen

### ⚡ LIGHTNING (Électricité)
- **Dégâts**: 18.0
- **Vitesse**: 0.0 (statique)
- **Portée**: 0.0 (spawn sur le joueur)
- **Rayon**: 250.0 (zone énorme)
- **Cooldown**: 3.5s
- **Durée**: 0.3s (très rapide)
- **Type**: Onde d'expansion autour du joueur
- **Spécial**: Ignore l'axe Y (touche sur toute la hauteur)

---

## 🧪 Zones Statiques

### 💨 GAS_STATIC
- **Dégâts**: 5.0
- **Durée**: 10.0s
- **Rayon**: 20.0

### 💧 WATER_STATIC
- **Dégâts**: 2.0
- **Durée**: 15.0s
- **Rayon**: 20.0

### ❄️ ICE_STATIC
- **Dégâts**: 2.0
- **Durée**: 12.0s
- **Rayon**: 20.0

### ⚡ LIGHTNING_STATIC
- **Dégâts**: 15.0
- **Durée**: 3.0s (court mais puissant)
- **Rayon**: 30.0

### 🧊💨 GAS_BLOCK (Gaz gelé)
- **Type d'élément**: FROZEN_GAS
- **Dégâts**: 5.0
- **Durée**: 45.0s
- **Rayon**: 30.0
- **Spécial**: Réagit violemment avec le feu et l'électricité !

---

## 💥 Réactions Chimiques

### ❌ Annulation
| Éléments | Résultat | Description |
|----------|----------|-------------|
| 🔥 FEU + 💧 EAU | Rien | Les deux se détruisent mutuellement |

### 💥 Explosions
| Éléments | Résultat | Dégâts | Rayon | Durée | Description |
|----------|----------|--------|-------|-------|-------------|
| 🔥 FEU + 💨 GAZ | 💥 EXPLOSION | 25.0 | 60.0 | 1.5s | Le feu reste, le gaz explose |
| 💨 GAZ + ⚡ ÉLECTRICITÉ | 🔥💥 FIRE_EXPLOSION | 30.0 | 80.0 | 1.2s | Explosion de feu |
| 🔥 FEU + ⚡ ÉLECTRICITÉ | ⚡🔥 PLASMA | 37.0 | 50.0 | 0.5s | État le plus chaud de la matière |
| 🧊💨 GAZ GELÉ + 🔥 FEU | 🔥💥💥 MEGA EXPLOSION | **45.0** | **280.0** | 0.6s | **ULTRA VIOLENT !** Combo 3 éléments |
| 🧊💨 GAZ GELÉ + ⚡ ÉLECTRICITÉ | 🔥💥💥 MEGA EXPLOSION | **45.0** | **280.0** | 0.6s | **ULTRA VIOLENT !** Combo 3 éléments |

### 🧊 Gel
| Éléments | Résultat | Description |
|----------|----------|-------------|
| 💨 GAZ + ❄️ GLACE | 🧊💨 GAS_BLOCK (FROZEN_GAS) | Bloc de gaz gelé (45s) - Réagit violemment ! |
| 💧 EAU + ❄️ GLACE | ❄️ ICE_STATIC | L'eau gèle au contact (la glace reste) |
| 🧊💨 GAZ GELÉ + 💧 EAU | ❄️ ICE_STATIC | Le gaz gelé transforme l'eau en glace |
| 🧊💨 GAZ GELÉ + 💨 GAZ | 🧊💨 GAS_BLOCK | Nouveau bloc de gaz gelé |

### 💧 Séparation (DÉSACTIVÉE)
| Éléments | Résultat | Description |
|----------|----------|-------------|
| ~~💨 GAZ + 💧 EAU~~ | ~~2x WATER_STATIC~~ | Aucune interaction (commentée)

### ⚡ Électrification
| Éléments | Résultat | Description |
|----------|----------|-------------|
| 💧 EAU + ⚡ ÉLECTRICITÉ | ⚡ LIGHTNING_STATIC | Zone électrique (15 dégâts pendant 3s) |
| ❄️ GLACE + ⚡ ÉLECTRICITÉ | ❄️💥 ICE_EXPLOSION | Explosion de glace (20 dégâts, 150px rayon) |

---

## 📊 Tableau Récapitulatif des Interactions

|  | 🔥 FEU | 💨 GAZ | 💧 EAU | ❄️ GLACE | ⚡ ÉLECTRICITÉ | 🧊💨 GAZ GELÉ |
|---|---|---|---|---|---|---|
| **🔥 FEU** | - | 💥 EXPLOSION (25) | ❌ Annulation | - | ⚡🔥 PLASMA (37) | 🔥💥💥 MEGA (45) |
| **💨 GAZ** | 💥 EXPLOSION (25) | - | - | 🧊💨 Bloc gelé | 🔥💥 Explosion feu (30) | 🧊💨 Bloc gelé |
| **💧 EAU** | ❌ Annulation | - | - | ❄️ Glace (2) | ⚡ Zone électrique (15) | ❄️ Glace (2) |
| **❄️ GLACE** | - | 🧊💨 Bloc gelé | ❄️ Glace (2) | - | ❄️💥 Explosion glace (20) | - |
| **⚡ ÉLECTRICITÉ** | ⚡🔥 PLASMA (37) | 🔥💥 Explosion feu (30) | ⚡ Zone électrique (15) | ❄️💥 Explosion glace (20) | - | 🔥💥💥 MEGA (45) |
| **🧊💨 GAZ GELÉ** | 🔥💥💥 MEGA (45) | 🧊💨 Bloc gelé | ❄️ Glace (2) | - | 🔥💥💥 MEGA (45) | - |

**Légende:**
- `-` : Aucune interaction (se traversent)
- `(nombre)` : Dégâts de la réaction
- 🔥💥💥 **MEGA EXPLOSION** : Combo 3 éléments ultra violent !

---

## 🎮 Ordre de Puissance des Attaques

1. **🔥💥💥 MEGA EXPLOSION** - **45 dégâts** (GAZ GELÉ + FEU/ÉLECTRICITÉ) - **COMBO 3 ÉLÉMENTS**
2. **⚡🔥 PLASMA** - 37 dégâts (FEU + ÉLECTRICITÉ)
3. **🔥💥 FIRE_EXPLOSION** - 30 dégâts (GAZ + ÉLECTRICITÉ)
4. **💥 EXPLOSION** - 25 dégâts (FEU + GAZ)
5. **❄️💥 ICE_EXPLOSION** - 20 dégâts (GLACE + ÉLECTRICITÉ)
6. **⚡ LIGHTNING** - 18 dégâts (attaque principale)
7. **🔥 FIRE** - 15 dégâts (attaque principale)
8. **⚡ LIGHTNING_STATIC** - 15 dégâts (zone)
9. **❄️ ICE** - 12 dégâts (attaque principale)
10. **💧 WATER** - 8 dégâts (attaque principale)
11. **💨 GAS** - 8 dégâts (attaque principale)
12. **💨 GAS_STATIC** - 5 dégâts (zone)
13. **🧊💨 GAS_BLOCK** - 5 dégâts (zone 45s)
14. **💧 WATER_STATIC** - 2 dégâts (zone passive)
15. **❄️ ICE_STATIC** - 2 dégâts (zone passive)

---

## 💡 Stratégies Recommandées

### 🔥💥💥 Combo MEGA EXPLOSION (Combo 3 Éléments)
**Setup :**
1. Lancer du gaz
2. Lancer de la glace dessus → Crée un bloc de gaz gelé
3. Lancer du feu OU de l'électricité sur le bloc gelé
4. **Résultat** : **MEGA EXPLOSION** - 45 dégâts, 280px de rayon !

### Combo Offensif Maximum
1. Poser du gaz derrière soi
2. Lancer de l'électricité dedans
3. **Résultat**: Explosion de feu (30 dégâts) + zone électrique

### Combo Défensif
1. Lancer de l'eau au sol
2. Lancer de la glace dessus
3. **Résultat**: Mur de glace statique (2 dégâts passifs)

### Combo Zone Control
1. Spammer du gaz (CD 0.4s)
2. Créer des trainées de gaz partout
3. **Résultat**: Zone toxique persistante (10s)

### Combo Burst Damage
1. Lancer du feu
2. Lancer de l'électricité au même endroit
3. **Résultat**: PLASMA ultra-puissant (37 dégâts en 0.5s)
