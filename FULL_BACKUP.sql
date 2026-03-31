--
-- PostgreSQL database dump
--

\restrict urecEcuBi4aMwtayiYh0UjQkCOaedyUyMP7xs1AtqZzq0pysiXkaYl2Fz6ThQ0K

-- Dumped from database version 17.8 (a284a84)
-- Dumped by pg_dump version 17.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: rider_status; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.rider_status AS ENUM (
    'available',
    'busy',
    'offline'
);


ALTER TYPE public.rider_status OWNER TO neondb_owner;

--
-- Name: check_food_item_images_limit(); Type: FUNCTION; Schema: public; Owner: neondb_owner
--

CREATE FUNCTION public.check_food_item_images_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  img_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO img_count
  FROM food_item_images
  WHERE food_item_id = NEW.food_item_id;

  IF img_count >= 5 THEN
    RAISE EXCEPTION 'Maximum 5 images allowed per food item';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_food_item_images_limit() OWNER TO neondb_owner;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: neondb_owner
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO neondb_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT admins_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'sub-admin'::character varying])::text[])))
);


ALTER TABLE public.admins OWNER TO neondb_owner;

--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admins_id_seq OWNER TO neondb_owner;

--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: earnings; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.earnings (
    id integer NOT NULL,
    order_id integer,
    entity_type character varying(20),
    entity_id integer NOT NULL,
    gross_amount numeric(10,2),
    deductions jsonb,
    net_amount numeric(10,2),
    currency character varying(3) DEFAULT 'USD'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT earnings_entity_type_check CHECK (((entity_type)::text = ANY ((ARRAY['admin'::character varying, 'rider'::character varying, 'restaurant'::character varying])::text[])))
);


ALTER TABLE public.earnings OWNER TO neondb_owner;

--
-- Name: earnings_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.earnings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.earnings_id_seq OWNER TO neondb_owner;

--
-- Name: earnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.earnings_id_seq OWNED BY public.earnings.id;


--
-- Name: email_otps; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.email_otps (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    otp character varying(10) NOT NULL,
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    is_verified boolean DEFAULT false,
    attempt_count integer DEFAULT 0
);


ALTER TABLE public.email_otps OWNER TO neondb_owner;

--
-- Name: email_otps_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.email_otps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_otps_id_seq OWNER TO neondb_owner;

--
-- Name: email_otps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.email_otps_id_seq OWNED BY public.email_otps.id;


--
-- Name: food_item_images; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.food_item_images (
    id integer NOT NULL,
    food_item_id integer NOT NULL,
    image_url text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.food_item_images OWNER TO neondb_owner;

--
-- Name: food_item_images_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.food_item_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.food_item_images_id_seq OWNER TO neondb_owner;

--
-- Name: food_item_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.food_item_images_id_seq OWNED BY public.food_item_images.id;


--
-- Name: food_items; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.food_items (
    id integer NOT NULL,
    restaurant_id integer,
    name character varying(255) NOT NULL,
    price numeric(10,2) NOT NULL,
    available boolean DEFAULT true,
    preparation_time_minutes integer DEFAULT 10,
    portion character varying(10) DEFAULT 'full'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_available boolean DEFAULT true,
    CONSTRAINT food_items_portion_check CHECK (((portion)::text = ANY ((ARRAY['full'::character varying, 'half'::character varying])::text[])))
);


ALTER TABLE public.food_items OWNER TO neondb_owner;

--
-- Name: food_items_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.food_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.food_items_id_seq OWNER TO neondb_owner;

--
-- Name: food_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.food_items_id_seq OWNED BY public.food_items.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.issues (
    id integer NOT NULL,
    user_id integer,
    rider_id integer,
    restaurant_id integer,
    order_id integer,
    message text NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT issues_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'resolved'::character varying])::text[])))
);


ALTER TABLE public.issues OWNER TO neondb_owner;

--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issues_id_seq OWNER TO neondb_owner;

--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer,
    rider_id integer,
    restaurant_id integer,
    message text,
    status character varying(20) DEFAULT 'unread'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT notification_target_check CHECK ((((((user_id IS NOT NULL))::integer + ((rider_id IS NOT NULL))::integer) + ((restaurant_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT notifications_status_check CHECK (((status)::text = ANY ((ARRAY['unread'::character varying, 'read'::character varying])::text[])))
);


ALTER TABLE public.notifications OWNER TO neondb_owner;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO neondb_owner;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer,
    food_item_id integer,
    quantity integer DEFAULT 1,
    portion character varying(10) DEFAULT 'full'::character varying,
    price numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT order_items_portion_check CHECK (((portion)::text = ANY ((ARRAY['full'::character varying, 'half'::character varying])::text[])))
);


ALTER TABLE public.order_items OWNER TO neondb_owner;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO neondb_owner;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: order_restaurants; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.order_restaurants (
    id integer NOT NULL,
    order_id integer,
    restaurant_id integer,
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT order_restaurants_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'preparing'::character varying, 'ready'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.order_restaurants OWNER TO neondb_owner;

--
-- Name: order_restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.order_restaurants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_restaurants_id_seq OWNER TO neondb_owner;

--
-- Name: order_restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.order_restaurants_id_seq OWNED BY public.order_restaurants.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    user_id integer,
    delivery_address text NOT NULL,
    delivery_phone character varying(20) NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    status character varying(20) DEFAULT 'new'::character varying,
    payment_type character varying(10) DEFAULT 'cod'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    assigned_rider_id integer,
    delivery_location public.geography(Point,4326),
    queued_at timestamp without time zone,
    cancelled_by character varying(20),
    cancel_reason text,
    cancelled_at timestamp without time zone,
    CONSTRAINT cancelled_by_check CHECK (((cancelled_by)::text = ANY ((ARRAY['user'::character varying, 'admin'::character varying, 'system'::character varying, 'restaurant'::character varying])::text[]))),
    CONSTRAINT orders_payment_type_check CHECK (((payment_type)::text = 'cod'::text)),
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['new'::character varying, 'accepted'::character varying, 'preparing'::character varying, 'ready'::character varying, 'waiting'::character varying, 'assigned'::character varying, 'delivered'::character varying, 'cancelled'::character varying, 'temporary_issue'::character varying])::text[])))
);


ALTER TABLE public.orders OWNER TO neondb_owner;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO neondb_owner;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: pickup_sequence; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.pickup_sequence (
    id integer NOT NULL,
    order_id integer NOT NULL,
    restaurant_id integer NOT NULL,
    sequence integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.pickup_sequence OWNER TO neondb_owner;

--
-- Name: pickup_sequence_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.pickup_sequence_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pickup_sequence_id_seq OWNER TO neondb_owner;

--
-- Name: pickup_sequence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.pickup_sequence_id_seq OWNED BY public.pickup_sequence.id;


--
-- Name: restaurants; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.restaurants (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    address text NOT NULL,
    phone_number character varying(20),
    status character varying(20) DEFAULT 'open'::character varying,
    owner_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    opening_time time without time zone,
    closing_time time without time zone,
    is_open boolean DEFAULT true,
    email text,
    password text,
    owner_name text,
    upi_id text,
    account_no text,
    ifsc text,
    location_geo public.geography(Point,4326),
    CONSTRAINT check_valid_time CHECK (((opening_time IS NULL) OR (closing_time IS NULL) OR (opening_time < closing_time))),
    CONSTRAINT restaurants_status_check CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.restaurants OWNER TO neondb_owner;

--
-- Name: restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.restaurants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.restaurants_id_seq OWNER TO neondb_owner;

--
-- Name: restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.restaurants_id_seq OWNED BY public.restaurants.id;


--
-- Name: rider_assignments; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.rider_assignments (
    id integer NOT NULL,
    order_id integer,
    rider_id integer,
    status character varying(20) DEFAULT 'pending'::character varying,
    assigned_at timestamp without time zone DEFAULT now(),
    picked_at timestamp without time zone,
    delivered_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT rider_assignments_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'picked'::character varying, 'delivered'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.rider_assignments OWNER TO neondb_owner;

--
-- Name: rider_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.rider_assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rider_assignments_id_seq OWNER TO neondb_owner;

--
-- Name: rider_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.rider_assignments_id_seq OWNED BY public.rider_assignments.id;


--
-- Name: riders; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.riders (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    phone_number character varying(20) NOT NULL,
    status public.rider_status DEFAULT 'offline'::public.rider_status,
    vehicle_type character varying(50),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    total_distance_today numeric DEFAULT 0,
    last_location_update timestamp without time zone,
    location_geo public.geography(Point,4326)
);


ALTER TABLE public.riders OWNER TO neondb_owner;

--
-- Name: riders_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.riders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.riders_id_seq OWNER TO neondb_owner;

--
-- Name: riders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.riders_id_seq OWNED BY public.riders.id;


--
-- Name: serviceable_areas; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.serviceable_areas (
    id integer NOT NULL,
    area_name character varying(255),
    area_coordinates jsonb,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.serviceable_areas OWNER TO neondb_owner;

--
-- Name: serviceable_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.serviceable_areas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.serviceable_areas_id_seq OWNER TO neondb_owner;

--
-- Name: serviceable_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.serviceable_areas_id_seq OWNED BY public.serviceable_areas.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    setting_key character varying(50) NOT NULL,
    setting_value jsonb NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.system_settings OWNER TO neondb_owner;

--
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_settings_id_seq OWNER TO neondb_owner;

--
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone_number character varying(20) NOT NULL,
    password character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO neondb_owner;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO neondb_owner;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: website_status; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.website_status (
    id integer NOT NULL,
    status character varying(10) DEFAULT 'on'::character varying,
    maintenance_notice text,
    maintenance_notice_sent boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT website_status_status_check CHECK (((status)::text = ANY ((ARRAY['on'::character varying, 'off'::character varying])::text[])))
);


ALTER TABLE public.website_status OWNER TO neondb_owner;

--
-- Name: website_status_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.website_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.website_status_id_seq OWNER TO neondb_owner;

--
-- Name: website_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.website_status_id_seq OWNED BY public.website_status.id;


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: earnings id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.earnings ALTER COLUMN id SET DEFAULT nextval('public.earnings_id_seq'::regclass);


--
-- Name: email_otps id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.email_otps ALTER COLUMN id SET DEFAULT nextval('public.email_otps_id_seq'::regclass);


--
-- Name: food_item_images id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.food_item_images ALTER COLUMN id SET DEFAULT nextval('public.food_item_images_id_seq'::regclass);


--
-- Name: food_items id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.food_items ALTER COLUMN id SET DEFAULT nextval('public.food_items_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: order_restaurants id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_restaurants ALTER COLUMN id SET DEFAULT nextval('public.order_restaurants_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: pickup_sequence id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.pickup_sequence ALTER COLUMN id SET DEFAULT nextval('public.pickup_sequence_id_seq'::regclass);


--
-- Name: restaurants id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.restaurants ALTER COLUMN id SET DEFAULT nextval('public.restaurants_id_seq'::regclass);


--
-- Name: rider_assignments id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.rider_assignments ALTER COLUMN id SET DEFAULT nextval('public.rider_assignments_id_seq'::regclass);


--
-- Name: riders id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.riders ALTER COLUMN id SET DEFAULT nextval('public.riders_id_seq'::regclass);


--
-- Name: serviceable_areas id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.serviceable_areas ALTER COLUMN id SET DEFAULT nextval('public.serviceable_areas_id_seq'::regclass);


--
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: website_status id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.website_status ALTER COLUMN id SET DEFAULT nextval('public.website_status_id_seq'::regclass);


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.admins (id, name, email, password, role, created_at, updated_at) FROM stdin;
2	Admin One	admin1@test.com	password123	admin	2026-03-19 12:45:06.39353	2026-03-19 12:45:06.39353
\.


--
-- Data for Name: earnings; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.earnings (id, order_id, entity_type, entity_id, gross_amount, deductions, net_amount, currency, created_at) FROM stdin;
\.


--
-- Data for Name: email_otps; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.email_otps (id, email, otp, expires_at, created_at, is_verified, attempt_count) FROM stdin;
\.


--
-- Data for Name: food_item_images; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.food_item_images (id, food_item_id, image_url, created_at) FROM stdin;
\.


--
-- Data for Name: food_items; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.food_items (id, restaurant_id, name, price, available, preparation_time_minutes, portion, created_at, updated_at, is_available) FROM stdin;
1	1	Burger	100.00	t	10	full	2026-03-20 00:25:52.344248	2026-03-20 00:25:52.344248	t
2	1	Pizza	200.00	t	10	full	2026-03-20 00:25:52.344248	2026-03-20 00:25:52.344248	t
\.


--
-- Data for Name: issues; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.issues (id, user_id, rider_id, restaurant_id, order_id, message, status, created_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.notifications (id, user_id, rider_id, restaurant_id, message, status, created_at) FROM stdin;
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.order_items (id, order_id, food_item_id, quantity, portion, price, created_at) FROM stdin;
\.


--
-- Data for Name: order_restaurants; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.order_restaurants (id, order_id, restaurant_id, status, created_at) FROM stdin;
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.orders (id, user_id, delivery_address, delivery_phone, total_amount, status, payment_type, created_at, updated_at, assigned_rider_id, delivery_location, queued_at, cancelled_by, cancel_reason, cancelled_at) FROM stdin;
1	1	Addr1	9999999991	100.00	ready	cod	2026-03-20 00:26:38.249094	2026-03-20 00:26:38.249094	\N	\N	\N	\N	\N	\N
2	1	Addr2	9999999991	120.00	ready	cod	2026-03-20 00:26:38.249094	2026-03-20 00:26:38.249094	\N	\N	\N	\N	\N	\N
3	1	Addr3	9999999991	150.00	cancelled	cod	2026-03-20 00:26:38.249094	2026-03-20 00:28:35.489295	\N	\N	2026-03-20 00:27:13.109299	system	No rider available	2026-03-20 00:28:35.489295
\.


--
-- Data for Name: pickup_sequence; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.pickup_sequence (id, order_id, restaurant_id, sequence, created_at) FROM stdin;
\.


--
-- Data for Name: restaurants; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.restaurants (id, name, address, phone_number, status, owner_id, created_at, updated_at, opening_time, closing_time, is_open, email, password, owner_name, upi_id, account_no, ifsc, location_geo) FROM stdin;
1	Test Restaurant	Test Address	\N	open	\N	2026-03-20 00:25:28.019054	2026-03-20 00:25:28.019054	\N	\N	t	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: rider_assignments; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.rider_assignments (id, order_id, rider_id, status, assigned_at, picked_at, delivered_at, created_at) FROM stdin;
\.


--
-- Data for Name: riders; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.riders (id, name, phone_number, status, vehicle_type, created_at, updated_at, total_distance_today, last_location_update, location_geo) FROM stdin;
1	Rider1	8888888881	available	\N	2026-03-20 00:26:17.209025	2026-03-20 00:26:17.209025	0	\N	\N
2	Rider2	8888888882	available	\N	2026-03-20 00:26:17.209025	2026-03-20 00:26:17.209025	0	\N	\N
\.


--
-- Data for Name: serviceable_areas; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.serviceable_areas (id, area_name, area_coordinates, created_at) FROM stdin;
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: cloud_admin
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.system_settings (id, setting_key, setting_value, updated_at) FROM stdin;
1	max_waiting_orders_alert	{"value": 2}	2026-03-20 00:24:27.763983
2	max_orders_per_rider	{"value": 1}	2026-03-20 00:24:27.763983
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.users (id, name, email, phone_number, password, created_at, updated_at) FROM stdin;
1	User1	u1@test.com	9999999991	pass	2026-03-20 00:24:50.319094	2026-03-20 00:24:50.319094
\.


--
-- Data for Name: website_status; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.website_status (id, status, maintenance_notice, maintenance_notice_sent, created_at) FROM stdin;
\.


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.admins_id_seq', 2, true);


--
-- Name: earnings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.earnings_id_seq', 1, false);


--
-- Name: email_otps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.email_otps_id_seq', 1, false);


--
-- Name: food_item_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.food_item_images_id_seq', 1, false);


--
-- Name: food_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.food_items_id_seq', 2, true);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.issues_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.order_items_id_seq', 1, false);


--
-- Name: order_restaurants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.order_restaurants_id_seq', 1, false);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.orders_id_seq', 3, true);


--
-- Name: pickup_sequence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.pickup_sequence_id_seq', 1, false);


--
-- Name: restaurants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.restaurants_id_seq', 1, true);


--
-- Name: rider_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.rider_assignments_id_seq', 1, false);


--
-- Name: riders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.riders_id_seq', 2, true);


--
-- Name: serviceable_areas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.serviceable_areas_id_seq', 1, false);


--
-- Name: system_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.system_settings_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Name: website_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.website_status_id_seq', 1, false);


--
-- Name: admins admins_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_key UNIQUE (email);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: earnings earnings_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.earnings
    ADD CONSTRAINT earnings_pkey PRIMARY KEY (id);


--
-- Name: email_otps email_otps_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.email_otps
    ADD CONSTRAINT email_otps_pkey PRIMARY KEY (id);


--
-- Name: food_item_images food_item_images_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.food_item_images
    ADD CONSTRAINT food_item_images_pkey PRIMARY KEY (id);


--
-- Name: food_items food_items_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.food_items
    ADD CONSTRAINT food_items_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: order_restaurants order_restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_restaurants
    ADD CONSTRAINT order_restaurants_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: pickup_sequence pickup_sequence_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.pickup_sequence
    ADD CONSTRAINT pickup_sequence_pkey PRIMARY KEY (id);


--
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);


--
-- Name: rider_assignments rider_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT rider_assignments_pkey PRIMARY KEY (id);


--
-- Name: riders riders_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.riders
    ADD CONSTRAINT riders_phone_number_key UNIQUE (phone_number);


--
-- Name: riders riders_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.riders
    ADD CONSTRAINT riders_pkey PRIMARY KEY (id);


--
-- Name: serviceable_areas serviceable_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.serviceable_areas
    ADD CONSTRAINT serviceable_areas_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: rider_assignments unique_order_assignment; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT unique_order_assignment UNIQUE (order_id);


--
-- Name: order_restaurants unique_order_restaurant; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_restaurants
    ADD CONSTRAINT unique_order_restaurant UNIQUE (order_id, restaurant_id);


--
-- Name: pickup_sequence unique_order_restaurant_sequence; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.pickup_sequence
    ADD CONSTRAINT unique_order_restaurant_sequence UNIQUE (order_id, restaurant_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_number_key UNIQUE (phone_number);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: website_status website_status_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.website_status
    ADD CONSTRAINT website_status_pkey PRIMARY KEY (id);


--
-- Name: idx_earnings_entity; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_earnings_entity ON public.earnings USING btree (entity_type, entity_id);


--
-- Name: idx_earnings_order_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_earnings_order_id ON public.earnings USING btree (order_id);


--
-- Name: idx_email_otps_email; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_email_otps_email ON public.email_otps USING btree (email);


--
-- Name: idx_food_item_images_item; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_food_item_images_item ON public.food_item_images USING btree (food_item_id);


--
-- Name: idx_food_items_restaurant; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_food_items_restaurant ON public.food_items USING btree (restaurant_id);


--
-- Name: idx_issues_order; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_issues_order ON public.issues USING btree (order_id);


--
-- Name: idx_notifications_restaurant; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_notifications_restaurant ON public.notifications USING btree (restaurant_id);


--
-- Name: idx_notifications_rider; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_notifications_rider ON public.notifications USING btree (rider_id);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_order_items_order_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_order_items_order_id ON public.order_items USING btree (order_id);


--
-- Name: idx_orders_assigned_rider; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_orders_assigned_rider ON public.orders USING btree (assigned_rider_id);


--
-- Name: idx_orders_created_at; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_orders_created_at ON public.orders USING btree (created_at);


--
-- Name: idx_orders_delivery_location; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_orders_delivery_location ON public.orders USING gist (delivery_location);


--
-- Name: idx_orders_status; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_orders_status ON public.orders USING btree (status);


--
-- Name: idx_orders_user_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_orders_user_id ON public.orders USING btree (user_id);


--
-- Name: idx_pickup_sequence_order; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_pickup_sequence_order ON public.pickup_sequence USING btree (order_id);


--
-- Name: idx_rider_assignments_order_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_rider_assignments_order_id ON public.rider_assignments USING btree (order_id);


--
-- Name: idx_rider_assignments_rider_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_rider_assignments_rider_id ON public.rider_assignments USING btree (rider_id);


--
-- Name: idx_riders_geo; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_riders_geo ON public.riders USING gist (location_geo);


--
-- Name: idx_riders_location; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_riders_location ON public.riders USING gist (location_geo);


--
-- Name: idx_riders_status; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_riders_status ON public.riders USING btree (status);


--
-- Name: idx_serviceable_areas_name; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_serviceable_areas_name ON public.serviceable_areas USING btree (area_name);


--
-- Name: food_item_images trigger_check_images_limit; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER trigger_check_images_limit BEFORE INSERT ON public.food_item_images FOR EACH ROW EXECUTE FUNCTION public.check_food_item_images_limit();


--
-- Name: admins update_admins_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON public.admins FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: food_items update_food_items_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_food_items_updated_at BEFORE UPDATE ON public.food_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: orders update_orders_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: restaurants update_restaurants_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_restaurants_updated_at BEFORE UPDATE ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: riders update_riders_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_riders_updated_at BEFORE UPDATE ON public.riders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: system_settings update_system_settings_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON public.system_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: neondb_owner
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: earnings earnings_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.earnings
    ADD CONSTRAINT earnings_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: food_item_images food_item_images_food_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.food_item_images
    ADD CONSTRAINT food_item_images_food_item_id_fkey FOREIGN KEY (food_item_id) REFERENCES public.food_items(id) ON DELETE CASCADE;


--
-- Name: food_items food_items_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.food_items
    ADD CONSTRAINT food_items_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: issues issues_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: issues issues_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: issues issues_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_rider_id_fkey FOREIGN KEY (rider_id) REFERENCES public.riders(id);


--
-- Name: issues issues_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: notifications notifications_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: notifications notifications_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_rider_id_fkey FOREIGN KEY (rider_id) REFERENCES public.riders(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: order_items order_items_food_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_food_item_id_fkey FOREIGN KEY (food_item_id) REFERENCES public.food_items(id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_restaurants order_restaurants_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_restaurants
    ADD CONSTRAINT order_restaurants_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_restaurants order_restaurants_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_restaurants
    ADD CONSTRAINT order_restaurants_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id);


--
-- Name: orders orders_assigned_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_assigned_rider_id_fkey FOREIGN KEY (assigned_rider_id) REFERENCES public.riders(id);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pickup_sequence pickup_sequence_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.pickup_sequence
    ADD CONSTRAINT pickup_sequence_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: pickup_sequence pickup_sequence_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.pickup_sequence
    ADD CONSTRAINT pickup_sequence_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurants restaurants_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.admins(id);


--
-- Name: rider_assignments rider_assignments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT rider_assignments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: rider_assignments rider_assignments_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.rider_assignments
    ADD CONSTRAINT rider_assignments_rider_id_fkey FOREIGN KEY (rider_id) REFERENCES public.riders(id);


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

\unrestrict urecEcuBi4aMwtayiYh0UjQkCOaedyUyMP7xs1AtqZzq0pysiXkaYl2Fz6ThQ0K

