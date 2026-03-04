using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? LocaleId { get; set; }
        public bool? IsDeleted { get; set; }
        public string? SortBy { get; set; }
    }
}
