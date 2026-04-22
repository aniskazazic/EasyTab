using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Exceptions
{
    public class UserException : Exception
    {
        public UserException(string message) : base(message)
        {

        }

        public UserException(string message, Exception inner) : base(message, inner) { }
    }
}
