--
-- PostgreSQL database dump
--
-- Dumped from database version 15.2
-- Dumped by pg_dump version 15.2
-- Started on 2023-08-04 21:48:27
SET
    statement_timeout = 0;

SET
    lock_timeout = 0;

SET
    idle_in_transaction_session_timeout = 0;

SET
    client_encoding = 'UTF8';

SET
    standard_conforming_strings = on;

SELECT
    pg_catalog.set_config('search_path', '', false);

SET
    check_function_bodies = false;

SET
    xmloption = content;

SET
    client_min_messages = warning;

SET
    row_security = off;

--
-- TOC entry 3455 (class 1262 OID 27150)
-- Name: WinterLift; Type: DATABASE; Schema: -; Owner: postgres
--
CREATE DATABASE "WinterLift" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Italian_Italy.1252';

ALTER DATABASE "WinterLift" OWNER TO postgres;

\ connect "WinterLift"
SET
    statement_timeout = 0;

SET
    lock_timeout = 0;

SET
    idle_in_transaction_session_timeout = 0;

SET
    client_encoding = 'UTF8';

SET
    standard_conforming_strings = on;

SELECT
    pg_catalog.set_config('search_path', '', false);

SET
    check_function_bodies = false;

SET
    xmloption = content;

SET
    client_min_messages = warning;

SET
    row_security = off;

--
-- TOC entry 881 (class 1247 OID 27233)
-- Name: sessoenum; Type: TYPE; Schema: public; Owner: postgres
--
CREATE TYPE public.sessoenum AS ENUM ('M', 'F');

ALTER TYPE public.sessoenum OWNER TO postgres;

--
-- TOC entry 869 (class 1247 OID 27182)
-- Name: tipoimpianto; Type: TYPE; Schema: public; Owner: postgres
--
CREATE TYPE public.tipoimpianto AS ENUM ('Seggiovia', 'Cabinovia');

ALTER TYPE public.tipoimpianto OWNER TO postgres;

--
-- TOC entry 232 (class 1255 OID 27306)
-- Name: controllo_esistenza_cabinvoia(); Type: FUNCTION; Schema: public; Owner: postgres
--
CREATE FUNCTION public.controllo_esistenza_cabinvoia() RETURNS trigger LANGUAGE plpgsql AS $ $ BEGIN IF NEW.Impianto = (
    SELECT
        Impianto
    FROM
        Cabinovia
    where
        NEW.Impianto = Cabinovia.Impianto
        and NEW.Comprensorio = Cabinovia.Comprensorio
) THEN RAISE EXCEPTION 'Un impianto non puo essere sia cabinovia che seggiovia';

END IF;

RETURN NEW;

END;

$ $;

ALTER FUNCTION public.controllo_esistenza_cabinvoia() OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 27308)
-- Name: controllo_esistenza_seggiovia(); Type: FUNCTION; Schema: public; Owner: postgres
--
CREATE FUNCTION public.controllo_esistenza_seggiovia() RETURNS trigger LANGUAGE plpgsql AS $ $ BEGIN IF NEW.Impianto = (
    SELECT
        Impianto
    FROM
        Seggiovia
    where
        NEW.Impianto = Seggiovia.Impianto
        and NEW.Comprensorio = Seggiovia.Comprensorio
) THEN RAISE EXCEPTION 'Un impianto non puo essere sia cabinovia che seggiovia';

END IF;

RETURN NEW;

END;

$ $;

ALTER FUNCTION public.controllo_esistenza_seggiovia() OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 27310)
-- Name: controllo_operativita_impianto_passaggio(); Type: FUNCTION; Schema: public; Owner: postgres
--
CREATE FUNCTION public.controllo_operativita_impianto_passaggio() RETURNS trigger LANGUAGE plpgsql AS $ $ BEGIN IF NEW.Impianto = (
    SELECT
        impianto
    from
        manutenzione M
    where
        M.impianto = NEW.impianto
        and M.comprensorio = NEW.comprensorio
        and New.data_ora >= M.Data_inizio
        and (
            M.Data_fine IS NULL
            or M.Data_fine >= NEW.data_ora
        )
    group by
        Impianto
) THEN RAISE EXCEPTION 'Passaggio non attuabile, impianto sotto manutenzione';

END IF;

RETURN NEW;

END;

$ $;

ALTER FUNCTION public.controllo_operativita_impianto_passaggio() OWNER TO postgres;

--
-- TOC entry 231 (class 1255 OID 27304)
-- Name: controllo_validita_tessera(); Type: FUNCTION; Schema: public; Owner: postgres
--
CREATE FUNCTION public.controllo_validita_tessera() RETURNS trigger LANGUAGE plpgsql AS $ $ BEGIN IF NEW.Data_ora > (
    SELECT
        Data_scadenza
    FROM
        Tessera_sciatore
    where
        NEW.Persona = Tessera_sciatore.Proprietario
) THEN RAISE EXCEPTION 'Tessera scaduta passaggio non attuabile';

END IF;

RETURN NEW;

END;

$ $;

ALTER FUNCTION public.controllo_validita_tessera() OWNER TO postgres;

--
-- TOC entry 230 (class 1255 OID 27302)
-- Name: controllo_valore_manutenzione(); Type: FUNCTION; Schema: public; Owner: postgres
--
CREATE FUNCTION public.controllo_valore_manutenzione() RETURNS trigger LANGUAGE plpgsql AS $ $ BEGIN IF EXTRACT(
    YEAR
    FROM
        NEW.Data_inizio
) < (
    SELECT
        Anno_inaugurazione
    FROM
        Comprensorio C
        join Impianto I on I.Comprensorio = C.Nome
    WHERE
        NEW.Impianto = I.Codice
        and NEW.Comprensorio = I.Comprensorio
) THEN RAISE EXCEPTION 'Valore non valido';

END IF;

RETURN NEW;

END;

$ $;

ALTER FUNCTION public.controllo_valore_manutenzione() OWNER TO postgres;

SET
    default_tablespace = '';

SET
    default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 27171)
-- Name: azienda; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.azienda (
    piva character(11) NOT NULL,
    nome character varying(50) NOT NULL,
    n_dip integer NOT NULL,
    localita_sede character varying(50) NOT NULL,
    provincia_sede character varying(50) NOT NULL
);

ALTER TABLE
    public.azienda OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 27267)
-- Name: cabina; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.cabina (
    cabinovia character(4) NOT NULL,
    comprensorio character varying(50) NOT NULL,
    n_cabina integer NOT NULL,
    capienza integer NOT NULL,
    n_posti_in_piedi integer NOT NULL,
    peso double precision NOT NULL
);

ALTER TABLE
    public.cabina OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 27257)
-- Name: cabinovia; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.cabinovia (
    impianto character(4) NOT NULL,
    comprensorio character varying(50) NOT NULL,
    n_funi integer NOT NULL
);

ALTER TABLE
    public.cabinovia OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 27166)
-- Name: comprensorio; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.comprensorio (
    nome character varying(50) NOT NULL,
    anno_inaugurazione integer NOT NULL
);

ALTER TABLE
    public.comprensorio OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 27287)
-- Name: passaggio; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.passaggio (
    persona character(16) NOT NULL,
    data_ora timestamp without time zone NOT NULL,
    impianto character(4) NOT NULL,
    comprensorio character varying(50) NOT NULL
);

ALTER TABLE
    public.passaggio OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 27586)
-- Name: frequentatori_comprensorio; Type: VIEW; Schema: public; Owner: postgres
--
CREATE VIEW public.frequentatori_comprensorio AS
SELECT
    passaggio.comprensorio,
    passaggio.persona
FROM
    public.passaggio
GROUP BY
    passaggio.comprensorio,
    passaggio.persona;

ALTER TABLE
    public.frequentatori_comprensorio OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 27202)
-- Name: gestione; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.gestione (
    azienda character(11) NOT NULL,
    comprensorio character varying(50) NOT NULL,
    quota double precision NOT NULL
);

ALTER TABLE
    public.gestione OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 27187)
-- Name: impianto; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.impianto (
    codice character(4) NOT NULL,
    comprensorio character varying(50) NOT NULL,
    altitudine_partenza integer NOT NULL,
    altitudine_arrivo integer NOT NULL,
    tipo public.tipoimpianto NOT NULL,
    localita_impianto character varying(50) NOT NULL,
    provincia_impianto character varying(50) NOT NULL
);

ALTER TABLE
    public.impianto OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 27156)
-- Name: localita; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.localita (
    nome character varying(50) NOT NULL,
    provincia character varying(50) NOT NULL,
    n_abitanti integer NOT NULL
);

ALTER TABLE
    public.localita OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 27217)
-- Name: manutenzione; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.manutenzione (
    impianto character(4) NOT NULL,
    comprensorio character varying(50) NOT NULL,
    data_inizio date NOT NULL,
    data_fine date,
    azienda character(11) NOT NULL,
    costo double precision NOT NULL
);

ALTER TABLE
    public.manutenzione OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 27594)
-- Name: passaggi_per_giorno; Type: VIEW; Schema: public; Owner: postgres
--
CREATE VIEW public.passaggi_per_giorno AS
SELECT
    passaggio.impianto,
    passaggio.comprensorio,
    date_trunc('day' :: text, passaggio.data_ora) AS giorno,
    count(*) AS n_passaggi
FROM
    public.passaggio
GROUP BY
    passaggio.impianto,
    passaggio.comprensorio,
    (date_trunc('day' :: text, passaggio.data_ora));

ALTER TABLE
    public.passaggi_per_giorno OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 27237)
-- Name: persona; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.persona (
    cf character(16) NOT NULL,
    data_nascita date NOT NULL,
    sesso public.sessoenum NOT NULL,
    residenza character varying(50) NOT NULL
);

ALTER TABLE
    public.persona OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 27151)
-- Name: provincia; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.provincia (
    nome character varying(50) NOT NULL,
    superficie double precision NOT NULL,
    is_capoluogo boolean NOT NULL
);

ALTER TABLE
    public.provincia OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 27277)
-- Name: seggiovia; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.seggiovia (
    impianto character(4) NOT NULL,
    comprensorio character varying(50) NOT NULL,
    n_sedili integer NOT NULL
);

ALTER TABLE
    public.seggiovia OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 27608)
-- Name: spese_gestione_per_aziende; Type: VIEW; Schema: public; Owner: postgres
--
CREATE VIEW public.spese_gestione_per_aziende AS
SELECT
    comprensorio.nome,
    gestione.azienda,
    sum(manutenzione.costo) AS costi_totali,
    (
        (
            sum(manutenzione.costo) / (100) :: double precision
        ) * gestione.quota
    ) AS spesa_personale
FROM
    (
        (
            (
                public.manutenzione
                JOIN public.impianto ON (
                    (
                        (impianto.codice = manutenzione.impianto)
                        AND (
                            (impianto.comprensorio) :: text = (manutenzione.comprensorio) :: text
                        )
                    )
                )
            )
            JOIN public.comprensorio ON (
                (
                    (impianto.comprensorio) :: text = (comprensorio.nome) :: text
                )
            )
        )
        JOIN public.gestione ON (
            (
                (comprensorio.nome) :: text = (gestione.comprensorio) :: text
            )
        )
    )
GROUP BY
    comprensorio.nome,
    gestione.azienda,
    gestione.quota;

ALTER TABLE
    public.spese_gestione_per_aziende OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 27247)
-- Name: tessera_sciatore; Type: TABLE; Schema: public; Owner: postgres
--
CREATE TABLE public.tessera_sciatore (
    id_tessera character(12) NOT NULL,
    data_scadenza date NOT NULL,
    prezzo_abbonamento double precision NOT NULL,
    dettagli_assicurativi character varying(256) NOT NULL,
    proprietario character(16) NOT NULL
);

ALTER TABLE
    public.tessera_sciatore OWNER TO postgres;

--
-- TOC entry 3440 (class 0 OID 27171)
-- Dependencies: 217
-- Data for Name: azienda; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.azienda
VALUES
    (
        '12345678901',
        'ACME Corporation',
        100,
        'Bologna',
        'Bologna'
    );

INSERT INTO
    public.azienda
VALUES
    (
        '45678901234',
        'ABC Ltd',
        200,
        'Alessandria',
        'Alessandria'
    );

INSERT INTO
    public.azienda
VALUES
    (
        '65432109876',
        'DEF Corporation',
        80,
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.azienda
VALUES
    (
        '78901234567',
        'GHI Industries',
        150,
        'Bolzano',
        'Bolzano'
    );

INSERT INTO
    public.azienda
VALUES
    (
        '23456789012',
        'JKL Ltd',
        120,
        'Brindisi',
        'Brindisi'
    );

INSERT INTO
    public.azienda
VALUES
    (
        '34567890123',
        'XYZ S.p.A.',
        300,
        'Udine',
        'Udine'
    );

INSERT INTO
    public.azienda
VALUES
    (
        '56789012345',
        'MNO S.r.l.',
        50,
        'Feltre',
        'Belluno'
    );

--
-- TOC entry 3447 (class 0 OID 27267)
-- Dependencies: 224
-- Data for Name: cabina; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.cabina
VALUES
    (
        '0002',
        'Comprensorio del Sella Ronda',
        2,
        8,
        2,
        600
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0002',
        'Comprensorio del Sella Ronda',
        3,
        5,
        1,
        400
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0003',
        'Comprensorio della Valtellina',
        1,
        5,
        1,
        400
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0003',
        'Comprensorio della Valtellina',
        2,
        7,
        1,
        200
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0005',
        'Comprensorio della Val Gardena',
        1,
        5,
        1,
        400
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0006',
        'Comprensorio delle Dolomiti',
        1,
        4,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0006',
        'Comprensorio delle Dolomiti',
        2,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0008',
        'Comprensorio dei Monti Sibillini',
        1,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0008',
        'Comprensorio dei Monti Sibillini',
        2,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0009',
        'Comprensorio dei Monti Lessini',
        1,
        3,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0009',
        'Comprensorio dei Monti Lessini',
        2,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    ('0011', 'Comprensorio del Cervino', 2, 8, 2, 600);

INSERT INTO
    public.cabina
VALUES
    ('0011', 'Comprensorio del Cervino', 3, 5, 1, 400);

INSERT INTO
    public.cabina
VALUES
    ('0011', 'Comprensorio del Cervino', 1, 5, 1, 400);

INSERT INTO
    public.cabina
VALUES
    ('0011', 'Comprensorio del Cervino', 4, 5, 4, 700);

INSERT INTO
    public.cabina
VALUES
    (
        '0014',
        'Comprensorio della Valle d Aosta',
        2,
        7,
        1,
        200
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0014',
        'Comprensorio della Valle d Aosta',
        3,
        5,
        1,
        400
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0014',
        'Comprensorio della Valle d Aosta',
        4,
        4,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0014',
        'Comprensorio della Valle d Aosta',
        1,
        3,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0017',
        'Comprensorio delle Alpi Apuane',
        2,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0017',
        'Comprensorio delle Alpi Apuane',
        1,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0017',
        'Comprensorio delle Alpi Apuane',
        3,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0020',
        'Comprensorio dei Monti Lattari',
        2,
        5,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0020',
        'Comprensorio dei Monti Lattari',
        1,
        3,
        4,
        700
    );

INSERT INTO
    public.cabina
VALUES
    (
        '0020',
        'Comprensorio dei Monti Lattari',
        3,
        5,
        4,
        700
    );

--
-- TOC entry 3446 (class 0 OID 27257)
-- Dependencies: 223
-- Data for Name: cabinovia; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.cabinovia
VALUES
    ('0002', 'Comprensorio del Sella Ronda', 1);

INSERT INTO
    public.cabinovia
VALUES
    ('0003', 'Comprensorio della Valtellina', 2);

INSERT INTO
    public.cabinovia
VALUES
    ('0005', 'Comprensorio della Val Gardena', 1);

INSERT INTO
    public.cabinovia
VALUES
    ('0006', 'Comprensorio delle Dolomiti', 2);

INSERT INTO
    public.cabinovia
VALUES
    ('0008', 'Comprensorio dei Monti Sibillini', 1);

INSERT INTO
    public.cabinovia
VALUES
    ('0009', 'Comprensorio dei Monti Lessini', 3);

INSERT INTO
    public.cabinovia
VALUES
    ('0011', 'Comprensorio del Cervino', 2);

INSERT INTO
    public.cabinovia
VALUES
    ('0014', 'Comprensorio della Valle d Aosta', 3);

INSERT INTO
    public.cabinovia
VALUES
    ('0017', 'Comprensorio delle Alpi Apuane', 2);

INSERT INTO
    public.cabinovia
VALUES
    ('0020', 'Comprensorio dei Monti Lattari', 3);

--
-- TOC entry 3439 (class 0 OID 27166)
-- Dependencies: 216
-- Data for Name: comprensorio; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio del Cervino', 1967);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio del Sella Ronda', 1974);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio della Valtellina', 1964);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio della Valle d Aosta', 1962);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio della Val Gardena', 1976);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio delle Dolomiti', 1973);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio delle Alpi Apuane', 1955);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio dei Monti Sibillini', 1971);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio dei Monti Lessini', 1960);

INSERT INTO
    public.comprensorio
VALUES
    ('Comprensorio dei Monti Lattari', 1968);

--
-- TOC entry 3442 (class 0 OID 27202)
-- Dependencies: 219
-- Data for Name: gestione; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.gestione
VALUES
    ('12345678901', 'Comprensorio del Cervino', 100);

INSERT INTO
    public.gestione
VALUES
    (
        '45678901234',
        'Comprensorio del Sella Ronda',
        100
    );

INSERT INTO
    public.gestione
VALUES
    (
        '12345678901',
        'Comprensorio della Valle d Aosta',
        50
    );

INSERT INTO
    public.gestione
VALUES
    (
        '45678901234',
        'Comprensorio della Valle d Aosta',
        50
    );

INSERT INTO
    public.gestione
VALUES
    ('45678901234', 'Comprensorio delle Dolomiti', 50);

INSERT INTO
    public.gestione
VALUES
    ('12345678901', 'Comprensorio delle Dolomiti', 50);

INSERT INTO
    public.gestione
VALUES
    (
        '65432109876',
        'Comprensorio dei Monti Sibillini',
        30
    );

INSERT INTO
    public.gestione
VALUES
    (
        '45678901234',
        'Comprensorio dei Monti Sibillini',
        30
    );

INSERT INTO
    public.gestione
VALUES
    (
        '34567890123',
        'Comprensorio dei Monti Sibillini',
        40
    );

INSERT INTO
    public.gestione
VALUES
    (
        '45678901234',
        'Comprensorio dei Monti Lattari',
        10
    );

INSERT INTO
    public.gestione
VALUES
    (
        '12345678901',
        'Comprensorio dei Monti Lattari',
        90
    );

INSERT INTO
    public.gestione
VALUES
    (
        '65432109876',
        'Comprensorio dei Monti Lessini',
        100
    );

INSERT INTO
    public.gestione
VALUES
    (
        '23456789012',
        'Comprensorio delle Alpi Apuane',
        50
    );

INSERT INTO
    public.gestione
VALUES
    (
        '45678901234',
        'Comprensorio delle Alpi Apuane',
        50
    );

INSERT INTO
    public.gestione
VALUES
    (
        '65432109876',
        'Comprensorio della Valtellina',
        20
    );

INSERT INTO
    public.gestione
VALUES
    (
        '12345678901',
        'Comprensorio della Valtellina',
        20
    );

INSERT INTO
    public.gestione
VALUES
    (
        '34567890123',
        'Comprensorio della Valtellina',
        20
    );

INSERT INTO
    public.gestione
VALUES
    (
        '56789012345',
        'Comprensorio della Valtellina',
        20
    );

INSERT INTO
    public.gestione
VALUES
    (
        '45678901234',
        'Comprensorio della Valtellina',
        20
    );

--
-- TOC entry 3441 (class 0 OID 27187)
-- Dependencies: 218
-- Data for Name: impianto; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.impianto
VALUES
    (
        '0001',
        'Comprensorio del Cervino',
        2000,
        3000,
        'Seggiovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0002',
        'Comprensorio del Sella Ronda',
        1500,
        2500,
        'Cabinovia',
        'Belluno',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0003',
        'Comprensorio della Valtellina',
        1200,
        2200,
        'Cabinovia',
        'Brescia',
        'Brescia'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0004',
        'Comprensorio della Valle d Aosta',
        1800,
        2800,
        'Seggiovia',
        'Aosta',
        'Aosta'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0005',
        'Comprensorio della Val Gardena',
        1600,
        2600,
        'Cabinovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0006',
        'Comprensorio delle Dolomiti',
        1400,
        2400,
        'Cabinovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0007',
        'Comprensorio delle Alpi Apuane',
        1000,
        2000,
        'Seggiovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0008',
        'Comprensorio dei Monti Sibillini',
        1300,
        2300,
        'Cabinovia',
        'Aosta',
        'Aosta'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0009',
        'Comprensorio dei Monti Lessini',
        1100,
        2100,
        'Cabinovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0010',
        'Comprensorio dei Monti Lattari',
        1700,
        2700,
        'Seggiovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0011',
        'Comprensorio del Cervino',
        2100,
        2900,
        'Cabinovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0012',
        'Comprensorio del Sella Ronda',
        1500,
        1900,
        'Seggiovia',
        'Belluno',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0013',
        'Comprensorio della Valtellina',
        1200,
        1800,
        'Seggiovia',
        'Brescia',
        'Brescia'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0014',
        'Comprensorio della Valle d Aosta',
        1800,
        2500,
        'Cabinovia',
        'Aosta',
        'Aosta'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0015',
        'Comprensorio della Val Gardena',
        1900,
        2600,
        'Seggiovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0016',
        'Comprensorio delle Dolomiti',
        1900,
        2400,
        'Seggiovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0017',
        'Comprensorio delle Alpi Apuane',
        1500,
        2000,
        'Cabinovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0018',
        'Comprensorio dei Monti Sibillini',
        1400,
        2500,
        'Seggiovia',
        'Aosta',
        'Aosta'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0019',
        'Comprensorio dei Monti Lessini',
        1500,
        2300,
        'Seggiovia',
        'Feltre',
        'Belluno'
    );

INSERT INTO
    public.impianto
VALUES
    (
        '0020',
        'Comprensorio dei Monti Lattari',
        1900,
        2500,
        'Cabinovia',
        'Feltre',
        'Belluno'
    );

--
-- TOC entry 3438 (class 0 OID 27156)
-- Dependencies: 215
-- Data for Name: localita; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.localita
VALUES
    ('Agrigento', 'Agrigento', 30492);

INSERT INTO
    public.localita
VALUES
    ('Avellino', 'Avellino', 28068);

INSERT INTO
    public.localita
VALUES
    ('Belluno', 'Belluno', 36738);

INSERT INTO
    public.localita
VALUES
    ('Trento', 'Trento', 62072);

INSERT INTO
    public.localita
VALUES
    ('Bolzano', 'Bolzano', 73399);

INSERT INTO
    public.localita
VALUES
    ('Aosta', 'Aosta', 32635);

INSERT INTO
    public.localita
VALUES
    ('Sondrio', 'Sondrio', 32712);

INSERT INTO
    public.localita
VALUES
    ('Udine', 'Udine', 49058);

INSERT INTO
    public.localita
VALUES
    ('Terni', 'Terni', 21224);

INSERT INTO
    public.localita
VALUES
    ('Cuneo', 'Cuneo', 69032);

INSERT INTO
    public.localita
VALUES
    ('Caltanissetta', 'Caltanissetta', 22395);

INSERT INTO
    public.localita
VALUES
    ('Campobasso', 'Campobasso', 29206);

INSERT INTO
    public.localita
VALUES
    ('Caserta', 'Caserta', 26403);

INSERT INTO
    public.localita
VALUES
    ('Catania', 'Catania', 35454);

INSERT INTO
    public.localita
VALUES
    ('Ascoli Piceno', 'Ascoli Piceno', 27652);

INSERT INTO
    public.localita
VALUES
    ('Alessandria', 'Alessandria', 93145);

INSERT INTO
    public.localita
VALUES
    ('Feltre', 'Belluno', 20594);

INSERT INTO
    public.localita
VALUES
    ('Bergamo', 'Bergamo', 120082);

INSERT INTO
    public.localita
VALUES
    ('Bologna', 'Bologna', 389261);

INSERT INTO
    public.localita
VALUES
    ('Brescia', 'Brescia', 196343);

INSERT INTO
    public.localita
VALUES
    ('Brindisi', 'Brindisi', 88088);

--
-- TOC entry 3443 (class 0 OID 27217)
-- Dependencies: 220
-- Data for Name: manutenzione; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.manutenzione
VALUES
    (
        '0002',
        'Comprensorio del Sella Ronda',
        '2023-05-01',
        '2023-05-06',
        '12345678901',
        1000
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0007',
        'Comprensorio delle Alpi Apuane',
        '2023-05-02',
        '2023-05-06',
        '23456789012',
        1500
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0010',
        'Comprensorio dei Monti Lattari',
        '2023-05-03',
        '2023-05-09',
        '34567890123',
        1200
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0007',
        'Comprensorio delle Alpi Apuane',
        '2022-12-02',
        '2023-05-06',
        '23456789012',
        1500
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0010',
        'Comprensorio dei Monti Lattari',
        '2022-12-03',
        '2023-05-09',
        '23456789012',
        1200
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0006',
        'Comprensorio delle Dolomiti',
        '2022-12-22',
        '2023-01-01',
        '78901234567',
        7000
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0010',
        'Comprensorio dei Monti Lattari',
        '2022-11-30',
        '2022-12-02',
        '12345678901',
        5000
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0003',
        'Comprensorio della Valtellina',
        '2022-12-10',
        '2022-12-12',
        '78901234567',
        500
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0008',
        'Comprensorio dei Monti Sibillini',
        '2022-12-12',
        '2022-12-17',
        '12345678901',
        1200
    );

INSERT INTO
    public.manutenzione
VALUES
    (
        '0004',
        'Comprensorio della Valle d Aosta',
        '2022-12-15',
        '2022-12-18',
        '12345678901',
        40000
    );

--
-- TOC entry 3449 (class 0 OID 27287)
-- Dependencies: 226
-- Data for Name: passaggio; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-05-01 10:00:00',
        '0001',
        'Comprensorio del Cervino'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-05-01 11:00:00',
        '0001',
        'Comprensorio del Cervino'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-06-01 09:00:00',
        '0002',
        'Comprensorio del Sella Ronda'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'CNTFNC88M57A319L',
        '2022-05-11 10:00:00',
        '0004',
        'Comprensorio della Valle d Aosta'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'SPTMRA90E44G463P',
        '2023-06-01 09:50:00',
        '0002',
        'Comprensorio del Sella Ronda'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRC82A21E413P',
        '2022-08-11 10:00:00',
        '0004',
        'Comprensorio della Valle d Aosta'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRC82A21E413P',
        '2022-08-11 11:00:00',
        '0004',
        'Comprensorio della Valle d Aosta'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRC82A21E413P',
        '2022-08-11 11:30:00',
        '0004',
        'Comprensorio della Valle d Aosta'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRC82A21E413P',
        '2022-09-11 12:30:00',
        '0008',
        'Comprensorio dei Monti Sibillini'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2022-09-11 12:30:00',
        '0006',
        'Comprensorio delle Dolomiti'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-05-01 14:20:00',
        '0001',
        'Comprensorio del Cervino'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-05-01 17:13:00',
        '0001',
        'Comprensorio del Cervino'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-05-01 14:00:00',
        '0001',
        'Comprensorio del Cervino'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2023-05-01 11:13:00',
        '0001',
        'Comprensorio del Cervino'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2021-06-01 09:00:00',
        '0002',
        'Comprensorio del Sella Ronda'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2021-06-01 10:00:00',
        '0002',
        'Comprensorio del Sella Ronda'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSGPP85D24L736I',
        '2021-06-01 12:12:02',
        '0002',
        'Comprensorio del Sella Ronda'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRA80A01H501W',
        '2021-12-01 09:00:00',
        '0003',
        'Comprensorio della Valtellina'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRA80A01H501W',
        '2021-12-01 10:00:00',
        '0003',
        'Comprensorio della Valtellina'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRA80A01H501W',
        '2021-12-01 12:12:02',
        '0003',
        'Comprensorio della Valtellina'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RSSMRA80A01H501W',
        '2021-12-01 14:11:00',
        '0003',
        'Comprensorio della Valtellina'
    );

INSERT INTO
    public.passaggio
VALUES
    (
        'RMNSFI94E43G675J',
        '2021-12-01 13:11:00',
        '0010',
        'Comprensorio dei Monti Lattari'
    );

--
-- TOC entry 3444 (class 0 OID 27237)
-- Dependencies: 221
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.persona
VALUES
    ('RSSMRA80A01H501W', '1980-01-01', 'M', 'Trento');

INSERT INTO
    public.persona
VALUES
    (
        'BNCLRA75C42D612A',
        '1975-03-15',
        'F',
        'Alessandria'
    );

INSERT INTO
    public.persona
VALUES
    ('RSSGPP85D24L736I', '1985-04-24', 'M', 'Belluno');

INSERT INTO
    public.persona
VALUES
    ('SPTMRA90E44G463P', '1990-07-10', 'F', 'Belluno');

INSERT INTO
    public.persona
VALUES
    ('FRRLCU81B22F205W', '1981-02-22', 'M', 'Bergamo');

INSERT INTO
    public.persona
VALUES
    ('RCCCHR93C65D901M', '1993-09-15', 'F', 'Bologna');

INSERT INTO
    public.persona
VALUES
    ('MRNLSN86H14L745F', '1986-08-14', 'M', 'Aosta');

INSERT INTO
    public.persona
VALUES
    ('CNTFNC88M57A319L', '1988-05-27', 'F', 'Bergamo');

INSERT INTO
    public.persona
VALUES
    (
        'RSSMRC82A21E453U',
        '1982-11-21',
        'M',
        'Campobasso'
    );

INSERT INTO
    public.persona
VALUES
    (
        'RSSMRC82A21E413P',
        '1985-11-21',
        'F',
        'Campobasso'
    );

INSERT INTO
    public.persona
VALUES
    ('RSSPRC02A21E413P', '1990-10-21', 'F', 'Belluno');

INSERT INTO
    public.persona
VALUES
    ('RMNSFI94E43G675J', '1994-12-03', 'F', 'Bolzano');

INSERT INTO
    public.persona
VALUES
    ('VDVLXA02P18F241V', '2002-09-18', 'M', 'Bolzano');

--
-- TOC entry 3437 (class 0 OID 27151)
-- Dependencies: 214
-- Data for Name: provincia; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.provincia
VALUES
    ('Agrigento', 3042, false);

INSERT INTO
    public.provincia
VALUES
    ('Alessandria', 3560, false);

INSERT INTO
    public.provincia
VALUES
    ('Avellino', 2806, false);

INSERT INTO
    public.provincia
VALUES
    ('Belluno', 3678, true);

INSERT INTO
    public.provincia
VALUES
    ('Bergamo', 2723, false);

INSERT INTO
    public.provincia
VALUES
    ('Trento', 6207, true);

INSERT INTO
    public.provincia
VALUES
    ('Bolzano', 7399, true);

INSERT INTO
    public.provincia
VALUES
    ('Aosta', 3263, true);

INSERT INTO
    public.provincia
VALUES
    ('Sondrio', 3212, true);

INSERT INTO
    public.provincia
VALUES
    ('Udine', 4905, false);

INSERT INTO
    public.provincia
VALUES
    ('Terni', 2122, false);

INSERT INTO
    public.provincia
VALUES
    ('Cuneo', 6902, false);

INSERT INTO
    public.provincia
VALUES
    ('Caltanissetta', 2395, false);

INSERT INTO
    public.provincia
VALUES
    ('Campobasso', 2906, true);

INSERT INTO
    public.provincia
VALUES
    ('Caserta', 2640, false);

INSERT INTO
    public.provincia
VALUES
    ('Catania', 3545, false);

INSERT INTO
    public.provincia
VALUES
    ('Ascoli Piceno', 2762, false);

INSERT INTO
    public.provincia
VALUES
    ('Brescia', 4763, false);

INSERT INTO
    public.provincia
VALUES
    ('Brindisi', 1858, false);

INSERT INTO
    public.provincia
VALUES
    ('Bologna', 3701, true);

--
-- TOC entry 3448 (class 0 OID 27277)
-- Dependencies: 225
-- Data for Name: seggiovia; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.seggiovia
VALUES
    ('0001', 'Comprensorio del Cervino', 40);

INSERT INTO
    public.seggiovia
VALUES
    ('0004', 'Comprensorio della Valle d Aosta', 60);

INSERT INTO
    public.seggiovia
VALUES
    ('0007', 'Comprensorio delle Alpi Apuane', 30);

INSERT INTO
    public.seggiovia
VALUES
    ('0010', 'Comprensorio dei Monti Lattari', 60);

INSERT INTO
    public.seggiovia
VALUES
    ('0012', 'Comprensorio del Sella Ronda', 40);

INSERT INTO
    public.seggiovia
VALUES
    ('0013', 'Comprensorio della Valtellina', 60);

INSERT INTO
    public.seggiovia
VALUES
    ('0015', 'Comprensorio della Val Gardena', 30);

INSERT INTO
    public.seggiovia
VALUES
    ('0016', 'Comprensorio delle Dolomiti', 60);

INSERT INTO
    public.seggiovia
VALUES
    ('0018', 'Comprensorio dei Monti Sibillini', 80);

INSERT INTO
    public.seggiovia
VALUES
    ('0019', 'Comprensorio dei Monti Lessini', 50);

--
-- TOC entry 3445 (class 0 OID 27247)
-- Dependencies: 222
-- Data for Name: tessera_sciatore; Type: TABLE DATA; Schema: public; Owner: postgres
--
INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS001       ',
        '2023-08-31',
        150,
        'Assicurazione infortuni inclusa.',
        'RSSMRA80A01H501W'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS002       ',
        '2023-08-31',
        180,
        'Copertura completa per danni accidentali',
        'BNCLRA75C42D612A'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS003       ',
        '2023-08-31',
        200,
        'Assicurazione infortuni inclusa',
        'RSSGPP85D24L736I'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS004       ',
        '2023-09-17',
        160,
        'Protezione per scii a noleggio',
        'SPTMRA90E44G463P'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS005       ',
        '2023-09-30',
        170,
        'Assicurazione infortuni inclusa',
        'FRRLCU81B22F205W'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS006       ',
        '2023-10-18',
        190,
        'Copertura completa per danni accidentali',
        'RCCCHR93C65D901M'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS007       ',
        '2023-10-31',
        160,
        'Protezione per scii a noleggio',
        'MRNLSN86H14L745F'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS008       ',
        '2023-12-31',
        180,
        'Assicurazione infortuni inclusa',
        'CNTFNC88M57A319L'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS009       ',
        '2023-12-31',
        170,
        'Assicurazione infortuni inclusa',
        'RSSMRC82A21E453U'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS010       ',
        '2023-08-31',
        200,
        'Protezione per scii a noleggio',
        'RMNSFI94E43G675J'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS011       ',
        '2023-08-20',
        170,
        'Copertura completa per danni accidentali',
        'RSSMRC82A21E413P'
    );

INSERT INTO
    public.tessera_sciatore
VALUES
    (
        'TS012       ',
        '2022-08-25',
        170,
        'Assicurazione infortuni inclusa',
        'RSSPRC02A21E413P'
    );

--
-- TOC entry 3250 (class 2606 OID 27175)
-- Name: azienda azienda_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.azienda
ADD
    CONSTRAINT azienda_pkey PRIMARY KEY (piva);

--
-- TOC entry 3267 (class 2606 OID 27271)
-- Name: cabina cabina_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.cabina
ADD
    CONSTRAINT cabina_pkey PRIMARY KEY (cabinovia, comprensorio, n_cabina);

--
-- TOC entry 3265 (class 2606 OID 27261)
-- Name: cabinovia cabinovia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.cabinovia
ADD
    CONSTRAINT cabinovia_pkey PRIMARY KEY (impianto, comprensorio);

--
-- TOC entry 3248 (class 2606 OID 27170)
-- Name: comprensorio comprensorio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.comprensorio
ADD
    CONSTRAINT comprensorio_pkey PRIMARY KEY (nome);

--
-- TOC entry 3254 (class 2606 OID 27206)
-- Name: gestione gestione_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.gestione
ADD
    CONSTRAINT gestione_pkey PRIMARY KEY (azienda, comprensorio);

--
-- TOC entry 3252 (class 2606 OID 27191)
-- Name: impianto impianto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.impianto
ADD
    CONSTRAINT impianto_pkey PRIMARY KEY (codice, comprensorio);

--
-- TOC entry 3246 (class 2606 OID 27160)
-- Name: localita localita_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.localita
ADD
    CONSTRAINT localita_pkey PRIMARY KEY (nome, provincia);

--
-- TOC entry 3257 (class 2606 OID 27221)
-- Name: manutenzione manutenzione_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.manutenzione
ADD
    CONSTRAINT manutenzione_pkey PRIMARY KEY (impianto, comprensorio, data_inizio);

--
-- TOC entry 3271 (class 2606 OID 27291)
-- Name: passaggio passaggio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.passaggio
ADD
    CONSTRAINT passaggio_pkey PRIMARY KEY (persona, data_ora);

--
-- TOC entry 3260 (class 2606 OID 27241)
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.persona
ADD
    CONSTRAINT persona_pkey PRIMARY KEY (cf);

--
-- TOC entry 3244 (class 2606 OID 27155)
-- Name: provincia provincia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.provincia
ADD
    CONSTRAINT provincia_pkey PRIMARY KEY (nome);

--
-- TOC entry 3269 (class 2606 OID 27281)
-- Name: seggiovia seggiovia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.seggiovia
ADD
    CONSTRAINT seggiovia_pkey PRIMARY KEY (impianto, comprensorio);

--
-- TOC entry 3263 (class 2606 OID 27251)
-- Name: tessera_sciatore tessera_sciatore_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.tessera_sciatore
ADD
    CONSTRAINT tessera_sciatore_pkey PRIMARY KEY (id_tessera);

--
-- TOC entry 3255 (class 1259 OID 27314)
-- Name: manutenzione_impianto_index; Type: INDEX; Schema: public; Owner: postgres
--
CREATE INDEX manutenzione_impianto_index ON public.manutenzione USING btree (impianto, comprensorio);

--
-- TOC entry 3258 (class 1259 OID 27313)
-- Name: ricavi_azienda_index; Type: INDEX; Schema: public; Owner: postgres
--
CREATE INDEX ricavi_azienda_index ON public.manutenzione USING btree (azienda);

--
-- TOC entry 3261 (class 1259 OID 27312)
-- Name: tessera_sciatore_index; Type: INDEX; Schema: public; Owner: postgres
--
CREATE INDEX tessera_sciatore_index ON public.tessera_sciatore USING btree (id_tessera);

--
-- TOC entry 3289 (class 2620 OID 27307)
-- Name: seggiovia check_esistenza_in_cabinovia; Type: TRIGGER; Schema: public; Owner: postgres
--
CREATE TRIGGER check_esistenza_in_cabinovia BEFORE
INSERT
    OR
UPDATE
    ON public.seggiovia FOR EACH ROW EXECUTE FUNCTION public.controllo_esistenza_cabinvoia();

--
-- TOC entry 3288 (class 2620 OID 27309)
-- Name: cabinovia check_esistenza_in_seggiovia; Type: TRIGGER; Schema: public; Owner: postgres
--
CREATE TRIGGER check_esistenza_in_seggiovia BEFORE
INSERT
    OR
UPDATE
    ON public.cabinovia FOR EACH ROW EXECUTE FUNCTION public.controllo_esistenza_seggiovia();

--
-- TOC entry 3290 (class 2620 OID 27311)
-- Name: passaggio check_operativita_impianto_su_passaggio; Type: TRIGGER; Schema: public; Owner: postgres
--
CREATE TRIGGER check_operativita_impianto_su_passaggio BEFORE
INSERT
    OR
UPDATE
    ON public.passaggio FOR EACH ROW EXECUTE FUNCTION public.controllo_operativita_impianto_passaggio();

--
-- TOC entry 3291 (class 2620 OID 27305)
-- Name: passaggio check_validita_tessera; Type: TRIGGER; Schema: public; Owner: postgres
--
CREATE TRIGGER check_validita_tessera BEFORE
INSERT
    OR
UPDATE
    ON public.passaggio FOR EACH ROW EXECUTE FUNCTION public.controllo_validita_tessera();

--
-- TOC entry 3287 (class 2620 OID 27303)
-- Name: manutenzione check_valore_manutenzione; Type: TRIGGER; Schema: public; Owner: postgres
--
CREATE TRIGGER check_valore_manutenzione BEFORE
INSERT
    OR
UPDATE
    ON public.manutenzione FOR EACH ROW EXECUTE FUNCTION public.controllo_valore_manutenzione();

--
-- TOC entry 3273 (class 2606 OID 27176)
-- Name: azienda azienda_localita_sede_provincia_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.azienda
ADD
    CONSTRAINT azienda_localita_sede_provincia_sede_fkey FOREIGN KEY (localita_sede, provincia_sede) REFERENCES public.localita(nome, provincia);

--
-- TOC entry 3283 (class 2606 OID 27272)
-- Name: cabina cabina_cabinovia_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.cabina
ADD
    CONSTRAINT cabina_cabinovia_comprensorio_fkey FOREIGN KEY (cabinovia, comprensorio) REFERENCES public.cabinovia(impianto, comprensorio) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- TOC entry 3282 (class 2606 OID 27262)
-- Name: cabinovia cabinovia_impianto_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.cabinovia
ADD
    CONSTRAINT cabinovia_impianto_comprensorio_fkey FOREIGN KEY (impianto, comprensorio) REFERENCES public.impianto(codice, comprensorio) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- TOC entry 3276 (class 2606 OID 27207)
-- Name: gestione gestione_azienda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.gestione
ADD
    CONSTRAINT gestione_azienda_fkey FOREIGN KEY (azienda) REFERENCES public.azienda(piva);

--
-- TOC entry 3277 (class 2606 OID 27212)
-- Name: gestione gestione_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.gestione
ADD
    CONSTRAINT gestione_comprensorio_fkey FOREIGN KEY (comprensorio) REFERENCES public.comprensorio(nome);

--
-- TOC entry 3274 (class 2606 OID 27192)
-- Name: impianto impianto_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.impianto
ADD
    CONSTRAINT impianto_comprensorio_fkey FOREIGN KEY (comprensorio) REFERENCES public.comprensorio(nome);

--
-- TOC entry 3275 (class 2606 OID 27197)
-- Name: impianto impianto_localita_impianto_provincia_impianto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.impianto
ADD
    CONSTRAINT impianto_localita_impianto_provincia_impianto_fkey FOREIGN KEY (localita_impianto, provincia_impianto) REFERENCES public.localita(nome, provincia);

--
-- TOC entry 3272 (class 2606 OID 27161)
-- Name: localita localita_provincia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.localita
ADD
    CONSTRAINT localita_provincia_fkey FOREIGN KEY (provincia) REFERENCES public.provincia(nome);

--
-- TOC entry 3278 (class 2606 OID 27227)
-- Name: manutenzione manutenzione_azienda_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.manutenzione
ADD
    CONSTRAINT manutenzione_azienda_fkey FOREIGN KEY (azienda) REFERENCES public.azienda(piva);

--
-- TOC entry 3279 (class 2606 OID 27222)
-- Name: manutenzione manutenzione_impianto_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.manutenzione
ADD
    CONSTRAINT manutenzione_impianto_comprensorio_fkey FOREIGN KEY (impianto, comprensorio) REFERENCES public.impianto(codice, comprensorio);

--
-- TOC entry 3285 (class 2606 OID 27297)
-- Name: passaggio passaggio_impianto_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.passaggio
ADD
    CONSTRAINT passaggio_impianto_comprensorio_fkey FOREIGN KEY (impianto, comprensorio) REFERENCES public.impianto(codice, comprensorio);

--
-- TOC entry 3286 (class 2606 OID 27292)
-- Name: passaggio passaggio_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.passaggio
ADD
    CONSTRAINT passaggio_persona_fkey FOREIGN KEY (persona) REFERENCES public.persona(cf);

--
-- TOC entry 3280 (class 2606 OID 27242)
-- Name: persona persona_residenza_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.persona
ADD
    CONSTRAINT persona_residenza_fkey FOREIGN KEY (residenza) REFERENCES public.provincia(nome);

--
-- TOC entry 3284 (class 2606 OID 27282)
-- Name: seggiovia seggiovia_impianto_comprensorio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.seggiovia
ADD
    CONSTRAINT seggiovia_impianto_comprensorio_fkey FOREIGN KEY (impianto, comprensorio) REFERENCES public.impianto(codice, comprensorio) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- TOC entry 3281 (class 2606 OID 27252)
-- Name: tessera_sciatore tessera_sciatore_proprietario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--
ALTER TABLE
    ONLY public.tessera_sciatore
ADD
    CONSTRAINT tessera_sciatore_proprietario_fkey FOREIGN KEY (proprietario) REFERENCES public.persona(cf) ON UPDATE CASCADE ON DELETE CASCADE;

-- Completed on 2023-08-04 21:48:27
--
-- PostgreSQL database dump complete

-- QUERIES
--1. Una specifica azienda vuole avere un resoconto sugli interventi di manutenzione attuati sugli impianti.
--Restituire per tale azienda il totale dei ricavi e dei giorni impiegati in interventi di manutenzione (la query dell’esempio utilizza “12345678901” come PIVA dell’azienda): 
select
    azienda.piva,
    COALESCE(sum(costo), 0) as ricavo,
    COALESCE(sum(data_fine - data_inizio), 0) as giorni_lavoro
from
    azienda
    left join manutenzione on manutenzione.azienda = azienda.piva
where
    azienda.piva = '12345678901'
group by
    azienda.piva;

--2. Dopo un’analisi dei dati raccolti sugli impianti sciistici è emerso che la maggior parte dei frequentatori sono uomini, si è deciso dunque di inviare una promozione alle donne con tessera-sciatore in scadenza.
--Mostrare il codice fiscale e l’id della tessera-sciatore delle donne la cui tessera scade tra meno di un mese : 
select
    proprietario,
    ID_tessera
from
    tessera_sciatore
    join persona on tessera_sciatore.proprietario = persona.CF
where
    sesso = 'F'
    and data_scadenza >= CURRENT_DATE
    and data_scadenza < CURRENT_DATE + interval '1 month';

--3. Si vuole valutare quali impianti gestiti dal sistema sono stati penalizzati da interventi di manutenzione in uno specifico intervallo di tempo. 
--Stampare il codice, il comprensorio e il tipo degli impianti che sono stati non-operativi almeno un giorno all’interno di un determinato periodo (la query dell’esempio utilizza come intervallo di tempo il mese di dicembre 2022):
select
    distinct impianto.codice,
    impianto.comprensorio,
    impianto.tipo
from
    impianto
    join manutenzione on impianto.codice = manutenzione.impianto
    and impianto.comprensorio = manutenzione.comprensorio
where
    (
        manutenzione.Data_inizio >= '2022-12-01' :: date
        and manutenzione.Data_inizio <= '2022-12-31' :: date
    )
    or (
        manutenzione.Data_fine >= '2022-12-01' :: date
        and manutenzione.Data_fine <= '2022-12-31' :: date
    )
    or (
        manutenzione.Data_inizio < '2022-12-01' :: date
        and (
            manutenzione.Data_fine > '2022-12-31' :: date
            or manutenzione.Data_fine is null
        )
    );

--4.Si vogliono ricavare informazioni sull'età dei frequentatori dei vari comprensori gestiti dal sistema.
--Mostrare per ogni comprensorio, in ordine crescente, l'età media degli sciatori che hanno effettuato almeno un passaggio negli impianti di quest’ultimo: 
drop view if exists frequentatori_comprensorio;

create view frequentatori_comprensorio as
select
    comprensorio,
    persona
from
    passaggio
group by
    (comprensorio, persona);

select
    comprensorio.nome,
    coalesce(
        TRUNC(
            avg(
                extract(
                    year
                    from
                        age(persona.data_nascita)
                )
            ),
            2
        ),
        null
    ) as eta_media
from
    comprensorio
    left join frequentatori_comprensorio on frequentatori_comprensorio.comprensorio = comprensorio.nome
    left join persona on frequentatori_comprensorio.persona = persona.cf
group by
    comprensorio.nome
order by
    eta_media asc;

--5.Si vogliono individuare gli impianti più frequentati gestiti dal sistema.
--Selezionare il codice, il comprensorio e il numero di passaggi medi per giorno degli impianti che hanno un numero di passaggi medi giornalieri maggiore rispetto la media dei passaggi per giorno fra tutti gli impianti:
drop view if exists passaggi_per_giorno;

create view passaggi_per_giorno as
select
    passaggio.impianto,
    passaggio.comprensorio,
    date_trunc('day', passaggio.data_ora) as giorno,
    count(*) as n_passaggi
from
    passaggio
group by
    passaggio.impianto,
    passaggio.comprensorio,
    giorno;

select
    impianto,
    comprensorio,
    TRUNC(avg(n_passaggi), 2) as n_passaggi_medi
from
    passaggi_per_giorno
group by
    impianto,
    comprensorio
having
    avg(n_passaggi) >(
        select
            avg(n_passaggi)
        from
            passaggi_per_giorno
    );

--6.Si vogliono individuare gli utenti affezionati ai soli impianti nella loro provincia di residenza. 
--Mostrare il codice fiscale e la provincia di residenza delle persone che hanno eseguito almeno un passaggio nei soli impianti situati nella loro provincia di residenza: 
Select
    CF as codice_fiscale,
    Residenza
from
    Persona Pe
    join Passaggio Pa on Pa.Persona = Pe.CF
    join Impianto I on Pa.impianto = I.Codice
    and Pa.comprensorio = I.comprensorio
where
    I.Provincia_impianto = Pe.residenza
group by
    Pe.CF
having
    count(DISTINCT CONCAT(I.codice, '|', I.comprensorio)) = (
        Select
            count(DISTINCT CONCAT(I2.codice, '|', I2.comprensorio))
        from
            Persona Pe2
            join Passaggio Pa2 on Pe2.CF = Pa2.Persona
            join Impianto I2 on Pa2.impianto = I2.Codice
            and Pa2.comprensorio = I2.comprensorio
        where
            Pe2.CF = Pe.CF
    );

--7.Si vogliono visualizzare gli impianti più capienti per ogni comprensorio.
--Mostrare la cabinovia e la seggiovia per ogni comprensorio che possono trasportare più persone, tenendo conto del fatto che il numero di persone trasportate da una seggiovia è pari al numeri di sedili di quest’ultima mentre il numero delle persone trasportate da una cabinovia è pari alla somma della capienza di tutte le sue cabine:
select
    *
from
    (
        select
            'Seggiovia' as Tipologia,
            comprensorio,
            impianto,
            N_Sedili as posti
        from
            Seggiovia S1
        where
            N_Sedili = (
                select
                    max(N_Sedili)
                from
                    Seggiovia S2
                where
                    S1.comprensorio = S2.comprensorio
                group by
                    Comprensorio
            )
        UNION
        select
            'Cabinovia ' Tipologia,
            C1.comprensorio,
            impianto,
            SUM(capienza) as posti
        from
            Cabinovia C1
            join Cabina Cab1 on Cab1.Cabinovia = C1.impianto
            and Cab1.comprensorio = C1.comprensorio
        group by
            (C1.comprensorio, impianto)
        having
            SUM(Capienza) = (
                select
                    max(posti_)
                from
                    (
                        select
                            SUM(capienza) as posti_
                        from
                            Cabinovia C2
                            join Cabina Cab2 on Cab2.Cabinovia = C2.impianto
                            and Cab2.comprensorio = C2.comprensorio
                        where
                            C1.comprensorio = C2.comprensorio
                        group by
                            (C2.comprensorio, impianto)
                    ) as Cabinovia_posti
            )
    ) as capienza_impianti_comprensori
order by
    comprensorio;

--8. Si vogliono esporre ad ogni utente dei dati interessanti sui loro utilizzi degli impianti.  
--Per ogni persona restituire il numero totale di utilizzi degli impianti e la media del numero di passaggi per anno, tenendo conto per quest’ultima solo degli anni in cui è stato eseguito almeno un passaggio:
select
    persona_utilizzi.codice_fiscale,
    persona_utilizzi.numero_utilizzi,
    TRUNC(persona_media_utilizzi.media_pax, 2) as media_passaggi_anno
from
    (
        select
            persona as codice_fiscale,
            count(*) as numero_utilizzi
        from
            passaggio PA
        group by
            PA.persona
    ) persona_utilizzi
    join (
        select
            codice_fiscale,
            avg(pax_year) as media_pax
        from
            (
                select
                    persona as codice_fiscale,
                    count(*) as pax_year
                from
                    passaggio PA
                group by
                    (
                        PA.persona,
                        EXTRACT(
                            YEAR
                            FROM
                                Data_ora
                        )
                    )
            ) as passaggi_anno_cf
        group by
            codice_fiscale
    ) persona_media_utilizzi on persona_media_utilizzi.codice_fiscale = persona_utilizzi.codice_fiscale;

--9. Si vuole esibire un resoconto sugli interventi di manutenzione avvenuti sugli impianti.
--Per ogni impianto mostrare il tipo, il numero di manutenzioni fatte, il costo totale delle manutenzioni ed i giorni in totale non operativi:
select
    codice,
    I.comprensorio,
    I.tipo,
    count(distinct Data_inizio),
    COALESCE(SUM(costo), 0) as costo_totale,
    COALESCE(SUM(Data_fine - Data_inizio), 0) as totale_giorni
from
    impianto I
    left join manutenzione M on M.impianto = I.codice
    and M.comprensorio = I.comprensorio
group by
    (I.codice, I.comprensorio);

--10. Una specifica azienda vuole avere un resoconto sulle spese totali di manutenzione che ha dovuto affrontare in seguito alla gestione dei comprensori di cui possiede una quota. 
--Mostrare il totale delle spese dell’azienda pesato sulla quote di gestione di ciascun comprensorio (la query dell’esempio utilizza “65432109876” come PIVA dell’azienda):
drop view if exists spese_gestione_per_aziende;

create view spese_gestione_per_aziende as
select
    comprensorio.nome,
    gestione.azienda,
    sum(manutenzione.costo) as costi_totali,
    (sum(manutenzione.costo) / 100) * gestione.quota as spesa_personale
from
    manutenzione
    join impianto on impianto.codice = manutenzione.impianto
    and impianto.comprensorio = manutenzione.comprensorio
    join comprensorio on impianto.comprensorio = comprensorio.nome
    join gestione on comprensorio.nome = gestione.comprensorio
group by
    (comprensorio.nome, gestione.azienda, quota);

select
    Azienda.PIVA,
    COALESCE(sum(spesa_personale), 0) as spesa_totale_aziendale
from
    azienda
    left join spese_gestione_per_aziende on azienda.piva = spese_gestione_per_aziende.azienda
where
    azienda.PIVA = '65432109876'
group by
    azienda.PIVA;