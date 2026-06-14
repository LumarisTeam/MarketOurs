import type { PostTagDto } from "../../types"
import { Link } from "react-router"

export function PostTagBadge({
  tag,
  fallback,
  clickable = true,
}: {
  tag?: PostTagDto | null
  fallback?: string
  clickable?: boolean
}) {
  if (!tag) return null

  const className = "inline-flex w-fit items-center rounded-full border border-primary/15 bg-primary/8 px-2.5 py-1 text-xs font-bold text-primary transition-colors"
  const label = tag.name || fallback

  if (!clickable) {
    return (
      <span className={className}>
        {label}
      </span>
    )
  }

  return (
    <Link
      to={`/tag/${tag.id}`}
      onClick={(event) => event.stopPropagation()}
      className={`${className} hover:border-primary/30 hover:bg-primary/12`}
    >
      {label}
    </Link>
  )
}
