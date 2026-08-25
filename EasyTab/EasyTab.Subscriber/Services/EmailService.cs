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
            try
            {
                var host = _configuration["Email:Host"] ?? "smtp.gmail.com";
                var port = int.Parse(_configuration["Email:Port"] ?? "587");
                var username = _configuration["Email:Username"] ?? "";
                var password = _configuration["Email:Password"] ?? "";
                var fromName = _configuration["Email:FromName"] ?? "EasyTab";

                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(fromName, username));
                message.To.Add(new MailboxAddress(toName, toEmail));
                message.Subject = subject;

                var bodyBuilder = new BodyBuilder { HtmlBody = htmlBody };
                message.Body = bodyBuilder.ToMessageBody();

                using var client = new SmtpClient();
                await client.ConnectAsync(host, port, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(username, password);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);

                _logger.LogInformation("Email uspješno poslan na {Email}", toEmail);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Greška pri slanju emaila na {Email}", toEmail);
            }
        }
    }
}
