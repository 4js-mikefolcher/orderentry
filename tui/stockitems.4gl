DATABASE custdemo

DEFINE cursorDefined SMALLINT

FUNCTION zoomStockCursor()

   IF NOT cursorDefined OR cursorDefined IS NULL THEN
      DECLARE cursStocks CURSOR FOR SELECT * FROM stock ORDER BY stock_num
      LET cursorDefined = TRUE
   END IF

END FUNCTION #zoomStockCursor

FUNCTION zoomStock()
   DEFINE r_stock RECORD LIKE stock.*
   DEFINE a_stocks DYNAMIC ARRAY OF RECORD
             stock_num LIKE stock.stock_num,
             description LIKE stock.description,
             reg_price LIKE stock.reg_price,
             promo_price LIKE stock.promo_price,
             unit LIKE stock.unit
          END RECORD
   DEFINE rowIdx INTEGER

   CALL zoomStockCursor()
   OPEN WINDOW stockWindow AT 3,3 WITH FORM "stockitems"
      ATTRIBUTES(BORDER)

   LET rowIdx = 0
   FOREACH cursStocks INTO r_stock.*
      LET rowIdx = rowIdx + 1
      LET a_stocks[rowIdx].stock_num = r_stock.stock_num
      LET a_stocks[rowIdx].description = r_stock.description
      LET a_stocks[rowIdx].reg_price = r_stock.reg_price
      LET a_stocks[rowIdx].promo_price = r_stock.promo_price
      LET a_stocks[rowIdx].unit = r_stock.unit
   END FOREACH

   CALL set_count(a_stocks.getLength()) 
   DISPLAY ARRAY a_stocks TO s_stock.*
      ATTRIBUTES(REVERSE)

      ON KEY (RETURN)
         ACCEPT DISPLAY

      AFTER DISPLAY
         LET rowIdx = arr_curr() 
         LET r_stock.stock_num = a_stocks[rowIdx].stock_num
         LET r_stock.description = a_stocks[rowIdx].description

   END DISPLAY

   IF int_flag THEN
      INITIALIZE r_stock.* TO NULL
      LET int_flag = FALSE
   END IF

   CLOSE WINDOW stockWindow

   RETURN r_stock.stock_num, r_stock.description

END FUNCTION #zoomStock
