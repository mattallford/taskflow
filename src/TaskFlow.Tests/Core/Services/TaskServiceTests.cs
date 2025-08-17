using Microsoft.EntityFrameworkCore;
using TaskFlow.Core.Models;
using TaskFlow.Core.Services;
using TaskFlow.Infrastructure.Data;
using TaskFlow.Infrastructure.Repositories;

namespace TaskFlow.Tests.Core.Services;

public class TaskServiceTests
{
    private TaskDbContext GetInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<TaskDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        
        return new TaskDbContext(options);
    }

    [Fact]
    public async Task CreateTaskAsync_ShouldCreateTask_WithValidData()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var repository = new TaskRepository(context);
        var service = new TaskService(repository);
        
        var task = new TaskItem
        {
            Title = "Test Task",
            Description = "Test Description",
            Status = TaskItemStatus.Todo,
            Priority = TaskPriority.Medium
        };

        // Act
        var result = await service.CreateTaskAsync(task);

        // Assert
        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("Test Task", result.Title);
        Assert.Equal("Test Description", result.Description);
        Assert.Equal(TaskItemStatus.Todo, result.Status);
        Assert.Equal(TaskPriority.Medium, result.Priority);
        Assert.True(result.CreatedDate > DateTime.MinValue);
        Assert.True(result.UpdatedDate > DateTime.MinValue);
    }

    [Fact]
    public async Task GetTaskByIdAsync_ShouldReturnTask_WhenTaskExists()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var repository = new TaskRepository(context);
        var service = new TaskService(repository);
        
        var task = new TaskItem
        {
            Title = "Test Task",
            Description = "Test Description",
            Status = TaskItemStatus.Todo,
            Priority = TaskPriority.High
        };

        var createdTask = await service.CreateTaskAsync(task);

        // Act
        var result = await service.GetTaskByIdAsync(createdTask.Id);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(createdTask.Id, result.Id);
        Assert.Equal("Test Task", result.Title);
    }

    [Fact]
    public async Task GetTaskByIdAsync_ShouldReturnNull_WhenTaskDoesNotExist()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var repository = new TaskRepository(context);
        var service = new TaskService(repository);

        // Act
        var result = await service.GetTaskByIdAsync(Guid.NewGuid());

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public async Task UpdateTaskAsync_ShouldUpdateTask_WhenTaskExists()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var repository = new TaskRepository(context);
        var service = new TaskService(repository);
        
        var task = new TaskItem
        {
            Title = "Original Task",
            Description = "Original Description",
            Status = TaskItemStatus.Todo,
            Priority = TaskPriority.Low
        };

        var createdTask = await service.CreateTaskAsync(task);
        var originalUpdateTime = createdTask.UpdatedDate;

        // Wait a bit to ensure UpdatedDate changes
        await Task.Delay(10);

        // Act
        createdTask.Title = "Updated Task";
        createdTask.Status = TaskItemStatus.InProgress;
        var result = await service.UpdateTaskAsync(createdTask);

        // Assert
        Assert.Equal("Updated Task", result.Title);
        Assert.Equal(TaskItemStatus.InProgress, result.Status);
        Assert.True(result.UpdatedDate > originalUpdateTime);
    }

    [Fact]
    public async Task DeleteTaskAsync_ShouldDeleteTask_WhenTaskExists()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var repository = new TaskRepository(context);
        var service = new TaskService(repository);
        
        var task = new TaskItem
        {
            Title = "Task to Delete",
            Description = "This task will be deleted",
            Status = TaskItemStatus.Todo,
            Priority = TaskPriority.Medium
        };

        var createdTask = await service.CreateTaskAsync(task);

        // Act
        var deleteResult = await service.DeleteTaskAsync(createdTask.Id);
        var getResult = await service.GetTaskByIdAsync(createdTask.Id);

        // Assert
        Assert.True(deleteResult);
        Assert.Null(getResult);
    }
}