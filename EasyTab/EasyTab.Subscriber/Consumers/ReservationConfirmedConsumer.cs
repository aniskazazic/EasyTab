using EasyTab.Model.Messages;
using EasyTab.Subscriber.Services;

namespace EasyTab.Subscriber.Consumers
{
    public class ReservationConfirmedConsumer
    {
        private readonly EmailService _emailService;
        private readonly ILogger<ReservationConfirmedConsumer> _logger;

        public ReservationConfirmedConsumer(EmailService emailService, ILogger<ReservationConfirmedConsumer> logger)
        {
            _emailService = emailService;
            _logger = logger;
        }

        public async Task HandleAsync(ReservationConfirmedMessage message)
        {
            _logger.LogInformation("Processing ReservationConfirmedMessage for ReservationId: {Id}", message.ReservationId);

            var subject = "Vaša rezervacija je potvrđena — EasyTab";
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
        .status-badge {{ display: inline-block; background-color: #dcfce7; color: #166534; padding: 3px 8px; border-radius: 4px; font-weight: 600; font-size: 13px; }}
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
            <p>Vaša rezervacija je <span class='status-badge'>Potvrđena</span> od strane lokala.</p>
            
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
                    <td class='value'>{message.StartTime} - {message.EndTime}</td>
                </tr>
                <tr>
                    <td class='label'>Broj osoba:</td>
                    <td class='value'>{message.NumberOfGuests}</td>
                </tr>
                <tr>
                    <td class='label'>Broj rezervacije:</td>
                    <td class='value'>#{message.ReservationId}</td>
                </tr>
            </table>

            <p>Ukoliko dođe do promjene planova, molimo vas da blagovremeno otkažete rezervaciju kroz aplikaciju.</p>
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
