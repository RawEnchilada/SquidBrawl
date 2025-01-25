using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;

namespace Terrain;

[Tool]
public class Vector3DSerializer : JsonConverter<Vector3>
{
    public override Vector3 Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        using JsonDocument doc = JsonDocument.ParseValue(ref reader);
        JsonElement root = doc.RootElement;

        return new Vector3(
            root.GetProperty("X").GetSingle(),
            root.GetProperty("Y").GetSingle(),
            root.GetProperty("Z").GetSingle()
        );
    }

    public override void Write(Utf8JsonWriter writer, Vector3 value, JsonSerializerOptions options)
    {
        writer.WriteStartObject();
        writer.WriteNumber("X", value.X);
        writer.WriteNumber("Y", value.Y);
        writer.WriteNumber("Z", value.Z);
        writer.WriteEndObject();
    }
}
