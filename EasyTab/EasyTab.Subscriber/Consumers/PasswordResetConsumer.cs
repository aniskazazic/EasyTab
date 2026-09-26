using EasyTab.Model.Messages;
using EasyTab.Subscriber.Services;

namespace EasyTab.Subscriber.Consumers
{
    public class PasswordResetConsumer
    {
        private readonly EmailService _emailService;
        private readonly ILogger<PasswordResetConsumer> _logger;

        public PasswordResetConsumer(EmailService emailService, ILogger<PasswordResetConsumer> logger)
        {
            _emailService = emailService;
            _logger = logger;
        }

        public async Task HandleAsync(PasswordResetMessage message)
        {
            _logger.LogInformation("Processing PasswordResetMessage for {Email}", message.Email);

            var subject = "EasyTab - Zahtjev za oporavak lozinke";
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
        .code-box {{ background-color: #eff6ff; border: 1px solid #bfdbfe; padding: 18px; border-radius: 6px; margin: 20px 0; text-align: center; }}
        .code {{ font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #1e40af; font-family: monospace; }}
        .warning {{ font-size: 13px; color: #64748b; margin-top: 8px; }}
        .footer {{ background-color: #f8fafc; padding: 16px 24px; border-top: 1px solid #e2e8f0; font-size: 12px; color: #64748b; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>EasyTab</h1>
        </div>
        <div class='body'>
            <h2>Oporavak lozinke</h2>
            <p>Pozdrav {message.FullName},</p>
            <p>Primili smo zahtjev za poništavanje lozinke za Vaš EasyTab nalog. Vaš jednokratni verifikacijski kod je:</p>
            <div class='code-box'>
                <div class='code'>{message.Code}</div>
                <div class='warning'>Kod vrijedi narednih 15 minuta.</div>
            </div>
            <p>Unesite ovaj kod u mobilnoj aplikaciji zajedno sa novom lozinkom.</p>
            <p style='color: #64748b; font-size: 13px;'>Ako niste Vi zatražili poništavanje lozinke, možete slobodno ignorisati ovu poruku. Vaša trenutna lozinka ostaje sigurna.</p>
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
