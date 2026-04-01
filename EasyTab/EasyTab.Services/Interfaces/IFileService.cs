using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IFileService
    {
        Task<string?> SaveFileAsync(IFormFile file, string subfolder);
        Task<bool> DeleteFileAsync(string fileUrl, string subfolder, int? userId=null);
    }
}
