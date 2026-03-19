using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class FileController : ControllerBase
    {
        private readonly IFileService _fileService;

        public FileController(IFileService fileService)
        {
            _fileService = fileService;
        }

        [HttpPost]
        public async Task<IActionResult> UploadFile(
            IFormFile file,
            [FromQuery] string subfolder = "ImageFolder/Misc")
        {
            if (file == null)
                return BadRequest("File je obavezan.");

            var url = await _fileService.SaveFileAsync(file, subfolder);

            if (url == null)
                return BadRequest("Neispravan file ili format. Dozvoljeni formati: jpg, jpeg, png.");

            return Ok(new { fileUrl = url });
        }

        [HttpDelete("delete")]
        public async Task<IActionResult> DeleteFile(
            [FromQuery] string fileUrl,
            [FromQuery] string subfolder)
        {
            var success = await _fileService.DeleteFileAsync(fileUrl, subfolder);
            if (!success)
                return NotFound("File nije pronađen.");

            return Ok("File uspješno obrisan.");
        }
    }
}
