using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class FileService : IFileService
    {
        private readonly string _baseUrl;
        private readonly string _webRootPath;

        public FileService(IWebHostEnvironment env, IConfiguration config)
        {
            _webRootPath = env.WebRootPath;
            _baseUrl = config["APP_BASE_URL"] ?? "http://localhost:5241";
        }

        public async Task<bool> DeleteFileAsync(string fileUrl, string subfolder)
        {
            if (string.IsNullOrEmpty(fileUrl))
                return false;

            var fileName = Path.GetFileName(fileUrl);
            var fullPath = Path.Combine(_webRootPath, subfolder, fileName);

            if (File.Exists(fullPath))
            {
                await Task.Run(() => File.Delete(fullPath));
                return true;
            }

            return false;
        }

        public async Task<string?> SaveFileAsync(IFormFile file, string subfolder)
        {
            if (file == null || file.Length == 0)
                return null;

            var extension = Path.GetExtension(file.FileName).ToLower();
            var allowed = new[] { ".jpg", ".jpeg", ".png" };
            if (!allowed.Contains(extension))
                return null;

            var uploadPath = Path.Combine(_webRootPath, subfolder);
            if (!Directory.Exists(uploadPath))
                Directory.CreateDirectory(uploadPath);

            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
                await file.CopyToAsync(stream);

            return $"{_baseUrl}/{subfolder.Replace("\\", "/")}/{fileName}";
        }
    }
}
