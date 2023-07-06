IMPORT com

MAIN

	CALL STARTLOG("order_entry_service.log")

	DATABASE custdemo

	CALL com.WebServiceEngine.RegisterRestService("order_entry_endpoints","oe")
	VAR wsMessage = startService()
	DISPLAY wsMessage

END MAIN

PRIVATE FUNCTION startService() RETURNS STRING
    DEFINE serviceStatus    INTEGER

    CALL com.WebServiceEngine.Start()
    LET int_flag = FALSE
    WHILE int_flag = FALSE

      LET serviceStatus = com.WebServiceEngine.ProcessServices(-1)
      CASE serviceStatus
         WHEN 0
            DISPLAY "Request processed."
         WHEN -1
            DISPLAY "Timeout reached."
         WHEN -2
            RETURN "Disconnected from application server."
         WHEN -3
            DISPLAY "Client Connection lost."
         WHEN -4
            DISPLAY "Server interrupted with Ctrl-C."
         WHEN -9
            DISPLAY "Unsupported operation."
         WHEN -10
            DISPLAY "Internal server error."
         WHEN -23
            DISPLAY "Deserialization error."
         WHEN -35
            DISPLAY "No such REST operation found."
         WHEN -36
            DISPLAY "Missing REST parameter."
         OTHERWISE
            RETURN SFMT("Unexpected server error %1.", serviceStatus)
            LET int_flag = TRUE
     END CASE

	  END WHILE

  RETURN "Server stopped"

END FUNCTION