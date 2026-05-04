using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services.Database;

public partial class _220030Context : DbContext
{
    private void CreateConfiguration(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Categori__3214EC07D81A11B5");

            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Cities__3214EC070B29E5C4");

            entity.Property(e => e.Name).HasMaxLength(100);

            entity.HasOne(d => d.Country).WithMany(p => p.Cities)
                .HasForeignKey(d => d.CountryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Cities__CountryI__3B75D760");
        });

        modelBuilder.Entity<Country>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Countrie__3214EC071B510B79");

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<Favourite>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Favourit__3214EC0732D7945E");

            entity.Property(e => e.DateAdded)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Locale).WithMany(p => p.Favourites)
                .HasForeignKey(d => d.LocaleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Favourite__Local__74AE54BC");

            entity.HasOne(d => d.User).WithMany(p => p.Favourites)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Favourite__UserI__75A278F5");
        });

        modelBuilder.Entity<Locale>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Locales__3214EC07B3B220E9");

            entity.Property(e => e.Address).HasMaxLength(255);
            entity.Property(e => e.DeletedAt).HasColumnType("datetime");
            entity.Property(e => e.Logo).HasMaxLength(255);
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.PhoneNumber).HasMaxLength(20);

            entity.HasOne(d => d.Category).WithMany(p => p.Locales)
                .HasForeignKey(d => d.CategoryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Locales__Categor__5535A963");

            entity.HasOne(d => d.City).WithMany(p => p.Locales)
                .HasForeignKey(d => d.CityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Locales__CityId__5441852A");

            entity.HasOne(d => d.Owner).WithMany(p => p.Locales)
                .HasForeignKey(d => d.OwnerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Locales__OwnerId__5629CD9C");
        });

        modelBuilder.Entity<LocaleImage>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__LocaleIm__3214EC0720D3ED62");

            entity.Property(e => e.FileName).HasMaxLength(100);
            entity.Property(e => e.ContentType).HasMaxLength(100);
            entity.Property(e => e.Base64Content).IsRequired();
            entity.Property(e => e.CreatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Locale).WithMany(p => p.LocaleImages)
                .HasForeignKey(d => d.LocaleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__LocaleIma__Local__787EE5A0");
        });

        modelBuilder.Entity<Reaction>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Reaction__3214EC073F1AB34B");

            entity.HasOne(d => d.Review).WithMany(p => p.Reactions)
                .HasForeignKey(d => d.ReviewId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reactions__Revie__6E01572D");

            entity.HasOne(d => d.User).WithMany(p => p.Reactions)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reactions__UserI__6EF57B66");
        });

        modelBuilder.Entity<Reservation>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Reservat__3214EC07938B47B8");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ReservationDate).HasColumnType("datetime");

            entity.HasOne(d => d.Table).WithMany(p => p.Reservations)
                .HasForeignKey(d => d.TableId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reservati__Table__656C112C");

            entity.HasOne(d => d.User).WithMany(p => p.Reservations)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reservati__UserI__6477ECF3");
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Reviews__3214EC07EE2BA60A");

            entity.Property(e => e.DateAdded)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DeletedAt).HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(500);

            entity.HasOne(d => d.Locale).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.LocaleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reviews__LocaleI__6B24EA82");

            entity.HasOne(d => d.User).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reviews__UserId__6A30C649");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Roles__3214EC07D3F60231");

            entity.Property(e => e.DeletedAt).HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<Table>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Tables__3214EC07285A725C");

            entity.Property(e => e.Name).HasMaxLength(50);
            entity.Property(e => e.Xcoordinate).HasColumnName("XCoordinate");
            entity.Property(e => e.Ycoordinate).HasColumnName("YCoordinate");

            entity.HasOne(d => d.Locale).WithMany(p => p.Tables)
                .HasForeignKey(d => d.LocaleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Tables__LocaleId__5CD6CB2B");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Users__3214EC07B093556C");

            entity.Property(e => e.BirthDate).HasColumnType("datetime");
            entity.Property(e => e.DeletedAt).HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.FirstName).HasMaxLength(50);
            entity.Property(e => e.LastName).HasMaxLength(50);
            entity.Property(e => e.PasswordHash).HasMaxLength(255);
            entity.Property(e => e.PasswordSalt).HasMaxLength(255);
            entity.Property(e => e.PhoneNumber).HasMaxLength(20);
            entity.Property(e => e.ProfilePicture).HasMaxLength(255);
            entity.Property(e => e.Username).HasMaxLength(50);
        });

        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__UserRole__3214EC074D5F43C8");

            entity.Property(e => e.DeletedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Role).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__UserRoles__RoleI__45F365D3");

            entity.HasOne(d => d.User).WithMany(p => p.UserRoles)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__UserRoles__UserI__44FF419A");
        });

        modelBuilder.Entity<Worker>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Workers__3214EC07C018FE00");

            entity.Property(e => e.EndDate).HasColumnType("datetime");
            entity.Property(e => e.HireDate).HasColumnType("datetime");

            entity.HasOne(d => d.Locale).WithMany(p => p.Workers)
                .HasForeignKey(d => d.LocaleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Workers__LocaleI__59FA5E80");

            entity.HasOne(d => d.User).WithMany(p => p.Workers)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Workers__UserId__59063A47");
        });

        modelBuilder.Entity<Zone>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__Zones__3214EC07EDBBD183");

            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.Xcoordinate).HasColumnName("XCoordinate");
            entity.Property(e => e.Ycoordinate).HasColumnName("YCoordinate");

            entity.HasOne(d => d.Locale).WithMany(p => p.Zones)
                .HasForeignKey(d => d.LocaleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Zones__LocaleId__5FB337D6");
        });

        modelBuilder.Entity<UserRole>()
       .HasOne(ur => ur.User)
       .WithMany(u => u.UserRoles)
       .HasForeignKey(ur => ur.UserId)
       .OnDelete(DeleteBehavior.Cascade);

        // Role -> UserRoles
        modelBuilder.Entity<UserRole>()
            .HasOne(ur => ur.Role)
            .WithMany(r => r.UserRoles)
            .HasForeignKey(ur => ur.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<LocaleImage>()
            .HasOne(a => a.Locale)
           .WithMany(p => p.LocaleImages)
           .HasForeignKey(a => a.LocaleId)
           .OnDelete(DeleteBehavior.Cascade);

        //// User -> Worker (ako treba)
        //modelBuilder.Entity<Worker>()
        //    .HasOne(w => w.User)
        //    .WithMany(u => u.Workers)
        //    .HasForeignKey(w => w.UserId)
        //    .OnDelete(DeleteBehavior.Cascade);

        //// User -> Locale (Owner)
        //modelBuilder.Entity<Locale>()
        //    .HasOne(l => l.Owner)
        //    .WithMany(u => u.Locales)
        //    .HasForeignKey(l => l.OwnerId)
        //    .OnDelete(DeleteBehavior.Cascade);
    }
}
