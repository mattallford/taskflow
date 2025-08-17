import React from 'react';
import { TaskStatus } from '../types';

interface TaskFiltersProps {
  activeFilter: 'all' | TaskStatus;
  onFilterChange: (filter: 'all' | TaskStatus) => void;
  taskCounts: {
    all: number;
    todo: number;
    inProgress: number;
    done: number;
  };
}

const TaskFilters: React.FC<TaskFiltersProps> = ({
  activeFilter,
  onFilterChange,
  taskCounts,
}) => {
  const filters = [
    { key: 'all' as const, label: 'All Tasks', count: taskCounts.all },
    { key: TaskStatus.Todo, label: 'To Do', count: taskCounts.todo },
    { key: TaskStatus.InProgress, label: 'In Progress', count: taskCounts.inProgress },
    { key: TaskStatus.Done, label: 'Done', count: taskCounts.done },
  ];

  return (
    <div className="task-filters">
      {filters.map(filter => (
        <button
          key={filter.key}
          className={`filter-button ${activeFilter === filter.key ? 'active' : ''}`}
          onClick={() => onFilterChange(filter.key)}
        >
          {filter.label} ({filter.count})
        </button>
      ))}
    </div>
  );
};

export default TaskFilters;