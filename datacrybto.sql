
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

