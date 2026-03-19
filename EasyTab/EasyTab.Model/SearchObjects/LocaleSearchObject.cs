using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.SearchObject
{
    public class LocaleSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CityId { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsDeleted { get; set; }
        public int? CountryId {  get; set; }
        public int? OwnerId { get; set; }
    }
}
