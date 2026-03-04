using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class ReactionInsertRequest
    {
        public int ReviewId { get; set; }
        public int UserId { get; set; }
        public bool IsLike { get; set; }
    }
}
