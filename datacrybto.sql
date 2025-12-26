
ALTER TABLE public.cryptomonnaies
ADD CONSTRAINT unq_crypto_symbole UNIQUE (symbole);

ALTER TABLE public.paire_trading
ADD CONSTRAINT fk_paire_crypto_base_symbole
FOREIGN KEY (crypto_base)
REFERENCES public.cryptomonnaies(symbole);

ALTER TABLE public.paire_trading
ADD CONSTRAINT fk_paire_crypto_contre_symbole
FOREIGN KEY (crypto_contre)
REFERENCES public.cryptomonnaies(symbole);

ALTER TABLE public.utilisateurs
ADD CONSTRAINT chk_utilisateurs_statut
CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BLOCKED'));


ALTER TABLE public.utilisateurs
ADD CONSTRAINT unq_utilisateurs_email
UNIQUE (email);

-- Empêche deux cryptos d’avoir le même symbole (BTC, ETH…)

ALTER TABLE public.paire_trading
ADD CONSTRAINT unq_paire_trading
UNIQUE (crypto_base, crypto_contre);

ALTER TABLE public.paire_trading
ADD CONSTRAINT chk_paire_diff
CHECK (crypto_base <> crypto_contre);

ALTER TABLE public.paire_trading
ADD CONSTRAINT chk_paire_statut
CHECK (status IN ('ACTIVE', 'SUSPENDED', 'DELISTED'));


ALTER TABLE public.portefeuilles
ADD CONSTRAINT fk_portefeuille_user
FOREIGN KEY (utilisateur_id)
REFERENCES utilisateurs(id);

-- Lien entre le portefeuille et la crypto
ALTER TABLE public.portefeuilles
ADD CONSTRAINT fk_portefeuille_crypto
FOREIGN KEY (crypto_id)
REFERENCES cryptomonnaies(id);

-- Un utilisateur ne peut avoir qu’un seul portefeuille par crypto
ALTER TABLE public.portefeuilles
ADD CONSTRAINT unq_portefeuille_user_crypto
UNIQUE (utilisateur_id, crypto_id);

-- Empêche un solde négatif
ALTER TABLE public.portefeuilles
ADD CONSTRAINT chk_solde_coherent
CHECK (solde_total >= solde_bloque AND solde_bloque >= 0);


ALTER TABLE public.ordres
ADD CONSTRAINT chk_ordres_mode
CHECK (mode IN ('LIMIT', 'MARKET'));


-- Limite le sens de l’ordre (achat ou vente)
ALTER TABLE public.ordres
ADD CONSTRAINT chk_ordres_sens
CHECK (type_ordre IN ('BUY', 'SELL'));

-- Limite les statuts possibles d’un ordre
ALTER TABLE public.ordres
ADD CONSTRAINT chk_ordre_statut
CHECK (statut IN ('OPEN', 'PARTIAL', 'FILLED', 'CANCELED'));

-- Empêche des quantités incohérentes
ALTER TABLE public.ordres
ADD CONSTRAINT chk_ordre_quantite
CHECK (quantite >= 0);

-- Règle métier :
-- LIMIT → prix obligatoire
-- MARKET → prix interdit (NULL)
ALTER TABLE public.ordres
ADD CONSTRAINT chk_prix_limit_market
CHECK (
    (mode = 'LIMIT' AND prix IS NOT NULL AND prix > 0)
    OR
    (mode = 'MARKET' AND prix IS NULL)
);


ALTER TABLE public.trades
ADD CONSTRAINT fk_trade_ordre
FOREIGN KEY (ordre_id)
REFERENCES ordres(id);




ALTER TABLE public.trades
ADD CONSTRAINT chk_trade_prix
CHECK (prix> 0);

ALTER TABLE public.trades
ADD CONSTRAINT chk_trade_quantite
CHECK (quantite > 0);

ALTER TABLE public.prix_marche
ADD CONSTRAINT fk_prix_paire
FOREIGN KEY (paire_id)
REFERENCES paire_trading(id);

ALTER TABLE prix_marche
ADD CONSTRAINT chk_prix_positive
CHECK (prix > 0);

ALTER TABLE prix_marche
ADD CONSTRAINT chk_volume_positive
CHECK (volume >= 0);

ALTER TABLE public.statistique_marche
ADD CONSTRAINT fk_stat_paire
FOREIGN KEY (paire_id)
REFERENCES paire_trading(id);

ALTER TABLE public.statistique_marche
ADD CONSTRAINT chk_stat_indicateur
CHECK (indicateur IN ('RSI', 'VWAP', 'VOLATILITE'));

ALTER TABLE public.statistique_marche
ADD CONSTRAINT chk_stat_valeur
CHECK (
    (indicateur = 'RSI' AND valeur BETWEEN 0 AND 100)
    OR
    (indicateur IN ('VWAP', 'VOLATILITE') AND valeur >= 0)
);

ALTER TABLE public.statistique_marche
ALTER COLUMN date_maj
TYPE TIMESTAMPTZ
USING date_maj::timestamptz;

ALTER TABLE public.statistique_marche
ADD CONSTRAINT unq_stat_unique
UNIQUE (paire_id, indicateur, periode, date_maj);


ALTER TABLE public.detection_anomalie
ADD CONSTRAINT chk_score_risque
CHECK (score_risque BETWEEN 0 AND 100);

ALTER TABLE public.audit_trail
ADD CONSTRAINT fk_audit_user
FOREIGN KEY (utilisateur_id)
REFERENCES utilisateurs(id);

--indexation:

CREATE INDEX idx_utilisateurs_email
ON utilisateurs(email);

CREATE INDEX idx_utilisateurs_statut
ON utilisateurs(status);


CREATE INDEX idx_paire_crypto
ON paire_trading(crypto_base, crypto_contre);

CREATE INDEX idx_paire_active
ON paire_trading(id)
WHERE status = 'ACTIVE';


CREATE INDEX idx_ordres_user
ON ordres(utilisateur_id);

CREATE INDEX idx_ordres_paire_statut
ON ordres(paire_id, statut);

CREATE INDEX idx_ordres_type
ON ordres(type_ordre);

CREATE INDEX idx_ordres_open
ON ordres(paire_id, prix, date_creation)
WHERE statut IN ('OPEN', 'PARTIAL');

--historique, graphiques
CREATE INDEX idx_trades_date
ON trades(date_execution);

-- trades par paire (VWAP, RSI)
CREATE INDEX idx_trades_paire_date
ON trades(paire_id, date_execution);

CREATE INDEX idx_trades_ordres
ON trades(ordre_id_achat, ordre_id_vente);

-- prix courant par paire (temps réel)
CREATE UNIQUE INDEX idx_prix_paire_unique
ON prix_marche(paire_id);

-- statistiques par paire
CREATE INDEX idx_stat_paire
ON statistique_marche(paire_id);

-- indicateur + période (RSI, VWAp)
CREATE INDEX idx_stat_indicateur
ON statistique_marche(indicateur, periode);

--récupération dernière stat
CREATE INDEX idx_stat_latest
ON statistique_marche(paire_id, indicateur, date_maj DESC);

-- audit par date (logs)
CREATE INDEX idx_audit_date
ON audit_trail(date_action);

-- audit par utilisateur
CREATE INDEX idx_audit_user
ON audit_trail(utilisateur_id);

-- table ciblée (ordre / trade / portefeuille)
CREATE INDEX idx_audit_table
ON audit_trail(table_cible);

--insertion data:

INSERT INTO utilisateurs (nom, email, date_inscription, status)
SELECT
    'exemp_' || i,
    'exemp' || i || '@mail.com',
    CURRENT_DATE - (i % 365),
    'ACTIVE'
FROM generate_series(1,34000) i;
SELECT COUNT(*) FROM utilisateurs;

INSERT INTO cryptomonnaies (nom, symbole, date_creation, status)
SELECT 
    'Crypto_' || i,
    'C' || i,
    CURRENT_DATE,
    'ACTIVE'
FROM generate_series(1,34000) i
ON CONFLICT (symbole) DO NOTHING;

SELECT COUNT(*) FROM cryptomonnaies;

INSERT INTO paire_trading (crypto_base, crypto_contre, status, date_ouverture)
SELECT 
    c1.symbole,
    c2.symbole,
    'ACTIVE',
    CURRENT_DATE
FROM cryptomonnaies c1
JOIN cryptomonnaies c2 
    ON c1.id < c2.id 
LIMIT 1000;         

SELECT *FROM paire_trading ;

-- Utiliser des IDs réels existants
INSERT INTO ordres (utilisateur_id, paire_id, type_ordre, mode, quantite, prix, statut, date_creation)
SELECT
    (i % 1000) + 1,
    (SELECT id FROM paire_trading ORDER BY id LIMIT 1 OFFSET (i % (SELECT COUNT(*) FROM paire_trading))),
    CASE WHEN i % 2 = 0 THEN 'BUY' ELSE 'SELL' END,
    'LIMIT',
    random()*10,
    random()*50000,
    'OPEN',
    NOW()
FROM generate_series(1,1000) i;
SELECT COUNT(*) FROM ordres;

INSERT INTO trades (ordre_id, prix, quantite, date_execution)
SELECT
    id,                   
    random()*50000,       
    random()*5,           
    NOW()                 
FROM ordres
LIMIT 1000;
SELECT COUNT(*) FROM trades;

INSERT INTO statistique_marche (paire_id, indicateur, valeur, periode, date_maj)
SELECT
    (i % 500) + 1,
    'RSI',
    random()*100,
    '24h',
    NOW() + (i || ' seconds')::interval
FROM generate_series(1,1000) i;

SELECT COUNT(*) FROM statistique_marche ;


INSERT INTO detection_anomalie (type, ordre_id, utilisateur_id, date_detection, commentaire, score_risque)
SELECT
    'WASH_TRADING',
    o.id,  -- ID réel d'ordre
    o.utilisateur_id,
    NOW() + (ROW_NUMBER() OVER () || ' seconds')::interval,
    'Suspicious activity',
    (random()*100)::int
FROM ordres o
LIMIT 1000;
SELECT COUNT(*) FROM detection_anomalie ;


INSERT INTO prix_marche (paire_id, prix, volume, date_maj)
SELECT
    pt.id,
    30000 + random()*20000,   
    1 + random()*100,         
    CURRENT_DATE
FROM paire_trading pt
CROSS JOIN generate_series(1,34);
SELECT COUNT(*) FROM prix_marche WHERE paire_id = 1000;

