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

            var subject = "Dobrodošli u EasyTab! 🍽️";
            var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 30px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 28px; letter-spacing: 1px; }}
        .header p {{ margin: 8px 0 0; opacity: 0.9; font-size: 16px; }}
        .body {{ padding: 35px 30px; }}
        .body h2 {{ color: #333; margin-top: 0; }}
        .body p {{ color: #555; line-height: 1.7; font-size: 15px; }}
        .highlight {{ background: #f0f0ff; border-left: 4px solid #667eea; padding: 12px 16px; border-radius: 0 8px 8px 0; margin: 20px 0; }}
        .highlight strong {{ color: #667eea; }}
        .footer {{ background: #f9f9f9; padding: 20px 30px; text-align: center; color: #999; font-size: 13px; border-top: 1px solid #eee; }}
        .btn {{ display: inline-block; background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 13px 30px; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🍽️ EasyTab</h1>
            <p>Vaš novi način rezervacije</p>
        </div>
        <div class='body'>
            <h2>Dobrodošli, {message.FullName}! 👋</h2>
            <p>Vaša registracija je uspješno završena. Sada možete uživati u svim pogodnostima EasyTab platforme.</p>
            <div class='highlight'>
                <strong>Vaše korisničko ime:</strong> {message.Username}<br>
                <strong>Email adresa:</strong> {message.Email}
            </div>
            <p>Putem EasyTab aplikacije možete:</p>
            <ul style='color: #555; line-height: 2;'>
                <li>🔍 Pregledavati i pretraživati restorane i kafiće</li>
                <li>📅 Rezervisati stolove u nekoliko klikova</li>
                <li>⭐ Ostavljati recenzije i ocjene lokala</li>
                <li>❤️ Čuvati favorite lokale</li>
            </ul>
            <p>Ukoliko imate pitanja, slobodno nas kontaktirajte.</p>
            <p style='color: #333; font-weight: bold;'>Srdačan pozdrav,<br>EasyTab tim 🍽️</p>
        </div>
        <div class='footer'>
            © 2026 EasyTab
        </div>
    </div>
</body>
</html>";

            await _emailService.SendAsync(message.Email, message.FullName, subject, body);
        }
    }
}
