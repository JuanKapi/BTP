CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateConnection FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~calculateConnection.

    METHODS setBookingDate FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~setBookingDate.

    METHODS setBookingNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~setBookingNumber.

    METHODS validateConnection FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateConnection.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCustomer.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateConnection.
  ENDMETHOD.

  METHOD setBookingDate.
  ENDMETHOD.

  METHOD setBookingNumber.
  ENDMETHOD.

  METHOD validateConnection.
  ENDMETHOD.

  METHOD validateCustomer.
  ENDMETHOD.

ENDCLASS.
