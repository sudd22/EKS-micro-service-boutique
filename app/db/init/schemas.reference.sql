CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS product_schema;
CREATE SCHEMA IF NOT EXISTS order_schema;
CREATE SCHEMA IF NOT EXISTS payment_schema;
CREATE SCHEMA IF NOT EXISTS notification_schema;

CREATE ROLE auth_user         LOGIN PASSWORD 'auth_password_placeholder';
CREATE ROLE product_user      LOGIN PASSWORD 'product_password_placeholder';
CREATE ROLE order_user        LOGIN PASSWORD 'order_password_placeholder';
CREATE ROLE payment_user      LOGIN PASSWORD 'payment_password_placeholder';
CREATE ROLE notification_user LOGIN PASSWORD 'notification_password_placeholder';

GRANT USAGE, CREATE ON SCHEMA auth_schema         TO auth_user;
GRANT USAGE, CREATE ON SCHEMA product_schema      TO product_user;
GRANT USAGE, CREATE ON SCHEMA order_schema        TO order_user;
GRANT USAGE, CREATE ON SCHEMA payment_schema      TO payment_user;
GRANT USAGE, CREATE ON SCHEMA notification_schema TO notification_user;

CREATE ROLE exporter_user LOGIN PASSWORD 'exporter_password_placeholder';
GRANT pg_monitor TO exporter_user;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
