using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class Reactions
    {
        public int Id { get; set; }
        public int ReviewId { get; set; }
        public int UserId { get; set; }
        public bool IsLike { get; set; }
    }
    public class ReactionsCount
    {
        public int Likes { get; set; }
        public int Dislikes { get; set; }
    }

}
