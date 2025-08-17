import { Task, CreateTaskRequest, UpdateTaskRequest, HealthResponse } from '../types';

// Use relative URLs that match nginx ingress paths
// No environment variables needed - works with nginx ingress routing
class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

async function fetchWithErrorHandling<T>(url: string, options?: RequestInit): Promise<T> {
  try {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      ...options,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new ApiError(response.status, errorText || `HTTP ${response.status}`);
    }

    // Handle empty responses (like DELETE)
    if (response.status === 204 || response.headers.get('content-length') === '0') {
      return {} as T;
    }

    return await response.json();
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    // Network or other fetch errors
    throw new ApiError(0, `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

export const taskApi = {
  async getTasks(status?: number): Promise<Task[]> {
    const url = status !== undefined 
      ? `/api/tasks?status=${status}`
      : `/api/tasks`;
    return fetchWithErrorHandling<Task[]>(url);
  },

  async getTask(id: string): Promise<Task> {
    return fetchWithErrorHandling<Task>(`/api/tasks/${id}`);
  },

  async createTask(task: CreateTaskRequest): Promise<Task> {
    return fetchWithErrorHandling<Task>(`/api/tasks`, {
      method: 'POST',
      body: JSON.stringify(task),
    });
  },

  async updateTask(id: string, task: UpdateTaskRequest): Promise<Task> {
    return fetchWithErrorHandling<Task>(`/api/tasks/${id}`, {
      method: 'PUT',
      body: JSON.stringify(task),
    });
  },

  async deleteTask(id: string): Promise<void> {
    return fetchWithErrorHandling<void>(`/api/tasks/${id}`, {
      method: 'DELETE',
    });
  },

  async getHealth(): Promise<HealthResponse> {
    return fetchWithErrorHandling<HealthResponse>(`/health`);
  }
};

export { ApiError };