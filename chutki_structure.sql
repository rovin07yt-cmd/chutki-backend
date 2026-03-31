--
-- PostgreSQL database dump
--

\restrict fcpuvFMeq7gLkozVf9zspwVMdqxM7yAVgs69Y1lVkbboA5Ca7klQKGhMakvpVAg

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
-- Name: finance_transactions; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.finance_transactions (
    id integer NOT NULL,
    type character varying(50) NOT NULL,
    entity_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.finance_transactions OWNER TO neondb_owner;

--
-- Name: finance_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.finance_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.finance_transactions_id_seq OWNER TO neondb_owner;

--
-- Name: finance_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.finance_transactions_id_seq OWNED BY public.finance_transactions.id;


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
    category character varying,
    description text,
    veg_type character varying(10),
    subcategory character varying(50),
    mrp numeric,
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
    preparation_time_minutes integer,
    preparing_started_at timestamp without time zone,
    cod_collected boolean DEFAULT false,
    payment_collected_amount numeric DEFAULT 0,
    CONSTRAINT cancelled_by_check CHECK (((cancelled_by)::text = ANY ((ARRAY['user'::character varying, 'admin'::character varying, 'system'::character varying, 'restaurant'::character varying])::text[]))),
    CONSTRAINT orders_payment_type_check CHECK (((payment_type)::text = 'cod'::text)),
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['new'::character varying, 'accepted'::character varying, 'preparing'::character varying, 'ready'::character varying, 'assigned'::character varying, 'picked'::character varying, 'delivered'::character varying, 'cancelled'::character varying])::text[])))
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
    sequence_number integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    rider_id integer
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
-- Name: restaurant_payments; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.restaurant_payments (
    id integer NOT NULL,
    restaurant_id integer,
    amount numeric(10,2),
    paid_at timestamp without time zone DEFAULT now(),
    upi_id text,
    bank_account_number text,
    account_holder_name text,
    ifsc_code text
);


ALTER TABLE public.restaurant_payments OWNER TO neondb_owner;

--
-- Name: restaurant_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.restaurant_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.restaurant_payments_id_seq OWNER TO neondb_owner;

--
-- Name: restaurant_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.restaurant_payments_id_seq OWNED BY public.restaurant_payments.id;


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
    location_geo public.geography,
    owner_name text,
    upi_id text,
    account_no text,
    ifsc text,
    email text,
    password text,
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
    start_distance numeric DEFAULT 0,
    end_distance numeric DEFAULT 0,
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
    location_geo public.geography(Point,4326),
    phone character varying,
    upi_id character varying,
    account_no character varying,
    ifsc character varying
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
    updated_at timestamp without time zone DEFAULT now(),
    phone character varying,
    upi_id character varying,
    account_no character varying,
    ifsc character varying,
    role character varying DEFAULT 'user'::character varying
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
-- Name: finance_transactions id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.finance_transactions ALTER COLUMN id SET DEFAULT nextval('public.finance_transactions_id_seq'::regclass);


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
-- Name: restaurant_payments id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.restaurant_payments ALTER COLUMN id SET DEFAULT nextval('public.restaurant_payments_id_seq'::regclass);


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
-- Name: finance_transactions finance_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.finance_transactions
    ADD CONSTRAINT finance_transactions_pkey PRIMARY KEY (id);


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
-- Name: restaurant_payments restaurant_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.restaurant_payments
    ADD CONSTRAINT restaurant_payments_pkey PRIMARY KEY (id);


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
-- Name: earnings unique_order_entity; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.earnings
    ADD CONSTRAINT unique_order_entity UNIQUE (order_id, entity_type);


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
-- Name: idx_finance_created; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_finance_created ON public.finance_transactions USING btree (created_at);


--
-- Name: idx_finance_entity; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_finance_entity ON public.finance_transactions USING btree (entity_id);


--
-- Name: idx_finance_type; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_finance_type ON public.finance_transactions USING btree (type);


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
    ADD CONSTRAINT earnings_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


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
-- Name: pickup_sequence pickup_sequence_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.pickup_sequence
    ADD CONSTRAINT pickup_sequence_rider_id_fkey FOREIGN KEY (rider_id) REFERENCES public.riders(id);


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

\unrestrict fcpuvFMeq7gLkozVf9zspwVMdqxM7yAVgs69Y1lVkbboA5Ca7klQKGhMakvpVAg

