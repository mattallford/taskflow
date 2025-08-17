import React, { useState } from 'react';
import { Task, TaskStatus, TaskPriority } from '../types';
import TaskForm from './TaskForm';

interface TaskItemProps {
  task: Task;
  onUpdate: (id: string, task: Partial<Task>) => void;
  onDelete: (id: string) => void;
  onStatusChange: (id: string, status: TaskStatus) => void;
}

const TaskItem: React.FC<TaskItemProps> = ({
  task,
  onUpdate,
  onDelete,
  onStatusChange,
}) => {
  const [isEditing, setIsEditing] = useState(false);

  const getStatusClass = (status: TaskStatus) => {
    switch (status) {
      case TaskStatus.Todo:
        return 'status-todo';
      case TaskStatus.InProgress:
        return 'status-inprogress';
      case TaskStatus.Done:
        return 'status-done';
      default:
        return 'status-todo';
    }
  };

  const getStatusText = (status: TaskStatus) => {
    switch (status) {
      case TaskStatus.Todo:
        return 'To Do';
      case TaskStatus.InProgress:
        return 'In Progress';
      case TaskStatus.Done:
        return 'Done';
      default:
        return 'To Do';
    }
  };

  const getPriorityClass = (priority: TaskPriority) => {
    switch (priority) {
      case TaskPriority.Low:
        return 'priority-low';
      case TaskPriority.Medium:
        return 'priority-medium';
      case TaskPriority.High:
        return 'priority-high';
      default:
        return 'priority-low';
    }
  };

  const getPriorityText = (priority: TaskPriority) => {
    switch (priority) {
      case TaskPriority.Low:
        return 'Low';
      case TaskPriority.Medium:
        return 'Medium';
      case TaskPriority.High:
        return 'High';
      default:
        return 'Low';
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString();
  };

  const handleStatusNext = () => {
    const nextStatus = task.status === TaskStatus.Todo 
      ? TaskStatus.InProgress
      : task.status === TaskStatus.InProgress
      ? TaskStatus.Done
      : TaskStatus.Todo;
    
    onStatusChange(task.id, nextStatus);
  };

  const handleEdit = (updatedTask: Partial<Task>) => {
    onUpdate(task.id, updatedTask);
    setIsEditing(false);
  };

  if (isEditing) {
    return (
      <div className="task-item">
        <TaskForm
          initialData={task}
          onSubmit={handleEdit}
          onCancel={() => setIsEditing(false)}
          isEditing
        />
      </div>
    );
  }

  return (
    <div className="task-item">
      <div className="task-header">
        <h3 className="task-title">{task.title}</h3>
        <div className="task-meta">
          <span className={`status-badge ${getStatusClass(task.status)}`}>
            {getStatusText(task.status)}
          </span>
          <div 
            className={`priority-indicator ${getPriorityClass(task.priority)}`}
            title={`${getPriorityText(task.priority)} Priority`}
          />
        </div>
      </div>

      {task.description && (
        <p className="task-description">{task.description}</p>
      )}

      <div className="task-dates">
        <span>Created: {formatDate(task.createdDate)}</span>
        {task.dueDate && (
          <span>Due: {formatDate(task.dueDate)}</span>
        )}
      </div>

      <div className="task-actions">
        <button
          className="btn btn-secondary btn-small"
          onClick={handleStatusNext}
        >
          {task.status === TaskStatus.Todo && 'Start Progress'}
          {task.status === TaskStatus.InProgress && 'Mark Done'}
          {task.status === TaskStatus.Done && 'Reset to Todo'}
        </button>
        <button
          className="btn btn-secondary btn-small"
          onClick={() => setIsEditing(true)}
        >
          Edit
        </button>
        <button
          className="btn btn-danger btn-small"
          onClick={() => onDelete(task.id)}
        >
          Delete
        </button>
      </div>
    </div>
  );
};

export default TaskItem;