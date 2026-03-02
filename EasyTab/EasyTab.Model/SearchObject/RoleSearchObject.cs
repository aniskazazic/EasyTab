using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.SearchObject
{
    public class RoleSearchObject : BaseSearchObject
    {
        public string? NameGTE { get; set; }
        public bool? IsDeleted { get; set; }

    }
}
