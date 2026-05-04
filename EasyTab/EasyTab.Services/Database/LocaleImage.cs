using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EasyTab.Services.Database;

public partial class LocaleImage
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string FileName { get; set; } = string.Empty;

    [Required]
    public string ContentType { get; set; } = string.Empty;

    [Required]
    public string Base64Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public int LocaleId { get; set; }

    [ForeignKey("LocaleId")]
    public virtual Locale Locale { get; set; } = null!;
}
