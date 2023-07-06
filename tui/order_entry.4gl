DATABASE custdemo

DEFINE r_orders RECORD LIKE orders.*
DEFINE r_items RECORD LIKE items.*
DEFINE r_stock RECORD LIKE stock.*
DEFINE r_factory RECORD LIKE factory.*
DEFINE r_customer RECORD LIKE customer.*
DEFINE a_items DYNAMIC ARRAY OF RECORD LIKE items.*

DEFINE queryText VARCHAR(500)
DEFINE factoryName LIKE factory.fac_name
DEFINE customerName LIKE customer.store_name

MAIN
   DEFINE quitFlag SMALLINT

   WHENEVER ANY ERROR CALL errorHandler
   CALL STARTLOG("order_entry.log")

   DATABASE custdemo
   CALL prepareSQL()
   
   OPEN WINDOW orderForm WITH FORM "orders"

   LET quitFlag = FALSE
   WHILE NOT quitFlag

      MENU "Orders"
         COMMAND "Query"
            IF orderQuery() THEN
               CALL displayScroll()
            END IF
            CLEAR FORM
         COMMAND "Add"
            IF enterOrder(TRUE) THEN
               MESSAGE "Order added" 
            ELSE
               ERROR "Order canceled"
            END IF
            CLEAR FORM
         COMMAND "Exit"
            LET quitFlag = TRUE
            EXIT MENU
      END MENU   

   END WHILE
   CLOSE WINDOW orderForm

END MAIN

FUNCTION prepareSQL()
   DEFINE sqlText VARCHAR(1000)

   LET sqlText = "SELECT factory.fac_name FROM factory WHERE fac_code = ?"
   PREPARE prepSingleFactory FROM sqlText
   DECLARE cursSingleFactory CURSOR FOR prepSingleFactory

   LET sqlText = "SELECT customer.store_name FROM customer WHERE store_num = ?"
   PREPARE prepSingleCustomer FROM sqlText
   DECLARE cursSingleCustomer CURSOR FOR prepSingleCustomer

   LET sqlText = "SELECT stock.* FROM stock WHERE stock_num = ?"
   PREPARE prepSingleStock FROM sqlText
   DECLARE cursSingleStock CURSOR FOR prepSingleStock

   LET sqlText = "SELECT items.* FROM items WHERE order_num = ?"
   PREPARE prepItems FROM sqlText
   DECLARE cursItems CURSOR FOR prepItems

   LET sqlText = "INSERT INTO orders (order_num, order_date, store_num, fac_code, ship_instr, promo) ",
                 " VALUES(0,?,?,?,?,?)" 
   PREPARE insertOrders FROM sqlText

   LET sqlText = "INSERT INTO items (order_num, stock_num, quantity, price)",
                 " VALUES(?,?,?,?)" 
   PREPARE insertItems FROM sqlText

   LET sqlText = "UPDATE orders ",
                 " SET orders.order_date = ?, ",
                 " orders.store_num = ?, ",
                 " orders.fac_code = ?, ",
                 " orders.ship_instr = ?, ",
                 " orders.promo = ? ",
                 " WHERE orders.order_num = ? "
   PREPARE updateOrders FROM sqlText

   LET sqlText = "DELETE FROM orders WHERE orders.order_num = ?"
   PREPARE deleteOrders FROM sqlText

   LET sqlText = "DELETE FROM items WHERE items.order_num = ?"
   PREPARE deleteItems FROM sqlText

END FUNCTION #prepareSQL

FUNCTION orderQuery()
   DEFINE wherePart CHAR(200)

   CONSTRUCT wherePart ON orders.* FROM s_orders.*

      ON KEY (CONTROL-T)
         CASE
            WHEN INFIELD(store_num)
               CALL zoomCustomer() RETURNING r_customer.store_num, r_customer.store_name
               IF r_customer.store_num IS NOT NULL THEN
                  DISPLAY r_customer.store_num TO s_orders.store_num
                  DISPLAY r_customer.store_name TO customer.store_name
               END IF
            WHEN INFIELD(fac_code)
               CALL zoomFactory() RETURNING r_factory.*
               IF r_factory.fac_code IS NOT NULL THEN
                  DISPLAY r_factory.fac_code TO s_orders.fac_code
                  DISPLAY r_factory.fac_name TO factory.fac_name
               END IF
         END CASE

      BEFORE FIELD store_num, fac_code
         MESSAGE "Use Control-T for table help window"

   END CONSTRUCT

   IF int_flag THEN
      RETURN FALSE
   END IF

   LET int_flag = FALSE

   LET queryText = "SELECT orders.*, factory.fac_name, customer.store_name FROM orders",
                   " INNER JOIN factory ON factory.fac_code = orders.fac_code",
                   " INNER JOIN customer ON customer.store_num = orders.store_num",
                   " WHERE ", wherePart CLIPPED
   CALL buildUserQuery()
   RETURN fetchOrder("F")

END FUNCTION #orderQuery

FUNCTION buildUserQuery()

   DECLARE cursOrderQuery SCROLL CURSOR FROM queryText
   OPEN cursOrderQuery

END FUNCTION #buildUserQuery

FUNCTION fetchOrder(fetchAction)
   DEFINE fetchAction CHAR(1)
   DEFINE idx INTEGER
   DEFINE orderTotal, orderSubtotal DECIMAL(12,2)

   CASE UPSHIFT(fetchAction)
      WHEN "F" 
         FETCH FIRST cursOrderQuery INTO r_orders.*, factoryName, customerName
      WHEN "P" 
         FETCH PREVIOUS cursOrderQuery INTO r_orders.*, factoryName, customerName
      WHEN "N" 
         FETCH NEXT cursOrderQuery INTO r_orders.*, factoryName, customerName
      WHEN "L" 
         FETCH LAST cursOrderQuery INTO r_orders.*, factoryName, customerName
      WHEN "S" 
         FETCH CURRENT cursOrderQuery INTO r_orders.*, factoryName, customerName
      WHEN "C"
         CLOSE cursOrderQuery
         INITIALIZE r_orders.*, factoryName, customerName TO NULL
   END CASE

   IF sqlca.sqlcode == 0 THEN

      #Initialize the item section
      CALL a_items.clear()
      LET orderTotal = 0
      INITIALIZE r_items.* TO NULL
      FOR idx = 1 TO 3
         DISPLAY r_items.* TO s_items[idx].*
      END FOR

      #Display the selected record to the screen
      DISPLAY r_orders.* TO s_orders.*
      DISPLAY factoryName TO factory.fac_name
      DISPLAY customerName TO customer.store_name
      DISPLAY orderTotal TO formonly.order_total

      IF UPSHIFT(fetchAction) <> "C" THEN

         #Fetch the order items
         LET idx = 0
         FOREACH cursItems USING r_orders.order_num INTO r_items.*
            LET idx = idx + 1  
            LET a_items[idx] = r_items
            DISPLAY r_items.* TO s_items[idx].*
            LET orderSubtotal = r_items.price * r_items.quantity
            LET orderTotal = orderTotal + orderSubtotal
         END FOREACH
         DISPLAY orderTotal TO formonly.order_total

      END IF 
      RETURN TRUE
   END IF

   RETURN FALSE

END FUNCTION #fetchOrder

FUNCTION displayScroll()
   DEFINE fetchResult SMALLINT

   MENU "Scroll"
      COMMAND "First"
         LET fetchResult = fetchOrder("F")
      COMMAND "Previous"
         LET fetchResult = fetchOrder("P")
         IF NOT fetchResult THEN
            ERROR "Current record is the first in the search list"
         END IF
      COMMAND "Next"
         LET fetchResult = fetchOrder("N")
         IF NOT fetchResult THEN
            ERROR "Current record is the last in the search list"
         END IF
      COMMAND "Last"
         LET fetchResult = fetchOrder("L")
      COMMAND "Update"
         IF enterOrder(FALSE) THEN
            MESSAGE "Order updated"
            CALL buildUserQuery()
            LET fetchResult = fetchOrder("F")
         ELSE
            ERROR "Order canceled"
            LET fetchResult = fetchOrder("S")
         END IF
      COMMAND "Delete"
         IF deleteOrder() THEN
            MESSAGE "Order deleted"
            CALL buildUserQuery()
            LET fetchResult = fetchOrder("F")
         ELSE
            ERROR "Delete canceled"
            LET fetchResult = fetchOrder("S")
         END IF
      COMMAND "Exit"
         LET fetchResult = fetchOrder("C")
         EXIT MENU
   END MENU 
   
END FUNCTION #displayScroll

FUNCTION enterOrder(addMode)
   DEFINE addMode SMALLINT
   DEFINE recNotFound SMALLINT
   DEFINE rowIdx INTEGER

   IF addMode THEN
      INITIALIZE r_orders.* TO NULL
      LET r_orders.order_num = 0
      CALL a_items.clear()
   END IF
   
   INPUT r_orders.* WITHOUT DEFAULTS FROM s_orders.*

      BEFORE INPUT
         LET recNotFound = FALSE 

      ON KEY (CONTROL-T)
         CASE
            WHEN INFIELD(store_num)
               CALL zoomCustomer() RETURNING r_customer.store_num, r_customer.store_name
               IF r_customer.store_num IS NOT NULL THEN
                  LET r_orders.store_num = r_customer.store_num
                  DISPLAY r_orders.store_num TO s_orders.store_num
                  DISPLAY r_customer.store_name TO customer.store_name
               END IF
            WHEN INFIELD(fac_code)
               CALL zoomFactory() RETURNING r_factory.*
               IF r_factory.fac_code IS NOT NULL THEN
                  LET r_orders.fac_code = r_factory.fac_code
                  DISPLAY r_orders.fac_code TO s_orders.fac_code
                  DISPLAY r_factory.fac_name TO factory.fac_name
               END IF
         END CASE

      AFTER FIELD order_date
         IF r_orders.order_date IS NULL THEN
            ERROR "Order Date is required"
            NEXT FIELD order_date
         END IF

      BEFORE FIELD store_num, fac_code
         MESSAGE "Use Control-T for table help window"

      AFTER FIELD store_num
         IF r_orders.store_num IS NULL THEN
            ERROR "Customer store number is required"
            NEXT FIELD store_num
         END IF
     
         #Fetch the customer record
         OPEN cursSingleCustomer USING r_orders.store_num
         FETCH cursSingleCustomer INTO customerName
         LET recNotFound = (sqlca.sqlcode <> 0)
         CLOSE cursSingleCustomer

         IF recNotFound THEN
            ERROR "No Customer record found for the store number entered"
            NEXT FIELD store_num
         END IF
         DISPLAY customerName TO customer.store_name

      AFTER FIELD fac_code
         IF r_orders.fac_code IS NULL THEN
            ERROR "Factory code is required"
            NEXT FIELD fac_code
         END IF
     
         #Fetch the factory record
         OPEN cursSingleFactory USING r_orders.fac_code
         FETCH cursSingleFactory INTO factoryName
         LET recNotFound = (sqlca.sqlcode <> 0)
         CLOSE cursSingleFactory

         IF recNotFound THEN
            ERROR "No Factory record found for the factory code entered"
            NEXT FIELD fac_code
         END IF
         DISPLAY factoryName TO factory.fac_name

      AFTER FIELD promo
         IF r_orders.promo IS NULL THEN
            ERROR "Promotion is required"
            NEXT FIELD promo
         END IF

   END INPUT

   IF int_flag THEN
      RETURN FALSE
   END IF

   INPUT ARRAY a_items WITHOUT DEFAULTS FROM s_items.*

      BEFORE ROW
         LET rowIdx = arr_curr()
         LET a_items[rowIdx].order_num = r_orders.order_num

      ON KEY (CONTROL-T)
         IF INFIELD(stock_num) THEN
            CALL zoomStock() RETURNING r_stock.stock_num, r_stock.description
            IF r_stock.stock_num IS NOT NULL THEN
               LET a_items[rowIdx].stock_num = r_stock.stock_num
               NEXT FIELD CURRENT
            END IF
         END IF

      BEFORE FIELD stock_num
         MESSAGE "Use Control-T for table help window"

      AFTER FIELD stock_num
         LET r_items = a_items[rowIdx]  
         IF r_items.stock_num IS NULL THEN
            ERROR "Stock number is required"
            NEXT FIELD stock_num
         END IF

         #Fetch the stock record
         OPEN cursSingleStock USING r_items.stock_num
         FETCH cursSingleStock INTO r_stock.*
         LET recNotFound = (sqlca.sqlcode <> 0)
         CLOSE cursSingleStock

         IF recNotFound THEN
            ERROR "No Stock record found for the stock number entered"
            NEXT FIELD stock_num
         END IF
         MESSAGE r_stock.description

         IF r_orders.promo == "Y" THEN
            LET a_items[rowIdx].price = r_stock.promo_price
         ELSE
            LET a_items[rowIdx].price = r_stock.reg_price
         END IF

      AFTER FIELD quantity
         LET r_items = a_items[rowIdx]
         IF r_items.quantity IS NULL THEN
            ERROR "Quantity is required"
            NEXT FIELD quantity
         END IF

         IF r_items.quantity <= 0 THEN
            ERROR "Quantity must be greater than 0"
            NEXT FIELD quantity
         END IF

   END INPUT

   IF int_flag THEN
      RETURN FALSE
   END IF

   BEGIN WORK

   IF addMode THEN

      EXECUTE insertOrders USING r_orders.order_date, r_orders.store_num,
                                 r_orders.fac_code, r_orders.ship_instr,
                                 r_orders.promo
      LET r_orders.order_num = sqlca.sqlerrd[2]

   ELSE

      EXECUTE updateOrders USING r_orders.order_date, r_orders.store_num,
                                 r_orders.fac_code, r_orders.ship_instr,
                                 r_orders.promo, r_orders.order_num
      EXECUTE deleteItems USING r_orders.order_num

   END IF

   FOR rowIdx = 1 TO a_items.getLength()
      LET a_items[rowIdx].order_num = r_orders.order_num
      EXECUTE insertItems USING a_items[rowIdx].*
   END FOR

   COMMIT WORK

   RETURN TRUE

END FUNCTION #enterOrder

FUNCTION deleteOrder()
   DEFINE deleteRecord SMALLINT

   OPEN WINDOW deletePrompt AT 6,6 WITH 10 ROWS, 45 COLUMNS
      ATTRIBUTES(MENU LINE 8, MESSAGE LINE 4, BORDER)

   LET deleteRecord = FALSE
   MENU "Delete Order"

      BEFORE MENU
         MESSAGE "Confirm deletion of order #", r_orders.order_num USING "<<<<<<<", "?"

      COMMAND "Delete"
         LET deleteRecord = TRUE
         EXIT MENU

      COMMAND "Cancel"
         EXIT MENU

   END MENU

   IF deleteRecord THEN

      BEGIN WORK 

      DELETE FROM items WHERE order_num = r_orders.order_num
      DELETE FROM orders WHERE order_num = r_orders.order_num
   
      COMMIT WORK

   END IF
   CLOSE WINDOW deletePrompt

   RETURN deleteRecord

END FUNCTION #deleteOrder

FUNCTION errorHandler()

   DISPLAY "Error Code: ", status
   DISPLAY "Error Message: ", err_get(status)

   EXIT PROGRAM -1

END FUNCTION #errorHandler
