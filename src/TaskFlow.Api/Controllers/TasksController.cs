using Microsoft.AspNetCore.Mvc;
using TaskFlow.Api.DTOs;
using TaskFlow.Core.Interfaces;
using TaskFlow.Core.Models;

namespace TaskFlow.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly ITaskService _taskService;
    private readonly ILogger<TasksController> _logger;

    public TasksController(ITaskService taskService, ILogger<TasksController> logger)
    {
        _taskService = taskService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TaskDto>>> GetTasks([FromQuery] TaskItemStatus? status = null)
    {
        try
        {
            var tasks = status.HasValue 
                ? await _taskService.GetTasksByStatusAsync(status.Value)
                : await _taskService.GetAllTasksAsync();

            var taskDtos = tasks.Select(MapToDto);
            
            _logger.LogInformation("Retrieved {Count} tasks", taskDtos.Count());
            return Ok(taskDtos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving tasks");
            return StatusCode(500, "An error occurred while retrieving tasks");
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TaskDto>> GetTask(Guid id)
    {
        try
        {
            var task = await _taskService.GetTaskByIdAsync(id);
            
            if (task == null)
            {
                _logger.LogWarning("Task with ID {TaskId} not found", id);
                return NotFound($"Task with ID {id} not found");
            }

            _logger.LogInformation("Retrieved task with ID {TaskId}", id);
            return Ok(MapToDto(task));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving task with ID {TaskId}", id);
            return StatusCode(500, "An error occurred while retrieving the task");
        }
    }

    [HttpPost]
    public async Task<ActionResult<TaskDto>> CreateTask(CreateTaskDto createTaskDto)
    {
        try
        {
            var task = new TaskItem
            {
                Title = createTaskDto.Title,
                Description = createTaskDto.Description,
                Status = createTaskDto.Status,
                Priority = createTaskDto.Priority,
                DueDate = createTaskDto.DueDate
            };

            var createdTask = await _taskService.CreateTaskAsync(task);
            var taskDto = MapToDto(createdTask);

            _logger.LogInformation("Created task with ID {TaskId}", createdTask.Id);
            return CreatedAtAction(nameof(GetTask), new { id = createdTask.Id }, taskDto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating task");
            return StatusCode(500, "An error occurred while creating the task");
        }
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<TaskDto>> UpdateTask(Guid id, UpdateTaskDto updateTaskDto)
    {
        try
        {
            var existingTask = await _taskService.GetTaskByIdAsync(id);
            if (existingTask == null)
            {
                _logger.LogWarning("Task with ID {TaskId} not found for update", id);
                return NotFound($"Task with ID {id} not found");
            }

            existingTask.Title = updateTaskDto.Title;
            existingTask.Description = updateTaskDto.Description;
            existingTask.Status = updateTaskDto.Status;
            existingTask.Priority = updateTaskDto.Priority;
            existingTask.DueDate = updateTaskDto.DueDate;

            var updatedTask = await _taskService.UpdateTaskAsync(existingTask);
            var taskDto = MapToDto(updatedTask);

            _logger.LogInformation("Updated task with ID {TaskId}", id);
            return Ok(taskDto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating task with ID {TaskId}", id);
            return StatusCode(500, "An error occurred while updating the task");
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteTask(Guid id)
    {
        try
        {
            var deleted = await _taskService.DeleteTaskAsync(id);
            
            if (!deleted)
            {
                _logger.LogWarning("Task with ID {TaskId} not found for deletion", id);
                return NotFound($"Task with ID {id} not found");
            }

            _logger.LogInformation("Deleted task with ID {TaskId}", id);
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting task with ID {TaskId}", id);
            return StatusCode(500, "An error occurred while deleting the task");
        }
    }

    private static TaskDto MapToDto(TaskItem task)
    {
        return new TaskDto
        {
            Id = task.Id,
            Title = task.Title,
            Description = task.Description,
            Status = task.Status,
            Priority = task.Priority,
            CreatedDate = task.CreatedDate,
            DueDate = task.DueDate,
            UpdatedDate = task.UpdatedDate
        };
    }
}