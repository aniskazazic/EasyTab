using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace EasyTab.API.Helpers
{
    public class TimeOnlyJsonConverter : JsonConverter<TimeOnly>
    {
        public const string Format = "HH:mm:ss";

        public override TimeOnly Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            return TimeOnly.ParseExact(reader.GetString()!, Format);
        }

        public override void Write(Utf8JsonWriter writer, TimeOnly value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.ToString(Format));
        }
    }
}