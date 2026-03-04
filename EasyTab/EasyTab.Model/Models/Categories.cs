using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Models
{
    public class Categories
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        //public virtual ICollection<Locale> Locales { get; set; } = new List<Locale>();
    }
}
