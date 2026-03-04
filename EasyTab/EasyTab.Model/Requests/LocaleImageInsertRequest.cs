using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class LocaleImageInsertRequest
    {
        public int LocaleId { get; set; }
        public string ImageBase64 { get; set; }
    }
}
