namespace TaskFlow.Api.FeatureFlags;

/// <summary>
/// The feature flags TaskFlow uses, by their slug in Octopus (Project ➜ Feature Flags).
/// </summary>
public static class FeatureFlagKeys
{
    public const string DarkMode = "dark-mode";

    public static readonly IReadOnlyList<string> All = [DarkMode];
}
