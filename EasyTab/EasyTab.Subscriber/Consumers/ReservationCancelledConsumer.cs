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

            var subject = "Vaša rezervacija je otkazana — EasyTab";
            var formattedDate = message.ReservationDate.ToString("dd.MM.yyyy");

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
        .table-details {{ width: 100%; border-collapse: collapse; margin: 16px 0; }}
        .table-details td {{ padding: 8px 0; font-size: 14px; border-bottom: 1px solid #f1f5f9; }}
        .table-details td.label {{ color: #64748b; width: 40%; }}
        .table-details td.value {{ color: #0f172a; font-weight: 600; }}
        .status-badge {{ display: inline-block; background-color: #fee2e2; color: #991b1b; padding: 3px 8px; border-radius: 4px; font-weight: 600; font-size: 13px; }}
        .reason-box {{ background-color: #fef2f2; border: 1px solid #fee2e2; padding: 12px 16px; border-radius: 4px; margin: 16px 0; font-size: 14px; }}
        .reason-box .reason-label {{ font-size: 12px; color: #991b1b; font-weight: 600; text-transform: uppercase; margin-bottom: 4px; }}
        .reason-box .reason-text {{ color: #1e293b; }}
        .footer {{ background-color: #f8fafc; padding: 16px 24px; border-top: 1px solid #e2e8f0; font-size: 12px; color: #64748b; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>EasyTab</h1>
        </div>
        <div class='body'>
            <h2>Zdravo {message.UserFullName},</h2>
            <p>Vaša rezervacija je <span class='status-badge'>Otkazana</span>.</p>
            
            <table class='table-details'>
                <tr>
                    <td class='label'>Lokal:</td>
                    <td class='value'>{message.LocaleName}</td>
                </tr>
                <tr>
                    <td class='label'>Datum:</td>
                    <td class='value'>{formattedDate}</td>
                </tr>
                <tr>
                    <td class='label'>Termin:</td>
                    <td class='value'>{ReservationTimeText.Format(message.StartTime, message.EndTime)}</td>
                </tr>
                <tr>
                    <td class='label'>Broj rezervacije:</td>
                    <td class='value'>#{message.ReservationId}</td>
                </tr>
            </table>

            <div class='reason-box'>
                <div class='reason-label'>Razlog otkazivanja:</div>
                <div class='reason-text'>{message.CancellationReason}</div>
            </div>

            <p>Ukoliko želite, možete napraviti novu rezervaciju u EasyTab aplikaciji.</p>
            <p style='margin-top: 20px;'>Srdačan pozdrav,<br>EasyTab tim</p>
        </div>
        <div class='footer'>
            © 2026 EasyTab. Sva prava zadržana.
        </div>
    </div>
</body>
</html>";

            await _emailService.SendAsync(message.UserEmail, message.UserFullName, subject, body);
        }
    }
}
