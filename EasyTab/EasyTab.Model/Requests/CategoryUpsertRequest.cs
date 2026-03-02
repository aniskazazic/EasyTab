using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Requests
{
    public class CategoryUpsertRequest
    {
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
    }
}
