using Microsoft.AspNetCore.Mvc;
using OpenFeature;
using OpenFeature.Constant;
using TaskFlow.Api.FeatureFlags;

namespace TaskFlow.Api.Controllers;

/// <summary>
/// Shows how the API currently evaluates each feature flag, and why.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class FeaturesController : ControllerBase
{
    private readonly IFeatureClient _featureClient;

    public FeaturesController(IFeatureClient featureClient)
    {
        _featureClient = featureClient;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var flags = new List<object>();
        foreach (var key in FeatureFlagKeys.All)
        {
            // The second argument is the code default, returned when the provider can't answer
            var details = await _featureClient.GetBooleanDetailsAsync(key, false);
            flags.Add(new
            {
                Key = key,
                details.Value,
                details.Reason,
                Error = details.ErrorType == ErrorType.None ? null : details.ErrorMessage ?? details.ErrorType.ToString()
            });
        }

        return Ok(new
        {
            Provider = global::OpenFeature.Api.Instance.GetProviderMetadata()?.Name,
            Flags = flags
        });
    }
}
