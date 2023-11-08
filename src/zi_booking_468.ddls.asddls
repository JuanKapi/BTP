@EndUserText.label: 'CDS Interface projeccion Booking'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZI_BOOKING_468
  as projection on ZR_BOOKING_468
{
    key BookingUuid,
    TravelUuid,
    BookingId,
    BookingDate,
    CustomerId,
    AirlineID,
    ConnectionId,
    FlightDate,
    FlightPrice,
    CurrencyCode,
    BookingStatus,
    LocalLastChangedAt,
    /* Associations */
    _BookingStatus,
    _Carrier,
    _Connection,
    _Customer,
    _Travel : redirected to parent ZI_TRAVEL_468
    
}
