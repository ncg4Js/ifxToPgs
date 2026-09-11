--------------------------------------------------------------------------
-- generate_db.sql
--
-- Informix SQL script to create a small "Fruits by Vendor" database.
--
-- Tables:
--   fruits            - catalog of fruits
--   vendors           - catalog of vendors
--   fruits_by_vendor  - association table (which vendor sells which fruit)
--
-- Keys:
--   PRIMARY KEY  : fruits.entryid, vendors.entryid, fruits_by_vendor.entryid
--                  (all SERIAL, auto-incremented by Informix)
--   FOREIGN KEYS : fruits_by_vendor.fruit_id  -> fruits.entryid
--                  fruits_by_vendor.vendor_id -> vendors.entryid
--
-- Cascade delete rule:
--   Deleting a row from "fruits" must remove its related rows in
--   "fruits_by_vendor". This is NOT done with a direct DELETE statement
--   inside the trigger. Instead, the trigger calls an SPL function
--   (fn_delete_fruit_cascade) which performs the DELETE.
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- Clean up (drop in dependency order: trigger/function, child, parents)
--------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_fruits_cascade_delete;
DROP PROCEDURE IF EXISTS fn_delete_fruit_cascade(INTEGER);
DROP TABLE IF EXISTS fruits_by_vendor;
DROP TABLE IF EXISTS fruits;
DROP TABLE IF EXISTS vendors;

--------------------------------------------------------------------------
-- Table: fruits
--   PRIMARY KEY: entryid
--------------------------------------------------------------------------

CREATE TABLE fruits
(
    entryid     SERIAL       NOT NULL,
    fruit_name  VARCHAR(50)  NOT NULL,
    variety     VARCHAR(50),
    color       VARCHAR(30),
    season      VARCHAR(20),

    PRIMARY KEY (entryid) CONSTRAINT pk_fruits,
    UNIQUE (fruit_name)   CONSTRAINT uq_fruits_name
);

--------------------------------------------------------------------------
-- Table: vendors
--   PRIMARY KEY: entryid
--------------------------------------------------------------------------

CREATE TABLE vendors
(
    entryid       SERIAL       NOT NULL,
    vendor_name   VARCHAR(50)  NOT NULL,
    contact_name  VARCHAR(50),
    phone         VARCHAR(20),
    email         VARCHAR(50),

    PRIMARY KEY (entryid) CONSTRAINT pk_vendors,
    UNIQUE (vendor_name)  CONSTRAINT uq_vendors_name
);

--------------------------------------------------------------------------
-- Table: fruits_by_vendor
--   PRIMARY KEY: entryid
--   FOREIGN KEY: fruit_id  -> fruits.entryid
--   FOREIGN KEY: vendor_id -> vendors.entryid
--------------------------------------------------------------------------

CREATE TABLE fruits_by_vendor
(
    entryid    SERIAL         NOT NULL,
    fruit_id   INTEGER        NOT NULL,
    vendor_id  INTEGER        NOT NULL,
    price      DECIMAL(8,2),

    PRIMARY KEY (entryid) CONSTRAINT pk_fruits_by_vendor,

    FOREIGN KEY (fruit_id) REFERENCES fruits(entryid)
        CONSTRAINT fk_fbv_fruit,

    FOREIGN KEY (vendor_id) REFERENCES vendors(entryid)
        CONSTRAINT fk_fbv_vendor,

    UNIQUE (fruit_id, vendor_id) CONSTRAINT uq_fbv_fruit_vendor
);

--------------------------------------------------------------------------
-- SPL routine: fn_delete_fruit_cascade
--   Performs the actual DELETE of the dependent fruits_by_vendor rows
--   for a given fruit entryid. This is called from the trigger below -
--   the trigger itself never issues the DELETE directly.
--
--   Implemented as a PROCEDURE (not a value-returning FUNCTION) because
--   Informix trigger actions cannot consume a routine's return value -
--   an EXECUTE FUNCTION with an unconsumed result raises error -684
--   ("returns too many values") when invoked from a trigger.
--------------------------------------------------------------------------

CREATE PROCEDURE fn_delete_fruit_cascade(p_fruit_id INTEGER)

    DELETE FROM fruits_by_vendor
    WHERE fruit_id = p_fruit_id;

END PROCEDURE;

--------------------------------------------------------------------------
-- Trigger: trg_fruits_cascade_delete
--   Fires on DELETE from fruits, for each row, and calls the SPL
--   routine above to cascade the delete into fruits_by_vendor.
--------------------------------------------------------------------------

CREATE TRIGGER trg_fruits_cascade_delete
    DELETE ON fruits
    REFERENCING OLD AS pre
    FOR EACH ROW
    (EXECUTE PROCEDURE fn_delete_fruit_cascade(pre.entryid));

--------------------------------------------------------------------------
-- Sample data: 10 fruits
--------------------------------------------------------------------------

INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Apple',      'Gala',        'Red',    'Autumn');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Banana',     'Cavendish',   'Yellow', 'Year-round');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Orange',     'Navel',       'Orange', 'Winter');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Grape',      'Thompson',    'Green',  'Summer');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Strawberry', 'Albion',      'Red',    'Spring');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Pineapple',  'Smooth Cayenne','Brown','Summer');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Mango',      'Tommy Atkins','Orange', 'Summer');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Watermelon', 'Crimson Sweet','Green', 'Summer');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Pear',       'Bartlett',    'Green',  'Autumn');
INSERT INTO fruits (fruit_name, variety, color, season) VALUES ('Peach',      'Elberta',     'Orange', 'Summer');

--------------------------------------------------------------------------
-- Sample data: 10 vendors
--------------------------------------------------------------------------

INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Green Valley Farms',   'Alice Johnson', '555-0101', 'alice@greenvalley.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Sunrise Produce',       'Bob Smith',     '555-0102', 'bob@sunriseproduce.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Tropical Imports Co.',  'Carla Diaz',    '555-0103', 'carla@tropicalimports.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Orchard Fresh',         'David Lee',     '555-0104', 'david@orchardfresh.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Berry Best Suppliers',  'Emma Wilson',   '555-0105', 'emma@berrybest.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Market Street Growers', 'Frank Moore',   '555-0106', 'frank@marketstreet.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Coastal Fruit Traders', 'Grace Kim',     '555-0107', 'grace@coastalfruit.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Highland Harvest',      'Henry Brown',   '555-0108', 'henry@highlandharvest.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Valley View Vendors',   'Irene Clark',   '555-0109', 'irene@valleyview.example');
INSERT INTO vendors (vendor_name, contact_name, phone, email) VALUES ('Riverside Organics',    'Jack Turner',   '555-0110', 'jack@riverside.example');

--------------------------------------------------------------------------
-- Sample data: 5 fruits_by_vendor associations
--   (entryid values below assume a fresh database where SERIAL starts
--    at 1; fruits/vendors were inserted above in the order listed)
--------------------------------------------------------------------------

INSERT INTO fruits_by_vendor (fruit_id, vendor_id, price) VALUES (1, 1, 1.25);  -- Apple      / Green Valley Farms
INSERT INTO fruits_by_vendor (fruit_id, vendor_id, price) VALUES (2, 2, 0.55);  -- Banana     / Sunrise Produce
INSERT INTO fruits_by_vendor (fruit_id, vendor_id, price) VALUES (7, 3, 2.10);  -- Mango      / Tropical Imports Co.
INSERT INTO fruits_by_vendor (fruit_id, vendor_id, price) VALUES (9, 4, 1.75);  -- Pear       / Orchard Fresh
INSERT INTO fruits_by_vendor (fruit_id, vendor_id, price) VALUES (5, 5, 3.00);  -- Strawberry / Berry Best Suppliers
