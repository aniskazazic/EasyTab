using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model
{
    public class UserException : Exception
    {
        public UserException(string messaage) : base(messaage) { }
    }
}
