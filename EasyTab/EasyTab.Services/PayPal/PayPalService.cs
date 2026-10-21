using System;
using System.Collections.Generic;
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

        private void LogPayPalError(string operation, HttpStatusCode statusCode, string content)
        {
            try
            {
                var error = JsonSerializer.Deserialize<PayPalErrorResponse>(content);
                var issues = error?.Details != null && error.Details.Count > 0
                    ? string.Join(", ", error.Details.Select(d => d.Issue).Where(i => !string.IsNullOrEmpty(i)))
                    : (error?.Name ?? "N/A");

                _logger.LogError(
                    "PayPal {Operation} failed. HTTP Status: {StatusCode}, Name: {Name}, Message: {Message}, Issues: {Issues}, DebugId: {DebugId}",
                    operation,
                    (int)statusCode,
                    error?.Name ?? "N/A",
                    error?.Message ?? "N/A",
                    issues,
                    error?.DebugId ?? "N/A");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "PayPal {Operation} failed with HTTP status {StatusCode}. Raw response: {Content}",
                    operation, (int)statusCode, content);
            }
        }

        private static UserException CreateUserFriendlyException(string content, string defaultMessage)
        {
            try
            {
                var error = JsonSerializer.Deserialize<PayPalErrorResponse>(content);
                var issues = error?.Details?.Select(d => d.Issue ?? "").ToList() ?? new List<string>();
                var allIssues = issues.Concat(new[] { error?.Name ?? "" }).Where(s => !string.IsNullOrEmpty(s)).ToList();

                if (allIssues.Any(i => string.Equals(i, "ORDER_NOT_APPROVED", StringComparison.OrdinalIgnoreCase) ||
                                       string.Equals(i, "PAYER_ACTION_REQUIRED", StringComparison.OrdinalIgnoreCase)) ||
                    content.Contains("ORDER_NOT_APPROVED", StringComparison.OrdinalIgnoreCase) ||
                    content.Contains("PAYER_ACTION_REQUIRED", StringComparison.OrdinalIgnoreCase))
                {
                    return new UserException("Placanje nije odobreno na PayPalu. Pokusajte ponovo.");
                }

                if (allIssues.Any(i => string.Equals(i, "INSTRUMENT_DECLINED", StringComparison.OrdinalIgnoreCase)) ||
                    content.Contains("INSTRUMENT_DECLINED", StringComparison.OrdinalIgnoreCase))
                {
                    return new UserException("PayPal je odbio nacin placanja. Odaberite drugi.");
                }

                if (allIssues.Any(i => string.Equals(i, "COMPLIANCE_VIOLATION", StringComparison.OrdinalIgnoreCase)) ||
                    content.Contains("COMPLIANCE_VIOLATION", StringComparison.OrdinalIgnoreCase))
                {
                    return new UserException("PayPal je odbio naplatu. Pokusajte ponovo kasnije ili odaberite drugi nacin placanja.");
                }
            }
            catch
            {
                // Fallback na string inspekciju ako JSON deserializacija ne uspije
            }

            if (content.Contains("ORDER_NOT_APPROVED", StringComparison.OrdinalIgnoreCase) ||
                content.Contains("PAYER_ACTION_REQUIRED", StringComparison.OrdinalIgnoreCase))
            {
                return new UserException("Placanje nije odobreno na PayPalu. Pokusajte ponovo.");
            }

            if (content.Contains("INSTRUMENT_DECLINED", StringComparison.OrdinalIgnoreCase))
            {
                return new UserException("PayPal je odbio nacin placanja. Odaberite drugi.");
            }

            if (content.Contains("COMPLIANCE_VIOLATION", StringComparison.OrdinalIgnoreCase))
            {
                return new UserException("PayPal je odbio naplatu. Pokusajte ponovo kasnije ili odaberite drugi nacin placanja.");
            }

            return new UserException("Placanje trenutno nije moguce. Pokusajte kasnije.");
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

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("GetAccessToken", response.StatusCode, content);
                throw new UserException("Neuspješna autentifikacija sa servisom za plaćanje.");
            }

            var tokenResponse = JsonSerializer.Deserialize<PayPalTokenResponse>(content);
            if (tokenResponse == null || string.IsNullOrEmpty(tokenResponse.AccessToken))
            {
                throw new UserException("Greška pri dohvatanju pristupnog tokena za plaćanje.");
            }

            // OAuth token u IMemoryCache ističe 60 sekundi prije stvarnog isteka
            var cacheExpirationSeconds = Math.Max(tokenResponse.ExpiresIn - 60, 60);
            _memoryCache.Set(TokenCacheKey, tokenResponse.AccessToken, TimeSpan.FromSeconds(cacheExpirationSeconds));

            return tokenResponse.AccessToken;
        }

        public async Task<(string orderId, string? approvalUrl)> CreateOrderAsync(decimal amountEur, string currency, string referenceId, string description)
        {
            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Post, "v2/checkout/orders");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

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

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("CreateOrder", response.StatusCode, content);
                throw CreateUserFriendlyException(content, "Kreiranje narudžbe za plaćanje nije uspjelo.");
            }

            var order = JsonSerializer.Deserialize<PayPalOrderResponse>(content);
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

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("GetOrder", response.StatusCode, content);
                throw new UserException("Dohvatanje narudžbe za plaćanje nije uspjelo.");
            }

            var order = JsonSerializer.Deserialize<PayPalOrderResponse>(content);
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

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("CaptureOrder", response.StatusCode, content);

                // 3) Obrada ORDER_ALREADY_CAPTURED (422): ne bacaj grešku, dohvati order, provjeri COMPLETED i iznos/valutu
                if (response.StatusCode == HttpStatusCode.UnprocessableEntity &&
                    content.Contains("ORDER_ALREADY_CAPTURED", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogInformation("Order {OrderId} was already captured on PayPal (ORDER_ALREADY_CAPTURED). Reconciling from GetOrder.", orderId);
                    var existingOrder = await GetOrderAsync(orderId);
                    if (string.Equals(existingOrder.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
                    {
                        var capture = existingOrder.PurchaseUnits?.FirstOrDefault()?.Payments?.Captures?.FirstOrDefault();
                        var captureId = capture?.Id ?? existingOrder.Id;
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

            var orderResponse = JsonSerializer.Deserialize<PayPalOrderResponse>(content);
            var capturedUnit = orderResponse?.PurchaseUnits?.FirstOrDefault()?.Payments?.Captures?.FirstOrDefault();

            if (capturedUnit == null || string.IsNullOrEmpty(capturedUnit.Id))
            {
                _logger.LogError("PayPal capture response did not contain capture details for order {OrderId}: {Response}", orderId, content);
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

            var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                LogPayPalError("RefundCapture", response.StatusCode, content);

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

                throw CreateUserFriendlyException(content, "Povrat sredstava putem servisa za plaćanje nije uspio.");
            }

            var refund = JsonSerializer.Deserialize<PayPalRefund>(content);
            return new PayPalRefundResult
            {
                RefundId = refund?.Id,
                Status = refund?.Status ?? "COMPLETED",
                AlreadyRefunded = false
            };
        }
    }
}
