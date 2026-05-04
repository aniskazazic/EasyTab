using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.SearchObject
{
    public class LocaleImageSearchObject : BaseSearchObject
    {
        public string? FileName { get; set; }
        public string? ContentType { get; set; }
        public int? LocaleId { get; set; }
    }
}
