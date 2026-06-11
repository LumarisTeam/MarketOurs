export interface ApiResponse<T = unknown> {
  code: number;
  errorCode: number;
  /** 错误码名称如 "PostNotFound"，方便调试；客户端应基于 errorCode 做程序化判断 */
  errorName: string;
  message: string;
  detail: string | null;
  data: T;
  requestId: string | null;
  timestamp: string | null;
}

export interface PagedResult<T> {
  items: T[];
  totalCount: number;
  pageIndex: number;
  pageSize: number;
  totalPages: number;
  hasPreviousPage: boolean;
  hasNextPage: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  totalCount: number;
  pageIndex: number;
  pageSize: number;
  totalPages: number;
}
