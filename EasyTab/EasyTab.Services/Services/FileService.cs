using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
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
        private readonly _220030Context _context;
        private readonly ILogger<FileService> _logger;

        public FileService(IWebHostEnvironment env, IConfiguration config, _220030Context context, ILogger<FileService> logger)
        {
            _webRootPath = env.WebRootPath;
            _baseUrl = config["APP_BASE_URL"] ?? "http://localhost:5241";
            _context= context;
            _logger = logger;
        }

        public async Task<bool> DeleteFileAsync(string fileUrl, string subfolder, int? userId)
        {
            _logger.LogWarning("Deleting file. Subfolder: {Subfolder}, UserId: {UserId}", subfolder, userId);

            if (string.IsNullOrEmpty(fileUrl))
            {
                _logger.LogWarning("Delete file skipped because fileUrl is empty");
                return false;
            }

            var fileName = Path.GetFileName(fileUrl);
            var fullPath = Path.Combine(_webRootPath, subfolder, fileName);

            if (File.Exists(fullPath))
            {
                await Task.Run(() => File.Delete(fullPath));
                _logger.LogWarning("File deleted from disk. FileName: {FileName}", fileName);

                // Očisti iz baze ako je userId proslijeđen
                if (userId.HasValue)
                {
                    var user = await _context.Users.FindAsync(userId.Value);
                    if (user != null)
                    {
                        user.ProfilePicture = null;
                        await _context.SaveChangesAsync();
                        _logger.LogInformation("Profile picture reference removed for user. UserId: {UserId}", userId.Value);
                    }
                }

                return true;
            }

            _logger.LogWarning("Delete file skipped because file was not found. FileName: {FileName}", fileName);
            return false;
        }

        public async Task<string?> SaveFileAsync(IFormFile file, string subfolder)
        {
            if (file == null || file.Length == 0)
            {
                _logger.LogWarning("Save file skipped because uploaded file is empty");
                return null;
            }

            var extension = Path.GetExtension(file.FileName).ToLower();
            var allowed = new[] { ".jpg", ".jpeg", ".png" };
            if (!allowed.Contains(extension))
            {
                _logger.LogWarning("Save file skipped due to unsupported extension. Extension: {Extension}", extension);
                return null;
            }

            var uploadPath = Path.Combine(_webRootPath, subfolder);
            if (!Directory.Exists(uploadPath))
                Directory.CreateDirectory(uploadPath);

            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
                await file.CopyToAsync(stream);

            _logger.LogInformation("File saved. Subfolder: {Subfolder}, FileName: {FileName}", subfolder, fileName);
            return $"{_baseUrl}/{subfolder.Replace("\\", "/")}/{fileName}";
        }
    }
}
