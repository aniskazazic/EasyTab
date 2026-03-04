using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.SearchObject
{
    public class WorkerSearchObject : BaseSearchObject
    {
        public int? LocaleId { get; set; }
        public string? Q { get; set; }
    }
}
