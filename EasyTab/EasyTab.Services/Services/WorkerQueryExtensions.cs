using EasyTab.Services.Database;

namespace EasyTab.Services.Services;

internal static class WorkerQueryExtensions
{
    // Aktivni angažman: uklonjeni radnik (soft delete) se ne računa kao radnik lokala.
    public static IQueryable<Worker> Active(this IQueryable<Worker> workers)
        => workers.Where(worker => !worker.IsDeleted);
}
