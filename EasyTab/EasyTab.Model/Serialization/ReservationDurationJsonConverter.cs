using System;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace EasyTab.Model.Serialization;

public static class ReservationDurationMessages
{
    public const string InvalidValue =
        "Dužina rezervacije mora biti broj sati veći od 0 i najviše 24. " +
        "Za decimalne vrijednosti koristite tačku (npr. 1.5), ne zarez (1,5).";
}

public sealed class ReservationDurationJsonConverter : JsonConverter<double>
{
    public override double Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options) =>
        ReservationDurationJsonValue.Read(ref reader);

    public override void Write(
        Utf8JsonWriter writer,
        double value,
        JsonSerializerOptions options) =>
        writer.WriteNumberValue(value);
}

public sealed class NullableReservationDurationJsonConverter : JsonConverter<double?>
{
    public override double? Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return null;
        }

        return ReservationDurationJsonValue.Read(ref reader);
    }

    public override void Write(
        Utf8JsonWriter writer,
        double? value,
        JsonSerializerOptions options)
    {
        if (value.HasValue)
        {
            writer.WriteNumberValue(value.Value);
            return;
        }

        writer.WriteNullValue();
    }
}

internal static class ReservationDurationJsonValue
{
    public static double Read(ref Utf8JsonReader reader)
    {
        double value;
        if (reader.TokenType == JsonTokenType.Number)
        {
            if (!reader.TryGetDouble(out value))
            {
                throw new JsonException(ReservationDurationMessages.InvalidValue);
            }
        }
        else if (reader.TokenType == JsonTokenType.String)
        {
            var text = reader.GetString();
            if (string.IsNullOrWhiteSpace(text) ||
                text.Contains(',') ||
                !double.TryParse(
                    text,
                    NumberStyles.Float,
                    CultureInfo.InvariantCulture,
                    out value))
            {
                throw new JsonException(ReservationDurationMessages.InvalidValue);
            }
        }
        else
        {
            throw new JsonException(ReservationDurationMessages.InvalidValue);
        }

        if (!double.IsFinite(value))
        {
            throw new JsonException(ReservationDurationMessages.InvalidValue);
        }

        return value;
    }
}
