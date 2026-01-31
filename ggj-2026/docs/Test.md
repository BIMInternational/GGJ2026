Voici un fichier .md (Markdown) structuré de manière professionnelle. Ce document est conçu pour être lu par un humain (ton équipe) ou par un assistant de code (Copilot/ChatGPT) afin de générer le code source directement.

Spécifications Techniques : Système de Combat Systémique (Godot 4)
1. Vision du Projet
Développer un système de combat modulaire basé sur des Masques. Chaque masque définit une attaque avec des propriétés élémentaires. Le cœur du gameplay repose sur la chimie émergente : les attaques interagissent physiquement entre elles via des collisions d'aires (Area2D/3D).

2. Architecture de Données (Resources)
L'attaque n'est pas codée en dur, elle est définie par une Resource.

Fichier : AttackData.gd

element_type : (Enum : NONE, FIRE, GAS, WATER, ELECTRIC, WIND)

damage : float

range_distance : float (distance d'apparition par rapport au joueur)

dissipation_time : float (durée de vie de la zone)

cooldown : float

speed : float (0 = statique, >0 = projectile)

visual_effect : PackedScene (Particules/Sprites)

3. Le Template d'Attaque (Scene)
Une scène unique AttackInstance.tscn (Area2D) gère toutes les attaques du jeu.

Logique du script :

Initialisation : Reçoit une AttackData et configure son apparence et ses stats.

Mouvement : Si speed > 0, se déplace dans la direction du regard.

Détection : Utilise le signal area_entered.

Signalement : Si l'aire entrée est une autre AttackInstance, appelle le ChemistryManager.

4. Le Gestionnaire d'Interactions (Autoload/Singleton)
Le ChemistryManager.gd contient la table de vérité des réactions.

Interactions prioritaires à implémenter :

FIRE + GAS : Supprimer les deux -> Instancier Explosion_AOE.

WATER + ELECTRIC : Appliquer un multiplicateur de taille à l'aire électrique.

WIND + (FIRE/GAS) : Modifier le vecteur de vélocité de l'élément touché.

5. Système de Masques (Player)
Le joueur possède un inventaire de AttackData.

current_mask_index : Int

Input "ChangeMask" : Incrémente l'index.

Input "Attack" :

Vérifie le cooldown.

Instancie AttackInstance.tscn.

Injecte la AttackData du masque actuel.

🛠 Étapes d'implémentation (Trame de travail)
Phase 1 (Data) : Créer le script AttackData.gd et générer deux fichiers .tres (un pour le Feu, un pour le Gaz).

Phase 2 (Physique) : Créer la scène AttackInstance capable de s'auto-détruire après dissipation_time.

Phase 3 (Chimie) : Coder le Singleton ChemistryManager avec une fonction resolve(area_a, area_b).

Phase 4 (Player) : Coder le switch de masque et le spawn de l'attaque à la position du joueur + range_distance.