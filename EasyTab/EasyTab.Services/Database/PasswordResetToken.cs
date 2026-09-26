using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EasyTab.Services.Database
{
    public class PasswordResetToken
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        [Required]
        [MaxLength(255)]
        public string CodeHash { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string CodeSalt { get; set; } = string.Empty;

        public DateTime ExpiryTime { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
