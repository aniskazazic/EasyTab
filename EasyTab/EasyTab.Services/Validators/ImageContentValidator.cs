using FluentValidation;
using FluentValidation.Results;
using System;

namespace EasyTab.Services.Validators
{
    public static class ImageContentValidator
    {
        public const int MaximumImageSizeInBytes = 300 * 1024;
        public const string ErrorMessage = "Slika mora biti JPG, JPEG ili PNG i manja od 300 KB.";

        public static bool IsAllowedFileName(string? fileName)
        {
            var extension = System.IO.Path.GetExtension(fileName)?.ToLowerInvariant();
            return extension is ".jpg" or ".jpeg" or ".png";
        }

        public static bool IsAllowedContentType(string? contentType) =>
            contentType?.Trim().ToLowerInvariant() is "image/jpeg" or "image/jpg" or "image/png";

        public static bool IsValidImageUpload(string? base64Content, string? fileName, string? contentType)
        {
            if (!IsAllowedFileName(fileName) || !IsValidImage(base64Content, contentType, true))
                return false;

            var isPng = string.Equals(System.IO.Path.GetExtension(fileName), ".png", StringComparison.OrdinalIgnoreCase);
            return isPng == string.Equals(contentType?.Trim(), "image/png", StringComparison.OrdinalIgnoreCase);
        }

        public static void ValidateOptionalImage(string? base64Content, string propertyName)
        {
            if (string.IsNullOrWhiteSpace(base64Content))
                return;

            ValidateImage(base64Content, null, propertyName);
        }

        public static void ValidateRequiredImage(
            string? base64Content,
            string? contentType,
            string propertyName,
            string? fileName)
        {
            if (!IsValidImageUpload(base64Content, fileName, contentType))
                throw new ValidationException(new[] { new ValidationFailure(propertyName, ErrorMessage) });
        }

        private static void ValidateImage(
            string? base64Content,
            string? contentType,
            string propertyName,
            bool requireContentType = false)
        {
            if (!IsValidImage(base64Content, contentType, requireContentType))
            {
                throw new ValidationException(new[]
                {
                    new ValidationFailure(propertyName, ErrorMessage)
                });
            }
        }

        private static bool IsValidImage(
            string? base64Content,
            string? contentType,
            bool requireContentType)
        {
            if (string.IsNullOrWhiteSpace(base64Content))
                return false;

            var maximumBase64Length = ((MaximumImageSizeInBytes + 2) / 3) * 4;
            if (base64Content.Length > maximumBase64Length)
                return false;

            byte[] imageBytes;
            try
            {
                imageBytes = Convert.FromBase64String(base64Content);
            }
            catch (FormatException)
            {
                return false;
            }

            if (imageBytes.Length == 0 || imageBytes.Length >= MaximumImageSizeInBytes)
                return false;

            var isJpeg = imageBytes.Length >= 3 &&
                imageBytes[0] == 0xFF &&
                imageBytes[1] == 0xD8 &&
                imageBytes[2] == 0xFF;
            var isPng = imageBytes.Length >= 4 &&
                imageBytes[0] == 0x89 &&
                imageBytes[1] == 0x50 &&
                imageBytes[2] == 0x4E &&
                imageBytes[3] == 0x47;

            if (!isJpeg && !isPng)
                return false;

            if (!requireContentType && contentType == null)
                return true;

            if (string.IsNullOrWhiteSpace(contentType))
                return false;

            var suppliedContentType = contentType.Trim();
            return isJpeg
                ? string.Equals(suppliedContentType, "image/jpeg", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(suppliedContentType, "image/jpg", StringComparison.OrdinalIgnoreCase)
                : string.Equals(suppliedContentType, "image/png", StringComparison.OrdinalIgnoreCase);
        }
    }
}
