import { apiClient } from './apiClient';
import type {
  CreateTeacherCommentRequest,
  PagedResult,
  TeacherCommentItem,
  TeacherCommentSummary,
  UpdateTeacherCommentRequest,
} from '../types';

export const teacherCommentService = {
  create: (data: CreateTeacherCommentRequest) =>
    apiClient.post<TeacherCommentItem>('/TeacherComment', data),

  update: (key: string, data: UpdateTeacherCommentRequest) =>
    apiClient.put<TeacherCommentItem>(`/TeacherComment/${key}`, data),

  getByUser: (userId: string) =>
    apiClient.get<TeacherCommentItem[]>(`/TeacherComment/user/${encodeURIComponent(userId)}`),

  deleteMine: (key: string) =>
    apiClient.delete<void>(`/TeacherComment/${key}`),

  searchApproved: (keyword?: string, page = 1, pageSize = 20) => {
    const params = new URLSearchParams({
      page: String(page),
      pageSize: String(pageSize),
    });
    if (keyword?.trim()) params.append('keyword', keyword.trim());
    return apiClient.get<PagedResult<TeacherCommentItem>>(`/TeacherComment/search?${params.toString()}`);
  },

  getByTeacher: (teacherName: string) =>
    apiClient.get<TeacherCommentItem[]>(`/TeacherComment/teacher/${encodeURIComponent(teacherName)}`),

  getSummary: (teacherName: string) => {
    const params = new URLSearchParams({ teacherName });
    return apiClient.get<TeacherCommentSummary>(`/TeacherComment/summary?${params.toString()}`);
  },
};
