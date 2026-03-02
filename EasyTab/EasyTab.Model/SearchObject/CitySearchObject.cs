using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.SearchObject
{
    public class CitySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CountryId { get; set; }
    }
}
