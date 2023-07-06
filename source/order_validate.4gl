SCHEMA custdemo

PUBLIC TYPE TValidation RECORD
	success BOOLEAN,
	validMessage STRING
END RECORD

DEFINE cursorsDefined BOOLEAN = FALSE

PRIVATE FUNCTION declareCursors() RETURNS ()
	DEFINE sqlText STRING

	WHENEVER ANY ERROR RAISE

	IF NOT cursorsDefined THEN

		LET sqlText = "SELECT orders.* FROM orders WHERE order_num = ?"
		PREPARE prepSingleOrder FROM sqlText
		DECLARE cursSingleOrder CURSOR FOR prepSingleOrder

		LET sqlText = "SELECT factory.fac_name FROM factory WHERE fac_code = ?"
		PREPARE prepSingleFactory FROM sqlText
		DECLARE cursSingleFactory CURSOR FOR prepSingleFactory

		LET sqlText = "SELECT customer.store_name FROM customer WHERE store_num = ?"
		PREPARE prepSingleCustomer FROM sqlText
		DECLARE cursSingleCustomer CURSOR FOR prepSingleCustomer

		LET sqlText = "SELECT stock.* FROM stock WHERE stock_num = ?"
		PREPARE prepSingleStock FROM sqlText
		DECLARE cursSingleStock CURSOR FOR prepSingleStock

		LET cursorsDefined = TRUE

	END IF

END FUNCTION #declareCursors

PUBLIC FUNCTION validateOrder(addMode BOOLEAN, r_orders RECORD LIKE orders.* INOUT) RETURNS (TValidation)
	DEFINE valid TValidation = (success: TRUE, validMessage: "Validate Record")

	CALL declareCursors()
	VAR recNotFound = FALSE

	IF addMode THEN

		LET r_orders.order_num = 0

	ELSE

		#Fetch the order record
		OPEN cursSingleOrder USING r_orders.order_num
		FETCH cursSingleOrder
		LET recNotFound = (sqlca.sqlcode <> 0)
		CLOSE cursSingleOrder

		IF recNotFound THEN
			LET valid.success = FALSE
			CALL valid.invalidate("No order record found for the order number entered")
			RETURN valid
		END IF

	END IF

	IF r_orders.order_date IS NULL THEN
		CALL valid.invalidate("Order Date is required")
		RETURN valid
	END IF

	IF r_orders.store_num IS NULL THEN
		CALL valid.invalidate("Customer store number is required")
		RETURN valid
	END IF
     
	#Fetch the customer record
	OPEN cursSingleCustomer USING r_orders.store_num
	FETCH cursSingleCustomer
	LET recNotFound = (sqlca.sqlcode <> 0)
	CLOSE cursSingleCustomer

	IF recNotFound THEN
		LET valid.success = FALSE
		CALL valid.invalidate("No Customer record found for the store number entered")
		RETURN valid
	END IF

	IF r_orders.fac_code IS NULL THEN
		CALL valid.invalidate("Factory code is required")
		RETURN valid
	END IF

	#Fetch the factory record
	OPEN cursSingleFactory USING r_orders.fac_code
	FETCH cursSingleFactory
	LET recNotFound = (sqlca.sqlcode <> 0)
	CLOSE cursSingleFactory

	IF recNotFound THEN
		CALL valid.invalidate("No Factory record found for the factory code entered")
		RETURN valid
	END IF

	IF r_orders.promo IS NULL THEN
		CALL valid.invalidate("Promotion is required")
		RETURN valid
	END IF

	RETURN valid

END FUNCTION #validateOrder

PUBLIC FUNCTION validateItem(addMode BOOLEAN, promoFlag STRING, r_item RECORD LIKE items.* INOUT) RETURNS (TValidation)
	DEFINE valid TValidation = (success: TRUE, validMessage: "Valid Record")
	DEFINE r_stock RECORD LIKE stock.*

	CALL declareCursors()
	VAR recNotFound = FALSE

	IF addMode THEN

		LET r_item.order_num = 0

	ELSE

		#Fetch the order record
		OPEN cursSingleOrder USING r_item.order_num
		FETCH cursSingleOrder
		LET recNotFound = (sqlca.sqlcode <> 0)
		CLOSE cursSingleOrder

		IF recNotFound THEN
			LET valid.success = FALSE
			CALL valid.invalidate("No order record found for the order number entered")
			RETURN valid
		END IF

	END IF

	IF r_item.stock_num IS NULL THEN
		CALL valid.invalidate("Stock number is required")
		RETURN valid
	END IF

	#Fetch the stock record
	OPEN cursSingleStock USING r_item.stock_num
	FETCH cursSingleStock INTO r_stock.*
	LET recNotFound = (sqlca.sqlcode <> 0)
	CLOSE cursSingleStock

	IF recNotFound THEN
		CALL valid.invalidate("No Stock record found for the stock number entered")
		RETURN valid
	END IF

	IF r_item.quantity IS NULL OR r_item.quantity <= 0 THEN
		CALL valid.invalidate("Quantity must be greater than zero")
		RETURN valid
	END IF

	IF r_item.price IS NULL OR r_item.price <= 0 THEN
		IF promoFlag.toUpperCase() == "Y" THEN
			LET r_item.price = r_stock.promo_price
		ELSE
			LET r_item.price = r_stock.reg_price
		END IF
	END IF

	RETURN valid

END FUNCTION #validateItem

PRIVATE FUNCTION (self TValidation) invalidate(validMessage STRING) RETURNS ()

	LET self.success = FALSE
	LET self.validMessage = validMessage

END FUNCTION #invalidate