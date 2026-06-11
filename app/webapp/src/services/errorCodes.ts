const errorCodeMessages: Record<number, string> = {
  0: '操作成功',

  1000: '参数不能为空',
  1001: '参数格式不正确',
  1002: '参数超出允许范围',
  1003: '参数验证失败',

  2000: '资源已存在',
  2001: '操作失败',
  2002: '数据处理失败',
  2003: '当前状态不允许执行此操作',

  3000: '请先登录',
  3001: '权限不足',
  3002: '登录已过期，请重新登录',
  3003: '令牌无效',
  3004: '令牌已过期',
  3005: '不支持的第三方登录方式',

  4000: '资源不存在',

  4100: '用户不存在',
  4101: '账号已被禁用',
  4102: '该账号已被注册',
  4103: '密码错误',

  4200: '帖子不存在',
  4201: '帖子创建失败',
  4202: '帖子更新失败',
  4203: '无权删除该帖子',

  4300: '评论不存在',
  4301: '父评论不存在',
  4302: '评论创建失败',
  4303: '评论更新失败',
  4304: '无权删除该评论',

  5000: '服务器内部错误，请稍后重试',
  5001: '数据库操作失败',
  5002: '缓存服务异常，请稍后重试',
  5003: '网络连接异常，请检查网络',

  6000: '外部服务调用失败',
  6001: '外部服务响应超时',
  6002: '外部服务返回错误',
  6003: '外部服务未配置',

  7000: '操作过于频繁，请稍后重试',
  7001: '无效请求',
};

const DEFAULT_ERROR_MESSAGE = '操作失败，请稍后重试';

export function getErrorMessage(errorCode?: number | null, fallback?: string | null): string {
  if (errorCode != null && errorCode !== 0 && errorCodeMessages[errorCode]) {
    return errorCodeMessages[errorCode];
  }
  if (fallback && fallback.trim()) {
    return fallback.trim();
  }
  return DEFAULT_ERROR_MESSAGE;
}

export function extractUserMessage(err: unknown, fallback?: string): string {
  if (err && typeof err === 'object' && 'userMessage' in err) {
    return (err as { userMessage: string }).userMessage;
  }
  if (err && typeof err === 'object' && 'errorCode' in err) {
    const code = (err as { errorCode: number }).errorCode;
    const msg = (err as { message?: string }).message;
    return getErrorMessage(code, msg);
  }
  if (err && typeof err === 'object' && 'message' in err) {
    return (err as { message: string }).message || fallback || DEFAULT_ERROR_MESSAGE;
  }
  if (typeof err === 'string') {
    return err || fallback || DEFAULT_ERROR_MESSAGE;
  }
  return fallback || DEFAULT_ERROR_MESSAGE;
}
