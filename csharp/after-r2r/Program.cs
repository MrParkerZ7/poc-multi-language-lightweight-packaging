using System.Text.Json;

var output = new Dictionary<string, string>
{
    ["hello"]     = "world",
    ["language"]  = "csharp",
    ["uuid"]      = Guid.NewGuid().ToString(),
    ["timestamp"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"),
};

Console.WriteLine(JsonSerializer.Serialize(output));
