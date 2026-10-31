import { Link } from "react-router"
import { useTranslation } from "react-i18next"
import { cn } from "@/lib/utils"
import type { PostDto } from "@/types"
import { formatPostRelativeDate, getPostAuthorName, getPostExcerpt } from "@/lib/postDisplay"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { OptimizedImage } from "@/components/ui/optimized-image"
import { PostTagBadge } from "@/components/post/PostTagBadge"

/**
 * 列表栏中的紧凑行：非虚拟化，一屏放得下 10 条左右。
 * 选中态 = bg-muted + 2px 主色左条。
 */
export function CompactPostRow({
  post,
  selected,
  rank,
  trailing,
}: {
  post: PostDto
  selected: boolean
  rank?: number
  trailing?: React.ReactNode
}) {
  const { t, i18n } = useTranslation()
  const authorName = getPostAuthorName(post, t("common.user"))
  const authorInitials = authorName.slice(0, 2).toUpperCase()
  const authorAvatar =
    post.author?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${post.userId}`
  const excerpt = post.content.trim() ? getPostExcerpt(post.content.trim(), 60) : ""
  const thumbnail = post.images?.[0]

  return (
    <Link
      to={`/post/${post.id}`}
      aria-current={selected ? "page" : undefined}
      className={cn(
        "relative flex gap-3 border-b border-border/30 px-4 py-1.5 transition-colors",
        selected ? "bg-muted" : "hover:bg-muted/50",
      )}
    >
      {selected && (
        <span aria-hidden className="absolute inset-y-2 left-0 w-0.5 rounded-full bg-primary" />
      )}

      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <div className="flex min-w-0 items-center gap-2">
          {typeof rank === "number" ? (
            <span
              className={cn(
                "flex h-4 w-4 shrink-0 items-center justify-center rounded-md text-[10px] font-semibold tabular-nums",
                rank <= 3 ? "bg-primary/10 text-primary" : "bg-muted text-muted-foreground",
              )}
            >
              {rank}
            </span>
          ) : (
            <Avatar className="h-6 w-6 rounded-full">
              <AvatarImage src={authorAvatar} alt={authorName} />
              <AvatarFallback className="text-[9px]">{authorInitials}</AvatarFallback>
            </Avatar>
          )}
          <span className="min-w-0 truncate text-xs text-muted-foreground">{authorName}</span>
          <span className="ml-auto shrink-0 text-[11px] tabular-nums text-muted-foreground/70">
            {trailing ?? formatPostRelativeDate(post.createdAt, i18n, post.updatedAt, t("post.edited"))}
          </span>
        </div>

        <p className="line-clamp-1 text-[13px] font-medium leading-snug text-foreground">
          {post.title}
        </p>

        {(post.tag || excerpt) && (
          <div className="flex min-w-0 items-center gap-1.5">
            {post.tag && (
              <span className="flex shrink-0 [&>span]:px-1.5 [&>span]:py-0 [&>span]:text-[10px] [&>span]:leading-4">
                <PostTagBadge tag={post.tag} clickable={false} />
              </span>
            )}
            {excerpt && (
              <p className="min-w-0 flex-1 truncate text-[11px] leading-4 text-muted-foreground/80">
                {excerpt}
              </p>
            )}
          </div>
        )}
      </div>

      {thumbnail && (
        <OptimizedImage
          src={thumbnail}
          alt={post.title}
          className="h-11 w-11 shrink-0 self-center rounded-lg bg-muted object-cover"
        />
      )}
    </Link>
  )
}
