using Microsoft.EntityFrameworkCore;
using Serilog;
using TaskFlow.Core.Interfaces;
using TaskFlow.Core.Services;
using TaskFlow.Infrastructure.Data;
using TaskFlow.Infrastructure.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllers();

// Configure global UTC handling for PostgreSQL timestamps
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

// Configure Entity Framework
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var useInMemory = string.IsNullOrEmpty(connectionString) && builder.Environment.IsDevelopment();

if (useInMemory)
{
    // Use in-memory database for local development when PostgreSQL is not available
    Log.Information("Using in-memory database for development");
    builder.Services.AddDbContext<TaskDbContext>(options =>
        options.UseInMemoryDatabase("TaskFlowDev"));
}
else
{
    // Use PostgreSQL for production and container environments
    connectionString ??= "Host=localhost;Database=taskflowdb;Username=postgres;Password=postgres";
    Log.Information("Using PostgreSQL database with connection: {ConnectionString}", 
        connectionString.Replace("Password=", "Password=***"));
    
    builder.Services.AddDbContext<TaskDbContext>(options =>
        options.UseNpgsql(connectionString));
}

// Register application services
builder.Services.AddScoped<ITaskRepository, TaskRepository>();
builder.Services.AddScoped<ITaskService, TaskService>();

// Configure OpenAPI/Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() 
    { 
        Title = "TaskFlow API", 
        Version = "v1",
        Description = "A modern task management API built with .NET and PostgreSQL"
    });
});

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "TaskFlow API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseHttpsRedirection();
app.UseCors();

app.UseSerilogRequestLogging();

app.MapControllers();

try
{
    Log.Information("Starting TaskFlow API");
    
    // Ensure database is created and seeded (skip in test environment)
    if (!app.Environment.IsEnvironment("Testing"))
    {
        await InitializeDatabaseAsync(app.Services, useInMemory);
    }
    
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

// Database initialization helper
static async Task InitializeDatabaseAsync(IServiceProvider services, bool useInMemory)
{
    using var scope = services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<TaskDbContext>();
    
    if (!useInMemory)
    {
        // Wait for PostgreSQL to be ready in container environments
        var maxRetries = 30;
        var retryCount = 0;
        
        while (retryCount < maxRetries)
        {
            try
            {
                Log.Information("Attempting to connect to database (attempt {Attempt}/{MaxRetries})", 
                    retryCount + 1, maxRetries);
                
                await context.Database.CanConnectAsync();
                Log.Information("Database connection successful");
                break;
            }
            catch (Exception ex)
            {
                retryCount++;
                if (retryCount >= maxRetries)
                {
                    Log.Fatal(ex, "Failed to connect to database after {MaxRetries} attempts", maxRetries);
                    throw;
                }
                
                Log.Warning("Database connection failed (attempt {Attempt}/{MaxRetries}): {Error}. Retrying in 2 seconds...",
                    retryCount, maxRetries, ex.Message);
                
                await Task.Delay(2000);
            }
        }
    }
    
    // Ensure database is created and seed data
    await context.Database.EnsureCreatedAsync();
    await DbSeeder.SeedAsync(context);
    Log.Information("Database initialized and seeded successfully");
}

// Make the implicit Program class accessible to tests
public partial class Program { }