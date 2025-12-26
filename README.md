# CryptoTrade 
## 1. Présentation Générale

CryptoTrade est une plateforme de trading de cryptomonnaies conçue pour supporter
un très grand volume d’ordres et de transactions en temps réel, tout en garantissant
la cohérence des données, la performance et la traçabilité.

La base de données PostgreSQL constitue le cœur du système et assure :
- La gestion des utilisateurs et de leurs portefeuilles
- Le traitement des ordres d’achat et de vente
- L’exécution des trades
- Le suivi des prix et indicateurs de marché
- L’audit et la détection d’anomalies

---

## 2. Objectifs Techniques

- Gérer des milliers à millions d’ordres quotidiens
- Réduire la latence des requêtes critiques
- Permettre des analyses financières avancées
- Garantir l’intégrité et la traçabilité des données
- Optimiser PostgreSQL via indexation, partitionnement et monitoring

---

## 3. Modèle de Données (MLD)

Le modèle logique de données repose sur **10 tables principales** :

- utilisateurs  
- cryptomonnaies  
- paire_trading  
- ordres  
- trades  
- portefeuilles  
- prix_marche  
- statistique_marche  
- detection_anomalie  
- audit_trail  

<img width="1625" height="892" alt="image" src="https://github.com/user-attachments/assets/1d5dadb7-b0ff-4591-b463-6e74858a6d2e" />


---

## 4. Description des Tables

### 4.1 utilisateurs
Stocke les informations des utilisateurs de la plateforme.

- email unique
- statut contrôlé (ACTIVE, SUSPENDED, BLOCKED)
- lien avec ordres, portefeuilles, anomalies et audit

---

### 4.2 cryptomonnaies
Catalogue des cryptomonnaies disponibles pour le trading.

- symbole unique (BTC, ETH…)
- utilisé dans les paires de trading et les portefeuilles

---

### 4.3 paire_trading
Définit les marchés de trading (ex : BTC/USDT).

- composée de deux cryptomonnaies
- empêche les paires incohérentes
- statut de disponibilité du marché

---

### 4.4 ordres
Représente les ordres Buy / Sell des utilisateurs.

- partitionnée par date_creation
- règles métier strictes (LIMIT / MARKET)
- fortement indexée pour le carnet d’ordres


### 4.5 trades
Correspond aux exécutions réelles issues des ordres.

- lié aux ordres via clé composite
- partitionné par date_execution
- utilisé pour les calculs analytiques


### 4.6 portefeuilles
Gère les soldes des utilisateurs par cryptomonnaie.

- un portefeuille par crypto et utilisateur
- empêche les soldes incohérents ou négatifs


### 4.7 prix_marche
Historique des prix et volumes par paire de trading.

- base des calculs RSI, VWAP et volatilité
- utilisé pour les analyses temporelles


### 4.8 statistique_marche
Stocke les indicateurs calculés.

- RSI
- VWAP
- Volatilité
- unicité par paire, indicateur, période et date


### 4.9 detection_anomalie
Enregistre les comportements suspects.

- wash trading
- spoofing
- score de risque (0 à 100)


### 4.10 audit_trail
Assure la traçabilité complète des actions.

- partitionné par type d’action (INSERT, UPDATE, DELETE)
- utilisé pour audit et conformité


## 5. Contraintes et Intégrité

- Contraintes d’unicité (email, symbole, paires)
- Contraintes CHECK (statuts, quantités, scores)
- Clés étrangères strictes
- Respect des règles métier du trading


## 6. Fonctions Métier

- calc_rsi : calcul du RSI sur une période donnée
- calc_vwap : calcul du VWAP par paire
- calc_volatilite : mesure de la volatilité

Ces fonctions permettent des analyses financières avancées directement en SQL.


## 7. Analyses SQL Avancées

### Window Functions
- Calculs cumulés (VWAP)
- Analyses temporelles par paire

### LATERAL JOIN
- Statistiques dynamiques par paire
- Dernier prix + indicateurs glissants

### DISTINCT ON
- Récupération rapide du dernier état

## 8. Optimisation PostgreSQL

- Index B-tree ciblés
- Index partiels pour ordres actifs
- Partitionnement des tables volumineuses
- work_mem ajusté pour éviter les temp files


## 10. Jeux de Données de Test et Validation

Afin de valider le bon fonctionnement, la performance et la robustesse de la base de données CryptoTrade, des jeux de données volumineux ont été insérés et exploités.

### 10.1 Insertion de données massives

Les tables principales ont été alimentées avec des données synthétiques réalistes :

- **30 000 utilisateurs** insérés dans la table `utilisateurs`
- **Cryptomonnaies et paires de trading réalistes** dans `cryptomonnaies` et `paire_trading`
- **30 000 ordres** simulant des ordres BUY / SELL avec modes LIMIT et MARKET
- **30 000 lignes de prix de marché** dans `prix_marche`
- **Trades générés automatiquement** à partir des ordres
- Données réparties sur différentes dates afin de tester le partitionnement

Ces volumes permettent de simuler un environnement proche d’une plateforme de trading réelle.

---

### 10.2 Tests des fonctions métier

Les fonctions SQL ont été testées sur les données insérées :

- **calc_vwap** : vérification du calcul du prix moyen pondéré par le volume pour chaque paire
- **calc_rsi** : calcul du RSI sur différentes périodes (ex : 14, 20)
- **calc_volatilite** : mesure de la volatilité sur des fenêtres temporelles variables

Les résultats obtenus confirment la cohérence des calculs et leur capacité à fonctionner sur de grands volumes de données.

---

### 10.3 Tests des index et performances

Plusieurs requêtes de test ont été exécutées afin de mesurer l’impact de l’indexation :

- Sélection des ordres par `utilisateur_id`
- Recherche des ordres actifs par `paire_id` et `statut`
- Récupération du dernier prix par paire
- Calculs analytiques utilisant des **Window Functions**

Les résultats montrent :
- Une réduction significative du temps d’exécution des requêtes
- Une diminution des lectures disque
- Une meilleure exploitation des **Index-Only Scans**

---

### 10.4 Tests de charge et validation

Les tests confirment que :
- La base supporte efficacement plusieurs dizaines de milliers de lignes
- Le partitionnement améliore les performances sur les tables volumineuses
- Les index sont correctement utilisés par le planner PostgreSQL
- Les fonctions analytiques restent performantes même avec des volumes élevés

---

Ces tests valident la capacité de la base de données CryptoTrade à fonctionner dans un contexte de charge réelle tout en conservant des performances élevées.


## 11. Conclusion

La base de données CryptoTrade est :
- Performante
- Scalable
- Sécurisée
- Orientée analyse et audit

Elle constitue une base solide pour une plateforme de trading professionnelle
et extensible.

