using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net;
using System.Text.Json;

namespace TaskFlow.Tests.Api.Controllers;

/// <summary>
/// Without a client identifier from Octopus, no feature flag provider is registered and every flag uses its code default.
/// </summary>
public class FeatureFlagsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public FeatureFlagsTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder => builder.UseEnvironment("IntegrationTests"));
    }

    [Fact]
    public async Task GetFeatures_ShouldReturnCodeDefaults_WhenNoClientIdentifier()
    {
        var response = await _factory.CreateClient().GetAsync("/api/features");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var darkMode = json.RootElement.GetProperty("flags").EnumerateArray()
            .Single(flag => flag.GetProperty("key").GetString() == "dark-mode");
        Assert.False(darkMode.GetProperty("value").GetBoolean());
    }

    [Theory]
    [InlineData(null)]
    [InlineData("#{Octopus.FeatureFlags.ClientIdentifier}")]
    public async Task GetConfig_ShouldReturnNoClientIdentifier_WhenNotSupplied(string? clientIdentifier)
    {
        var client = _factory
            .WithWebHostBuilder(builder => builder.UseSetting("FeatureFlags:ClientIdentifier", clientIdentifier))
            .CreateClient();

        var response = await client.GetAsync("/api/config");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(JsonValueKind.Null, json.RootElement.GetProperty("featureFlagsClientIdentifier").ValueKind);
    }
}
