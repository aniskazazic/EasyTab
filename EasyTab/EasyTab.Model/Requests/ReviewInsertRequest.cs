using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class ReviewInsertRequest
    {
        public string Description { get; set; }
        public float Rating { get; set; }
        [JsonIgnore]
        public int UserId { get; set; }
        public int LocaleId { get; set; }
    }
}
