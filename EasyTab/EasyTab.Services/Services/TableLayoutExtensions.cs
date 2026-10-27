using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;

namespace EasyTab.Services.Services;

internal static class TableLayoutExtensions
{
    // Negative coordinates reserve a removed table without changing the database schema or its history.
    private const double RemovedCoordinate = -1;

    public static IQueryable<Table> OnLayout(this IQueryable<Table> tables)
        => tables.Where(table => table.Xcoordinate >= 0 && table.Ycoordinate >= 0);

    public static bool IsRemoved(this Table table)
        => table.Xcoordinate < 0 || table.Ycoordinate < 0;

    public static void RemoveFromLayout(this Table table)
    {
        table.Xcoordinate = RemovedCoordinate;
        table.Ycoordinate = RemovedCoordinate;
    }

    public static void ValidatePosition(double? x, double? y)
    {
        if ((x.HasValue && (!double.IsFinite(x.Value) || x.Value < 0)) ||
            (y.HasValue && (!double.IsFinite(y.Value) || y.Value < 0)))
            throw new UserException("Koordinate stola moraju biti nenegativni konačni brojevi.");
    }
}
