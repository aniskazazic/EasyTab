using System.Collections.Concurrent;
using System.Threading;

namespace EasyTab.Services.Services
{
    public sealed class LookupCacheVersionService
    {
        private readonly ConcurrentDictionary<string, long> _versions = new();

        public long GetVersion(string group)
        {
            return _versions.GetOrAdd(group, 0);
        }

        public void Invalidate(string group)
        {
            _versions.AddOrUpdate(group, 1, (_, version) => Interlocked.Increment(ref version));
        }
    }
}
