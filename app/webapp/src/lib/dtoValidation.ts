export const DTO_LIMITS = {
  postTitleMax: 128,
  postContentMax: 1024,
  commentContentMax: 512,
  userAccountMax: 128,
  userPasswordMin: 6,
  userPasswordMax: 128,
  userNameMax: 128,
  userAvatarMax: 128,
  userEmailMax: 128,
  userPhoneMax: 32,
  userInfoMax: 1024,
} as const;

export function requiredMax(value: string, max: number, emptyMessage: string, maxMessage: string) {
  const text = value.trim();
  if (!text) return emptyMessage;
  if (text.length > max) return maxMessage;
  return null;
}

export function optionalMax(value: string | null | undefined, max: number, maxMessage: string) {
  if ((value ?? "").trim().length > max) return maxMessage;
  return null;
}

export function passwordLength(value: string, emptyMessage: string, minMessage: string, maxMessage: string) {
  if (!value) return emptyMessage;
  if (value.length < DTO_LIMITS.userPasswordMin) return minMessage;
  if (value.length > DTO_LIMITS.userPasswordMax) return maxMessage;
  return null;
}
