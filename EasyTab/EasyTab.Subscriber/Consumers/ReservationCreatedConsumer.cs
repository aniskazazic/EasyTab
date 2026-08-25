using EasyTab.Model.Messages;
using EasyTab.Subscriber.Services;

namespace EasyTab.Subscriber.Consumers
{
    public class ReservationCreatedConsumer
    {
        private readonly EmailService _emailService;
        private readonly ILogger<ReservationCreatedConsumer> _logger;

        public ReservationCreatedConsumer(EmailService emailService, ILogger<ReservationCreatedConsumer> logger)
        {
            _emailService = emailService;
            _logger = logger;
        }

        public async Task HandleAsync(ReservationCreatedMessage message)
        {
            _logger.LogInformation("Processing ReservationCreatedMessage for ReservationId: {Id}", message.ReservationId);

            var subject = "✅ Rezervacija uspješno kreirana — EasyTab";
            var formattedDate = message.ReservationDate.ToString("dd.MM.yyyy");

            var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 40px 30px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 28px; }}
        .header .icon {{ font-size: 48px; margin-bottom: 10px; }}
        .body {{ padding: 35px 30px; }}
        .body h2 {{ color: #333; margin-top: 0; }}
        .body p {{ color: #555; line-height: 1.7; font-size: 15px; }}
        .reservation-card {{ background: #f0fff4; border: 2px solid #38ef7d; border-radius: 10px; padding: 20px; margin: 20px 0; }}
        .reservation-card .row {{ display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #e0f7e9; }}
        .reservation-card .row:last-child {{ border-bottom: none; }}
        .reservation-card .label {{ color: #555; font-size: 14px; }}
        .reservation-card .value {{ color: #222; font-weight: bold; font-size: 14px; }}
        .footer {{ background: #f9f9f9; padding: 20px 30px; text-align: center; color: #999; font-size: 13px; border-top: 1px solid #eee; }}
        .status {{ display: inline-block; background: #38ef7d; color: #1a5c32; padding: 6px 16px; border-radius: 20px; font-weight: bold; font-size: 13px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <div class='icon'>✅</div>
            <h1>Rezervacija kreirana!</h1>
        </div>
        <div class='body'>
            <h2>Zdravo, {message.UserFullName}! 👋</h2>
            <p>Vaša rezervacija je <span class='status'>Na čekanju</span> i bit će potvrđena od strane lokala.</p>
            <div class='reservation-card'>
                <div class='row'>
                    <span class='label'>🏠 Lokal</span>
                    <span class='value'>{message.LocaleName}</span>
                </div>
                <div class='row'>
                    <span class='label'>📅 Datum</span>
                    <span class='value'>{formattedDate}</span>
                </div>
                <div class='row'>
                    <span class='label'>⏰ Termin</span>
                    <span class='value'>{message.StartTime} — {message.EndTime}</span>
                </div>
                <div class='row'>
                    <span class='label'>👥 Broj gostiju</span>
                    <span class='value'>{message.NumberOfGuests}</span>
                </div>
                <div class='row'>
                    <span class='label'>🔖 ID rezervacije</span>
                    <span class='value'>#{message.ReservationId}</span>
                </div>
            </div>
            <p>Pratite status vaše rezervacije u EasyTab aplikaciji. Dobit ćete obavijest kada lokal potvrdi vašu rezervaciju.</p>
            <p style='color: #333; font-weight: bold;'>Hvala što koristite EasyTab!<br>EasyTab tim 🍽️</p>
        </div>
        <div class='footer'>
            © 2025 EasyTab · Sva prava zadržana
        </div>
    </div>
</body>
</html>";

            await _emailService.SendAsync(message.UserEmail, message.UserFullName, subject, body);
        }
    }
}
