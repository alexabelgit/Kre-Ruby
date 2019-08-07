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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pricing_model; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pricing_model AS ENUM (
    'products',
    'orders'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abuse_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.abuse_reports (
    id integer NOT NULL,
    reason integer NOT NULL,
    source integer NOT NULL,
    abusable_type character varying NOT NULL,
    abusable_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    additional_info character varying,
    status integer DEFAULT 0 NOT NULL,
    decision integer DEFAULT 0 NOT NULL
);


--
-- Name: abuse_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.abuse_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abuse_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.abuse_reports_id_seq OWNED BY public.abuse_reports.id;


--
-- Name: addon_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addon_prices (
    id integer NOT NULL,
    addon_id integer NOT NULL,
    ecommerce_platform_id integer NOT NULL,
    price_in_cents integer DEFAULT 0 NOT NULL,
    deprecated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    chargebee_id character varying
);


--
-- Name: addon_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.addon_prices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addon_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.addon_prices_id_seq OWNED BY public.addon_prices.id;


--
-- Name: addons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addons (
    id integer NOT NULL,
    name character varying NOT NULL,
    description character varying,
    state integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    slug character varying
);


--
-- Name: addons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.addons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.addons_id_seq OWNED BY public.addons.id;


--
-- Name: ahoy_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ahoy_events (
    id integer NOT NULL,
    visit_id integer,
    user_id integer,
    name character varying,
    properties jsonb,
    "time" timestamp without time zone
);


--
-- Name: ahoy_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ahoy_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ahoy_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ahoy_events_id_seq OWNED BY public.ahoy_events.id;


--
-- Name: applied_coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applied_coupons (
    id integer NOT NULL,
    coupon_id integer NOT NULL,
    bundle_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: applied_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applied_coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applied_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applied_coupons_id_seq OWNED BY public.applied_coupons.id;


--
-- Name: applied_discounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applied_discounts (
    id integer NOT NULL,
    bundle_id integer NOT NULL,
    package_discount_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: applied_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applied_discounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applied_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applied_discounts_id_seq OWNED BY public.applied_discounts.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: billing_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_subscriptions (
    id integer NOT NULL,
    store_id integer NOT NULL,
    kind integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    id_from_provider integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    payment_profile_id integer,
    disabled boolean DEFAULT false,
    cancel_at_end_of_period boolean DEFAULT true NOT NULL,
    current_period_ends_at timestamp without time zone,
    product_price_in_cents integer DEFAULT 0 NOT NULL
);


--
-- Name: billing_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.billing_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.billing_subscriptions_id_seq OWNED BY public.billing_subscriptions.id;


--
-- Name: bundle_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bundle_items (
    id integer NOT NULL,
    bundle_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    price_entry_id integer,
    price_entry_type character varying
);


--
-- Name: bundle_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bundle_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bundle_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bundle_items_id_seq OWNED BY public.bundle_items.id;


--
-- Name: bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bundles (
    id integer NOT NULL,
    store_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    state integer
);


--
-- Name: bundles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bundles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bundles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bundles_id_seq OWNED BY public.bundles.id;


--
-- Name: chargebee_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chargebee_customers (
    id bigint NOT NULL,
    id_from_provider character varying NOT NULL,
    email character varying,
    first_name character varying,
    last_name character varying,
    store_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: chargebee_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chargebee_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chargebee_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chargebee_customers_id_seq OWNED BY public.chargebee_customers.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    commentable_id integer NOT NULL,
    commentable_type character varying NOT NULL,
    display_name character varying
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: coupon_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupon_codes (
    id bigint NOT NULL,
    code character varying,
    discount_coupon_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    current boolean DEFAULT false NOT NULL
);


--
-- Name: coupon_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coupon_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupon_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coupon_codes_id_seq OWNED BY public.coupon_codes.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupons (
    id integer NOT NULL,
    name character varying NOT NULL,
    description character varying,
    code character varying NOT NULL,
    discount_type integer,
    discount_value double precision,
    state integer NOT NULL,
    expired_at timestamp without time zone,
    available_usages integer,
    ecommerce_platform_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    store_id integer NOT NULL,
    email character varying,
    name character varying,
    id_from_provider character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    anonymized boolean DEFAULT false NOT NULL
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: discount_coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discount_coupons (
    id bigint NOT NULL,
    id_from_provider character varying,
    valid_from timestamp without time zone,
    valid_until timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    issue_count integer DEFAULT 0 NOT NULL,
    "limit" integer,
    discount_amount integer,
    discount_type character varying,
    name character varying,
    code_type integer NOT NULL,
    send_per integer NOT NULL,
    store_id bigint,
    discount_sequence integer DEFAULT 0,
    status integer DEFAULT 0
);


--
-- Name: discount_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discount_coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discount_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discount_coupons_id_seq OWNED BY public.discount_coupons.id;


--
-- Name: downloads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.downloads (
    id bigint NOT NULL,
    name text,
    path text,
    url text,
    expired_at timestamp without time zone,
    filetype text,
    status integer,
    store_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: downloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.downloads_id_seq OWNED BY public.downloads.id;


--
-- Name: ecommerce_platforms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ecommerce_platforms (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ecommerce_platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ecommerce_platforms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ecommerce_platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ecommerce_platforms_id_seq OWNED BY public.ecommerce_platforms.id;


--
-- Name: email_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_events (
    id integer NOT NULL,
    email_id integer NOT NULL,
    source integer DEFAULT 0 NOT NULL,
    "timestamp" bigint,
    event text,
    "smtp-id" text,
    sg_event_id text,
    sg_message_id text,
    category text,
    newsletter text,
    response text,
    reason text,
    ip text,
    useragent text,
    attempt text,
    status text,
    type_id text,
    url text,
    additional_arguments text,
    event_post_timestamp bigint,
    raw text,
    asm_group_id smallint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: email_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_events_id_seq OWNED BY public.email_events.id;


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emails (
    id integer NOT NULL,
    emailable_id integer NOT NULL,
    emailable_type character varying NOT NULL,
    "smtp-id" text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    address character varying,
    helpful_id character varying NOT NULL,
    sg_message_id character varying
);


--
-- Name: emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emails_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emails_id_seq OWNED BY public.emails.id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stores (
    id integer NOT NULL,
    url character varying NOT NULL,
    name character varying NOT NULL,
    access_token character varying,
    provider integer,
    id_from_provider character varying NOT NULL,
    logo character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    storefront_status integer DEFAULT 0 NOT NULL,
    user_id integer NOT NULL,
    coupon_code character varying,
    phone character varying,
    installed_at timestamp without time zone,
    uninstalled_at timestamp without time zone,
    legal_name character varying,
    domain character varying,
    trial_started_at timestamp without time zone,
    trial_ends_at timestamp without time zone,
    ecommerce_platform_id integer,
    deactivated_at timestamp without time zone,
    products_count integer DEFAULT 0,
    number_of_orders_to_import integer DEFAULT 0 NOT NULL,
    billing_started_at timestamp without time zone,
    shopify_metafield_id text,
    last_sync_error_at timestamp without time zone,
    last_sync_error character varying,
    pricing_model public.pricing_model DEFAULT 'products'::public.pricing_model,
    shopify_metafields_synced_at timestamp without time zone,
    plan_emails_suspended boolean DEFAULT false
);


--
-- Name: enabled_addons; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.enabled_addons AS
 SELECT stores.id AS store_id,
    addon_prices.addon_id AS enabled_addon_id
   FROM ((((public.stores
     JOIN public.bundles ON ((bundles.store_id = stores.id)))
     JOIN public.bundle_items ON ((bundle_items.bundle_id = bundles.id)))
     JOIN public.addon_prices ON ((addon_prices.id = bundle_items.price_entry_id)))
     JOIN public.addons ON ((addons.id = addon_prices.addon_id)))
  WHERE ((bundles.state = 2) AND ((bundle_items.price_entry_type)::text = 'AddonPrice'::text))
  WITH NO DATA;


--
-- Name: external_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_assets (
    id integer NOT NULL,
    name character varying NOT NULL,
    extension character varying NOT NULL,
    digest character varying NOT NULL,
    key character varying NOT NULL,
    url character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_assets_id_seq OWNED BY public.external_assets.id;


--
-- Name: flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flags (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    flaggable_id integer NOT NULL,
    flaggable_type character varying NOT NULL
);


--
-- Name: flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flags_id_seq OWNED BY public.flags.id;


--
-- Name: imported_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imported_questions (
    id integer NOT NULL,
    product_id integer NOT NULL,
    customer_id integer NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    marked_for_deletion boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    body text,
    answer text,
    submitted_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    votes_count integer
);


--
-- Name: imported_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imported_questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imported_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imported_questions_id_seq OWNED BY public.imported_questions.id;


--
-- Name: imported_review_request_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imported_review_request_products (
    id integer NOT NULL,
    product_id integer NOT NULL,
    imported_review_request_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imported_review_request_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imported_review_request_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imported_review_request_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imported_review_request_products_id_seq OWNED BY public.imported_review_request_products.id;


--
-- Name: imported_review_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imported_review_requests (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    scheduled_for timestamp without time zone NOT NULL,
    marked_for_deletion boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imported_review_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imported_review_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imported_review_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imported_review_requests_id_seq OWNED BY public.imported_review_requests.id;


--
-- Name: imported_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imported_reviews (
    id integer NOT NULL,
    product_id integer,
    customer_id integer NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    marked_for_deletion boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    rating integer,
    feedback text,
    comment text,
    review_date timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    votes_count integer,
    title character varying
);


--
-- Name: imported_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imported_reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imported_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imported_reviews_id_seq OWNED BY public.imported_reviews.id;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    id integer NOT NULL,
    mediable_id integer NOT NULL,
    mediable_type character varying NOT NULL,
    media_type integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cloudinary_public_id character varying,
    status integer DEFAULT 0 NOT NULL,
    explicit boolean DEFAULT false NOT NULL,
    moderated boolean DEFAULT false NOT NULL,
    moderation_result jsonb
);


--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_id_seq OWNED BY public.media.id;


--
-- Name: order_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_products (
    id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: order_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_products_id_seq OWNED BY public.order_products.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    id_from_provider character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    order_number character varying,
    order_date timestamp without time zone,
    last_synced_at timestamp without time zone,
    currency character varying DEFAULT 'USD'::character varying,
    item_total numeric(8,2) DEFAULT 0.0 NOT NULL,
    total numeric(8,2) DEFAULT 0.0 NOT NULL
);


--
-- Name: orders_gifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders_gifts (
    id bigint NOT NULL,
    bundle_id bigint,
    amount integer,
    applied_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: orders_gifts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_gifts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_gifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_gifts_id_seq OWNED BY public.orders_gifts.id;


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: package_discounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.package_discounts (
    id integer NOT NULL,
    addons_count integer,
    discount_percents integer,
    ecommerce_platform_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    chargebee_id character varying,
    deprecated_at timestamp without time zone
);


--
-- Name: package_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.package_discounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: package_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.package_discounts_id_seq OWNED BY public.package_discounts.id;


--
-- Name: payment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_methods (
    id bigint NOT NULL,
    id_from_provider character varying,
    processing_platform character varying,
    payment_type character varying,
    card_type character varying,
    masked_number character varying,
    expiry_month integer,
    expiry_year integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    chargebee_customer_id integer
);


--
-- Name: payment_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_methods_id_seq OWNED BY public.payment_methods.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id bigint NOT NULL,
    id_from_provider character varying,
    amount integer,
    payment_type character varying,
    description text,
    payment_made_at timestamp without time zone,
    subscription_id bigint,
    store_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id integer NOT NULL,
    ecommerce_platform_id integer,
    name character varying,
    price_in_cents integer,
    deprecated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    chargebee_id character varying,
    slug character varying,
    orders_limit integer,
    extension_price_in_cents integer,
    extended_orders_limit integer,
    is_secret boolean DEFAULT false,
    popular boolean DEFAULT false,
    description text,
    overages_limit_in_cents integer,
    pricing_model public.pricing_model,
    min_products_limit integer DEFAULT 0,
    max_products_limit integer
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: product_group_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_group_products (
    id integer NOT NULL,
    product_group_id integer NOT NULL,
    product_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_group_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_group_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_group_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_group_products_id_seq OWNED BY public.product_group_products.id;


--
-- Name: product_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_groups (
    id integer NOT NULL,
    name character varying,
    store_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_groups_id_seq OWNED BY public.product_groups.id;


--
-- Name: product_limits_modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_limits_modifiers (
    id bigint NOT NULL,
    store_id bigint,
    additional_products integer,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_limits_modifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_limits_modifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_limits_modifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_limits_modifiers_id_seq OWNED BY public.product_limits_modifiers.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id integer NOT NULL,
    store_id integer NOT NULL,
    name character varying NOT NULL,
    id_from_provider character varying NOT NULL,
    category character varying,
    featured_image character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url character varying,
    suppressed boolean DEFAULT false NOT NULL,
    storefront_availability integer DEFAULT 0 NOT NULL,
    shopify_metafield_id text,
    overwrite_featured_image boolean DEFAULT false,
    synced_image_backup character varying,
    status integer DEFAULT 0,
    skus character varying[] DEFAULT '{}'::character varying[],
    last_synced_at timestamp without time zone,
    image_last_synced_at timestamp without time zone,
    shopify_metafields_synced_at timestamp without time zone,
    original_image_url text
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: products_sync_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products_sync_batches (
    id bigint NOT NULL,
    store_id bigint,
    sync_id character varying,
    products_info jsonb,
    arguments jsonb,
    processed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: products_sync_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_sync_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_sync_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_sync_batches_id_seq OWNED BY public.products_sync_batches.id;


--
-- Name: promotion_discount_coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotion_discount_coupons (
    id bigint NOT NULL,
    promotion_id bigint,
    discount_coupon_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: promotion_discount_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotion_discount_coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_discount_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.promotion_discount_coupons_id_seq OWNED BY public.promotion_discount_coupons.id;


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotions (
    id bigint NOT NULL,
    name character varying,
    template text,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    store_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id_from_provider character varying,
    usage_count integer DEFAULT 0 NOT NULL,
    incentive boolean DEFAULT false
);


--
-- Name: promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.promotions_id_seq OWNED BY public.promotions.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id integer NOT NULL,
    product_id integer NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    customer_id integer,
    submitted_at timestamp without time zone NOT NULL,
    verification integer DEFAULT 0 NOT NULL,
    votes_count integer DEFAULT 0,
    migrated boolean DEFAULT false
);


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- Name: review_request_coupon_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_request_coupon_codes (
    id bigint NOT NULL,
    coupon_code_id bigint,
    review_request_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: review_request_coupon_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_request_coupon_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_request_coupon_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_request_coupon_codes_id_seq OWNED BY public.review_request_coupon_codes.id;


--
-- Name: review_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_requests (
    id integer NOT NULL,
    order_id integer,
    scheduled_for timestamp without time zone,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    customer_id integer,
    with_incentive boolean DEFAULT false
);


--
-- Name: review_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_requests_id_seq OWNED BY public.review_requests.id;


--
-- Name: review_reviewables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_reviewables (
    id bigint NOT NULL,
    review_id bigint,
    reviewable_id integer NOT NULL,
    reviewable_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: review_reviewables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_reviewables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_reviewables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_reviewables_id_seq OWNED BY public.review_reviewables.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    order_product_id integer,
    status integer DEFAULT 0 NOT NULL,
    rating integer,
    feedback text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    review_date timestamp without time zone,
    publish_date timestamp without time zone,
    review_request_id integer,
    source integer DEFAULT 0 NOT NULL,
    verification integer DEFAULT 0 NOT NULL,
    votes_count integer DEFAULT 0,
    transaction_item_id integer,
    customer_id integer,
    with_incentive boolean DEFAULT false,
    migrated boolean DEFAULT false,
    title character varying
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id integer NOT NULL,
    var character varying NOT NULL,
    value text,
    target_type character varying NOT NULL,
    target_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: social_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_accounts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    provider integer NOT NULL,
    uid character varying NOT NULL,
    access_token character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    access_secret character varying
);


--
-- Name: social_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_accounts_id_seq OWNED BY public.social_accounts.id;


--
-- Name: social_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_posts (
    id integer NOT NULL,
    postable_id integer NOT NULL,
    postable_type character varying NOT NULL,
    provider integer NOT NULL,
    uid character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: social_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_posts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_posts_id_seq OWNED BY public.social_posts.id;


--
-- Name: store_products_usages; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.store_products_usages AS
 SELECT stores.id AS store_id,
    count(products.id) AS products_count
   FROM (public.stores
     JOIN public.products ON ((stores.id = products.store_id)))
  WHERE ((products.suppressed = false) AND (products.status = 0))
  GROUP BY stores.id
  WITH NO DATA;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    state integer,
    bundle_id integer NOT NULL,
    last_payment_at timestamp without time zone,
    expired_at timestamp without time zone,
    payment_error character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id_from_provider text,
    processing_platform character varying DEFAULT 'shopify'::character varying NOT NULL,
    activated_on timestamp without time zone,
    cancelled_on timestamp without time zone,
    next_billing_at timestamp without time zone,
    billing_interval character varying DEFAULT 'month'::character varying,
    total_due integer DEFAULT 0,
    due_invoices_count integer,
    due_since timestamp without time zone,
    chargebee_customer_id integer,
    hosted_page_id text,
    dunning_start_date timestamp without time zone,
    dunning_end_date timestamp without time zone,
    cancellation_reason character varying,
    initial_bundle_id integer,
    gifted boolean DEFAULT false,
    migrated_to_products_billing_at timestamp without time zone,
    gifted_products_amount integer,
    gifted_products_valid_till timestamp without time zone
);


--
-- Name: store_subscription_usages; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.store_subscription_usages AS
 SELECT stores.id AS store_id,
    (max(plans.orders_limit) + COALESCE(max(gifted_orders.amount), (0)::bigint)) AS orders_limit,
    COALESCE(max(plans.min_products_limit), 0) AS min_products_limit,
    COALESCE(max(plans.max_products_limit), 0) AS max_products_limit,
    COALESCE(max(plans.pricing_model), 'orders'::public.pricing_model) AS pricing_model,
    (max(subscriptions.next_billing_at) - '1 mon'::interval) AS cycle_start,
    max(subscriptions.next_billing_at) AS cycle_end,
    count(DISTINCT orders.id) AS orders_amount
   FROM ((((((((public.stores
     JOIN public.bundles ON ((bundles.store_id = stores.id)))
     LEFT JOIN public.orders_gifts ON ((orders_gifts.bundle_id = bundles.id)))
     JOIN public.bundle_items ON ((bundle_items.bundle_id = bundles.id)))
     JOIN public.plans ON (((bundle_items.price_entry_id = plans.id) AND ((bundle_items.price_entry_type)::text = 'Plan'::text))))
     JOIN public.subscriptions ON (((subscriptions.bundle_id = bundles.id) OR (subscriptions.initial_bundle_id = bundles.id))))
     JOIN public.customers ON ((customers.store_id = stores.id)))
     JOIN public.orders ON ((orders.customer_id = customers.id)))
     LEFT JOIN ( SELECT bundles_1.id AS bundle_id,
            sum(orders_gifts_1.amount) AS amount
           FROM ((public.orders_gifts orders_gifts_1
             JOIN public.bundles bundles_1 ON ((orders_gifts_1.bundle_id = bundles_1.id)))
             JOIN public.subscriptions subscriptions_1 ON (((subscriptions_1.bundle_id = bundles_1.id) OR (subscriptions_1.initial_bundle_id = bundles_1.id))))
          WHERE ((subscriptions_1.state = 3) AND ((orders_gifts_1.applied_at >= (subscriptions_1.next_billing_at - '1 mon'::interval)) AND (orders_gifts_1.applied_at <= subscriptions_1.next_billing_at)))
          GROUP BY bundles_1.id) gifted_orders ON ((bundles.id = gifted_orders.bundle_id)))
  WHERE ((subscriptions.state = 3) AND (orders.order_date > stores.created_at) AND ((orders.created_at >= (subscriptions.next_billing_at - '1 mon'::interval)) AND (orders.created_at <= subscriptions.next_billing_at)))
  GROUP BY stores.id
  WITH NO DATA;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: store_summaries; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.store_summaries AS
 SELECT users.email,
    stores.id AS store_id,
    stores.name AS store_name,
    stores.created_at AS first_installed_at,
    stores.installed_at AS latest_installed_at,
        CASE
            WHEN (stores.access_token IS NULL) THEN 'inactive'::text
            ELSE 'active'::text
        END AS store_status,
        CASE
            WHEN (stores.status = 1) THEN 'active'::text
            ELSE 'inactive'::text
        END AS backend_status,
        CASE
            WHEN (stores.storefront_status = 1) THEN 'active'::text
            ELSE 'inactive'::text
        END AS storefront_status,
    ecommerce_platforms.name AS ecommerce_platform,
    COALESCE(active_plans.plan_name, (
        CASE
            WHEN (stores.trial_ends_at > now()) THEN 'Trial'::text
            WHEN (stores.trial_ends_at > (now() - '5 days'::interval)) THEN 'Grace period'::text
            ELSE 'Trial ended'::text
        END)::character varying) AS plan_name,
    active_plans.price_in_cents
   FROM (((public.users
     LEFT JOIN public.stores ON ((users.id = stores.user_id)))
     JOIN public.ecommerce_platforms ON ((ecommerce_platforms.id = stores.ecommerce_platform_id)))
     LEFT JOIN ( SELECT bundles.store_id,
            plans.name AS plan_name,
            plans.price_in_cents
           FROM ((public.bundles
             JOIN public.bundle_items ON ((bundles.id = bundle_items.bundle_id)))
             JOIN public.plans ON (((plans.id = bundle_items.price_entry_id) AND ((bundle_items.price_entry_type)::text = 'Plan'::text))))
          WHERE (bundles.state = 2)) active_plans ON ((active_plans.store_id = stores.id)))
  ORDER BY stores.id;


--
-- Name: stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stores_id_seq OWNED BY public.stores.id;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: suggested_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suggested_plans (
    id bigint NOT NULL,
    store_id bigint,
    plan_id bigint,
    priority integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: suggested_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suggested_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suggested_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suggested_plans_id_seq OWNED BY public.suggested_plans.id;


--
-- Name: suppressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppressions (
    id integer NOT NULL,
    source integer,
    customer_id integer,
    store_id integer,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: suppressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suppressions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suppressions_id_seq OWNED BY public.suppressions.id;


--
-- Name: tolk_locales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tolk_locales (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: tolk_locales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tolk_locales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tolk_locales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tolk_locales_id_seq OWNED BY public.tolk_locales.id;


--
-- Name: tolk_phrases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tolk_phrases (
    id integer NOT NULL,
    key text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: tolk_phrases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tolk_phrases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tolk_phrases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tolk_phrases_id_seq OWNED BY public.tolk_phrases.id;


--
-- Name: tolk_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tolk_translations (
    id integer NOT NULL,
    phrase_id integer,
    locale_id integer,
    text text,
    previous_text text,
    primary_updated boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: tolk_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tolk_translations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tolk_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tolk_translations_id_seq OWNED BY public.tolk_translations.id;


--
-- Name: transaction_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_items (
    id bigint NOT NULL,
    order_id bigint,
    review_request_id bigint,
    customer_id bigint,
    reviewable_id integer NOT NULL,
    reviewable_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: transaction_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_items_id_seq OWNED BY public.transaction_items.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
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
-- Name: visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visits (
    id integer NOT NULL,
    visit_token character varying,
    visitor_token character varying,
    ip character varying,
    user_agent text,
    referrer text,
    landing_page text,
    user_id integer,
    referring_domain character varying,
    search_keyword character varying,
    browser character varying,
    os character varying,
    device_type character varying,
    screen_height integer,
    screen_width integer,
    country character varying,
    region character varying,
    city character varying,
    postal_code character varying,
    latitude numeric,
    longitude numeric,
    utm_source character varying,
    utm_medium character varying,
    utm_term character varying,
    utm_content character varying,
    utm_campaign character varying,
    started_at timestamp without time zone
);


--
-- Name: visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.visits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.visits_id_seq OWNED BY public.visits.id;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    votable_id integer NOT NULL,
    votable_type character varying NOT NULL
);


--
-- Name: votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.votes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.votes_id_seq OWNED BY public.votes.id;


--
-- Name: abuse_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuse_reports ALTER COLUMN id SET DEFAULT nextval('public.abuse_reports_id_seq'::regclass);


--
-- Name: addon_prices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addon_prices ALTER COLUMN id SET DEFAULT nextval('public.addon_prices_id_seq'::regclass);


--
-- Name: addons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addons ALTER COLUMN id SET DEFAULT nextval('public.addons_id_seq'::regclass);


--
-- Name: ahoy_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events ALTER COLUMN id SET DEFAULT nextval('public.ahoy_events_id_seq'::regclass);


--
-- Name: applied_coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applied_coupons ALTER COLUMN id SET DEFAULT nextval('public.applied_coupons_id_seq'::regclass);


--
-- Name: applied_discounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applied_discounts ALTER COLUMN id SET DEFAULT nextval('public.applied_discounts_id_seq'::regclass);


--
-- Name: billing_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.billing_subscriptions_id_seq'::regclass);


--
-- Name: bundle_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bundle_items ALTER COLUMN id SET DEFAULT nextval('public.bundle_items_id_seq'::regclass);


--
-- Name: bundles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bundles ALTER COLUMN id SET DEFAULT nextval('public.bundles_id_seq'::regclass);


--
-- Name: chargebee_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chargebee_customers ALTER COLUMN id SET DEFAULT nextval('public.chargebee_customers_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: coupon_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_codes ALTER COLUMN id SET DEFAULT nextval('public.coupon_codes_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: discount_coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount_coupons ALTER COLUMN id SET DEFAULT nextval('public.discount_coupons_id_seq'::regclass);


--
-- Name: downloads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.downloads ALTER COLUMN id SET DEFAULT nextval('public.downloads_id_seq'::regclass);


--
-- Name: ecommerce_platforms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_platforms ALTER COLUMN id SET DEFAULT nextval('public.ecommerce_platforms_id_seq'::regclass);


--
-- Name: email_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_events ALTER COLUMN id SET DEFAULT nextval('public.email_events_id_seq'::regclass);


--
-- Name: emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails ALTER COLUMN id SET DEFAULT nextval('public.emails_id_seq'::regclass);


--
-- Name: external_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_assets ALTER COLUMN id SET DEFAULT nextval('public.external_assets_id_seq'::regclass);


--
-- Name: flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flags ALTER COLUMN id SET DEFAULT nextval('public.flags_id_seq'::regclass);


--
-- Name: imported_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_questions ALTER COLUMN id SET DEFAULT nextval('public.imported_questions_id_seq'::regclass);


--
-- Name: imported_review_request_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_review_request_products ALTER COLUMN id SET DEFAULT nextval('public.imported_review_request_products_id_seq'::regclass);


--
-- Name: imported_review_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_review_requests ALTER COLUMN id SET DEFAULT nextval('public.imported_review_requests_id_seq'::regclass);


--
-- Name: imported_reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_reviews ALTER COLUMN id SET DEFAULT nextval('public.imported_reviews_id_seq'::regclass);


--
-- Name: media id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- Name: order_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_products ALTER COLUMN id SET DEFAULT nextval('public.order_products_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: orders_gifts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_gifts ALTER COLUMN id SET DEFAULT nextval('public.orders_gifts_id_seq'::regclass);


--
-- Name: package_discounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_discounts ALTER COLUMN id SET DEFAULT nextval('public.package_discounts_id_seq'::regclass);


--
-- Name: payment_methods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_methods ALTER COLUMN id SET DEFAULT nextval('public.payment_methods_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: product_group_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_group_products ALTER COLUMN id SET DEFAULT nextval('public.product_group_products_id_seq'::regclass);


--
-- Name: product_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_groups ALTER COLUMN id SET DEFAULT nextval('public.product_groups_id_seq'::regclass);


--
-- Name: product_limits_modifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_limits_modifiers ALTER COLUMN id SET DEFAULT nextval('public.product_limits_modifiers_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: products_sync_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_sync_batches ALTER COLUMN id SET DEFAULT nextval('public.products_sync_batches_id_seq'::regclass);


--
-- Name: promotion_discount_coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_discount_coupons ALTER COLUMN id SET DEFAULT nextval('public.promotion_discount_coupons_id_seq'::regclass);


--
-- Name: promotions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions ALTER COLUMN id SET DEFAULT nextval('public.promotions_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- Name: review_request_coupon_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_request_coupon_codes ALTER COLUMN id SET DEFAULT nextval('public.review_request_coupon_codes_id_seq'::regclass);


--
-- Name: review_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_requests ALTER COLUMN id SET DEFAULT nextval('public.review_requests_id_seq'::regclass);


--
-- Name: review_reviewables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_reviewables ALTER COLUMN id SET DEFAULT nextval('public.review_reviewables_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: social_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts ALTER COLUMN id SET DEFAULT nextval('public.social_accounts_id_seq'::regclass);


--
-- Name: social_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_posts ALTER COLUMN id SET DEFAULT nextval('public.social_posts_id_seq'::regclass);


--
-- Name: stores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores ALTER COLUMN id SET DEFAULT nextval('public.stores_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: suggested_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suggested_plans ALTER COLUMN id SET DEFAULT nextval('public.suggested_plans_id_seq'::regclass);


--
-- Name: suppressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions ALTER COLUMN id SET DEFAULT nextval('public.suppressions_id_seq'::regclass);


--
-- Name: tolk_locales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tolk_locales ALTER COLUMN id SET DEFAULT nextval('public.tolk_locales_id_seq'::regclass);


--
-- Name: tolk_phrases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tolk_phrases ALTER COLUMN id SET DEFAULT nextval('public.tolk_phrases_id_seq'::regclass);


--
-- Name: tolk_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tolk_translations ALTER COLUMN id SET DEFAULT nextval('public.tolk_translations_id_seq'::regclass);


--
-- Name: transaction_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_items ALTER COLUMN id SET DEFAULT nextval('public.transaction_items_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits ALTER COLUMN id SET DEFAULT nextval('public.visits_id_seq'::regclass);


--
-- Name: votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes ALTER COLUMN id SET DEFAULT nextval('public.votes_id_seq'::regclass);


--
-- Name: abuse_reports abuse_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuse_reports
    ADD CONSTRAINT abuse_reports_pkey PRIMARY KEY (id);


--
-- Name: addon_prices addon_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addon_prices
    ADD CONSTRAINT addon_prices_pkey PRIMARY KEY (id);


--
-- Name: addons addons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addons
    ADD CONSTRAINT addons_pkey PRIMARY KEY (id);


--
-- Name: ahoy_events ahoy_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events
    ADD CONSTRAINT ahoy_events_pkey PRIMARY KEY (id);


--
-- Name: applied_coupons applied_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applied_coupons
    ADD CONSTRAINT applied_coupons_pkey PRIMARY KEY (id);


--
-- Name: applied_discounts applied_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applied_discounts
    ADD CONSTRAINT applied_discounts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: billing_subscriptions billing_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_subscriptions
    ADD CONSTRAINT billing_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: bundle_items bundle_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bundle_items
    ADD CONSTRAINT bundle_items_pkey PRIMARY KEY (id);


--
-- Name: bundles bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bundles
    ADD CONSTRAINT bundles_pkey PRIMARY KEY (id);


--
-- Name: chargebee_customers chargebee_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chargebee_customers
    ADD CONSTRAINT chargebee_customers_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: coupon_codes coupon_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_codes
    ADD CONSTRAINT coupon_codes_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: discount_coupons discount_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount_coupons
    ADD CONSTRAINT discount_coupons_pkey PRIMARY KEY (id);


--
-- Name: downloads downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.downloads
    ADD CONSTRAINT downloads_pkey PRIMARY KEY (id);


--
-- Name: ecommerce_platforms ecommerce_platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ecommerce_platforms
    ADD CONSTRAINT ecommerce_platforms_pkey PRIMARY KEY (id);


--
-- Name: email_events email_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_pkey PRIMARY KEY (id);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: external_assets external_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_assets
    ADD CONSTRAINT external_assets_pkey PRIMARY KEY (id);


--
-- Name: flags flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flags
    ADD CONSTRAINT flags_pkey PRIMARY KEY (id);


--
-- Name: imported_questions imported_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_questions
    ADD CONSTRAINT imported_questions_pkey PRIMARY KEY (id);


--
-- Name: imported_review_request_products imported_review_request_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_review_request_products
    ADD CONSTRAINT imported_review_request_products_pkey PRIMARY KEY (id);


--
-- Name: imported_review_requests imported_review_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_review_requests
    ADD CONSTRAINT imported_review_requests_pkey PRIMARY KEY (id);


--
-- Name: imported_reviews imported_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imported_reviews
    ADD CONSTRAINT imported_reviews_pkey PRIMARY KEY (id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: order_products order_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_products
    ADD CONSTRAINT order_products_pkey PRIMARY KEY (id);


--
-- Name: orders_gifts orders_gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders_gifts
    ADD CONSTRAINT orders_gifts_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: package_discounts package_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.package_discounts
    ADD CONSTRAINT package_discounts_pkey PRIMARY KEY (id);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: product_group_products product_group_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_group_products
    ADD CONSTRAINT product_group_products_pkey PRIMARY KEY (id);


--
-- Name: product_groups product_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_groups
    ADD CONSTRAINT product_groups_pkey PRIMARY KEY (id);


--
-- Name: product_limits_modifiers product_limits_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_limits_modifiers
    ADD CONSTRAINT product_limits_modifiers_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products_sync_batches products_sync_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products_sync_batches
    ADD CONSTRAINT products_sync_batches_pkey PRIMARY KEY (id);


--
-- Name: promotion_discount_coupons promotion_discount_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_discount_coupons
    ADD CONSTRAINT promotion_discount_coupons_pkey PRIMARY KEY (id);


--
-- Name: promotions promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: review_request_coupon_codes review_request_coupon_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_request_coupon_codes
    ADD CONSTRAINT review_request_coupon_codes_pkey PRIMARY KEY (id);


--
-- Name: review_requests review_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_requests
    ADD CONSTRAINT review_requests_pkey PRIMARY KEY (id);


--
-- Name: review_reviewables review_reviewables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_reviewables
    ADD CONSTRAINT review_reviewables_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: social_accounts social_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts
    ADD CONSTRAINT social_accounts_pkey PRIMARY KEY (id);


--
-- Name: social_posts social_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_posts
    ADD CONSTRAINT social_posts_pkey PRIMARY KEY (id);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: suggested_plans suggested_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suggested_plans
    ADD CONSTRAINT suggested_plans_pkey PRIMARY KEY (id);


--
-- Name: suppressions suppressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions
    ADD CONSTRAINT suppressions_pkey PRIMARY KEY (id);


--
-- Name: tolk_locales tolk_locales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tolk_locales
    ADD CONSTRAINT tolk_locales_pkey PRIMARY KEY (id);


--
-- Name: tolk_phrases tolk_phrases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tolk_phrases
    ADD CONSTRAINT tolk_phrases_pkey PRIMARY KEY (id);


--
-- Name: tolk_translations tolk_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tolk_translations
    ADD CONSTRAINT tolk_translations_pkey PRIMARY KEY (id);


--
-- Name: transaction_items transaction_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_items
    ADD CONSTRAINT transaction_items_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: index_abuse_reports_on_abusable_type_and_abusable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abuse_reports_on_abusable_type_and_abusable_id ON public.abuse_reports USING btree (abusable_type, abusable_id);


--
-- Name: index_abuse_reports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abuse_reports_on_created_at ON public.abuse_reports USING btree (created_at);


--
-- Name: index_addon_prices_on_addon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addon_prices_on_addon_id ON public.addon_prices USING btree (addon_id);


--
-- Name: index_addon_prices_on_ecommerce_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addon_prices_on_ecommerce_platform_id ON public.addon_prices USING btree (ecommerce_platform_id);


--
-- Name: index_ahoy_events_on_name_and_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_name_and_time ON public.ahoy_events USING btree (name, "time");


--
-- Name: index_ahoy_events_on_user_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_user_id_and_name ON public.ahoy_events USING btree (user_id, name);


--
-- Name: index_ahoy_events_on_visit_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_visit_id_and_name ON public.ahoy_events USING btree (visit_id, name);


--
-- Name: index_applied_coupons_on_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_applied_coupons_on_bundle_id ON public.applied_coupons USING btree (bundle_id);


--
-- Name: index_applied_coupons_on_coupon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_applied_coupons_on_coupon_id ON public.applied_coupons USING btree (coupon_id);


--
-- Name: index_applied_discounts_on_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_applied_discounts_on_bundle_id ON public.applied_discounts USING btree (bundle_id);


--
-- Name: index_applied_discounts_on_package_discount_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_applied_discounts_on_package_discount_id ON public.applied_discounts USING btree (package_discount_id);


--
-- Name: index_billing_subscriptions_on_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_billing_subscriptions_on_id_from_provider ON public.billing_subscriptions USING btree (id_from_provider);


--
-- Name: index_billing_subscriptions_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_billing_subscriptions_on_store_id ON public.billing_subscriptions USING btree (store_id);


--
-- Name: index_billing_subscriptions_on_store_id_and_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_billing_subscriptions_on_store_id_and_kind ON public.billing_subscriptions USING btree (store_id, kind);


--
-- Name: index_bundle_items_on_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bundle_items_on_bundle_id ON public.bundle_items USING btree (bundle_id);


--
-- Name: index_bundle_items_on_price_entry_id_and_price_entry_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bundle_items_on_price_entry_id_and_price_entry_type ON public.bundle_items USING btree (price_entry_id, price_entry_type);


--
-- Name: index_bundles_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bundles_on_state ON public.bundles USING btree (state);


--
-- Name: index_bundles_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bundles_on_store_id ON public.bundles USING btree (store_id);


--
-- Name: index_chargebee_customers_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chargebee_customers_on_store_id ON public.chargebee_customers USING btree (store_id);


--
-- Name: index_comments_on_commentable_id_and_commentable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_id_and_commentable_type ON public.comments USING btree (commentable_id, commentable_type);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_coupon_codes_on_discount_coupon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupon_codes_on_discount_coupon_id ON public.coupon_codes USING btree (discount_coupon_id);


--
-- Name: index_coupons_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupons_on_code ON public.coupons USING btree (code);


--
-- Name: index_coupons_on_ecommerce_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupons_on_ecommerce_platform_id ON public.coupons USING btree (ecommerce_platform_id);


--
-- Name: index_coupons_on_expired_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupons_on_expired_at ON public.coupons USING btree (expired_at);


--
-- Name: index_coupons_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupons_on_name ON public.coupons USING btree (name);


--
-- Name: index_coupons_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coupons_on_state ON public.coupons USING btree (state);


--
-- Name: index_customers_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customers_on_store_id ON public.customers USING btree (store_id);


--
-- Name: index_customers_on_store_id_and_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_customers_on_store_id_and_id_from_provider ON public.customers USING btree (store_id, id_from_provider);


--
-- Name: index_discount_coupons_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discount_coupons_on_created_at ON public.discount_coupons USING btree (created_at);


--
-- Name: index_discount_coupons_on_issue_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discount_coupons_on_issue_count ON public.discount_coupons USING btree (issue_count);


--
-- Name: index_discount_coupons_on_limit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discount_coupons_on_limit ON public.discount_coupons USING btree ("limit");


--
-- Name: index_discount_coupons_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discount_coupons_on_store_id ON public.discount_coupons USING btree (store_id);


--
-- Name: index_discount_coupons_on_valid_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discount_coupons_on_valid_from ON public.discount_coupons USING btree (valid_from);


--
-- Name: index_discount_coupons_on_valid_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discount_coupons_on_valid_until ON public.discount_coupons USING btree (valid_until);


--
-- Name: index_downloads_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_downloads_on_store_id ON public.downloads USING btree (store_id);


--
-- Name: index_ecommerce_platforms_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ecommerce_platforms_on_name ON public.ecommerce_platforms USING btree (name);


--
-- Name: index_email_events_on_email_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_events_on_email_id ON public.email_events USING btree (email_id);


--
-- Name: index_emails_on_emailable_id_and_emailable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emails_on_emailable_id_and_emailable_type ON public.emails USING btree (emailable_id, emailable_type);


--
-- Name: index_emails_on_helpful_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_emails_on_helpful_id ON public.emails USING btree (helpful_id);


--
-- Name: index_emails_on_smtp_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emails_on_smtp_id ON public.emails USING btree ("smtp-id");


--
-- Name: index_enabled_addons_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enabled_addons_on_store_id ON public.enabled_addons USING btree (store_id);


--
-- Name: index_enabled_addons_on_store_id_and_enabled_addon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enabled_addons_on_store_id_and_enabled_addon_id ON public.enabled_addons USING btree (store_id, enabled_addon_id);


--
-- Name: index_flags_on_flaggable_id_and_flaggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flags_on_flaggable_id_and_flaggable_type ON public.flags USING btree (flaggable_id, flaggable_type);


--
-- Name: index_imported_questions_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_questions_on_customer_id ON public.imported_questions USING btree (customer_id);


--
-- Name: index_imported_questions_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_questions_on_product_id ON public.imported_questions USING btree (product_id);


--
-- Name: index_imported_request_products_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_request_products_on_request_id ON public.imported_review_request_products USING btree (imported_review_request_id);


--
-- Name: index_imported_review_request_products_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_review_request_products_on_product_id ON public.imported_review_request_products USING btree (product_id);


--
-- Name: index_imported_review_requests_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_review_requests_on_customer_id ON public.imported_review_requests USING btree (customer_id);


--
-- Name: index_imported_reviews_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_reviews_on_created_at ON public.imported_reviews USING btree (created_at);


--
-- Name: index_imported_reviews_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_reviews_on_customer_id ON public.imported_reviews USING btree (customer_id);


--
-- Name: index_imported_reviews_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imported_reviews_on_product_id ON public.imported_reviews USING btree (product_id);


--
-- Name: index_media_on_mediable_id_and_mediable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_on_mediable_id_and_mediable_type ON public.media USING btree (mediable_id, mediable_type);


--
-- Name: index_order_products_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_products_on_order_id ON public.order_products USING btree (order_id);


--
-- Name: index_order_products_on_order_id_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_order_products_on_order_id_and_product_id ON public.order_products USING btree (order_id, product_id);


--
-- Name: index_order_products_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_products_on_product_id ON public.order_products USING btree (product_id);


--
-- Name: index_orders_gifts_on_applied_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_gifts_on_applied_at ON public.orders_gifts USING btree (applied_at);


--
-- Name: index_orders_gifts_on_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_gifts_on_bundle_id ON public.orders_gifts USING btree (bundle_id);


--
-- Name: index_orders_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_created_at ON public.orders USING btree (created_at);


--
-- Name: index_orders_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_customer_id ON public.orders USING btree (customer_id);


--
-- Name: index_orders_on_customer_id_and_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_customer_id_and_id_from_provider ON public.orders USING btree (customer_id, id_from_provider);


--
-- Name: index_orders_on_customer_id_and_order_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_customer_id_and_order_number ON public.orders USING btree (customer_id, order_number);


--
-- Name: index_orders_on_order_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_order_date ON public.orders USING btree (order_date);


--
-- Name: index_package_discounts_addons_per_platform; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_package_discounts_addons_per_platform ON public.package_discounts USING btree (addons_count, ecommerce_platform_id);


--
-- Name: index_package_discounts_on_ecommerce_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_package_discounts_on_ecommerce_platform_id ON public.package_discounts USING btree (ecommerce_platform_id);


--
-- Name: index_payment_methods_on_chargebee_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_methods_on_chargebee_customer_id ON public.payment_methods USING btree (chargebee_customer_id);


--
-- Name: index_payment_methods_on_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_methods_on_id_from_provider ON public.payment_methods USING btree (id_from_provider);


--
-- Name: index_payments_on_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_id_from_provider ON public.payments USING btree (id_from_provider);


--
-- Name: index_payments_on_payment_made_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_payment_made_at ON public.payments USING btree (payment_made_at);


--
-- Name: index_payments_on_payment_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_payment_type ON public.payments USING btree (payment_type);


--
-- Name: index_payments_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_store_id ON public.payments USING btree (store_id);


--
-- Name: index_payments_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_subscription_id ON public.payments USING btree (subscription_id);


--
-- Name: index_plans_on_ecommerce_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_ecommerce_platform_id ON public.plans USING btree (ecommerce_platform_id);


--
-- Name: index_plans_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_name ON public.plans USING btree (name);


--
-- Name: index_product_group_products_on_product_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_group_products_on_product_group_id ON public.product_group_products USING btree (product_group_id);


--
-- Name: index_product_group_products_on_product_group_id_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_group_products_on_product_group_id_and_product_id ON public.product_group_products USING btree (product_group_id, product_id);


--
-- Name: index_product_group_products_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_group_products_on_product_id ON public.product_group_products USING btree (product_id);


--
-- Name: index_product_groups_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_groups_on_store_id ON public.product_groups USING btree (store_id);


--
-- Name: index_product_limits_modifiers_on_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_limits_modifiers_on_ends_at ON public.product_limits_modifiers USING btree (ends_at);


--
-- Name: index_product_limits_modifiers_on_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_limits_modifiers_on_starts_at ON public.product_limits_modifiers USING btree (starts_at);


--
-- Name: index_product_limits_modifiers_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_limits_modifiers_on_store_id ON public.product_limits_modifiers USING btree (store_id);


--
-- Name: index_products_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_name ON public.products USING btree (name);


--
-- Name: index_products_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_store_id ON public.products USING btree (store_id);


--
-- Name: index_products_on_store_id_and_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_store_id_and_id_from_provider ON public.products USING btree (store_id, id_from_provider);


--
-- Name: index_products_on_suppressed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_suppressed ON public.products USING btree (suppressed);


--
-- Name: index_products_sync_batches_on_processed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_sync_batches_on_processed_at ON public.products_sync_batches USING btree (processed_at);


--
-- Name: index_products_sync_batches_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_sync_batches_on_store_id ON public.products_sync_batches USING btree (store_id);


--
-- Name: index_products_sync_batches_on_sync_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_sync_batches_on_sync_id ON public.products_sync_batches USING btree (sync_id);


--
-- Name: index_promotion_discount_coupons_on_discount_coupon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_promotion_discount_coupons_on_discount_coupon_id ON public.promotion_discount_coupons USING btree (discount_coupon_id);


--
-- Name: index_promotion_discount_coupons_on_promotion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_promotion_discount_coupons_on_promotion_id ON public.promotion_discount_coupons USING btree (promotion_id);


--
-- Name: index_promotions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_promotions_on_created_at ON public.promotions USING btree (created_at);


--
-- Name: index_promotions_on_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_promotions_on_ends_at ON public.promotions USING btree (ends_at);


--
-- Name: index_promotions_on_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_promotions_on_starts_at ON public.promotions USING btree (starts_at);


--
-- Name: index_promotions_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_promotions_on_store_id ON public.promotions USING btree (store_id);


--
-- Name: index_published_media_of_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_published_media_of_review ON public.media USING btree (mediable_id, mediable_type, status, media_type) WHERE (status = 1);


--
-- Name: index_questions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_created_at ON public.questions USING btree (created_at);


--
-- Name: index_questions_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_customer_id ON public.questions USING btree (customer_id);


--
-- Name: index_questions_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_product_id ON public.questions USING btree (product_id);


--
-- Name: index_questions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_status ON public.questions USING btree (status);


--
-- Name: index_questions_on_submitted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_questions_on_submitted_at ON public.questions USING btree (submitted_at);


--
-- Name: index_review_request_coupon_codes_on_coupon_code_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_request_coupon_codes_on_coupon_code_id ON public.review_request_coupon_codes USING btree (coupon_code_id);


--
-- Name: index_review_request_coupon_codes_on_review_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_request_coupon_codes_on_review_request_id ON public.review_request_coupon_codes USING btree (review_request_id);


--
-- Name: index_review_requests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_requests_on_created_at ON public.review_requests USING btree (created_at);


--
-- Name: index_review_requests_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_requests_on_customer_id ON public.review_requests USING btree (customer_id);


--
-- Name: index_review_requests_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_requests_on_order_id ON public.review_requests USING btree (order_id);


--
-- Name: index_review_requests_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_requests_on_status ON public.review_requests USING btree (status);


--
-- Name: index_review_reviewables_on_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_reviewables_on_review_id ON public.review_reviewables USING btree (review_id);


--
-- Name: index_review_reviewables_on_reviewable_id_and_reviewable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_reviewables_on_reviewable_id_and_reviewable_type ON public.review_reviewables USING btree (reviewable_id, reviewable_type);


--
-- Name: index_review_reviewables_on_reviewable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_reviewables_on_reviewable_type ON public.review_reviewables USING btree (reviewable_type);


--
-- Name: index_reviews_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_created_at ON public.reviews USING btree (created_at);


--
-- Name: index_reviews_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_customer_id ON public.reviews USING btree (customer_id);


--
-- Name: index_reviews_on_order_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_order_product_id ON public.reviews USING btree (order_product_id);


--
-- Name: index_reviews_on_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_rating ON public.reviews USING btree (rating);


--
-- Name: index_reviews_on_review_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_review_date ON public.reviews USING btree (review_date);


--
-- Name: index_reviews_on_review_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_review_request_id ON public.reviews USING btree (review_request_id);


--
-- Name: index_reviews_on_transaction_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_transaction_item_id ON public.reviews USING btree (transaction_item_id);


--
-- Name: index_reviews_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_updated_at ON public.reviews USING btree (updated_at);


--
-- Name: index_reviews_on_votes_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_votes_count ON public.reviews USING btree (votes_count);


--
-- Name: index_reviews_unique_on_order_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reviews_unique_on_order_product_id ON public.reviews USING btree (order_product_id);


--
-- Name: index_settings_on_target_type_and_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_settings_on_target_type_and_target_id ON public.settings USING btree (target_type, target_id);


--
-- Name: index_settings_on_target_type_and_target_id_and_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_target_type_and_target_id_and_var ON public.settings USING btree (target_type, target_id, var);


--
-- Name: index_social_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_accounts_on_user_id ON public.social_accounts USING btree (user_id);


--
-- Name: index_social_accounts_on_user_id_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_social_accounts_on_user_id_and_provider ON public.social_accounts USING btree (user_id, provider);


--
-- Name: index_social_posts_on_postable_id_and_postable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_posts_on_postable_id_and_postable_type ON public.social_posts USING btree (postable_id, postable_type);


--
-- Name: index_social_posts_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_social_posts_on_provider_and_uid ON public.social_posts USING btree (provider, uid);


--
-- Name: index_store_products_usages_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_store_products_usages_on_store_id ON public.store_products_usages USING btree (store_id);


--
-- Name: index_store_subscription_usages_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_store_subscription_usages_on_store_id ON public.store_subscription_usages USING btree (store_id);


--
-- Name: index_stores_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stores_on_domain ON public.stores USING btree (domain);


--
-- Name: index_stores_on_ecommerce_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stores_on_ecommerce_platform_id ON public.stores USING btree (ecommerce_platform_id);


--
-- Name: index_stores_on_provider_and_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stores_on_provider_and_id_from_provider ON public.stores USING btree (provider, id_from_provider);


--
-- Name: index_stores_on_trial_ends_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stores_on_trial_ends_at ON public.stores USING btree (trial_ends_at);


--
-- Name: index_stores_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stores_on_user_id ON public.stores USING btree (user_id);


--
-- Name: index_stores_on_user_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stores_on_user_id_unique ON public.stores USING btree (user_id);


--
-- Name: index_subscriptions_on_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_bundle_id ON public.subscriptions USING btree (bundle_id);


--
-- Name: index_subscriptions_on_cancelled_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_cancelled_on ON public.subscriptions USING btree (cancelled_on);


--
-- Name: index_subscriptions_on_chargebee_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_chargebee_customer_id ON public.subscriptions USING btree (chargebee_customer_id);


--
-- Name: index_subscriptions_on_expired_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_expired_at ON public.subscriptions USING btree (expired_at);


--
-- Name: index_subscriptions_on_id_from_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriptions_on_id_from_provider ON public.subscriptions USING btree (id_from_provider);


--
-- Name: index_subscriptions_on_initial_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_initial_bundle_id ON public.subscriptions USING btree (initial_bundle_id);


--
-- Name: index_subscriptions_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_state ON public.subscriptions USING btree (state);


--
-- Name: index_suggested_plans_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suggested_plans_on_plan_id ON public.suggested_plans USING btree (plan_id);


--
-- Name: index_suggested_plans_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suggested_plans_on_store_id ON public.suggested_plans USING btree (store_id);


--
-- Name: index_suppressions_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suppressions_on_customer_id ON public.suppressions USING btree (customer_id);


--
-- Name: index_suppressions_on_email_and_store_id_and_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suppressions_on_email_and_store_id_and_source ON public.suppressions USING btree (email, store_id, source);


--
-- Name: index_suppressions_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suppressions_on_store_id ON public.suppressions USING btree (store_id);


--
-- Name: index_tolk_locales_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tolk_locales_on_name ON public.tolk_locales USING btree (name);


--
-- Name: index_tolk_translations_on_phrase_id_and_locale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tolk_translations_on_phrase_id_and_locale_id ON public.tolk_translations USING btree (phrase_id, locale_id);


--
-- Name: index_transaction_items_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_items_on_customer_id ON public.transaction_items USING btree (customer_id);


--
-- Name: index_transaction_items_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_items_on_order_id ON public.transaction_items USING btree (order_id);


--
-- Name: index_transaction_items_on_review_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_items_on_review_request_id ON public.transaction_items USING btree (review_request_id);


--
-- Name: index_transaction_items_on_reviewable_id_and_reviewable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_items_on_reviewable_id_and_reviewable_type ON public.transaction_items USING btree (reviewable_id, reviewable_type);


--
-- Name: index_unique_imported_review_request_product; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unique_imported_review_request_product ON public.imported_review_request_products USING btree (imported_review_request_id, product_id);


--
-- Name: index_unique_review_requests_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unique_review_requests_on_order_id ON public.review_requests USING btree (order_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_visits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_visits_on_user_id ON public.visits USING btree (user_id);


--
-- Name: index_visits_on_visit_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_visits_on_visit_token ON public.visits USING btree (visit_token);


--
-- Name: index_votes_on_votable_id_and_votable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_votes_on_votable_id_and_votable_type ON public.votes USING btree (votable_id, votable_type);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20161101140759'),
('20161101141217'),
('20161101141601'),
('20161101142050'),
('20161101142524'),
('20161101142933'),
('20161101143248'),
('20161101143436'),
('20161101144114'),
('20161101144222'),
('20161101144347'),
('20161113225051'),
('20161119214041'),
('20161120164753'),
('20161120170304'),
('20161120173118'),
('20161120210029'),
('20161127211235'),
('20161127224208'),
('20161204172124'),
('20161218150912'),
('20161220175738'),
('20170102163209'),
('20170113235653'),
('20170114010148'),
('20170114044246'),
('20170117172438'),
('20170117172507'),
('20170118154216'),
('20170120130211'),
('20170120233246'),
('20170122122410'),
('20170122152111'),
('20170122152138'),
('20170204204815'),
('20170205004428'),
('20170222224137'),
('20170222232332'),
('20170223012316'),
('20170223035906'),
('20170226013356'),
('20170314192242'),
('20170319182351'),
('20170319184432'),
('20170319200518'),
('20170321153739'),
('20170321181304'),
('20170321214706'),
('20170321215504'),
('20170322132242'),
('20170324214319'),
('20170327222945'),
('20170423152913'),
('20170423163440'),
('20170430112813'),
('20170514142913'),
('20170515131834'),
('20170515134438'),
('20170520181059'),
('20170525172608'),
('20170605182723'),
('20170627124532'),
('20170706005436'),
('20170709191106'),
('20170709191454'),
('20170711090700'),
('20170712224017'),
('20170715172512'),
('20170719213336'),
('20170722120906'),
('20170725215538'),
('20170727141745'),
('20170729223155'),
('20170730221210'),
('20170731091729'),
('20170810014129'),
('20170811165419'),
('20170813171305'),
('20170815154729'),
('20170815154730'),
('20170820134034'),
('20170820220644'),
('20170824185939'),
('20170824202316'),
('20170904172408'),
('20170916222934'),
('20170925220303'),
('20171002160537'),
('20171002203205'),
('20171014170756'),
('20171015143732'),
('20171018132747'),
('20171125015806'),
('20171125170547'),
('20171125174239'),
('20171126203631'),
('20171202024559'),
('20171221200031'),
('20171221203110'),
('20171221203444'),
('20171221203700'),
('20171221205303'),
('20171221205612'),
('20171221205625'),
('20171221210032'),
('20171221210400'),
('20171221211232'),
('20171228191803'),
('20171229153546'),
('20180103162312'),
('20180106115425'),
('20180111143500'),
('20180111143754'),
('20180115090703'),
('20180116143633'),
('20180122193416'),
('20180128213819'),
('20180130211242'),
('20180131003523'),
('20180131005451'),
('20180201193653'),
('20180214092804'),
('20180214093042'),
('20180304150127'),
('20180314132127'),
('20180318150509'),
('20180320193045'),
('20180325171001'),
('20180326191904'),
('20180328094913'),
('20180409125113'),
('20180413121113'),
('20180424163205'),
('20180503110916'),
('20180504184226'),
('20180504194833'),
('20180506123837'),
('20180509085028'),
('20180517095757'),
('20180521080645'),
('20180523071221'),
('20180529093919'),
('20180614182937'),
('20180625114023'),
('20180628142010'),
('20180705171257'),
('20180713152159'),
('20180804182438'),
('20180806102635'),
('20180807085538'),
('20180816114849'),
('20180820205721'),
('20180821150503'),
('20180821153044'),
('20180822150623'),
('20180822151026'),
('20180822184600'),
('20180828214334'),
('20180905145055'),
('20180906075454'),
('20180912102938'),
('20180912121314'),
('20180915154900'),
('20180921123128'),
('20180923182346'),
('20180929002508'),
('20180929135102'),
('20181025201130'),
('20181026215245'),
('20181026230120'),
('20181101182857'),
('20181102090702'),
('20181105083624'),
('20181108190958'),
('20181118163338'),
('20181127144514'),
('20181202162030'),
('20181213130529'),
('20181213132147'),
('20181227101635'),
('20181228130621'),
('20190118182525'),
('20190118190740'),
('20190118190857'),
('20190118191012'),
('20190118191136'),
('20190118191235'),
('20190120013046'),
('20190123122522'),
('20190129145524'),
('20190129200057'),
('20190216151722'),
('20190223134814'),
('20190227143524'),
('20190306144218'),
('20190307112021'),
('20190307153414'),
('20190309190809'),
('20190310143750'),
('20190311153552'),
('20190322102757'),
('20190323192126'),
('20190323192346'),
('20190326180707'),
('20190327170751'),
('20190327170806'),
('20190327210601'),
('20190329151309'),
('20190416160853'),
('20190427161814'),
('20190428151246'),
('20190428160230'),
('20190502092721'),
('20190506162933'),
('20190507185115'),
('20190528212649'),
('20190530190344'),
('20190609102655'),
('20190615151119'),
('20190704160015'),
('20190707212903'),
('20190708185311'),
('20190708193336'),
('20190709160423');
