DATABASE custdemo

DEFINE cursorDefined SMALLINT

FUNCTION zoomFactoryCursor()

   IF NOT cursorDefined OR cursorDefined IS NULL THEN
      DECLARE cursFactories CURSOR FOR SELECT * FROM factory ORDER BY fac_code
      LET cursorDefined = TRUE
   END IF

END FUNCTION #zoomFactoryCursor

FUNCTION zoomFactory()
   DEFINE r_factory RECORD LIKE factory.*
   DEFINE a_factories DYNAMIC ARRAY OF RECORD LIKE factory.*
   DEFINE rowIdx INTEGER

   CALL zoomFactoryCursor()
   OPEN WINDOW factoryWindow AT 3,3 WITH FORM "factories"
      ATTRIBUTES(BORDER)

   LET rowIdx = 0
   FOREACH cursFactories INTO r_factory.*
      LET rowIdx = rowIdx + 1
      LET a_factories[rowIdx] = r_factory
   END FOREACH

   CALL set_count(a_factories.getLength()) 
   DISPLAY ARRAY a_factories TO s_factory.*
      ATTRIBUTES(REVERSE)

      ON KEY (RETURN)
         ACCEPT DISPLAY

      AFTER DISPLAY
         LET rowIdx = arr_curr() 
         LET r_factory = a_factories[rowIdx]

   END DISPLAY

   IF int_flag THEN
      INITIALIZE r_factory.* TO NULL
      LET int_flag = FALSE
   END IF

   CLOSE WINDOW factoryWindow

   RETURN r_factory.fac_code, r_factory.fac_name

END FUNCTION #zoomFactory
