import { AlertCircle, Eye, Flame, Heart, Loader2, RefreshCw } from "lucide-react"
import { useEffect, useEffectEvent, useState } from "react"
import { useTranslation } from "react-i18next"
import { useNavigate } from "react-router"
import { postService } from "../../services/postService"
import type { PostDto } from "../../types"
import { cn } from "../../lib/utils"
import { formatPostRelativeDate, getPostAuthorName, getPostExcerpt } from "../../lib/postDisplay"
import { PostTagBadge } from "../../components/post/PostTagBadge"

export default function HotPage() {
  const { t, i18n } = useTranslation()
  const navigate = useNavigate()
  const [posts, setPosts] = useState<PostDto[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadHotPosts = useEffectEvent(async (isRefresh = false) => {
    if (isRefresh) {
      setRefreshing(true)
    } else {
      setLoading(true)
    }

    setError(null)

    try {
      const response = await postService.getHotPosts(10)
      setPosts(response.data ?? [])
    } catch (err) {
      console.error(err)
      setError(t("hot.fetch_error"))
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  })

  useEffect(() => {
    void loadHotPosts()
  }, [])

  return (
    <div className="mx-auto max-w-4xl space-y-10 pb-24">
      {/* ── Hero ── */}
      <section className="glass-warm overflow-hidden rounded-[2.5rem] p-8 sm:p-10">
        <div className="flex flex-col gap-8 md:flex-row md:items-end md:justify-between">
          <div className="space-y-5">
            {/* Badge */}
            <div className="inline-flex items-center gap-2.5 text-sm font-medium tracking-wide text-amber-600/80 dark:text-amber-400/70">
              <Flame size={15} className="text-amber-500/70" />
              <span className="uppercase tracking-[0.15em]">{t("hot.badge")}</span>
            </div>

            <div className="space-y-3">
              <h1 className="text-4xl font-bold leading-tight tracking-tight text-foreground sm:text-5xl sm:leading-tight">
                {t("hot.title")}
              </h1>
              <p className="max-w-xl text-base leading-relaxed text-muted-foreground/80">
                {t("hot.subtitle")}
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => void loadHotPosts(true)}
            disabled={refreshing}
            className="inline-flex shrink-0 items-center gap-2 self-start rounded-full bg-foreground/10 px-4 py-2.5 text-sm font-medium text-foreground/80 backdrop-blur transition-all duration-300 hover:bg-foreground/15 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {refreshing ? (
              <Loader2 size={15} className="animate-spin" />
            ) : (
              <RefreshCw size={15} />
            )}
            <span>{refreshing ? t("hot.refreshing") : t("hot.refresh")}</span>
          </button>
        </div>
      </section>

      {/* ── Loading ── */}
      {loading ? (
        <div className="flex min-h-80 items-center justify-center rounded-[2.5rem] glass-card">
          <div className="flex items-center gap-3 text-muted-foreground/70">
            <Loader2 size={18} className="animate-spin" />
            <span className="text-sm font-medium">{t("common.loading")}</span>
          </div>
        </div>
      ) : error ? (
        /* ── Error ── */
        <div className="rounded-[2.5rem] glass-card p-10 text-center">
          <div className="mx-auto flex max-w-sm flex-col items-center gap-5">
            <div className="rounded-full bg-destructive/10 p-3 text-destructive/70">
              <AlertCircle size={22} />
            </div>
            <div className="space-y-2">
              <h2 className="text-lg font-semibold text-foreground">{t("hot.error_title")}</h2>
              <p className="text-sm leading-relaxed text-muted-foreground/80">{error}</p>
            </div>
            <button
              type="button"
              onClick={() => void loadHotPosts()}
              className="inline-flex items-center gap-2 rounded-full bg-foreground/10 px-4 py-2.5 text-sm font-medium text-foreground/80 backdrop-blur transition-all duration-300 hover:bg-foreground/15"
            >
              <RefreshCw size={15} />
              {t("hot.retry")}
            </button>
          </div>
        </div>
      ) : posts.length === 0 ? (
        /* ── Empty ── */
        <div className="rounded-[2.5rem] glass-card p-10 text-center">
          <div className="mx-auto max-w-sm space-y-4">
            <p className="text-lg font-semibold text-foreground">{t("hot.empty_title")}</p>
            <p className="text-sm leading-relaxed text-muted-foreground/70">{t("hot.empty_desc")}</p>
          </div>
        </div>
      ) : (
        /* ── Post List ── */
        <div className="space-y-5">
          {posts.map((post, index) => {
            const isTopThree = index < 3
            const authorName = getPostAuthorName(post, t("common.user"))
            const coverImage = post.images?.[0]

            return (
              <article
                key={post.id}
                onClick={() => navigate(`/post/${post.id}`)}
                className={cn(
                  "group cursor-pointer overflow-hidden rounded-4xl transition-all duration-500",
                  "hover:-translate-y-1 hover:shadow-xl hover:shadow-amber-500/5",
                  isTopThree
                    ? "glass-card-warm shadow-md shadow-amber-500/6"
                    : "glass-card"
                )}
              >
                <div className="flex flex-col-reverse sm:flex-row">
                  {/* Content */}
                  <div className="flex min-w-0 flex-1 flex-col p-6 sm:p-8">
                    {/* Meta row: rank + author + date */}
                    <div className="mb-4 flex items-center gap-4">
                      {/* Rank number */}
                      <span
                        className={cn(
                          "flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-sm font-semibold tabular-nums",
                          isTopThree
                            ? "bg-amber-500/12 text-amber-600 dark:bg-amber-400/12 dark:text-amber-400"
                            : "bg-muted text-muted-foreground"
                        )}
                      >
                        {isTopThree
                          ? ["1", "2", "3"][index]
                          : index + 1}
                      </span>

                      <div className="min-w-0 text-sm">
                        <span className="font-medium text-foreground/90">{authorName}</span>
                        <span className="mx-1.5 text-muted-foreground/40">·</span>
                        <span className="text-muted-foreground/60">
                          {formatPostRelativeDate(post.createdAt, i18n, post.updatedAt, t("post.edited"))}
                        </span>
                      </div>

                      {isTopThree && (
                        <span className="ml-auto shrink-0 rounded-full bg-amber-500/8 px-3 py-1 text-xs font-semibold tracking-wide text-amber-600/80 dark:bg-amber-400/8 dark:text-amber-400/70">
                          {t("hot.heat_label")}
                        </span>
                      )}
                    </div>

                    {/* Tag + title + excerpt */}
                    <div className="space-y-3">
                      <PostTagBadge tag={post.tag} />
                      <h2 className="text-xl font-bold leading-snug tracking-tight text-foreground transition-colors duration-300 group-hover:text-amber-600 dark:group-hover:text-amber-400 sm:text-2xl">
                        {post.title}
                      </h2>
                      <p className="line-clamp-3 whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground/75">
                        {getPostExcerpt(post.content, 180)}
                      </p>
                    </div>

                    {/* Stats */}
                    <div className="mt-5 flex items-center gap-5 text-sm text-muted-foreground/60">
                      <span className="inline-flex items-center gap-1.5">
                        <Heart size={14} className="text-rose-400/70" />
                        <span className="font-medium tabular-nums text-foreground/70">{post.likes}</span>
                      </span>
                      <span className="inline-flex items-center gap-1.5">
                        <Eye size={14} className="text-sky-400/70" />
                        <span className="font-medium tabular-nums text-foreground/70">{post.watch}</span>
                      </span>
                    </div>
                  </div>

                  {/* Cover image */}
                  {coverImage ? (
                    <div className="relative shrink-0 p-5 pb-0 sm:w-60 sm:p-4 sm:pl-0">
                      <div className="overflow-hidden rounded-2xl sm:h-full sm:min-h-50">
                        <img
                          src={coverImage}
                          alt={post.title}
                          className="h-48 w-full object-cover transition duration-700 group-hover:scale-[1.05] sm:h-full"
                        />
                      </div>
                    </div>
                  ) : (
                    <div className="shrink-0 p-5 pb-0 sm:w-60 sm:p-4 sm:pl-0">
                      <div className="flex h-48 items-center justify-center rounded-2xl bg-muted/60 sm:h-full sm:min-h-50">
                        <div className="space-y-2 text-center">
                          <Flame size={20} className="mx-auto text-amber-400/50" />
                          <p className="text-xs font-medium text-muted-foreground/50">{t("hot.cover_fallback")}</p>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}
