using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class LocaleImages
    {
        public int Id { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string ContentType { get; set; } = string.Empty;
        public string Base64Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public int LocaleId { get; set; }
    }
}
