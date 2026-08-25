using EasyTab.Model.Messages;
using EasyTab.Subscriber.Services;

namespace EasyTab.Subscriber.Consumers
{
    public class ReservationCancelledConsumer
    {
        private readonly EmailService _emailService;
        private readonly ILogger<ReservationCancelledConsumer> _logger;

        public ReservationCancelledConsumer(EmailService emailService, ILogger<ReservationCancelledConsumer> logger)
        {
            _emailService = emailService;
            _logger = logger;
        }

        public async Task HandleAsync(ReservationCancelledMessage message)
        {
            _logger.LogInformation("Processing ReservationCancelledMessage for ReservationId: {Id}", message.ReservationId);

            var subject = "❌ Vaša rezervacija je otkazana — EasyTab";
            var formattedDate = message.ReservationDate.ToString("dd.MM.yyyy");

            var body = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 40px 30px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 28px; }}
        .header .icon {{ font-size: 48px; margin-bottom: 10px; }}
        .body {{ padding: 35px 30px; }}
        .body h2 {{ color: #333; margin-top: 0; }}
        .body p {{ color: #555; line-height: 1.7; font-size: 15px; }}
        .reservation-card {{ background: #fff5f5; border: 2px solid #f5576c; border-radius: 10px; padding: 20px; margin: 20px 0; }}
        .reservation-card .row {{ display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #ffe0e0; }}
        .reservation-card .row:last-child {{ border-bottom: none; }}
        .reservation-card .label {{ color: #555; font-size: 14px; }}
        .reservation-card .value {{ color: #222; font-weight: bold; font-size: 14px; }}
        .reason-box {{ background: #fff0f0; border-left: 4px solid #f5576c; padding: 14px 16px; border-radius: 0 8px 8px 0; margin: 20px 0; }}
        .reason-box .label {{ font-size: 12px; color: #f5576c; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }}
        .reason-box .text {{ color: #333; font-size: 15px; }}
        .footer {{ background: #f9f9f9; padding: 20px 30px; text-align: center; color: #999; font-size: 13px; border-top: 1px solid #eee; }}
        .status {{ display: inline-block; background: #f5576c; color: white; padding: 6px 16px; border-radius: 20px; font-weight: bold; font-size: 13px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <div class='icon'>❌</div>
            <h1>Rezervacija otkazana</h1>
        </div>
        <div class='body'>
            <h2>Zdravo, {message.UserFullName},</h2>
            <p>Nažalost, vaša rezervacija je <span class='status'>Otkazana</span>.</p>
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
                    <span class='value'>{message.StartTime}</span>
                </div>
                <div class='row'>
                    <span class='label'>🔖 ID rezervacije</span>
                    <span class='value'>#{message.ReservationId}</span>
                </div>
            </div>
            <div class='reason-box'>
                <div class='label'>Razlog otkazivanja</div>
                <div class='text'>{message.CancellationReason}</div>
            </div>
            <p>Možete napraviti novu rezervaciju u EasyTab aplikaciji. Žao nam je zbog neugodnosti.</p>
            <p style='color: #333; font-weight: bold;'>Srdačan pozdrav,<br>EasyTab tim 🍽️</p>
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
