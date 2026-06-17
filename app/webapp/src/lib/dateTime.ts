import { formatDistanceToNow } from "date-fns"
import { enUS, zhCN } from "date-fns/locale"

const EDITED_THRESHOLD_MS = 5000

type DateInput = string | number | Date

function toDate(input: DateInput): Date | null {
  const date = input instanceof Date ? input : new Date(input)
  return Number.isNaN(date.getTime()) ? null : date
}

function getDateFnsLocale(locale?: string) {
  return locale?.toLowerCase().startsWith("zh") ? zhCN : enUS
}

function formatWithOptions(input: DateInput, locale: string | undefined, options: Intl.DateTimeFormatOptions) {
  const date = toDate(input)
  if (!date) {
    return String(input)
  }

  return new Intl.DateTimeFormat(locale, options).format(date)
}

export function formatLocalDate(input: DateInput, locale?: string) {
  return formatWithOptions(input, locale, {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

export function formatLocalDateTime(
  input: DateInput,
  locale?: string,
  options?: { includeSeconds?: boolean },
) {
  return formatWithOptions(input, locale, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    ...(options?.includeSeconds === false ? {} : { second: "2-digit" }),
  })
}

export function formatShortDate(input: DateInput, locale?: string) {
  return formatWithOptions(input, locale, {
    month: "short",
    day: "numeric",
  })
}

export function formatRelativeTime(input: DateInput, locale?: string) {
  const date = toDate(input)
  if (!date) {
    return String(input)
  }

  const deltaSeconds = Math.round((date.getTime() - Date.now()) / 1000)
  const formatter = new Intl.RelativeTimeFormat(locale, { numeric: "auto" })
  const units: Array<[Intl.RelativeTimeFormatUnit, number]> = [
    ["day", 86400],
    ["hour", 3600],
    ["minute", 60],
  ]

  for (const [unit, secondsPerUnit] of units) {
    if (Math.abs(deltaSeconds) >= secondsPerUnit || unit === "minute") {
      return formatter.format(Math.round(deltaSeconds / secondsPerUnit), unit)
    }
  }

  return formatter.format(deltaSeconds, "second")
}

export function formatRelativeDateFromNow(input: DateInput, locale?: string) {
  const date = toDate(input)
  if (!date) {
    return String(input)
  }

  return formatDistanceToNow(date, {
    addSuffix: true,
    locale: getDateFnsLocale(locale),
  })
}

export function formatEditedRelativeTime(
  createdAt: DateInput,
  locale?: string,
  updatedAt?: DateInput,
  editedLabel?: string,
) {
  const createdDate = toDate(createdAt)
  if (!createdDate) {
    return String(createdAt)
  }

  const display = formatRelativeDateFromNow(createdDate, locale)
  if (!updatedAt || !editedLabel) {
    return display
  }

  const updatedDate = toDate(updatedAt)
  if (!updatedDate) {
    return display
  }

  if (updatedDate.getTime() - createdDate.getTime() > EDITED_THRESHOLD_MS) {
    return `${display} (${editedLabel})`
  }

  return display
}

export function parseCalendarDate(input: string | Date) {
  if (input instanceof Date) {
    return toDate(input)
  }

  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(input)
  if (!match) {
    return toDate(input)
  }

  const [, year, month, day] = match
  return new Date(Number(year), Number(month) - 1, Number(day))
}
