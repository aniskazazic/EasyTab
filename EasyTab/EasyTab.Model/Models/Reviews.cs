using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class Reviews
    {
        public int Id { get; set; }
        public string Description { get; set; }
        public float Rating { get; set; }
        public int UserId { get; set; }
        public string? UserFullName { get; set; }
        public int LocaleId { get; set; }
        public string? LocaleName { get; set; }
        public DateTime DateAdded { get; set; }
        public bool IsDeleted { get; set; }
        public int Likes { get; set; }
        public int Dislikes { get; set; }
    }
}
