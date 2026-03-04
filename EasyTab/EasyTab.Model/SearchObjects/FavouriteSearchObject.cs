using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.SearchObjects
{
    public class FavouriteSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? LocaleId { get; set; }
    }
}
