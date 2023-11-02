CLASS zcl_carga_inicial DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_carga_inicial IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    out->write( |----> Travel| ).

    DELETE FROM ztb_travel_468.                         "#EC CI_NOWHERE
    DELETE FROM ztb_travel_468d.                        "#EC CI_NOWHERE

    INSERT ztb_travel_468 FROM (
        SELECT FROM /dmo/travel FIELDS
           " client
           uuid( ) AS travel_uuid,
           travel_id,
           agency_id,
           customer_id,
           begin_date,
           end_date,
           booking_fee,
           total_price,
           currency_code,
           description,
           CASE status WHEN 'B' THEN 'A'
                       WHEN 'p' THEN 'O'
                       WHEN 'N' THEN 'O'
                       ELSE 'X'  END AS overall_status,
           createdby  AS local_created_by,
           createdat  AS  local_created_at,
           lastchangedby  AS     local_last_changed_by,
           lastchangedat AS local_last_changed_at,
           lastchangedat AS last_changed_at
        WHERE travel_id BETWEEN '00000001' AND '00000025' ).


    IF sy-subrc EQ 0.
      out->write( | Travel entries inserted: { sy-dbcnt } | ).
    ENDIF.

    " bookings
    out->write( |-----> Bookings| ).

    DELETE FROM ztb_booking_468.                        "#EC CI_NOWHERE
    DELETE FROM ztb_booking_468d.                       "#EC CI_NOWHERE

    INSERT ztb_booking_468 FROM (
        SELECT
          FROM /dmo/booking
          JOIN ztb_travel_468 ON /dmo/booking~travel_id = ztb_travel_468~travel_id
          JOIN /dmo/travel    ON /dmo/travel~travel_id  = /dmo/booking~travel_id
        FIELDS  "client,
               uuid( ) AS booking_uuid,
               ztb_travel_468~travel_uuid AS parent_uuid,
               /dmo/booking~booking_id,
               /dmo/booking~booking_date,
               /dmo/booking~customer_id,
               /dmo/booking~carrier_id,
               /dmo/booking~connection_id,
               /dmo/booking~flight_date,
               /dmo/booking~flight_price,
               /dmo/booking~currency_code,
               CASE /dmo/travel~status WHEN 'P' THEN 'N'
                                       ELSE /dmo/travel~status END AS booking_status,
               ztb_travel_468~last_changed_at AS local_last_changed_at ).

    IF sy-subrc EQ 0.
      out->write( | Booking entries inserted:   { sy-dbcnt }| ).
    ENDIF.

    " supplements
    out->write( |----> Bookings| ).

    DELETE FROM ztb_booksup_468.                        "'#EC CI_NOWHERE
    DELETE FROM ztb_booksup_468d.                        "#EC CI_NOWHERE

    INSERT ztb_booksup_468 FROM (
        SELECT FROM /dmo/book_suppl AS supp
        JOIN ztb_travel_468  AS trvl  ON trvl~travel_id   = supp~travel_id
        JOIN ztb_booking_468 AS book  ON book~parent_uuid = trvl~travel_uuid
                                     AND book~booking_id  = supp~booking_id

        FIELDS
                "client
                uuid( )                       AS booksuppl_uuid,
                trvl~travel_uuid              AS root_uuid,
                book~booking_uuid             AS parent_uuid,
                supp~booking_supplement_id,
                supp~supplement_id,
                supp~price,
                supp~currency_code,
                trvl~last_changed_at      AS local_last_changed_at ).

    IF  sy-subrc EQ 0.
      out->write( | Supplements entries inserted: { sy-dbcnt } | ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
