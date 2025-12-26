CREATE SCHEMA IF NOT EXISTS public;

DROP TABLE IF EXISTS public.cryptomonnaies CASCADE;

CREATE TABLE public.cryptomonnaies (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    symbole VARCHAR(10) NOT NULL UNIQUE,
    date_creation DATE,
    status VARCHAR(50)
);

DROP TABLE public.utilisateurs CASCADE;
CREATE TABLE utilisateurs (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(100),
    email VARCHAR(100),
    date_inscription DATE,
    status VARCHAR(20)
);
=
DROP TABLE IF EXISTS public.paire_trading CASCADE;

CREATE TABLE public.paire_trading (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    crypto_base   VARCHAR(10) NOT NULL,
    crypto_contre VARCHAR(10) NOT NULL,

    status VARCHAR(50),
    date_ouverture DATE,

    CONSTRAINT fk_paire_crypto_base
        FOREIGN KEY (crypto_base)
        REFERENCES public.cryptomonnaies(symbole),

    CONSTRAINT fk_paire_crypto_contre
        FOREIGN KEY (crypto_contre)
        REFERENCES public.cryptomonnaies(symbole),

);


-- Table principale (partition parent)
DROP TABLE IF EXISTS ordres CASCADE;
CREATE TABLE ordres (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    date_creation TIMESTAMP NOT NULL,

    utilisateur_id INTEGER NOT NULL,
    paire_id INTEGER NOT NULL,
    type_ordre VARCHAR(20),
    quantite DECIMAL(20,8),
    prix DECIMAL(20,5),
    statut VARCHAR(50),
    mode VARCHAR(20),

    CONSTRAINT pk_ordres PRIMARY KEY (id, date_creation),
    CONSTRAINT fk_ordres_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id),
    CONSTRAINT fk_ordres_paire FOREIGN KEY (paire_id) REFERENCES paire_trading(id)
) PARTITION BY RANGE (date_creation);

--par date:
CREATE TABLE ordres_2025_12 PARTITION OF ordres
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');


DROP TABLE IF EXISTS trades CASCADE;

CREATE TABLE trades (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    ordre_id INTEGER NOT NULL,
    ordre_date_creation TIMESTAMP NOT NULL,
    prix DECIMAL(20,5),
    quantite DECIMAL(20,8),
    date_execution TIMESTAMP NOT NULL,

    CONSTRAINT pk_trades PRIMARY KEY (id, date_execution),

    CONSTRAINT fk_trades_ordre
        FOREIGN KEY (ordre_id, ordre_date_creation)
        REFERENCES ordres(id, date_creation)
) PARTITION BY RANGE (date_execution);
--date execution:
CREATE TABLE trades_2025_12 PARTITION OF trades
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE public.portefeuilles (
    id SERIAL PRIMARY KEY,
    utilisateur_id INTEGER NOT NULL,
    crypto_id INTEGER NOT NULL,
    solde_total DECIMAL(20,8),
    solde_bloque DECIMAL(20,8),
    date_maj DATE,
    CONSTRAINT fk_portefeuille_user
        FOREIGN KEY (utilisateur_id)
        REFERENCES public.utilisateurs(id),
    CONSTRAINT fk_portefeuille_crypto
        FOREIGN KEY (crypto_id)
        REFERENCES public.cryptomonnaies(id),
    CONSTRAINT unq_portefeuille UNIQUE (utilisateur_id, crypto_id)
);
DROP TABLE public.statistique_marche CASCADE;
CREATE TABLE public.prix_marche (
     id BIGINT GENERATED ALWAYS AS IDENTITY,
    paire_id INTEGER NOT NULL,
    prix DECIMAL(20,5),
    volume DECIMAL(20,8),
    date_maj DATE,
    CONSTRAINT fk_prix_paire
        FOREIGN KEY (paire_id)
        REFERENCES public.paire_trading(id)
);


DROP TABLE public.statistique_marche CASCADE;

CREATE TABLE public.statistique_marche (
    id SERIAL PRIMARY KEY,
    paire_id INTEGER NOT NULL,
    indicateur VARCHAR(20),
    valeur DECIMAL(20,8),
    periode VARCHAR(10) NOT NULL,
    date_maj DATE,
    CONSTRAINT fk_stat_paire
        FOREIGN KEY (paire_id)
        REFERENCES public.paire_trading(id)
);

CREATE TYPE audit_action_type AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE'
);

DROP TABLE IF EXISTS audit_trail CASCADE;

CREATE TABLE audit_trail (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    table_cible VARCHAR(50) NOT NULL,
    ordre_id INTEGER,
    action audit_action_type NOT NULL,
    utilisateur_id INTEGER,
    date_action TIMESTAMP NOT NULL,
    details TEXT,
    trade_id INTEGER,

    CONSTRAINT pk_audit PRIMARY KEY (id, action),

    CONSTRAINT fk_audit_user
        FOREIGN KEY (utilisateur_id)
        REFERENCES utilisateurs(id)

) PARTITION BY LIST (action);

--partition par insert
CREATE TABLE audit_trail_insert
PARTITION OF audit_trail
FOR VALUES IN ('INSERT');
--partition par update:
CREATE TABLE audit_trail_update
PARTITION OF audit_trail
FOR VALUES IN ('UPDATE');
--par delete:
CREATE TABLE audit_trail_delete
PARTITION OF audit_trail
FOR VALUES IN ('DELETE');




DROP TABLE IF EXISTS public.detection_anomalie CASCADE;
CREATE TABLE public.detection_anomalie (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50),
    ordre_id INTEGER,
    utilisateur_id INTEGER,
    date_detection TIMESTAMP,
    commentaire TEXT,
    score_risque INTEGER,
    CONSTRAINT fk_anomalie_ordre
        FOREIGN KEY (ordre_id)
        REFERENCES public.ordres(id),
    CONSTRAINT fk_anomalie_user
        FOREIGN KEY (utilisateur_id)
        REFERENCES public.utilisateurs(id)
);


