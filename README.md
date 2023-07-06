# orderentry
Order Entry Migration from I-4GL to Genero BDL

## Order Entry Project Overview
This project is designed to demonstrate how you can migrate a I-4GL program to Genero. The application \
OrderEntry can be run from the terminal as well as from the desktop and browser clients.  The OrderEntryPlus \
application contains Genero specific code to demonstrate how simple modifications can be made to enhance the \
look and feel of the application.  The OrderEntryWS application is a RESTful web service that contains \
endpoints to fetch, add, update, and delete orders.

## Prerequisites
Before you get started, you will need the following
- Need an Informix database to run against: CREATE DATABASE custdemo WITH LOG;
- Make sure your user account has dba access to the custdemo database
- Run the CreateDatabase application to create the tables and load the default data

## To Do List
There are several items that still need to be done

- Validate that the OrderEntry program runs in I-4GL.  There is still a DYNAMIC ARRAY in the order_entry.4gl module.
- Refactor the OrderEntryPlus and the OrderEntryWS projects to shared validation and insert, update, delete logic. 
- Potentially remove the table help windows in OrderEntryPlus, since the fields are now comboboxes
