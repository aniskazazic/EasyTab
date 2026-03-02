using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model
{
    public class Cities
    {
        public int Id { get; set; }

        public string Name { get; set; } = null!;

        public int CountryId { get; set; }
    }
}
