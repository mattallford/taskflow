using System.ComponentModel.DataAnnotations;
using TaskFlow.Core.Models;

namespace TaskFlow.Api.DTOs;

public class UpdateTaskDto
{
    [Required]
    [StringLength(200, MinimumLength = 1)]
    public string Title { get; set; } = string.Empty;
    
    [StringLength(1000)]
    public string? Description { get; set; }
    
    public TaskItemStatus Status { get; set; }
    
    public TaskPriority Priority { get; set; }
    
    public DateTime? DueDate { get; set; }
}