using Microsoft.AspNetCore.Mvc;
using TaskFlow.Api.FeatureFlags;

namespace TaskFlow.Api.Controllers;

/// <summary>
/// Runtime settings for the web app. The web image is built once and deployed everywhere, so anything that differs
/// per environment comes from here rather than being baked into the bundle.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ConfigController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public ConfigController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            // Safe to send to the browser: it only lets the holder read this environment's flag values
            FeatureFlagsClientIdentifier = FeatureFlagSetup.GetClientIdentifier(_configuration)
        });
    }
}
