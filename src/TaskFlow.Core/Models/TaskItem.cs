namespace TaskFlow.Core.Models;

public class TaskItem
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TaskItemStatus Status { get; set; } = TaskItemStatus.Todo;
    public TaskPriority Priority { get; set; } = TaskPriority.Medium;
    public DateTime CreatedDate { get; set; }
    public DateTime? DueDate { get; set; }
    public DateTime UpdatedDate { get; set; }
}