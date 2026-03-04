using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.SearchObjects
{
    public class ReactionSearchObject : BaseSearchObject
    {
        public int? ReviewId { get; set; }
        public int? UserId { get; set; }
    }
}
