import { apiClient } from "./apiClient"

export type ReportTargetType = 0 | 1 | 2
export type ReportReason = 0 | 1 | 2 | 3 | 4

export const reportService = {
  create: (data: { targetType: ReportTargetType; targetId: string; reason: ReportReason; description?: string }) =>
    apiClient.post("/Report", data),
}
