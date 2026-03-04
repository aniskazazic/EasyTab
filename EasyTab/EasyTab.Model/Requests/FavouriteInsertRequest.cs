using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class FavouriteInsertRequest
    {
        public int UserId { get; set; }
        public int LocaleId { get; set; }
    }
}
