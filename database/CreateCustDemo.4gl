#+ Database creation script for IBM Informix
#+
#+ Note: This script is a helper script to create an empty database schema
#+       Adapt it to fit your needs
 
MAIN
    DATABASE custdemo
    CALL db_drop_tables()
    CALL db_create_tables()
    CALL db_load_data()
END MAIN
 
#+ Note: This script is a helper script to create an empty database schema
#+       Adapt it to fit your needs

#+ Create all tables in database.
FUNCTION db_create_tables()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE TABLE customer (
        store_num SERIAL PRIMARY KEY,
        store_name CHAR(20),
        addr CHAR(20),
        addr2 CHAR(20),
        city CHAR(15),
        state CHAR(2),
        zipcode CHAR(5),
        contact_name CHAR(30),
        phone CHAR(18))"
    EXECUTE IMMEDIATE "CREATE TABLE factory (
        fac_code CHAR(3) NOT NULL PRIMARY KEY,
        fac_name CHAR(15))"
    EXECUTE IMMEDIATE "CREATE TABLE items (
        order_num INTEGER NOT NULL,
        stock_num INTEGER NOT NULL,
        quantity SMALLINT,
        price DECIMAL(8,2))"
    EXECUTE IMMEDIATE "CREATE TABLE orders (
        order_num SERIAL PRIMARY KEY,
        order_date DATE,
        store_num INTEGER NOT NULL,
        fac_code CHAR(3),
        ship_instr CHAR(10),
        promo CHAR(1))"
    EXECUTE IMMEDIATE "CREATE TABLE state (
        state_code CHAR(2) NOT NULL PRIMARY KEY,
        state_name CHAR(15))"
    EXECUTE IMMEDIATE "CREATE TABLE stock (
        stock_num SERIAL PRIMARY KEY,
        fac_code CHAR(3) NOT NULL,
        description CHAR(15),
        reg_price DECIMAL(8,2),
        promo_price DECIMAL(8,2),
        price_updated DATE,
        unit CHAR(4))"

END FUNCTION
 
#+ Drop all tables from database.
FUNCTION db_drop_tables()
    WHENEVER ERROR CONTINUE
 
    EXECUTE IMMEDIATE "DROP TABLE customer"
    EXECUTE IMMEDIATE "DROP TABLE factory"
    EXECUTE IMMEDIATE "DROP TABLE items"
    EXECUTE IMMEDIATE "DROP TABLE orders"
    EXECUTE IMMEDIATE "DROP TABLE state"
    EXECUTE IMMEDIATE "DROP TABLE stock"
 
END FUNCTION
 
#+ Load data for all tables in database.
FUNCTION db_load_data()
    DEFINE lTableName  STRING
    DEFINE lSQL        STRING
    DEFINE lSQLConstant STRING = "INSERT INTO %1"
    DEFINE lFileName   STRING
    DEFINE lFileNameConstant STRING = "%1.unl"
    DEFINE lTables DYNAMIC ARRAY OF STRING = [
                       "customer",
                       "factory",
                       "items",
                       "orders",
                       "state",
                       "stock"
                       ]
    DEFINE lIndex INTEGER
    WHENEVER ERROR STOP
 
    FOR lIndex = 1 TO lTables.getLength()
        LET lTableName = lTables[lIndex]
        LET lFileName = SFMT(lFileNameConstant, lTableName)
        LET lSQL = SFMT(lSQLConstant, lTableName)
        DISPLAY SFMT("LOAD FROM %1 %2", lFileName, lSQL)
        LOAD FROM lFileName lSQL
    END FOR
 
END FUNCTION #db_load_data