using System;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using EasyTab.Model.Exceptions;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EasyTab.Services.PayPal
{
    public class PayPalService : IPayPalService
    {
        private readonly HttpClient _httpClient;
        private readonly PayPalOptions _options;
        private readonly IMemoryCache _memoryCache;
        private readonly ILogger<PayPalService> _logger;

        private const string TokenCacheKey = "PayPal_OAuth_AccessToken";

        public PayPalService(
            HttpClient httpClient,
            IOptions<PayPalOptions> options,
            IMemoryCache memoryCache,
            ILogger<PayPalService> logger)
        {
            _httpClient = httpClient;
            _options = options.Value;
            _memoryCache = memoryCache;
            _logger = logger;

            if (!string.IsNullOrEmpty(_options.BaseUrl))
            {
                _httpClient.BaseAddress = new Uri(_options.BaseUrl.TrimEnd('/') + "/");
            }
        }

        private const string UnavailableMessage = "PayPal trenutno nije dostupan. Pokušajte ponovo kasnije.";
        private const string RefundFailureMessage = "Povrat uplate nije uspio. Rezervacija nije otkazana. Pokušajte ponovo kasnije.";

        private static string DebugId(HttpResponseMessage response, string? content = null)
        {
            var debugId = response.Headers.TryGetValues("PayPal-Debug-Id", out var values) ? values.FirstOrDefault() : null;
            if (content != null)
            {
                try
                {
                    using var document = JsonDocument.Parse(content);
                    if (document.RootElement.ValueKind == JsonValueKind.Object &&
                        document.RootElement.TryGetProperty("debug_id", out var value) && value.ValueKind == JsonValueKind.String)
                        debugId = value.GetString() ?? debugId;
                }
                catch (JsonException)
                {
                    return SafeCode(debugId);
                }
            }
            return SafeCode(debugId);
        }

        private async Task<(HttpResponseMessage Response, string Content)> SendAsync(HttpRequestMessage request, string operation)
        {
            HttpResponseMessage? response = null;
            try
            {
                response = await _httpClient.SendAsync(request);
                return (response, await response.Content.ReadAsStringAsync());
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is TaskCanceledException)
            {
                _logger.LogError("PayPal {Operation} failed. HTTP Status: {StatusCode}, ExceptionType: {ExceptionType}, DebugId: {DebugId}",
                    operation, response != null ? (int)response.StatusCode : (int?)(ex as HttpRequestException)?.StatusCode,
                    ex.GetType().Name, response == null ? null : DebugId(response));
                response?.Dispose();
                throw new UserException(UnavailableMessage);
            }
        }

        private T? DeserializeResponse<T>(string content, HttpResponseMessage response, string operation)
        {
            try
            {
                return JsonSerializer.Deserialize<T>(content);
            }
            catch (JsonException ex)
            {
                _logger.LogError("PayPal {Operation} failed. HTTP Status: {StatusCode}, ExceptionType: {ExceptionType}, DebugId: {DebugId}",
                    operation, (int)response.StatusCode, ex.GetType().Name, DebugId(response, content));
                throw new UserException(UnavailableMessage);
            }
        }

        private static string SafeResponse(string content)
        {
            // Only diagnostic codes are retained; tokens and buyer data are never logged.
            try
            {
                using var document = JsonDocument.Parse(content);
                using var stream = new System.IO.MemoryStream();
                using (var writer = new Utf8JsonWriter(stream))
                {
                    writer.WriteStartObject();
                    foreach (var key in new[] { "name", "debug_id" })
                        if (document.RootElement.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.String)
                            writer.WriteString(key, SafeCode(value.GetString()));
                    writer.WriteEndObject();
                }
                var sanitized = Encoding.UTF8.GetString(stream.ToArray());
                return sanitized[..Math.Min(sanitized.Length, 2000)];
            }
            catch (Exception ex) when (ex is JsonException || ex is InvalidOperationException)
            {
                return "[Unreadable PayPal response omitted]";
            }
        }

        private static string SafeCode(string? value) =>
            new string((value ?? "N/A").Where(c => char.IsAsciiLetterOrDigit(c) || c == '_' || c == '-').Take(200).ToArray());

        private void LogPayPalError(string operation, HttpResponseMessage response, string content)
        {
            try
            {
                var error = JsonSerializer.Deserialize<PayPalErrorResponse>(content);
                var issues = string.Join(", ", error?.Details?.Select(d => SafeCode(d.Issue)) ?? Enumerable.Empty<string>());
                _logger.LogError("PayPal {Operation} failed. HTTP Status: {StatusCode}, Name: {Name}, Issues: {Issues}, DebugId: {DebugId}",
                    operation, (int)response.StatusCode, SafeCode(error?.Name), issues[..Math.Min(issues.Length, 2000)],
                    SafeCode(error?.DebugId ?? DebugId(response)));
            }
            catch (JsonException ex)
            {
                _logger.LogError("PayPal {Operation} failed. HTTP Status: {StatusCode}, ExceptionType: {ExceptionType}, DebugId: {DebugId}, Response: {Response}",
                    operation, (int)response.StatusCode, ex.GetType().Name, DebugId(response, content), SafeResponse(content));
            }
        }

        private static UserException CreateUserFriendlyException(string content, string defaultMessage)
        {
            if (defaultMessage == RefundFailureMessage)
                return new UserException(defaultMessage);
            if (content.Contains("ORDER_NOT_APPROVED", StringComparison.OrdinalIgnoreCase) ||
                content.Contains("PAYER_ACTION_REQUIRED", StringComparison.OrdinalIgnoreCase))
                return new UserException("Plaćanje nije odobreno na PayPalu. Pokušajte ponovo.");
            if (content.Contains("INSTRUMENT_DECLINED", StringComparison.OrdinalIgnoreCase))
                return new UserException("PayPal je odbio način plaćanja. Odaberite drugi.");
            if (content.Contains("COMPLIANCE_VIOLATION", StringComparison.OrdinalIgnoreCase))
                return new UserException("PayPal je odbio naplatu. Pokušajte ponovo kasnije ili odaberite drugi način plaćanja.");
            return new UserException(defaultMessage);
        }

        private async Task<string> GetAccessTokenAsync()
        {
            if (_memoryCache.TryGetValue(TokenCacheKey, out string? cachedToken) && !string.IsNullOrEmpty(cachedToken))
            {
                return cachedToken;
            }

            var authValue = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_options.ClientId}:{_options.Secret}"));
            using var request = new HttpRequestMessage(HttpMethod.Post, "v1/oauth2/token");
            request.Headers.Authorization = new AuthenticationHeaderValue("Basic", authValue);
            request.Content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

            var (httpResponse, content) = await SendAsync(request, "GetAccessToken");
            using var response = httpResponse;

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("GetAccessToken", response, content);
                throw new UserException("Neuspješna autentifikacija sa servisom za plaćanje.");
            }

            var tokenResponse = DeserializeResponse<PayPalTokenResponse>(content, response, "GetAccessToken");
            if (tokenResponse == null || string.IsNullOrEmpty(tokenResponse.AccessToken))
            {
                throw new UserException("Greška pri dohvatanju pristupnog tokena za plaćanje.");
            }

            // OAuth token u IMemoryCache ističe 60 sekundi prije stvarnog isteka
            var cacheExpirationSeconds = Math.Max(tokenResponse.ExpiresIn - 60, 60);
            _memoryCache.Set(TokenCacheKey, tokenResponse.AccessToken, TimeSpan.FromSeconds(cacheExpirationSeconds));

            return tokenResponse.AccessToken;
        }

        public async Task<(string orderId, string? approvalUrl)> CreateOrderAsync(decimal amountEur, string currency, string referenceId, string description, string? requestId = null)
        {
            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Post, "v2/checkout/orders");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            if (requestId != null)
                request.Headers.TryAddWithoutValidation("PayPal-Request-Id", requestId);

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        reference_id = referenceId,
                        description = description,
                        amount = new
                        {
                            currency_code = currency,
                            value = amountEur.ToString("F2", CultureInfo.InvariantCulture)
                        }
                    }
                },
                application_context = new
                {
                    return_url = _options.ReturnUrl,
                    cancel_url = _options.CancelUrl,
                    user_action = "PAY_NOW"
                }
            };

            var json = JsonSerializer.Serialize(payload);
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
            request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            var (httpResponse, content) = await SendAsync(request, "CreateOrder");
            using var response = httpResponse;

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("CreateOrder", response, content);
                throw CreateUserFriendlyException(content, "Kreiranje narudžbe za plaćanje nije uspjelo.");
            }

            var order = DeserializeResponse<PayPalOrderResponse>(content, response, "CreateOrder");
            if (order == null || string.IsNullOrEmpty(order.Id))
            {
                throw new UserException("Neispravan odgovor od servisa za plaćanje pri kreiranju narudžbe.");
            }

            var approvalUrl = order.Links?.FirstOrDefault(l =>
                string.Equals(l.Rel, "approve", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(l.Rel, "payer-action", StringComparison.OrdinalIgnoreCase))?.Href;

            return (order.Id, approvalUrl);
        }

        public async Task<PayPalOrderResponse> GetOrderAsync(string orderId)
        {
            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Get, $"v2/checkout/orders/{orderId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var (httpResponse, content) = await SendAsync(request, "GetOrder");
            using var response = httpResponse;

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("GetOrder", response, content);
                if (response.StatusCode == HttpStatusCode.NotFound)
                    throw new NotFoundException("PayPal narudžba nije pronađena.");
                throw new UserException("Dohvatanje narudžbe za plaćanje nije uspjelo.");
            }

            var order = DeserializeResponse<PayPalOrderResponse>(content, response, "GetOrder");
            if (order == null)
            {
                throw new UserException("Neispravan odgovor od servisa za plaćanje.");
            }

            return order;
        }

        public async Task<PayPalCaptureResult> CaptureOrderAsync(string orderId, string requestId)
        {
            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Post, $"v2/checkout/orders/{orderId}/capture");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.TryAddWithoutValidation("PayPal-Request-Id", requestId);
            request.Content = new StringContent("{}", Encoding.UTF8, "application/json");
            request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            var (httpResponse, content) = await SendAsync(request, "CaptureOrder");
            using var response = httpResponse;

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("CaptureOrder", response, content);

                // 3) Obrada ORDER_ALREADY_CAPTURED (422): ne bacaj grešku, dohvati order, provjeri COMPLETED i iznos/valutu
                if (response.StatusCode == HttpStatusCode.UnprocessableEntity &&
                    content.Contains("ORDER_ALREADY_CAPTURED", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogInformation("Order {OrderId} was already captured on PayPal (ORDER_ALREADY_CAPTURED). Reconciling from GetOrder.", orderId);
                    var existingOrder = await GetOrderAsync(orderId);
                    if (string.Equals(existingOrder.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
                    {
                        var capture = existingOrder.PurchaseUnits?.FirstOrDefault()?.Payments?.Captures?.FirstOrDefault();
                        var captureId = capture?.Id ?? string.Empty;
                        var captureStatus = capture?.Status ?? existingOrder.Status;
                        var amountStr = capture?.Amount?.Value ?? existingOrder.PurchaseUnits?.FirstOrDefault()?.Amount?.Value;
                        var currencyCode = capture?.Amount?.CurrencyCode ?? existingOrder.PurchaseUnits?.FirstOrDefault()?.Amount?.CurrencyCode ?? string.Empty;
                        var parsedAmount = decimal.TryParse(amountStr, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed) ? parsed : 0m;

                        return new PayPalCaptureResult
                        {
                            CaptureId = captureId,
                            Status = captureStatus,
                            Amount = parsedAmount,
                            Currency = currencyCode
                        };
                    }
                }

                // Provjeri status narudžbe kod PayPala (da li je APPROVED, CREATED, itd.) i zabilježi u log
                try
                {
                    var currentOrder = await GetOrderAsync(orderId);
                    _logger.LogInformation("PayPal order {OrderId} status returned by GetOrder is '{OrderStatus}'.", orderId, currentOrder.Status);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Could not fetch current order status for {OrderId} during error handling.", orderId);
                }

                // 5) Korisniku vrati prilagođenu poruku ovisno o grešci
                throw CreateUserFriendlyException(content, "Placanje trenutno nije moguce. Pokusajte kasnije.");
            }

            var orderResponse = DeserializeResponse<PayPalOrderResponse>(content, response, "CaptureOrder");
            var capturedUnit = orderResponse?.PurchaseUnits?.FirstOrDefault()?.Payments?.Captures?.FirstOrDefault();

            if (capturedUnit == null || string.IsNullOrEmpty(capturedUnit.Id))
            {
                _logger.LogError("PayPal {Operation} returned incomplete capture details. HTTP Status: {StatusCode}, DebugId: {DebugId}, Response: {Response}",
                    "CaptureOrder", (int)response.StatusCode, SafeCode(DebugId(response)), SafeResponse(content));
                throw new UserException("Odgovor servisa za plaćanje ne sadrži podatke o naplati.");
            }

            var amount = decimal.TryParse(capturedUnit.Amount?.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out var a) ? a : 0m;
            return new PayPalCaptureResult
            {
                CaptureId = capturedUnit.Id,
                Status = capturedUnit.Status,
                Amount = amount,
                Currency = capturedUnit.Amount?.CurrencyCode ?? string.Empty
            };
        }

        public async Task<PayPalRefundResult> RefundCaptureAsync(string captureId, decimal amountEur, string currency, string requestId)
        {
            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Post, $"v2/payments/captures/{captureId}/refund");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.TryAddWithoutValidation("PayPal-Request-Id", requestId);

            var payload = new
            {
                amount = new
                {
                    currency_code = currency,
                    value = amountEur.ToString("F2", CultureInfo.InvariantCulture)
                }
            };

            var json = JsonSerializer.Serialize(payload);
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
            request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            var (httpResponse, content) = await SendAsync(request, "RefundCapture");
            using var response = httpResponse;

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("RefundCapture", response, content);

                // Ako je capture već u potpunosti refundiran, tretiraj kao uspjeh
                if (response.StatusCode == HttpStatusCode.UnprocessableEntity &&
                    (content.Contains("CAPTURE_ALREADY_REFUNDED", StringComparison.OrdinalIgnoreCase) ||
                     content.Contains("ALREADY_REFUNDED", StringComparison.OrdinalIgnoreCase)))
                {
                    _logger.LogInformation("Capture {CaptureId} was already refunded on PayPal. Treating as success.", captureId);
                    return new PayPalRefundResult
                    {
                        RefundId = null,
                        Status = "COMPLETED",
                        AlreadyRefunded = true
                    };
                }

                throw CreateUserFriendlyException(content, RefundFailureMessage);
            }

            var refund = DeserializeResponse<PayPalRefund>(content, response, "RefundCapture");
            return new PayPalRefundResult
            {
                RefundId = refund?.Id,
                Status = refund?.Status ?? string.Empty,
                AlreadyRefunded = false
            };
        }
    }
}
