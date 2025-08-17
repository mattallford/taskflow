import React, { useState, useEffect } from 'react';
import { Task, TaskStatus, CreateTaskRequest } from './types';
import { taskApi, ApiError } from './services/api';
import TaskList from './components/TaskList';
import TaskForm from './components/TaskForm';
import TaskFilters from './components/TaskFilters';
import ErrorMessage from './components/ErrorMessage';
import LoadingSpinner from './components/LoadingSpinner';
import './styles/index.css';

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [filteredTasks, setFilteredTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeFilter, setActiveFilter] = useState<'all' | TaskStatus>('all');
  const [showAddForm, setShowAddForm] = useState(false);

  // Load tasks on component mount
  useEffect(() => {
    loadTasks();
  }, []);

  // Filter tasks when tasks or active filter changes
  useEffect(() => {
    if (activeFilter === 'all') {
      setFilteredTasks(tasks);
    } else {
      setFilteredTasks(tasks.filter(task => task.status === activeFilter));
    }
  }, [tasks, activeFilter]);

  const loadTasks = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await taskApi.getTasks();
      setTasks(data);
    } catch (err) {
      if (err instanceof ApiError) {
        setError(`Failed to load tasks: ${err.message}`);
      } else {
        setError('Failed to load tasks. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleCreateTask = async (taskData: CreateTaskRequest) => {
    try {
      setError(null);
      const newTask = await taskApi.createTask(taskData);
      setTasks(prev => [newTask, ...prev]);
      setShowAddForm(false);
    } catch (err) {
      if (err instanceof ApiError) {
        setError(`Failed to create task: ${err.message}`);
      } else {
        setError('Failed to create task. Please try again.');
      }
    }
  };

  const handleUpdateTask = async (id: string, taskData: Partial<Task>) => {
    try {
      setError(null);
      const updatedTask = await taskApi.updateTask(id, {
        title: taskData.title!,
        description: taskData.description!,
        status: taskData.status!,
        priority: taskData.priority!,
        dueDate: taskData.dueDate
      });
      setTasks(prev => prev.map(task => task.id === id ? updatedTask : task));
    } catch (err) {
      if (err instanceof ApiError) {
        setError(`Failed to update task: ${err.message}`);
      } else {
        setError('Failed to update task. Please try again.');
      }
    }
  };

  const handleDeleteTask = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this task?')) {
      return;
    }

    try {
      setError(null);
      await taskApi.deleteTask(id);
      setTasks(prev => prev.filter(task => task.id !== id));
    } catch (err) {
      if (err instanceof ApiError) {
        setError(`Failed to delete task: ${err.message}`);
      } else {
        setError('Failed to delete task. Please try again.');
      }
    }
  };

  const handleStatusChange = async (id: string, status: TaskStatus) => {
    const task = tasks.find(t => t.id === id);
    if (!task) return;

    await handleUpdateTask(id, { ...task, status });
  };

  return (
    <div className="app">
      <header className="header">
        <h1>TaskFlow</h1>
        <p>Modern task management for productive teams</p>
      </header>

      <main className="main">
        {error && <ErrorMessage message={error} onDismiss={() => setError(null)} />}
        
        <TaskFilters 
          activeFilter={activeFilter}
          onFilterChange={setActiveFilter}
          taskCounts={{
            all: tasks.length,
            todo: tasks.filter(t => t.status === TaskStatus.Todo).length,
            inProgress: tasks.filter(t => t.status === TaskStatus.InProgress).length,
            done: tasks.filter(t => t.status === TaskStatus.Done).length,
          }}
        />

        <div className="add-task-section">
          {!showAddForm ? (
            <div>
              <h2>Add New Task</h2>
              <button 
                className="btn btn-primary"
                onClick={() => setShowAddForm(true)}
              >
                + Create Task
              </button>
            </div>
          ) : (
            <div>
              <h2>Create New Task</h2>
              <TaskForm
                onSubmit={handleCreateTask}
                onCancel={() => setShowAddForm(false)}
              />
            </div>
          )}
        </div>

        {loading ? (
          <LoadingSpinner />
        ) : (
          <TaskList
            tasks={filteredTasks}
            onUpdateTask={handleUpdateTask}
            onDeleteTask={handleDeleteTask}
            onStatusChange={handleStatusChange}
          />
        )}
      </main>
    </div>
  );
}

export default App;