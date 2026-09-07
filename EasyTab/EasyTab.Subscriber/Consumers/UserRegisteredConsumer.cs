using EasyTab.Model.Messages;
using EasyTab.Subscriber.Services;

namespace EasyTab.Subscriber.Consumers
{
    public class UserRegisteredConsumer
    {
        private readonly EmailService _emailService;
        private readonly ILogger<UserRegisteredConsumer> _logger;

        public UserRegisteredConsumer(EmailService emailService, ILogger<UserRegisteredConsumer> logger)
        {
            _emailService = emailService;
            _logger = logger;
        }

        public async Task HandleAsync(UserRegisteredMessage message)
        {
            _logger.LogInformation("Processing UserRegisteredMessage for {Email}", message.Email);

            var subject = "Dobrodošli u EasyTab";
            var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 20px; color: #1e293b; }}
        .container {{ max-width: 580px; margin: 0 auto; background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 6px; overflow: hidden; }}
        .header {{ background-color: #1E40AF; padding: 20px 24px; }}
        .header h1 {{ margin: 0; color: #ffffff; font-size: 20px; font-weight: 600; }}
        .body {{ padding: 24px; }}
        .body h2 {{ margin: 0 0 12px 0; font-size: 17px; color: #0f172a; }}
        .body p {{ margin: 0 0 12px 0; font-size: 14px; line-height: 1.5; color: #334155; }}
        .info-box {{ background-color: #f1f5f9; border: 1px solid #e2e8f0; padding: 12px 16px; border-radius: 4px; margin: 16px 0; font-size: 14px; line-height: 1.6; }}
        .footer {{ background-color: #f8fafc; padding: 16px 24px; border-top: 1px solid #e2e8f0; font-size: 12px; color: #64748b; }}
        ul {{ margin: 8px 0; padding-left: 20px; font-size: 14px; color: #334155; line-height: 1.6; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>EasyTab</h1>
        </div>
        <div class='body'>
            <h2>Dobrodošli, {message.FullName}</h2>
            <p>Vaša registracija na EasyTab platformi je uspješno završena.</p>
            <div class='info-box'>
                <strong>Korisničko ime:</strong> {message.Username}<br>
                <strong>Email:</strong> {message.Email}
            </div>
            <p>Pomoću EasyTab aplikacije možete jednostavno:</p>
            <ul>
                <li>Pregledati dostupne restorane i kafiće</li>
                <li>Rezervisati stol u željenom terminu</li>
                <li>Pratiti status svojih rezervacija</li>
            </ul>
            <p style='margin-top: 20px;'>Srdačan pozdrav,<br>EasyTab tim</p>
        </div>
        <div class='footer'>
            © 2026 EasyTab. Sva prava zadržana.
        </div>
    </div>
</body>
</html>";

            await _emailService.SendAsync(message.Email, message.FullName, subject, body);
        }
    }
}
