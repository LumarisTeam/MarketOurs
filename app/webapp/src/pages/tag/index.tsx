import { useEffect, useState } from "react"
import { Link, useParams } from "react-router"
import { Loader2, Tag as TagIcon } from "lucide-react"
import { useTranslation } from "react-i18next"
import { postService } from "../../services/postService"
import type { PostTagDto } from "../../types"
import { extractUserMessage } from "../../services/errorCodes"
import { PostFeed, BackLink } from "../../components/post/PostFeed"
import { PostTagBadge } from "../../components/post/PostTagBadge"

export default function TagPage() {
  const { id } = useParams()
  const { t } = useTranslation()
  const [tag, setTag] = useState<PostTagDto | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!id) {
      setError(t("tag.not_found"))
      setLoading(false)
      return
    }

    let cancelled = false

    const loadTag = async () => {
      setLoading(true)
      setError(null)
      try {
        const response = await postService.getPostTag(id)
        if (!cancelled) {
          setTag(response.data ?? null)
        }
      } catch (err) {
        if (!cancelled) {
          setError(extractUserMessage(err, t("tag.not_found")))
          setTag(null)
        }
      } finally {
        if (!cancelled) {
          setLoading(false)
        }
      }
    }

    void loadTag()

    return () => {
      cancelled = true
    }
  }, [id, t])

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Loader2 className="animate-spin text-primary" size={40} />
      </div>
    )
  }

  if (error || !tag || !id) {
    return (
      <div className="mx-auto flex min-h-[60vh] max-w-2xl flex-col items-center justify-center gap-4 px-4 text-center">
        <div className="rounded-full bg-destructive/10 p-4 text-destructive">
          <TagIcon size={24} />
        </div>
        <h1 className="text-2xl font-bold">{t("tag.not_found_title")}</h1>
        <p className="text-muted-foreground">{error ?? t("tag.not_found")}</p>
        <Link
          to="/"
          className="inline-flex items-center gap-2 rounded-2xl bg-primary px-5 py-3 font-semibold text-primary-foreground transition-opacity hover:opacity-90"
        >
          {t("post.back_to_feed")}
        </Link>
      </div>
    )
  }

  return (
    <PostFeed
      tagId={id}
      searchPlaceholder={t("tag.search_placeholder", { name: tag.name })}
      emptyMessage={t("tag.empty_posts", { name: tag.name })}
      header={(
        <section className="space-y-5 rounded-[2rem] border border-border/50 bg-card p-6 shadow-sm">
          <BackLink to="/" label={t("tag.back_to_feed")} />
          <div className="space-y-3">
            <PostTagBadge tag={tag} clickable={false} />
            <div className="space-y-2">
              <h1 className="text-3xl font-black tracking-tight">{t("tag.title", { name: tag.name })}</h1>
              <p className="text-sm leading-6 text-muted-foreground">
                {tag.isActive ? t("tag.subtitle") : t("tag.inactive_subtitle")}
              </p>
            </div>
          </div>
        </section>
      )}
    />
  )
}
