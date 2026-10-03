using System;

namespace EasyTab.Model.Exceptions
{
    public class InvalidRefreshTokenException : Exception
    {
        public InvalidRefreshTokenException(string message) : base(message)
        {
        }
    }
}
