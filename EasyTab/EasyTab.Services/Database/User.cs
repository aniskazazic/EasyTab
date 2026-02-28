using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class User
{
    public int Id { get; set; }

    public string Username { get; set; } = null!;

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public string PasswordSalt { get; set; } = null!;

    public string? PhoneNumber { get; set; }

    public DateTime? BirthDate { get; set; }

    public string? ProfilePicture { get; set; }

    public DateTime? DeletedAt { get; set; }

    public bool IsDeleted { get; set; }

    public virtual ICollection<Favourite> Favourites { get; set; } = new List<Favourite>();

    public virtual ICollection<Locale> Locales { get; set; } = new List<Locale>();

    public virtual ICollection<Reaction> Reactions { get; set; } = new List<Reaction>();

    public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

    public virtual ICollection<Worker> Workers { get; set; } = new List<Worker>();
}
