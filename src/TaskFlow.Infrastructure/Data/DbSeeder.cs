using TaskFlow.Core.Models;

namespace TaskFlow.Infrastructure.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(TaskDbContext context)
    {
        // Check if we already have data
        if (context.Tasks.Any())
        {
            return; // Database has been seeded
        }

        var tasks = new List<TaskItem>
        {
            new TaskItem
            {
                Id = Guid.NewGuid(),
                Title = "Set up development environment",
                Description = "Install necessary tools and configure the development workspace",
                Status = TaskItemStatus.Done,
                Priority = TaskPriority.High,
                CreatedDate = DateTime.UtcNow.AddDays(-5),
                UpdatedDate = DateTime.UtcNow.AddDays(-4)
            },
            new TaskItem
            {
                Id = Guid.NewGuid(),
                Title = "Design database schema",
                Description = "Create entity relationship diagrams and design the database structure",
                Status = TaskItemStatus.Done,
                Priority = TaskPriority.High,
                CreatedDate = DateTime.UtcNow.AddDays(-4),
                UpdatedDate = DateTime.UtcNow.AddDays(-3)
            },
            new TaskItem
            {
                Id = Guid.NewGuid(),
                Title = "Implement API endpoints",
                Description = "Create REST API endpoints for CRUD operations on tasks",
                Status = TaskItemStatus.InProgress,
                Priority = TaskPriority.High,
                CreatedDate = DateTime.UtcNow.AddDays(-3),
                UpdatedDate = DateTime.UtcNow.AddDays(-1),
                DueDate = DateTime.UtcNow.AddDays(2)
            },
            new TaskItem
            {
                Id = Guid.NewGuid(),
                Title = "Write unit tests",
                Description = "Create comprehensive unit tests for all business logic",
                Status = TaskItemStatus.Todo,
                Priority = TaskPriority.Medium,
                CreatedDate = DateTime.UtcNow.AddDays(-2),
                UpdatedDate = DateTime.UtcNow.AddDays(-2),
                DueDate = DateTime.UtcNow.AddDays(5)
            },
            new TaskItem
            {
                Id = Guid.NewGuid(),
                Title = "Set up CI/CD pipeline",
                Description = "Configure automated build and deployment pipeline",
                Status = TaskItemStatus.Todo,
                Priority = TaskPriority.Medium,
                CreatedDate = DateTime.UtcNow.AddDays(-1),
                UpdatedDate = DateTime.UtcNow.AddDays(-1),
                DueDate = DateTime.UtcNow.AddDays(7)
            },
            new TaskItem
            {
                Id = Guid.NewGuid(),
                Title = "Create documentation",
                Description = "Write API documentation and user guides",
                Status = TaskItemStatus.Todo,
                Priority = TaskPriority.Low,
                CreatedDate = DateTime.UtcNow,
                UpdatedDate = DateTime.UtcNow,
                DueDate = DateTime.UtcNow.AddDays(10)
            }
        };

        context.Tasks.AddRange(tasks);
        await context.SaveChangesAsync();
    }
}