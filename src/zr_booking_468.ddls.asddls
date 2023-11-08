@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Composition Root Entity'
define view entity ZR_BOOKING_468
  as select from ztb_booking_468
// aqui debemos agregar todas las associaciones a las tablas que tengan relaciones
  association        to parent ZR_TRAVEL_468 as _Travel     on $projection.TravelUuid    = _Travel.TravelUuid
  association [1..1] to /DMO/I_Customer      as _Customer   on $projection.CustomerId    = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier       as _Carrier    on $projection.AirlineID     = _Carrier.AirlineID
  association [1..1] to /DMO/I_Connection    as _Connection on $projection.AirlineID     = _Connection.AirlineID
                                                            and $projection.ConnectionId = _Connection.ConnectionID
  association [1..1] to /DMO/I_Booking_Status_VH as _BookingStatus on  $projection.BookingStatus = _BookingStatus.BookingStatus
  
  // Este composition lo genero el asistente... pero no debe ir pq ya se puso en el travel... y solo debe ir uno
  //   composition [0..*] of ZR_TRAVEL_5277_A as _Travel

{
  key booking_uuid          as BookingUuid,
      parent_uuid           as TravelUuid,

      booking_id            as BookingId,
      booking_date          as BookingDate,
      customer_id           as CustomerId,
      carrier_id            as AirlineID,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      currency_code         as CurrencyCode,
      booking_status        as BookingStatus,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      //   _association_name // Make association public
      _Travel,
      _Customer,
      _Carrier,
      _Connection,
      _BookingStatus
}
