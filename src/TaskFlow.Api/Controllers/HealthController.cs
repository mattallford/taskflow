using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskFlow.Infrastructure.Data;

namespace TaskFlow.Api.Controllers;

[ApiController]
[Route("[controller]")]
public class HealthController : ControllerBase
{
    private readonly TaskDbContext _context;
    private readonly ILogger<HealthController> _logger;

    public HealthController(TaskDbContext context, ILogger<HealthController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        try
        {
            // CanConnectAsync returns false rather than throwing when the database is unreachable
            if (!await _context.Database.CanConnectAsync())
            {
                throw new InvalidOperationException("Cannot connect to the database");
            }

            var healthCheck = new
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Database = "Connected"
            };

            _logger.LogInformation("Health check passed");
            return Ok(healthCheck);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Health check failed");
            
            var healthCheck = new
            {
                Status = "Unhealthy",
                Timestamp = DateTime.UtcNow,
                Database = "Disconnected",
                Error = ex.Message
            };

            return StatusCode(503, healthCheck);
        }
    }

    // Liveness check: the process is up and serving requests, whatever the state of the database
    [HttpGet("live")]
    public IActionResult Live()
    {
        return Ok(new { Status = "Alive", Timestamp = DateTime.UtcNow });
    }
}