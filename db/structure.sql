SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: agents_rdv_notifications_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.agents_rdv_notifications_level AS ENUM (
    'all',
    'others',
    'soon',
    'none'
);


--
-- Name: rdv_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rdv_status AS ENUM (
    'unknown',
    'waiting',
    'seen',
    'excused',
    'revoked',
    'noshow'
);


--
-- Name: sms_provider; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sms_provider AS ENUM (
    'netsize',
    'send_in_blue',
    'contact_experience',
    'sfr_mail2sms',
    'clever_technologies',
    'orange_contact_everyone'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: absences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.absences (
    id bigint NOT NULL,
    agent_id bigint,
    title character varying NOT NULL,
    organisation_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    recurrence text,
    first_day date NOT NULL,
    start_time time without time zone NOT NULL,
    end_day date NOT NULL,
    end_time time without time zone NOT NULL,
    expired_cached boolean DEFAULT false NOT NULL
);


--
-- Name: absences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.absences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: absences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.absences_id_seq OWNED BY public.absences.id;


--
-- Name: action_text_rich_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_text_rich_texts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    body text,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_text_rich_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_text_rich_texts_id_seq OWNED BY public.action_text_rich_texts.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: agent_territorial_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_territorial_roles (
    id bigint NOT NULL,
    agent_id bigint,
    territory_id bigint
);


--
-- Name: agent_territorial_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_territorial_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_territorial_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_territorial_roles_id_seq OWNED BY public.agent_territorial_roles.id;


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    first_name character varying,
    last_name character varying,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_type character varying,
    invited_by_id bigint,
    invitations_count integer DEFAULT 0,
    deleted_at timestamp without time zone,
    service_id bigint,
    email_original character varying,
    provider character varying DEFAULT 'email'::character varying NOT NULL,
    uid character varying DEFAULT ''::character varying NOT NULL,
    tokens text,
    allow_password_change boolean DEFAULT false,
    rdv_notifications_level public.agents_rdv_notifications_level DEFAULT 'soon'::public.agents_rdv_notifications_level,
    search_terms tsvector GENERATED ALWAYS AS (((to_tsvector('french'::regconfig, (COALESCE(first_name, ''::character varying))::text) || to_tsvector('french'::regconfig, (COALESCE(last_name, ''::character varying))::text)) || to_tsvector('french'::regconfig, (COALESCE(email, ''::character varying))::text))) STORED
);


--
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_id_seq OWNED BY public.agents.id;


--
-- Name: agents_organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents_organisations (
    id bigint NOT NULL,
    agent_id bigint,
    organisation_id bigint,
    level character varying DEFAULT 'basic'::character varying NOT NULL
);


--
-- Name: agents_organisations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_organisations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_organisations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_organisations_id_seq OWNED BY public.agents_organisations.id;


--
-- Name: agents_rdvs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents_rdvs (
    id bigint NOT NULL,
    agent_id bigint,
    rdv_id bigint
);


--
-- Name: agents_rdvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_rdvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_rdvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_rdvs_id_seq OWNED BY public.agents_rdvs.id;


--
-- Name: agents_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents_users (
    id bigint NOT NULL,
    user_id bigint,
    agent_id bigint
);


--
-- Name: agents_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_users_id_seq OWNED BY public.agents_users.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cron character varying
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: file_attentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.file_attentes (
    id bigint NOT NULL,
    rdv_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    notifications_sent integer DEFAULT 0,
    last_creneau_sent_at timestamp without time zone
);


--
-- Name: file_attentes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.file_attentes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: file_attentes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.file_attentes_id_seq OWNED BY public.file_attentes.id;


--
-- Name: lieux; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lieux (
    id bigint NOT NULL,
    name character varying,
    organisation_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    address character varying,
    latitude double precision,
    longitude double precision,
    phone_number character varying,
    phone_number_formatted character varying,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: lieux_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lieux_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lieux_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lieux_id_seq OWNED BY public.lieux.id;


--
-- Name: motif_libelles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.motif_libelles (
    id bigint NOT NULL,
    name character varying,
    service_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: motif_libelles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.motif_libelles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: motif_libelles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.motif_libelles_id_seq OWNED BY public.motif_libelles.id;


--
-- Name: motifs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.motifs (
    id bigint NOT NULL,
    name character varying,
    color character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_duration_in_min integer DEFAULT 30 NOT NULL,
    organisation_id bigint,
    reservable_online boolean DEFAULT false NOT NULL,
    min_booking_delay integer DEFAULT 1800,
    max_booking_delay integer DEFAULT 7889238,
    deleted_at timestamp without time zone,
    service_id bigint,
    restriction_for_rdv text,
    instruction_for_rdv text,
    for_secretariat boolean DEFAULT false,
    location_type integer DEFAULT 0 NOT NULL,
    follow_up boolean DEFAULT false,
    visibility_type character varying DEFAULT 'visible_and_notified'::character varying NOT NULL,
    sectorisation_level character varying DEFAULT 'departement'::character varying,
    custom_cancel_warning_message text,
    search_terms tsvector GENERATED ALWAYS AS (to_tsvector('french'::regconfig, (COALESCE(name, ''::character varying))::text)) STORED
);


--
-- Name: motifs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.motifs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: motifs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.motifs_id_seq OWNED BY public.motifs.id;


--
-- Name: motifs_plage_ouvertures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.motifs_plage_ouvertures (
    motif_id bigint,
    plage_ouverture_id bigint
);


--
-- Name: organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisations (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    departement character varying,
    horaires text,
    phone_number character varying,
    human_id character varying DEFAULT ''::character varying NOT NULL,
    website character varying,
    email character varying,
    territory_id bigint NOT NULL
);


--
-- Name: organisations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organisations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organisations_id_seq OWNED BY public.organisations.id;


--
-- Name: plage_ouvertures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plage_ouvertures (
    id bigint NOT NULL,
    agent_id bigint,
    title character varying,
    organisation_id bigint,
    first_day date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    recurrence text,
    lieu_id bigint,
    expired_cached boolean DEFAULT false
);


--
-- Name: plage_ouvertures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plage_ouvertures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plage_ouvertures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plage_ouvertures_id_seq OWNED BY public.plage_ouvertures.id;


--
-- Name: rdv_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rdv_events (
    id bigint NOT NULL,
    rdv_id bigint NOT NULL,
    event_type character varying,
    event_name character varying,
    created_at timestamp without time zone
);


--
-- Name: rdv_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rdv_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rdv_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rdv_events_id_seq OWNED BY public.rdv_events.id;


--
-- Name: rdvs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rdvs (
    id bigint NOT NULL,
    duration_in_min integer NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    organisation_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cancelled_at timestamp without time zone,
    motif_id bigint,
    sequence integer DEFAULT 0 NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    location character varying,
    created_by integer DEFAULT 0,
    context text,
    lieu_id bigint,
    status public.rdv_status DEFAULT 'unknown'::public.rdv_status NOT NULL
);


--
-- Name: rdvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rdvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rdvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rdvs_id_seq OWNED BY public.rdvs.id;


--
-- Name: rdvs_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rdvs_users (
    id bigint NOT NULL,
    rdv_id bigint,
    user_id bigint
);


--
-- Name: rdvs_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rdvs_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rdvs_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rdvs_users_id_seq OWNED BY public.rdvs_users.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sector_attributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sector_attributions (
    id bigint NOT NULL,
    sector_id bigint NOT NULL,
    organisation_id bigint NOT NULL,
    level character varying NOT NULL,
    agent_id bigint
);


--
-- Name: sector_attributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sector_attributions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sector_attributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sector_attributions_id_seq OWNED BY public.sector_attributions.id;


--
-- Name: sectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sectors (
    id bigint NOT NULL,
    departement character varying,
    name character varying NOT NULL,
    human_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    territory_id bigint NOT NULL
);


--
-- Name: sectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sectors_id_seq OWNED BY public.sectors.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    short_name character varying
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: super_admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.super_admins (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: super_admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.super_admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: super_admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.super_admins_id_seq OWNED BY public.super_admins.id;


--
-- Name: territories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.territories (
    id bigint NOT NULL,
    departement_number character varying DEFAULT ''::character varying NOT NULL,
    name character varying,
    phone_number character varying,
    phone_number_formatted character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sms_provider public.sms_provider,
    sms_configuration json,
    has_own_sms_provider boolean DEFAULT false,
    api_options character varying[] DEFAULT '{}'::character varying[] NOT NULL
);


--
-- Name: territories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.territories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: territories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.territories_id_seq OWNED BY public.territories.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    id bigint NOT NULL,
    organisation_id bigint,
    user_id bigint,
    logement integer,
    notes text
);


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_profiles_id_seq OWNED BY public.user_profiles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    first_name character varying,
    last_name character varying,
    email character varying,
    address character varying,
    phone_number character varying,
    birth_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_type character varying,
    invited_by_id bigint,
    invitations_count integer DEFAULT 0,
    caisse_affiliation integer,
    affiliation_number character varying,
    family_situation integer,
    number_of_children integer,
    old_logement integer,
    responsible_id bigint,
    deleted_at timestamp without time zone,
    birth_name character varying,
    email_original character varying,
    phone_number_formatted character varying,
    notify_by_sms boolean DEFAULT true,
    notify_by_email boolean DEFAULT true,
    last_sign_in_at timestamp without time zone,
    franceconnect_openid_sub character varying,
    created_through character varying,
    logged_once_with_franceconnect boolean,
    invite_for integer,
    city_code character varying,
    post_code character varying,
    city_name character varying,
    search_terms tsvector GENERATED ALWAYS AS ((((((to_tsvector('french'::regconfig, (COALESCE(first_name, ''::character varying))::text) || to_tsvector('french'::regconfig, (COALESCE(birth_name, ''::character varying))::text)) || to_tsvector('french'::regconfig, (COALESCE(last_name, ''::character varying))::text)) || to_tsvector('french'::regconfig, (COALESCE(email, ''::character varying))::text)) || to_tsvector('french'::regconfig, (COALESCE(phone_number_formatted, ''::character varying))::text)) || to_tsvector('french'::regconfig, (COALESCE(phone_number, ''::character varying))::text))) STORED
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id bigint NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone,
    object_changes text,
    virtual_attributes json
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: webhook_endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_endpoints (
    id bigint NOT NULL,
    target_url character varying NOT NULL,
    secret character varying,
    organisation_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: webhook_endpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhook_endpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhook_endpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhook_endpoints_id_seq OWNED BY public.webhook_endpoints.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id bigint NOT NULL,
    level character varying,
    city_name character varying,
    city_code character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sector_id bigint NOT NULL,
    street_name character varying,
    street_ban_id character varying
);


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zones_id_seq OWNED BY public.zones.id;


--
-- Name: absences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.absences ALTER COLUMN id SET DEFAULT nextval('public.absences_id_seq'::regclass);


--
-- Name: action_text_rich_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts ALTER COLUMN id SET DEFAULT nextval('public.action_text_rich_texts_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: agent_territorial_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_territorial_roles ALTER COLUMN id SET DEFAULT nextval('public.agent_territorial_roles_id_seq'::regclass);


--
-- Name: agents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents ALTER COLUMN id SET DEFAULT nextval('public.agents_id_seq'::regclass);


--
-- Name: agents_organisations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents_organisations ALTER COLUMN id SET DEFAULT nextval('public.agents_organisations_id_seq'::regclass);


--
-- Name: agents_rdvs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents_rdvs ALTER COLUMN id SET DEFAULT nextval('public.agents_rdvs_id_seq'::regclass);


--
-- Name: agents_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents_users ALTER COLUMN id SET DEFAULT nextval('public.agents_users_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: file_attentes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_attentes ALTER COLUMN id SET DEFAULT nextval('public.file_attentes_id_seq'::regclass);


--
-- Name: lieux id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lieux ALTER COLUMN id SET DEFAULT nextval('public.lieux_id_seq'::regclass);


--
-- Name: motif_libelles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motif_libelles ALTER COLUMN id SET DEFAULT nextval('public.motif_libelles_id_seq'::regclass);


--
-- Name: motifs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motifs ALTER COLUMN id SET DEFAULT nextval('public.motifs_id_seq'::regclass);


--
-- Name: organisations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations ALTER COLUMN id SET DEFAULT nextval('public.organisations_id_seq'::regclass);


--
-- Name: plage_ouvertures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plage_ouvertures ALTER COLUMN id SET DEFAULT nextval('public.plage_ouvertures_id_seq'::regclass);


--
-- Name: rdv_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdv_events ALTER COLUMN id SET DEFAULT nextval('public.rdv_events_id_seq'::regclass);


--
-- Name: rdvs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs ALTER COLUMN id SET DEFAULT nextval('public.rdvs_id_seq'::regclass);


--
-- Name: rdvs_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs_users ALTER COLUMN id SET DEFAULT nextval('public.rdvs_users_id_seq'::regclass);


--
-- Name: sector_attributions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sector_attributions ALTER COLUMN id SET DEFAULT nextval('public.sector_attributions_id_seq'::regclass);


--
-- Name: sectors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sectors ALTER COLUMN id SET DEFAULT nextval('public.sectors_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: super_admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.super_admins ALTER COLUMN id SET DEFAULT nextval('public.super_admins_id_seq'::regclass);


--
-- Name: territories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territories ALTER COLUMN id SET DEFAULT nextval('public.territories_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_profiles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: webhook_endpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints ALTER COLUMN id SET DEFAULT nextval('public.webhook_endpoints_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Name: absences absences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.absences
    ADD CONSTRAINT absences_pkey PRIMARY KEY (id);


--
-- Name: action_text_rich_texts action_text_rich_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts
    ADD CONSTRAINT action_text_rich_texts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: agent_territorial_roles agent_territorial_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_territorial_roles
    ADD CONSTRAINT agent_territorial_roles_pkey PRIMARY KEY (id);


--
-- Name: agents_organisations agents_organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents_organisations
    ADD CONSTRAINT agents_organisations_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: agents_rdvs agents_rdvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents_rdvs
    ADD CONSTRAINT agents_rdvs_pkey PRIMARY KEY (id);


--
-- Name: agents_users agents_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents_users
    ADD CONSTRAINT agents_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: file_attentes file_attentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_attentes
    ADD CONSTRAINT file_attentes_pkey PRIMARY KEY (id);


--
-- Name: lieux lieux_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lieux
    ADD CONSTRAINT lieux_pkey PRIMARY KEY (id);


--
-- Name: motif_libelles motif_libelles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motif_libelles
    ADD CONSTRAINT motif_libelles_pkey PRIMARY KEY (id);


--
-- Name: motifs motifs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motifs
    ADD CONSTRAINT motifs_pkey PRIMARY KEY (id);


--
-- Name: organisations organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT organisations_pkey PRIMARY KEY (id);


--
-- Name: plage_ouvertures plage_ouvertures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plage_ouvertures
    ADD CONSTRAINT plage_ouvertures_pkey PRIMARY KEY (id);


--
-- Name: rdv_events rdv_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdv_events
    ADD CONSTRAINT rdv_events_pkey PRIMARY KEY (id);


--
-- Name: rdvs rdvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs
    ADD CONSTRAINT rdvs_pkey PRIMARY KEY (id);


--
-- Name: rdvs_users rdvs_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs_users
    ADD CONSTRAINT rdvs_users_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sector_attributions sector_attributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sector_attributions
    ADD CONSTRAINT sector_attributions_pkey PRIMARY KEY (id);


--
-- Name: sectors sectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sectors
    ADD CONSTRAINT sectors_pkey PRIMARY KEY (id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: super_admins super_admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.super_admins
    ADD CONSTRAINT super_admins_pkey PRIMARY KEY (id);


--
-- Name: territories territories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territories
    ADD CONSTRAINT territories_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: webhook_endpoints webhook_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints
    ADD CONSTRAINT webhook_endpoints_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_absences_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_absences_on_agent_id ON public.absences USING btree (agent_id);


--
-- Name: index_absences_on_end_day; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_absences_on_end_day ON public.absences USING btree (end_day);


--
-- Name: index_absences_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_absences_on_organisation_id ON public.absences USING btree (organisation_id);


--
-- Name: index_action_text_rich_texts_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_action_text_rich_texts_uniqueness ON public.action_text_rich_texts USING btree (record_type, record_id, name);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_agent_territorial_roles_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_territorial_roles_on_agent_id ON public.agent_territorial_roles USING btree (agent_id);


--
-- Name: index_agent_territorial_roles_on_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_territorial_roles_on_territory_id ON public.agent_territorial_roles USING btree (territory_id);


--
-- Name: index_agents_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_confirmation_token ON public.agents USING btree (confirmation_token);


--
-- Name: index_agents_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_email ON public.agents USING btree (email);


--
-- Name: index_agents_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_invitation_token ON public.agents USING btree (invitation_token);


--
-- Name: index_agents_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_invitations_count ON public.agents USING btree (invitations_count);


--
-- Name: index_agents_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_invited_by_id ON public.agents USING btree (invited_by_id);


--
-- Name: index_agents_on_invited_by_type_and_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_invited_by_type_and_invited_by_id ON public.agents USING btree (invited_by_type, invited_by_id);


--
-- Name: index_agents_on_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_last_name ON public.agents USING btree (last_name);


--
-- Name: index_agents_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_reset_password_token ON public.agents USING btree (reset_password_token);


--
-- Name: index_agents_on_search_terms; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_search_terms ON public.agents USING gin (search_terms);


--
-- Name: index_agents_on_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_service_id ON public.agents USING btree (service_id);


--
-- Name: index_agents_on_uid_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_uid_and_provider ON public.agents USING btree (uid, provider);


--
-- Name: index_agents_organisations_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_organisations_on_agent_id ON public.agents_organisations USING btree (agent_id);


--
-- Name: index_agents_organisations_on_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_organisations_on_level ON public.agents_organisations USING btree (level);


--
-- Name: index_agents_organisations_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_organisations_on_organisation_id ON public.agents_organisations USING btree (organisation_id);


--
-- Name: index_agents_organisations_on_organisation_id_and_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_organisations_on_organisation_id_and_agent_id ON public.agents_organisations USING btree (organisation_id, agent_id);


--
-- Name: index_agents_rdvs_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_rdvs_on_agent_id ON public.agents_rdvs USING btree (agent_id);


--
-- Name: index_agents_rdvs_on_rdv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_rdvs_on_rdv_id ON public.agents_rdvs USING btree (rdv_id);


--
-- Name: index_agents_users_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_users_on_agent_id ON public.agents_users USING btree (agent_id);


--
-- Name: index_agents_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_users_on_user_id ON public.agents_users USING btree (user_id);


--
-- Name: index_file_attentes_on_rdv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_attentes_on_rdv_id ON public.file_attentes USING btree (rdv_id);


--
-- Name: index_file_attentes_on_rdv_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_file_attentes_on_rdv_id_and_user_id ON public.file_attentes USING btree (rdv_id, user_id);


--
-- Name: index_file_attentes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_attentes_on_user_id ON public.file_attentes USING btree (user_id);


--
-- Name: index_lieux_on_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lieux_on_enabled ON public.lieux USING btree (enabled);


--
-- Name: index_lieux_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lieux_on_name ON public.lieux USING btree (name);


--
-- Name: index_lieux_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lieux_on_organisation_id ON public.lieux USING btree (organisation_id);


--
-- Name: index_motif_libelles_on_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motif_libelles_on_service_id ON public.motif_libelles USING btree (service_id);


--
-- Name: index_motifs_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_on_deleted_at ON public.motifs USING btree (deleted_at);


--
-- Name: index_motifs_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_on_name ON public.motifs USING btree (name);


--
-- Name: index_motifs_on_name_scoped; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_motifs_on_name_scoped ON public.motifs USING btree (name, organisation_id, location_type, service_id) WHERE (deleted_at IS NULL);


--
-- Name: index_motifs_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_on_organisation_id ON public.motifs USING btree (organisation_id);


--
-- Name: index_motifs_on_reservable_online; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_on_reservable_online ON public.motifs USING btree (reservable_online);


--
-- Name: index_motifs_on_search_terms; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_on_search_terms ON public.motifs USING gin (search_terms);


--
-- Name: index_motifs_on_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_on_service_id ON public.motifs USING btree (service_id);


--
-- Name: index_motifs_plage_ouvertures_on_motif_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_plage_ouvertures_on_motif_id ON public.motifs_plage_ouvertures USING btree (motif_id);


--
-- Name: index_motifs_plage_ouvertures_on_plage_ouverture_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_motifs_plage_ouvertures_on_plage_ouverture_id ON public.motifs_plage_ouvertures USING btree (plage_ouverture_id);


--
-- Name: index_organisations_on_human_id_and_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organisations_on_human_id_and_territory_id ON public.organisations USING btree (human_id, territory_id) WHERE ((human_id)::text <> ''::text);


--
-- Name: index_organisations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_name ON public.organisations USING btree (name);


--
-- Name: index_organisations_on_name_and_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organisations_on_name_and_territory_id ON public.organisations USING btree (name, territory_id);


--
-- Name: index_organisations_on_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_territory_id ON public.organisations USING btree (territory_id);


--
-- Name: index_plage_ouvertures_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plage_ouvertures_on_agent_id ON public.plage_ouvertures USING btree (agent_id);


--
-- Name: index_plage_ouvertures_on_expired_cached; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plage_ouvertures_on_expired_cached ON public.plage_ouvertures USING btree (expired_cached);


--
-- Name: index_plage_ouvertures_on_lieu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plage_ouvertures_on_lieu_id ON public.plage_ouvertures USING btree (lieu_id);


--
-- Name: index_plage_ouvertures_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plage_ouvertures_on_organisation_id ON public.plage_ouvertures USING btree (organisation_id);


--
-- Name: index_rdv_events_on_rdv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdv_events_on_rdv_id ON public.rdv_events USING btree (rdv_id);


--
-- Name: index_rdvs_on_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_created_by ON public.rdvs USING btree (created_by);


--
-- Name: index_rdvs_on_lieu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_lieu_id ON public.rdvs USING btree (lieu_id);


--
-- Name: index_rdvs_on_motif_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_motif_id ON public.rdvs USING btree (motif_id);


--
-- Name: index_rdvs_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_organisation_id ON public.rdvs USING btree (organisation_id);


--
-- Name: index_rdvs_on_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_starts_at ON public.rdvs USING btree (starts_at);


--
-- Name: index_rdvs_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_status ON public.rdvs USING btree (status);


--
-- Name: index_rdvs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_on_updated_at ON public.rdvs USING btree (updated_at);


--
-- Name: index_rdvs_users_on_rdv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_users_on_rdv_id ON public.rdvs_users USING btree (rdv_id);


--
-- Name: index_rdvs_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rdvs_users_on_user_id ON public.rdvs_users USING btree (user_id);


--
-- Name: index_sector_attributions_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sector_attributions_on_agent_id ON public.sector_attributions USING btree (agent_id);


--
-- Name: index_sector_attributions_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sector_attributions_on_organisation_id ON public.sector_attributions USING btree (organisation_id);


--
-- Name: index_sector_attributions_on_sector_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sector_attributions_on_sector_id ON public.sector_attributions USING btree (sector_id);


--
-- Name: index_sectors_on_departement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sectors_on_departement ON public.sectors USING btree (departement);


--
-- Name: index_sectors_on_human_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sectors_on_human_id ON public.sectors USING btree (human_id);


--
-- Name: index_sectors_on_human_id_and_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sectors_on_human_id_and_territory_id ON public.sectors USING btree (human_id, territory_id);


--
-- Name: index_sectors_on_territory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sectors_on_territory_id ON public.sectors USING btree (territory_id);


--
-- Name: index_services_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_services_on_lower_name ON public.services USING btree (lower((name)::text));


--
-- Name: index_services_on_lower_short_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_services_on_lower_short_name ON public.services USING btree (lower((short_name)::text));


--
-- Name: index_services_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_on_name ON public.services USING btree (name);


--
-- Name: index_territories_on_departement_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_territories_on_departement_number ON public.territories USING btree (departement_number) WHERE ((departement_number)::text <> ''::text);


--
-- Name: index_user_profiles_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_profiles_on_organisation_id ON public.user_profiles USING btree (organisation_id);


--
-- Name: index_user_profiles_on_organisation_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_profiles_on_organisation_id_and_user_id ON public.user_profiles USING btree (organisation_id, user_id);


--
-- Name: index_user_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_profiles_on_user_id ON public.user_profiles USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON public.users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_invited_by_type_and_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_type_and_invited_by_id ON public.users USING btree (invited_by_type, invited_by_id);


--
-- Name: index_users_on_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_last_name ON public.users USING btree (last_name);


--
-- Name: index_users_on_phone_number_formatted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_phone_number_formatted ON public.users USING btree (phone_number_formatted);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_responsible_id ON public.users USING btree (responsible_id);


--
-- Name: index_users_on_search_terms; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_search_terms ON public.users USING gin (search_terms);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_webhook_endpoints_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_endpoints_on_organisation_id ON public.webhook_endpoints USING btree (organisation_id);


--
-- Name: index_zones_on_sector_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_sector_id ON public.zones USING btree (sector_id);


--
-- Name: rdv_events fk_rails_035f26fd74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdv_events
    ADD CONSTRAINT fk_rails_035f26fd74 FOREIGN KEY (rdv_id) REFERENCES public.rdvs(id);


--
-- Name: sector_attributions fk_rails_0594a899a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sector_attributions
    ADD CONSTRAINT fk_rails_0594a899a9 FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: file_attentes fk_rails_17eaaba2ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_attentes
    ADD CONSTRAINT fk_rails_17eaaba2ba FOREIGN KEY (rdv_id) REFERENCES public.rdvs(id);


--
-- Name: motifs fk_rails_257d0d082a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motifs
    ADD CONSTRAINT fk_rails_257d0d082a FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: motifs fk_rails_33a04338f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motifs
    ADD CONSTRAINT fk_rails_33a04338f9 FOREIGN KEY (service_id) REFERENCES public.services(id);


--
-- Name: rdvs fk_rails_37eac7572b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs
    ADD CONSTRAINT fk_rails_37eac7572b FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: lieux fk_rails_4b16f7f82c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lieux
    ADD CONSTRAINT fk_rails_4b16f7f82c FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: absences fk_rails_57fda25ce5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.absences
    ADD CONSTRAINT fk_rails_57fda25ce5 FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: plage_ouvertures fk_rails_5e481e3c5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plage_ouvertures
    ADD CONSTRAINT fk_rails_5e481e3c5e FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: webhook_endpoints fk_rails_609ee366f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_endpoints
    ADD CONSTRAINT fk_rails_609ee366f2 FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: users fk_rails_66aeb2c5c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_66aeb2c5c5 FOREIGN KEY (responsible_id) REFERENCES public.users(id);


--
-- Name: plage_ouvertures fk_rails_82107afa8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plage_ouvertures
    ADD CONSTRAINT fk_rails_82107afa8f FOREIGN KEY (lieu_id) REFERENCES public.lieux(id);


--
-- Name: plage_ouvertures fk_rails_957c6720ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plage_ouvertures
    ADD CONSTRAINT fk_rails_957c6720ae FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: absences fk_rails_a97f6d3edd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.absences
    ADD CONSTRAINT fk_rails_a97f6d3edd FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: rdvs fk_rails_bee9aec4c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs
    ADD CONSTRAINT fk_rails_bee9aec4c6 FOREIGN KEY (lieu_id) REFERENCES public.lieux(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: rdvs fk_rails_c61f26949a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdvs
    ADD CONSTRAINT fk_rails_c61f26949a FOREIGN KEY (motif_id) REFERENCES public.motifs(id);


--
-- Name: motif_libelles fk_rails_cb80a881d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motif_libelles
    ADD CONSTRAINT fk_rails_cb80a881d5 FOREIGN KEY (service_id) REFERENCES public.services(id);


--
-- Name: file_attentes fk_rails_d75a0af8dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_attentes
    ADD CONSTRAINT fk_rails_d75a0af8dc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: agents fk_rails_f2bdb8c2a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT fk_rails_f2bdb8c2a3 FOREIGN KEY (service_id) REFERENCES public.services(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20210301135256'),
('20210329100143'),
('20210412154510'),
('20210428130859'),
('20210505143758'),
('20210505151815'),
('20210506164841'),
('20210511111514'),
('20210601170102'),
('20210603103647'),
('20210607154248'),
('20210609204734'),
('20210707150348'),
('20210715091410'),
('20210715132110'),
('20210715175946'),
('20210715182043'),
('20210721221957'),
('20210723154303'),
('20210729000215'),
('20210804072701'),
('20210817150425'),
('20210818092811'),
('20210820115346'),
('20210824150636'),
('20210830145311'),
('20210909091303'),
('20210913213227'),
('20210922140002'),
('20210928142915'),
('20210929093324'),
('20210930100602'),
('20210930102134'),
('20210930125201'),
('20210930130027'),
('20210930143224'),
('20210930143411');


