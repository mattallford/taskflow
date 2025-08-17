using TaskFlow.Core.Interfaces;
using TaskFlow.Core.Models;

namespace TaskFlow.Core.Services;

public class TaskService : ITaskService
{
    private readonly ITaskRepository _taskRepository;

    public TaskService(ITaskRepository taskRepository)
    {
        _taskRepository = taskRepository;
    }

    public async Task<IEnumerable<TaskItem>> GetAllTasksAsync()
    {
        return await _taskRepository.GetAllAsync();
    }

    public async Task<IEnumerable<TaskItem>> GetTasksByStatusAsync(TaskItemStatus status)
    {
        return await _taskRepository.GetByStatusAsync(status);
    }

    public async Task<TaskItem?> GetTaskByIdAsync(Guid id)
    {
        return await _taskRepository.GetByIdAsync(id);
    }

    public async Task<TaskItem> CreateTaskAsync(TaskItem task)
    {
        task.Id = Guid.NewGuid();
        task.CreatedDate = DateTime.UtcNow;
        task.UpdatedDate = DateTime.UtcNow;
        
        // Ensure DueDate is UTC if provided
        if (task.DueDate.HasValue && task.DueDate.Value.Kind != DateTimeKind.Utc)
        {
            task.DueDate = task.DueDate.Value.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(task.DueDate.Value, DateTimeKind.Utc)
                : task.DueDate.Value.ToUniversalTime();
        }
        
        return await _taskRepository.CreateAsync(task);
    }

    public async Task<TaskItem> UpdateTaskAsync(TaskItem task)
    {
        var existingTask = await _taskRepository.GetByIdAsync(task.Id);
        if (existingTask == null)
        {
            throw new InvalidOperationException($"Task with id {task.Id} not found");
        }

        task.UpdatedDate = DateTime.UtcNow;
        
        // Ensure DueDate is UTC if provided
        if (task.DueDate.HasValue && task.DueDate.Value.Kind != DateTimeKind.Utc)
        {
            task.DueDate = task.DueDate.Value.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(task.DueDate.Value, DateTimeKind.Utc)
                : task.DueDate.Value.ToUniversalTime();
        }
        
        return await _taskRepository.UpdateAsync(task);
    }

    public async Task<bool> DeleteTaskAsync(Guid id)
    {
        return await _taskRepository.DeleteAsync(id);
    }
}