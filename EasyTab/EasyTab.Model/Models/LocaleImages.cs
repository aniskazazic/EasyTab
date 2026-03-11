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
        public int LocaleId { get; set; }
        public string? ImageUrl { get; set; }
        public string? ImageBase64 { get; set; }
        public string? ContentType { get; set; }
    }
}
