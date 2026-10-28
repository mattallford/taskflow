using Octopus.OpenFeature.Provider;

namespace TaskFlow.Api.FeatureFlags;

/// <summary>
/// Connects OpenFeature to Octopus Feature Flags.
/// </summary>
/// <remarks>
/// Octopus substitutes the Octopus.FeatureFlags.ClientIdentifier variable into FeatureFlags__ClientIdentifier at
/// deploy time. The identifier is a JWT that tells the Feature Flags service which project, environment and release
/// this is. Without one (dotnet run locally, or the integration tests) no provider is registered, and every flag
/// evaluates to the default value given in code.
/// </remarks>
public static class FeatureFlagSetup
{
    public static string? GetClientIdentifier(IConfiguration configuration)
    {
        var clientIdentifier = configuration["FeatureFlags:ClientIdentifier"];

        // An unsubstituted "#{...}" means the deployment didn't supply an identifier
        return string.IsNullOrWhiteSpace(clientIdentifier) || clientIdentifier.StartsWith("#{")
            ? null
            : clientIdentifier;
    }

    public static async Task UseOctopusFeatureFlagsAsync(this WebApplication app, string appVersion)
    {
        var clientIdentifier = GetClientIdentifier(app.Configuration);
        if (clientIdentifier is null)
        {
            // OpenFeature's default no-op provider stays in place. Evaluations return the code default, with an error
            // saying no provider has finished initializing.
            app.Logger.LogInformation("No feature flag client identifier configured; feature flags use their code defaults");
            return;
        }

        var configuration = new OctopusFeatureConfiguration(clientIdentifier, new ProductMetadata("TaskFlow.Api", appVersion))
        {
            // How often the provider asks the Feature Flags service whether anything has changed. The default is a
            // minute; 15 seconds keeps a demo responsive. Each check is a small request that only downloads the
            // flags again when their content hash has changed.
            CacheDuration = TimeSpan.FromSeconds(15),
            LoggerFactory = app.Services.GetRequiredService<ILoggerFactory>()
        };

        // Downloads the flags once before the API starts serving requests, then keeps them up to date in the background
        await global::OpenFeature.Api.Instance.SetProviderAsync(new OctopusFeatureProvider(configuration));
        app.Logger.LogInformation("Octopus feature flags connected");
    }
}
