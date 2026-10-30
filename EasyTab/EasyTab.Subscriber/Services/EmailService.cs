using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace EasyTab.Subscriber.Services
{
    public class EmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendAsync(string toEmail, string toName, string subject, string htmlBody)
        {
            for (var attempt = 0; attempt < 5; attempt++)
            {
                try
                {
                    var host = RequireSetting("Email:Host");
                    var port = int.Parse(RequireSetting("Email:Port"));
                    var username = RequireSetting("Email:Username");
                    var password = RequireSetting("Email:Password");
                    var fromName = RequireSetting("Email:FromName");
                    var fromAddress = _configuration["Email:FromAddress"];
                    if (string.IsNullOrWhiteSpace(fromAddress))
                        fromAddress = username;
                    var secureSocketOptions = GetSecureSocketOptions();

                    var message = new MimeMessage();
                    message.From.Add(new MailboxAddress(fromName, fromAddress));
                    message.To.Add(new MailboxAddress(toName, toEmail));
                    message.Subject = subject;
                    message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();

                    using var client = new SmtpClient();
                    await client.ConnectAsync(host, port, secureSocketOptions);
                    await client.AuthenticateAsync(username, password);
                    await client.SendAsync(message);
                    await client.DisconnectAsync(true);

                    _logger.LogInformation("Email uspješno poslan na {Email}", toEmail);
                    return;
                }
                catch (Exception ex) when (attempt < 4)
                {
                    var delaySeconds = 1 << attempt;
                    _logger.LogWarning(
                        ex,
                        "Greška pri slanju emaila na {Email}. Ponovni pokušaj za {DelaySeconds}s (pokušaj {Attempt}/5)",
                        toEmail,
                        delaySeconds,
                        attempt + 1);
                    await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri slanju emaila na {Email} nakon 5 pokušaja", toEmail);
                }
            }
        }

        private SecureSocketOptions GetSecureSocketOptions() =>
            _configuration["Email:SecureSocketOptions"]?.Trim().ToLowerInvariant() switch
            {
                null or "" or "starttls" => SecureSocketOptions.StartTls,
                "sslonconnect" => SecureSocketOptions.SslOnConnect,
                "auto" => SecureSocketOptions.Auto,
                "none" => SecureSocketOptions.None,
                _ => throw new InvalidOperationException(
                    "Email:SecureSocketOptions mora biti StartTls, SslOnConnect, Auto ili None.")
            };

        private string RequireSetting(string key)
        {
            var value = _configuration[key];
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidOperationException($"Missing required configuration value '{key}'.");

            return value;
        }
    }
}
