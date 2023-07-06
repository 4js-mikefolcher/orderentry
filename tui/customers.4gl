DATABASE custdemo

DEFINE cursorDefined SMALLINT

FUNCTION zoomCustomerCursor()

   IF NOT cursorDefined OR cursorDefined IS NULL THEN
      DECLARE cursCustomers CURSOR FOR SELECT * FROM customer ORDER BY store_num
      LET cursorDefined = TRUE
   END IF

END FUNCTION #zoomCustomerCursor

FUNCTION zoomCustomer()
   DEFINE r_customer RECORD LIKE customer.*
   DEFINE a_customers DYNAMIC ARRAY OF RECORD
             store_num LIKE customer.store_num,
             store_name LIKE customer.store_name,
             city LIKE customer.city,
             contact_name LIKE customer.contact_name
          END RECORD
   DEFINE rowIdx INTEGER

   CALL zoomCustomerCursor()
   OPEN WINDOW customerWindow AT 3,3 WITH FORM "customers"
      ATTRIBUTES(BORDER)

   LET rowIdx = 0
   FOREACH cursCustomers INTO r_customer.*
      LET rowIdx = rowIdx + 1
      LET a_customers[rowIdx].store_num = r_customer.store_num
      LET a_customers[rowIdx].store_name = r_customer.store_name
      LET a_customers[rowIdx].city = r_customer.city
      LET a_customers[rowIdx].contact_name = r_customer.contact_name
   END FOREACH

   CALL set_count(a_customers.getLength()) 
   DISPLAY ARRAY a_customers TO s_customer.*
      ATTRIBUTES(REVERSE)

      ON KEY (RETURN)
         ACCEPT DISPLAY

      AFTER DISPLAY
         LET rowIdx = arr_curr() 
         LET r_customer.store_num = a_customers[rowIdx].store_num
         LET r_customer.store_name = a_customers[rowIdx].store_name

   END DISPLAY

   IF int_flag THEN
      INITIALIZE r_customer.* TO NULL
      LET int_flag = FALSE
   END IF

   CLOSE WINDOW customerWindow

   RETURN r_customer.store_num, r_customer.store_name

END FUNCTION #zoomCustomer
