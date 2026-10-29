# 🌿 EcoCity — Plateforme Participative d'Écologie Urbaine

**EcoCity** est une application mobile et web participative développée avec **Flutter** et **Supabase**. Elle permet aux citoyens, aux associations et aux municipalités de collaborer activement pour assainir l'espace public en signalant et en suivant en temps réel les dépôts sauvages, poubelles débordantes et zones polluées.

---

## 🎯 1. La Vision Globale du Projet

L'application fonctionne comme une plateforme d'action citoyenne et communautaire :

1. **Signalement en 2 secondes** : Les citoyens signalent un problème environnemental sur le terrain soit via un formulaire rapide, soit directement en discutant avec un assistant intelligent.
2. **EcoBot (Assistant IA de terrain)** : Un chatbot interactif qui comprend le langage naturel, catégorise automatiquement le problème, extrait les coordonnées GPS et guide l'utilisateur vers les bonnes démarches écologiques.
3. **EcoMap (Carte interactive en temps réel)** : Affiche l'état écologique de la ville en direct grâce au moteur **Supabase Realtime** avec un code couleur clair par statut d'intervention.
4. **Mobilisation citoyenne** : La communauté vote (upvotes) pour prioriser les urgences, suit l'avancement des interventions et valide les zones nettoyées.

---

## 🏗️ 2. Architecture & Technologies

| Couche | Technologie | Rôle |
|---|---|---|
| **Frontend** | [Flutter 3.x](https://flutter.dev/) (Dart) | Interface multiplateforme moderne (Web, Android, iOS, Desktop) |
| **Backend & Base de données** | [Supabase](https://supabase.com/) (PostgreSQL) | Stockage des signalements, authentification et sécurité (RLS) |
| **Temps Réel** | Supabase Realtime | Synchronisation automatique instantanée de la carte et des compteurs |
| **Cartographie** | Leaflet / OpenStreetMap | Affichage interactif fluide sans coût d'API propriétaire |
| **Assistant IA** | Service EcoBot (OpenAI / Heuristique) | Analyse sémantique des signalements et conseils écologiques |
| **Géolocalisation** | `geolocator` | Récupération automatique des coordonnées GPS sur le terrain |

---

## 📱 3. Description Détaillée de Chaque Page

### 🔐 A. Authentification (`login_page.dart` & `signup_page.dart`)
* **Connexion (`LoginPage`)** : Authentification sécurisée par e-mail et mot de passe connectée à Supabase Auth.
* **Inscription (`SignupPage`)** : Création de compte citoyen avec validation des entrées (e-mail valide, confirmation du mot de passe).
* **Design** : Charte graphique soignée associant le vert écologique au thème EMSI, transitions fluides et gestion des erreurs de connexion.

---

### 🏠 B. Tableau de Bord d'Accueil (`eco_home_page.dart`)
Page centrale après connexion, offrant une vue d'ensemble sur l'action écologique :
* **Bandeau de statistiques en direct** : Affiche en temps réel le nombre total d'urgences signalées (🔴), d'actions en cours (🟠) et de zones nettoyées (🟢).
* **Cartes d'accès rapide** :
  * Accès direct à l'**EcoBot** pour échanger ou signaler par message.
  * Accès à l'**EcoMap** pour explorer la carte de la ville.
* **Top Signalements Prioritaires** : Classement dynamique des signalements les plus urgents ayant reçu le plus de votes de la communauté.
* **Boutons d'action flottants (FAB)** : Accès instantané à l'EcoBot ou au formulaire de déclaration.
* **Menu latéral (Drawer)** : Profil utilisateur, navigation et déconnexion sécurisée.

---

### 🤖 C. L'Assistant Terrain EcoBot (`chatbot_page.dart`)
Un chatbot intelligent qui dépasse le simple moteur de recherche textuel :
* **Signalement conversationnel ultra-rapide** : L'utilisateur peut simplement écrire : *"Il y a un tas de pneus abandonné près du boulevard d'Anfa"*. L'EcoBot détecte automatiquement la catégorie (encombrants/pneus), récupère la position GPS et propose de créer le signalement en un clic.
* **Conseils écologiques & orientation** : Répond aux questions du citoyen (ex : *Où jeter des piles usagées ? Comment trier le plastique ? Que faire en cas de fuite d'eau polluée ?*).
* **Suggestions en bulles d'action** : Questions fréquentes pré-configurées pour un usage rapide sur smartphone.
* **Bouton d'effacement de l'historique** et interface façon messagerie moderne.

---

### 🗺️ D. La Carte Interactive EcoMap (`eco_map_page.dart` & `eco_map_view_web.dart`)
La vue géographique globale de l'état environnemental de la ville :
* **Marqueurs visuels par statut** :
  * 🔴 **Signalé** : Problème écologique déclaré en attente de prise en charge.
  * 🟠 **En cours** : Équipe municipale ou action citoyenne en cours de nettoyage.
  * 🟢 **Résolu** : Zone réhabilitée et nettoyée.
* **Position de l'utilisateur** : Marqueur dynamique pulsant indiquant la position GPS actuelle.
* **Barre de filtres horizontaux** : Permet de filtrer en un clic par statut pour isoler les urgences non traitées.
* **Mode Realtime** : Dès qu'un citoyen ou agent met à jour un signalement, le marqueur change instantanément de couleur sur la carte pour tous les utilisateurs sans rechargement.
* **Fiche détaillée (Bottom Sheet)** : En cliquant sur un marqueur, une fiche complète apparaît avec description, date, catégorie, vote citoyen (`+1 Upvote`) et bouton de mise à jour du statut.

---

### ✍️ E. Formulaire Manuel de Signalement (`report_form_page.dart`)
Pour les utilisateurs préférant la méthode de saisie classique :
* **Sélecteur visuel de catégories** : Dépôt sauvage, Poubelles débordantes, Encombrants, Eaux usées, Plastique, etc.
* **Détection GPS en direct** : Affiche les coordonnées actuelles avec indicateur d'exactitude.
* **Champs Titre & Description** : Saisie des détails et consignes particulières.
* **Validation & Envoi** : Création atomique dans la base Supabase et notification instantanée.

---

## 🗄️ 4. Structure de la Base de Données (`reports`)

La table `reports` dans Supabase contient les colonnes suivantes :

| Champ | Type | Description |
|---|---|---|
| `id` | `UUID` | Identifiant unique généré automatiquement |
| `user_id` | `UUID` | Référence au citoyen connecté (`auth.users`) |
| `title` | `TEXT` | Titre du signalement |
| `description` | `TEXT` | Détail ou contexte du problème |
| `category` | `TEXT` | Catégorie (`depot_sauvage`, `poubelle`, `eau`, etc.) |
| `latitude` | `DOUBLE` | Coordonnée GPS Latitude |
| `longitude` | `DOUBLE` | Coordonnée GPS Longitude |
| `status` | `TEXT` | État : `'signale'`, `'en_cours'`, `'resolu'` |
| `upvotes` | `INTEGER` | Nombre de soutiens reçus par la communauté |
| `created_at` | `TIMESTAMPTZ` | Horodatage de création |

Le script SQL complet avec activation du **Realtime**, sécurité **RLS** et **données de test** est disponible dans [`supabase_reports_setup.sql`](supabase_reports_setup.sql).

---

## 🚀 5. Installation et Lancement

### Prérequis
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.20+)
* Un compte [Supabase](https://supabase.com/)

### Étape 1 : Configuration de Supabase
1. Créez un projet sur Supabase.
2. Ouvrez l'onglet **SQL Editor** dans Supabase.
3. Copiez-collez et exécutez le script [`supabase_reports_setup.sql`](supabase_reports_setup.sql).
4. Renseignez votre `SUPABASE_URL` et votre `SUPABASE_PUBLISHABLE_KEY` dans le fichier local `supabase_config.json`.

### Étape 2 : Lancement de l'application
```powershell
# 1. Télécharger les dépendances
flutter pub get

# 2. Vérifier le code
flutter analyze

# 3. Lancer l'application (navigateur Chrome ou Edge)
flutter run -d chrome --dart-define-from-file=supabase_config.json
```
