using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;

namespace Terrain;

[Tool]
public class Float3DSerializer : JsonConverter<float[,,]>
{
    public override float[,,] Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        using JsonDocument doc = JsonDocument.ParseValue(ref reader);
        JsonElement root = doc.RootElement;

        int dim1 = root.GetArrayLength();
        int dim2 = root[0].GetArrayLength();
        int dim3 = root[0][0].GetArrayLength();

        float[,,] result = new float[dim1, dim2, dim3];

        for (int i = 0; i < dim1; i++)
        {
            for (int j = 0; j < dim2; j++)
            {
                for (int k = 0; k < dim3; k++)
                {
                    result[i, j, k] = root[i][j][k].GetSingle();
                }
            }
        }

        return result;
    }

    public override void Write(Utf8JsonWriter writer, float[,,] value, JsonSerializerOptions options)
    {
        writer.WriteStartArray();

        for (int i = 0; i < value.GetLength(0); i++)
        {
            writer.WriteStartArray();
            for (int j = 0; j < value.GetLength(1); j++)
            {
                writer.WriteStartArray();
                for (int k = 0; k < value.GetLength(2); k++)
                {
                    writer.WriteNumberValue(value[i, j, k]);
                }
                writer.WriteEndArray();
            }
            writer.WriteEndArray();
        }

        writer.WriteEndArray();
    }
}
