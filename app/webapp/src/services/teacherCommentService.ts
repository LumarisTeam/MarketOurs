import { apiClient } from './apiClient';
import type {
  CreateTeacherCommentRequest,
  TeacherCommentItem,
  TeacherCommentSummary,
} from '../types';

export const teacherCommentService = {
  create: (data: CreateTeacherCommentRequest) =>
    apiClient.post<TeacherCommentItem>('/TeacherComment', data),

  getMine: () =>
    apiClient.get<TeacherCommentItem[]>('/TeacherComment/mine'),

  deleteMine: (key: string) =>
    apiClient.delete<void>(`/TeacherComment/${key}`),

  getByTeacher: (teacherName: string) =>
    apiClient.get<TeacherCommentItem[]>(`/TeacherComment/teacher/${encodeURIComponent(teacherName)}`),

  getSummary: (teacherName: string) => {
    const params = new URLSearchParams({ teacherName });
    return apiClient.get<TeacherCommentSummary>(`/TeacherComment/summary?${params.toString()}`);
  },
};
