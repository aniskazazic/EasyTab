using System.Text.RegularExpressions;

namespace EasyTab.API.Helpers
{
    public class FileHelper
    {
        public static string GetImageByProduct(string path, IWebHostEnvironment env)
        {
            string imageUrl = string.Empty;
            string HostUrl = "https://localhost:7110";
            string filepath = GetFilePath(path, env);
            if (!System.IO.File.Exists(filepath))
            {
                imageUrl = HostUrl + "/Uploads/Images/" + "NoImage.png";
            }
            else
            {
                imageUrl = HostUrl + "/Uploads/Images/" + path;
            }

            return imageUrl;
        }

        public static string GetFilePath(string productCode, IWebHostEnvironment env, string putanja = "\\Uploads\\Images\\")
        {
            return env.WebRootPath + putanja + productCode;
        }
        public static string GetImageTypeFromBase64(string base64String)
        {
            // Regularni izraz za izdvajanje tipa slike iz Base64 stringa
            var regex = new Regex(@"^data:image/(?<type>[a-zA-Z]+);base64,", RegexOptions.Compiled);

            // Pokušajte pronaći podudaranje sa regularnim izrazom
            var match = regex.Match(base64String);

            // Ako postoji podudaranje, preuzmite vrednost grupe "type"
            if (match.Success)
            {
                return match.Groups["type"].Value.ToLower();
            }

            // Ako ne uspete pronaći tip slike, vratite null ili neki podrazumevani vrednost
            return "png";
        }
    }
}
