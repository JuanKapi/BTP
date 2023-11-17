CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS :
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE '0', " open
        accepted TYPE c LENGTH 1 VALUE 'A', " accepted
        rejected TYPE c LENGTH 1 VALUE 'X', "rejected
      END OF travel_status.

    TYPES:
      t_entities_create TYPE TABLE FOR CREATE zr_travel_468\\Travel,
      t_entities_update TYPE TABLE FOR UPDATE zr_travel_468\\Travel,
      t_failed_travel   TYPE TABLE FOR FAILED EARLY zr_travel_468\\Travel,
      t_reported_travel TYPE TABLE FOR REPORTED EARLY zr_travel_468\\Travel.

    DATA agency TYPE /dmo/agency_id.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS deducDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deducDiscount RESULT result.

    METHODS reCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~reCalcTotalPrice.

    METHODS rejectTravelTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS Resume FOR MODIFY
      IMPORTING keys FOR ACTION Travel~Resume.

    METHODS setStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setStatusToOpen.

    METHODS setTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~setTravelNumber.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    METHODS is_create_granted
      IMPORTING country_code          TYPE land1  OPTIONAL
      RETURNING VALUE(create_granted) TYPE abap_bool.

    METHODS is_update_granted
      IMPORTING country_code          TYPE land1  OPTIONAL
      RETURNING VALUE(update_granted) TYPE abap_bool.

    METHODS is_delete_granted
      IMPORTING country_code          TYPE land1  OPTIONAL
      RETURNING VALUE(delete_granted) TYPE abap_bool.

    METHODS precheck_auth
      IMPORTING
        entities_create TYPE t_entities_create OPTIONAL
        entities_update TYPE t_entities_update OPTIONAL
      CHANGING
        failed          TYPE t_failed_travel
        reported        TYPE t_reported_travel.


ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ    ENTITIES OF zr_travel_468 IN LOCAL MODE
            ENTITY Travel
            FIELDS ( OverallStatus )
            WITH CORRESPONDING #( keys )
            RESULT DATA(lt_travels)
            FAILED failed.

    result = VALUE #(  FOR ls_travel IN lt_travels ( %tky = ls_travel-%tky

    %field-BookingFee       = COND #(   WHEN ls_travel-OverallStatus = travel_status-accepted
                                        THEN if_abap_behv=>fc-f-read_only
                                        ELSE if_abap_behv=>fc-f-unrestricted )

    %action-acceptTravel    = COND #(   WHEN ls_travel-OverallStatus = travel_status-accepted
                                        THEN if_abap_behv=>fc-o-disabled
                                        ELSE if_abap_behv=>fc-o-enabled )

    %action-rejectTravel    = COND #(   WHEN ls_travel-OverallStatus = travel_status-rejected
                                        THEN if_abap_behv=>fc-o-enabled
                                        ELSE if_abap_behv=>fc-o-disabled )

    %action-deducDiscount   = COND #(   WHEN ls_travel-OverallStatus = travel_status-accepted
                                        THEN if_abap_behv=>fc-o-disabled
                                        ELSE if_abap_behv=>fc-o-enabled )

    %assoc-_Booking         = COND #(   WHEN ls_travel-OverallStatus = travel_status-rejected
                                        THEN if_abap_behv=>fc-o-disabled
                                        ELSE if_abap_behv=>fc-o-enabled )

) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.

    DATA: lv_update_requested TYPE abap_boolean.
    DATA: lv_delete_requested TYPE abap_boolean.
    DATA: lv_update_granted TYPE abap_boolean.
    DATA: lv_delete_granted TYPE abap_boolean.

    READ    ENTITIES OF zr_travel_468 IN LOCAL MODE
            ENTITY Travel
            FIELDS ( AgencyID )
            WITH CORRESPONDING #( keys )
            RESULT DATA(lt_travels)
            FAILED failed.

    CHECK lt_travels IS NOT INITIAL.

    SELECT
    FROM            zr_travel_468   AS travel
    INNER JOIN      /dmo/agency     AS agency
    ON              travel~AgencyId = agency~agency_id
    FIELDS  travel~TravelUuid,
            travel~AgencyId,
            agency~country_code
    FOR ALL ENTRIES IN @lt_travels
    WHERE TravelUuid EQ @lt_travels-TravelUuid
    INTO TABLE @DATA(lt_travel_agency_country).

    lv_update_requested = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on
                                  THEN abap_true ELSE abap_false ).

    lv_delete_requested = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                                  THEN abap_true ELSE abap_false ).

    LOOP AT lt_travels INTO DATA(travel).

      READ TABLE lt_travel_agency_country WITH KEY TravelUUID = travel-TravelUUID
      ASSIGNING FIELD-SYMBOL(<travel_agency_country_code>).

      IF sy-subrc = 0.

        IF lv_update_requested = abap_true.

          lv_update_granted = is_update_granted(  <travel_agency_country_code>-country_code ).

          IF lv_update_granted = abap_false.

            APPEND VALUE #( %tky = travel-%tky
                         %msg = NEW /dmo/cm_flight_messages(
                         textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                         agency_id = travel-AgencyId
                         severity = if_abap_behv_message=>severity-error )
                         %element-agencyid = if_abap_behv=>mk-on )
                         TO reported-travel.

          ENDIF.


        ENDIF.

      ELSE.

        lv_update_granted = lv_delete_granted = is_create_granted(  ).
        IF lv_update_granted = abap_false.

          APPEND VALUE #( %tky = travel-%tky
                       %msg = NEW /dmo/cm_flight_messages(
                       textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                       agency_id = travel-AgencyId
                       severity = if_abap_behv_message=>severity-error )
                       %element-agencyid = if_abap_behv=>mk-on )
                       TO reported-travel.

        ENDIF.
      ENDIF.

      APPEND VALUE #( LET upd_auth = COND #( WHEN lv_update_granted = abap_true
                    THEN if_abap_behv=>auth-allowed
                    ELSE if_abap_behv=>auth-unauthorized )
                    del_auth = COND #( WHEN lv_delete_granted = abap_true
                    THEN if_abap_behv=>auth-allowed
                    ELSE if_abap_behv=>auth-unauthorized ) IN %tky = travel-%tky
                   %update = upd_auth
                   %action-edit = upd_auth
                   %delete = del_auth ) TO result.


    ENDLOOP.


  ENDMETHOD.

  METHOD get_global_authorizations.

    IF  requested_authorizations-%create EQ if_abap_behv=>mk-on.
      IF is_create_granted(  ) = abap_true.

        result-%create = if_abap_behv=>auth-allowed.

      ELSE.

        result-%create = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg = NEW /dmo/cm_flight_messages(
             textid = /dmo/cm_flight_messages=>not_authorized
             severity = if_abap_behv_message=>severity-error )
             %global = if_abap_behv=>mk-on )
             TO reported-travel.

      ENDIF.

    ENDIF.

    IF requested_authorizations-%update EQ if_abap_behv=>mk-on OR
       requested_authorizations-%action-edit EQ if_abap_behv=>mk-on.

      IF is_update_granted(  ) = abap_true.

        result-%update = if_abap_behv=>auth-allowed.

      ELSE.

        result-%update = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #(
                    %msg        = NEW /dmo/cm_flight_messages(
                    textid      = /dmo/cm_flight_messages=>not_authorized
                    severity    = if_abap_behv_message=>severity-error )
                    %global     = if_abap_behv=>mk-on )
                    TO reported-travel.

      ENDIF.

    ENDIF.

    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.

      IF is_create_granted(  ) = abap_true.

        result-%delete = if_abap_behv=>auth-allowed.

      ELSE.

        result-%delete = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #(
                    %msg        = NEW /dmo/cm_flight_messages(
                    textid      = /dmo/cm_flight_messages=>not_authorized
                    severity    = if_abap_behv_message=>severity-error )
                    %global     = if_abap_behv=>mk-on )
                    TO reported-travel.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD precheck_create.

    precheck_auth(
    EXPORTING
    entities_create = entities
    CHANGING
    failed  = failed-travel
    reported = reported-travel
    ).

  ENDMETHOD.

  METHOD precheck_update.

    precheck_auth(
    EXPORTING
    entities_update = entities
    CHANGING
    failed  = failed-travel
    reported = reported-travel
    ).

  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF zr_travel_468 IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
              overallstatus = travel_status-accepted ) ).

    READ ENTITIES OF zr_travel_468 IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travels) .

    result = VALUE #( FOR <travel> IN travels (
                            %tky = <travel>-%tky
                            %param = <travel> ) ).


  ENDMETHOD.

  METHOD deducDiscount.

*    "key[1]-
*    "result[ 0 ]-%is_draft = 1
*    "Mapped-travel[ 1 ]-
*    "failed-travel[ 1 ]-
*    "reported-travel[ 1 ]-
*
    DATA lt_travel_for_update TYPE TABLE FOR UPDATE zr_travel_468.
    DATA(lt_keys_with_valid_dicount) = keys.

    LOOP AT lt_keys_with_valid_dicount ASSIGNING FIELD-SYMBOL(<key_vith_valid_discount>)
        WHERE %param-discount_percent IS INITIAL
           OR %param-discount_percent > 100
           OR %param-discount_percent <= 0.

      APPEND VALUE #( %tky = <key_vith_valid_discount>-%tky ) TO failed-travel.

      APPEND VALUE #( %tky = <key_vith_valid_discount>-%tky
                      %msg = NEW /dmo/cm_flight_messages(
                      textid = /dmo/cm_flight_messages=>discount_invalid
                      severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice = if_abap_behv=>mk-on
                      %op-%action-deducDiscount = if_abap_behv=>mk-on ) TO reported-travel.


      DELETE lt_keys_with_valid_dicount.

    ENDLOOP.

    CHECK lt_keys_with_valid_dicount IS NOT INITIAL.
    READ ENTITIES OF zr_travel_468 IN LOCAL MODE
    ENTITY travel
    FIELDS ( BookingFee )
    WITH CORRESPONDING #( lt_keys_with_valid_dicount )
    RESULT DATA(lt_travels).

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<travel>).

      DATA percentage TYPE decfloat16.
      DATA(discount_percent) = lt_keys_with_valid_dicount[ KEY id %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percent / 100.

      DATA(reduced_fee) = <travel>-BookingFee * (  1 - percentage ).
      APPEND VALUE #( %tky = <travel>-%tky
      bookingFee = reduced_fee ) TO lt_travel_for_update.
    ENDLOOP.

    MODIFY ENTITIES OF zr_travel_468 IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Bookingfee )
    WITH lt_travel_for_update.

    READ ENTITIES OF zr_travel_468 IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( lt_travels )
    RESULT DATA(lt_travels_with_discount).

  ENDMETHOD.

  METHOD reCalcTotalPrice.

    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: lt_amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF zr_travel_468  IN LOCAL MODE
            ENTITY Travel
            FIELDS ( bookingFee Currencycode )
            WITH CORRESPONDING #( keys )
            RESULT DATA(lt_travels).

    DELETE lt_travels WHERE CurrencyCode IS INITIAL.

    READ ENTITIES OF zr_travel_468  IN LOCAL MODE
        ENTITY Travel BY \_booking
        FIELDS ( FlightPrice Currencycode )
        WITH CORRESPONDING #( lt_travels )
        LINK DATA(lt_booking_links_)
        RESULT DATA(lt_bookings).

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<travel>).

      lt_amount_per_currencycode = VALUE #( ( amount = <travel>-BookingFee
              currency_code = <travel>-CurrencyCode ) ).

      LOOP AT lt_booking_links_ INTO DATA(booking_link) USING KEY id WHERE source-%tky = <travel>-%tky.

        DATA(booking) = lt_bookings[ KEY id %tky = booking_link-target-%tky ].

        COLLECT VALUE   ty_amount_per_currencycode(
                        amount          = booking-flightprice
                        currency_code   = booking-currencycode )
                        into lt_amount_per_currencycode.


      ENDLOOP.

      DELETE lt_amount_per_currencycode WHERE currency_code IS INITIAL.

      CLEAR <travel>-TotalPrice.

      LOOP AT lt_amount_per_currencycode INTO DATA(ls_amount_per_currencycode).
        IF ls_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice = ls_amount_per_currencycode-amount.
        ELSE.


          /dmo/cl_flight_amdp=>convert_currency( EXPORTING iv_amount                  = ls_amount_per_currencycode-amount
                                                           iv_currency_code_source    = ls_amount_per_currencycode-currency_code
                                                           iv_currency_code_target    = <travel>-CurrencyCode
                                                           iv_exchange_rate_date      = cl_abap_context_info=>get_system_date(  )
                                                  IMPORTING
                                                           ev_amount                  = DATA(lv_total_book_price_per_curr) ).

          <travel>-TotalPrice += lv_total_book_price_per_curr.


        ENDIF.

      ENDLOOP.

    ENDLOOP.

    MODIFY ENTITIES OF zr_travel_468 IN LOCAL MODE
            ENTITY travel
            UPDATE FIELDS ( TotalPrice )
            WITH CORRESPONDING #(  lt_travels ).

  ENDMETHOD.

  METHOD rejectTravelTravel.

    MODIFY ENTITIES OF zr_travel_468 IN LOCAL MODE
            ENTITY travel
            UPDATE FIELDS ( Overallstatus )
            WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                    overallstatus = travel_status-rejected ) ).

    READ ENTITIES OF zr_travel_468  IN LOCAL MODE
            ENTITY Travel
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(travels).

    result = VALUE #( FOR <travel> IN travels (  %tky   = <travel>-%tky
                                                 %param = <travel> )  ).


  ENDMETHOD.

  METHOD Resume.
  ENDMETHOD.

  METHOD setStatusToOpen.
  ENDMETHOD.

  METHOD setTravelNumber.
  ENDMETHOD.

  METHOD validateAgency.
  ENDMETHOD.

  METHOD validateCustomer.
  ENDMETHOD.

  METHOD validateDates.
  ENDMETHOD.

  METHOD is_create_granted.

    IF country_code IS SUPPLIED.
      AUTHORITY-CHECK OBJECT 'DMO/TRVL'
      ID  '/DMO/CNTRY' FIELD country_code
      ID  'ACTVT'      FIELD '01'.

      create_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    ELSE.
      AUTHORITY-CHECK OBJECT 'DMO/TRVL'
      ID  '/DMO/CNTRY'    DUMMY
      ID 'ACTVT'          FIELD '01'.

      create_granted  = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    ENDIF.

    create_granted  = abap_true.

  ENDMETHOD.

  METHOD is_delete_granted.

    IF country_code IS SUPPLIED.

      AUTHORITY-CHECK OBJECT 'DMO/TRVL'
      ID  '/DMO/CNTRY' FIELD country_code
      ID  'ACTVT'      FIELD '06'.

      DELETE_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

      CASE country_code.
        WHEN 'US'.
          delete_granted = abap_true.
        WHEN OTHERS.
          delete_granted = abap_false.
      ENDCASE.

    ELSE.

      IF country_code IS SUPPLIED.

        AUTHORITY-CHECK OBJECT 'DMO/TRVL'
        ID  '/DMO/CNTRY'    DUMMY
        ID 'ACTVT'          FIELD '06'.

        DELETE_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

      ENDIF.

      delete_granted = abap_true.

    ENDIF.

  ENDMETHOD.

  METHOD is_update_granted.

    IF country_code IS SUPPLIED.
      AUTHORITY-CHECK OBJECT 'DMO/TRVL'
      ID  '/DMO/CNTRY'    FIELD country_code
      ID 'ACTVT'          FIELD '02'.

      update_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    ELSE.

      AUTHORITY-CHECK OBJECT 'DMO/TRVL'
      ID  '/DMO/CNTRY'    DUMMY
      ID 'ACTVT'          FIELD '02'.

      update_granted = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).

    ENDIF.

  ENDMETHOD.

  METHOD precheck_auth.

    DATA:
      entities          TYPE t_entities_update,
      operation         TYPE if_abap_behv=>t_char01,
      agencies          TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id,
      is_modify_granted TYPE abap_boolean.

    ASSERT NOT ( entities_create IS INITIAL EQUIV entities_update IS INITIAL ).

    IF entities_create IS NOT INITIAL.

      entities = CORRESPONDING #( entities_create MAPPING %cid_ref = %cid ).

      operation = if_abap_behv=>op-m-create.
    ELSE.

      entities = entities_update.

      operation = if_abap_behv=>op-m-update.
    ENDIF.

    DELETE entities WHERE %control-AgencyID = if_abap_behv=>mk-off.

    agencies = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).

    CHECK agencies IS NOT INITIAL.

    SELECT  FROM /dmo/agency FIELDS agency_id, country_code
    FOR ALL ENTRIES IN @agencies
    WHERE agency_id = @agencies-agency_id
    INTO TABLE @DATA(agency_country_codes).

    LOOP AT entities INTO DATA(entity).

      is_modify_granted = abap_true.

      READ  TABLE agency_country_codes WITH KEY agency_id = entity-AgencyID
            ASSIGNING FIELD-SYMBOL(<agency_country_code>).

      CHECK sy-subrc = 0.
      CASE operation.
        WHEN if_abap_behv=>op-m-create.

          is_modify_granted = is_create_granted( <agency_country_code>-country_code ).

        WHEN if_abap_behv=>op-m-update.

          is_modify_granted = is_update_granted( <agency_country_code>-country_code ).

      ENDCASE.

      IF is_modify_granted = abap_false.

        APPEND VALUE #( %cid = COND #(  WHEN operation = if_abap_behv=>op-m-create
                                THEN entity-%cid_ref )
                                %tky = entity-%tky ) TO failed.

        APPEND VALUE #( %cid = COND #( WHEN operation = if_abap_behv=>op-m-create
                                       THEN entity-%cid_ref )

                                %tky = entity-%tky
                                %msg = NEW /dmo/cm_flight_messages(
                                textid = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                agency_id = entity-AgencyId
                                severity = if_abap_behv_message=>severity-error )
                                %element-agencyid = if_abap_behv=>mk-on ) TO reported.



      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
