using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services.Database;

public partial class _220030Context : DbContext
{
    public _220030Context()
    {
    }

    public _220030Context(DbContextOptions<_220030Context> options)
        : base(options)
    {
    }

    public virtual DbSet<Category> Categories { get; set; }

    public virtual DbSet<City> Cities { get; set; }

    public virtual DbSet<Country> Countries { get; set; }

    public virtual DbSet<Favourite> Favourites { get; set; }

    public virtual DbSet<Locale> Locales { get; set; }

    public virtual DbSet<LocaleImage> LocaleImages { get; set; }

    public virtual DbSet<Reaction> Reactions { get; set; }

    public virtual DbSet<Reservation> Reservations { get; set; }

    public virtual DbSet<Review> Reviews { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<Table> Tables { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserRole> UserRoles { get; set; }

    public virtual DbSet<Worker> Workers { get; set; }

    public virtual DbSet<Zone> Zones { get; set; }

    public virtual DbSet<RefreshToken> RefreshTokens { get; set; }

//    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
//#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
//        => optionsBuilder.UseSqlServer("Data Source=localhost;Initial Catalog=220030;Integrated Security=True;TrustServerCertificate=True");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {

        base.OnModelCreating(modelBuilder);

        CreateConfiguration(modelBuilder);

        //OnModelCreatingPartial(modelBuilder);
    }

    //partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
