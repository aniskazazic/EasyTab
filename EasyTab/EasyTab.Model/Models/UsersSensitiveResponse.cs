using EasyTab.Model.Access;
using System;
using System.Collections.Generic;
using System.Text;
using static System.Collections.Specialized.BitVector32;

namespace EasyTab.Model.Models
{
    public partial class UsersSensitiveResponse : Users
    {
        public string PasswordHash { get; set; } = string.Empty;
        public string PasswordSalt { get; set; } = string.Empty;

    }
}
