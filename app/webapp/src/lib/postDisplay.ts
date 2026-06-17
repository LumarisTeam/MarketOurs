import type { i18n } from "i18next"
import type { PostDto } from "../types"
import { formatEditedRelativeTime } from "./dateTime"

export function formatPostRelativeDate(
  dateString: string,
  i18nInstance: i18n,
  updatedAtString?: string,
  editedLabel?: string,
) {
  return formatEditedRelativeTime(dateString, i18nInstance.resolvedLanguage, updatedAtString, editedLabel)
}

export function getPostExcerpt(content: string, maxLength = 150) {
  if (content.length <= maxLength) {
    return content
  }

  return `${content.slice(0, maxLength)}...`
}

export function getPostAuthorName(post: PostDto, fallbackUserLabel: string) {
  return post.author?.name || `${fallbackUserLabel} ${post.userId.slice(0, 4)}`
}
