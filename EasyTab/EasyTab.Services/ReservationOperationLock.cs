using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services;

internal static class ReservationOperationLock
{
    // All reservation writes acquire Locale -> Tables (ascending Id) -> Reservation.
    // Locks belong to the caller's transaction and are also respected by checkout.
    public static async Task<Locale> LocaleAsync(_220030Context context, int localeId)
    {
        if (context.Database.CurrentTransaction == null)
            throw new InvalidOperationException("Zaključavanje lokala zahtijeva transakciju.");

        return await context.Locales
            .FromSqlInterpolated($"SELECT * FROM [Locales] WITH (UPDLOCK, HOLDLOCK) WHERE [Id] = {localeId}")
            .AsNoTracking().SingleOrDefaultAsync(CancellationToken.None)
            ?? throw new NotFoundException("Lokal nije pronađen.");
    }

    public static async Task<Table> TableAsync(_220030Context context, int tableId)
    {
        var localeId = await context.Tables.AsNoTracking()
            .Where(table => table.Id == tableId).Select(table => (int?)table.LocaleId)
            .SingleOrDefaultAsync(CancellationToken.None)
            ?? throw new NotFoundException("Stol nije pronađen.");
        await LocaleAsync(context, localeId);
        return await context.Tables
            .FromSqlInterpolated($"SELECT * FROM [Tables] WITH (UPDLOCK, HOLDLOCK) WHERE [Id] = {tableId}")
            .AsNoTracking().SingleAsync(CancellationToken.None);
    }

    public static async Task LockTablesAsync(_220030Context context, int localeId)
    {
        // Locale must already be locked, including when it has no tables.
        await context.Tables
            .FromSqlInterpolated($"SELECT * FROM [Tables] WITH (UPDLOCK, HOLDLOCK) WHERE [LocaleId] = {localeId}")
            .AsNoTracking().OrderBy(table => table.Id).ToListAsync(CancellationToken.None);
    }

    public static async Task<Reservation> ReservationAsync(_220030Context context, int id)
    {
        var tableId = await context.Reservations.AsNoTracking()
            .Where(reservation => reservation.Id == id).Select(reservation => (int?)reservation.TableId)
            .SingleOrDefaultAsync(CancellationToken.None)
            ?? throw new NotFoundException("Rezervacija nije pronađena.");
        await TableAsync(context, tableId);
        var entity = await context.Reservations
            .FromSqlInterpolated($"SELECT * FROM [Reservations] WITH (UPDLOCK, HOLDLOCK) WHERE [Id] = {id}")
            .SingleAsync(CancellationToken.None);
        // A service may already have loaded this entity before waiting for the lock.
        await context.Entry(entity).ReloadAsync(CancellationToken.None);
        return entity;
    }
}
