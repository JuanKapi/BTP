@EndUserText.label: 'CDS Interface projeccion Travel'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_TRAVEL_468
  provider contract transactional_interface 
  as projection on ZR_TRAVEL_468
{
    key TravelUuid,
    TravelId,
    AgencyId,
    CustomerId,
    BeginDate,
    EndDate,
    BookingFee,
    TotalPrice,
    CurrencyCode,
    Description,
    OverallStatus,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Agency,
    _Booking : redirected to composition child ZI_BOOKING_468,
    _Currency,
    _Customer,
    _OverallStatus
}
