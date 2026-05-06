using System.Text.Json;
using System.Text.Json.Serialization;

[JsonSourceGenerationOptions(WriteIndented = false)]
[JsonSerializable(typeof(Dictionary<string, string>))]
internal partial class AppJsonContext : JsonSerializerContext { }

var output = new Dictionary<string, string>
{
    ["hello"]     = "world",
    ["language"]  = "csharp",
    ["uuid"]      = Guid.NewGuid().ToString(),
    ["timestamp"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"),
};

Console.WriteLine(JsonSerializer.Serialize(output, AppJsonContext.Default.DictionaryStringString));
