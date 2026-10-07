using System;
using System.Collections.Generic;

namespace EasyTab.Model.Responses;

public sealed class OwnerLocaleResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string Address { get; set; } = null!;
    public TimeOnly StartOfWorkingHours { get; set; }
    public TimeOnly EndOfWorkingHours { get; set; }
    public double LengthOfReservation { get; set; }
    public string? Logo { get; set; }
    public int CityId { get; set; }
    public int CategoryId { get; set; }
    public int OwnerId { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
    public string? PhoneNumber { get; set; }
}

public sealed class TableDistributionResponse
{
    public int Seats { get; set; }
    public int Count { get; set; }
    public double Percentage { get; set; }
}

public sealed class OwnerReservationsPageResponse
{
    public List<OwnerReservationListItemResponse> Items { get; set; } = new();
    public int TotalCount { get; set; }
}

public sealed class OwnerReservationListItemResponse
{
    public int Id { get; set; }
    public string FirstName { get; set; } = null!;
    public string LastName { get; set; } = null!;
    public DateTime ReservationDate { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public int NumberOfGuests { get; set; }
    public string TableName { get; set; } = null!;
    public bool IsCancelled { get; set; }
}
