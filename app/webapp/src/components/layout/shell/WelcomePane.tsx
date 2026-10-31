import { useEffect, useState } from "react"
import { Link } from "react-router"
import { useTranslation } from "react-i18next"
import { useSelector } from "react-redux"
import {
  ArrowRight,
  Bell,
  Flame,
  GraduationCap,
  LogIn,
  PlusSquare,
  Sparkles,
  UserPlus,
  type LucideIcon,
} from "lucide-react"
import type { RootState } from "@/stores"
import { postService } from "@/services/postService"
import type { PostDto } from "@/types"
import { cn } from "@/lib/utils"
import { Skeleton } from "@/components/ui/skeleton"

interface WelcomePaneProps {
  /** 标签页进入时展示标签上下文（可选） */
  tag?: { name: string; isActive?: boolean }
}

export function WelcomePane({ tag }: WelcomePaneProps) {
  const { t } = useTranslation()
  const { isAuthenticated } = useSelector((state: RootState) => state.auth)
  const [hotPosts, setHotPosts] = useState<PostDto[]>([])
  const [loadingHot, setLoadingHot] = useState(true)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      try {
        const response = await postService.getHotPosts(5)
        if (!cancelled) setHotPosts(response.data ?? [])
      } catch (error) {
        // 静默降级：热榜加载失败不影响欢迎页
        console.error(error)
      } finally {
        if (!cancelled) setLoadingHot(false)
      }
    }

    void load()

    return () => {
      cancelled = true
    }
  }, [])

  const shortcuts: { href: string; label: string; icon: LucideIcon }[] = [
    { href: "/hot", label: t("shell.welcome_quick_hot"), icon: Flame },
    { href: "/teacher-comments", label: t("shell.welcome_quick_teacher"), icon: GraduationCap },
    isAuthenticated
      ? { href: "/post/create", label: t("shell.welcome_quick_create"), icon: PlusSquare }
      : { href: "/login", label: t("shell.welcome_quick_login"), icon: LogIn },
    isAuthenticated
      ? { href: "/notifications", label: t("shell.welcome_quick_notifications"), icon: Bell }
      : { href: "/register", label: t("shell.welcome_quick_register"), icon: UserPlus },
  ]

  const title = tag ? t("tag.title", { name: tag.name }) : t("shell.welcome_title")
  const subtitle = tag
    ? tag.isActive === false
      ? t("tag.inactive_subtitle")
      : t("tag.subtitle")
    : t("shell.welcome_subtitle")

  return (
    <div className="space-y-6 pb-16">
      <section className="glass-card relative overflow-hidden rounded-[2.5rem] px-6 py-10 text-center sm:px-10 sm:py-12">
        <div className="pointer-events-none absolute -top-24 left-1/2 h-48 w-48 -translate-x-1/2 rounded-full bg-primary/10 blur-3xl" />
        <div className="relative">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-primary shadow-lg shadow-primary/20">
            <Sparkles size={24} className="text-primary-foreground" />
          </div>
          <p className="mt-5 text-[11px] font-semibold uppercase tracking-[0.22em] text-primary/80">
            {t("shell.welcome_eyebrow")}
          </p>
          <h1 className="mt-3 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            {title}
          </h1>
          <p className="mx-auto mt-4 max-w-md text-sm font-medium leading-relaxed text-foreground/80">
            {t("shell.welcome_slogan")}
          </p>
          <p className="mx-auto mt-2 max-w-md text-sm leading-relaxed text-muted-foreground">
            {subtitle}
          </p>
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="px-1 text-sm font-semibold text-foreground">
          {t("shell.welcome_quick_title")}
        </h2>
        <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
          {shortcuts.map(({ href, label, icon: Icon }) => (
            <Link
              key={href}
              to={href}
              className="glass-card group flex items-center gap-3 rounded-2xl px-4 py-3 transition-all duration-300 hover:-translate-y-0.5 hover:border-primary/20 hover:shadow-md hover:shadow-primary/5"
            >
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary transition-colors group-hover:bg-primary/15">
                <Icon size={18} />
              </span>
              <span className="truncate text-sm font-medium text-foreground">{label}</span>
            </Link>
          ))}
        </div>
      </section>

      <section className="glass-card rounded-[2rem] px-5 py-5 sm:px-6">
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="flex items-center gap-2 text-sm font-semibold text-foreground">
            <Flame size={16} className="text-amber-500/80" />
            {t("shell.welcome_top5_title")}
          </h2>
          <Link
            to="/hot"
            className="inline-flex items-center gap-1 text-xs font-medium text-muted-foreground transition-colors hover:text-primary"
          >
            {t("shell.welcome_top5_more")}
            <ArrowRight size={14} />
          </Link>
        </div>

        {loadingHot ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="flex items-center gap-3 rounded-2xl px-3 py-2.5">
                <Skeleton className="h-6 w-6 rounded-lg" />
                <Skeleton className="h-4 flex-1" />
                <Skeleton className="h-3 w-12" />
              </div>
            ))}
          </div>
        ) : hotPosts.length === 0 ? (
          <p className="px-3 py-6 text-center text-xs text-muted-foreground/80">
            {t("shell.welcome_top5_empty")}
          </p>
        ) : (
          <ol className="space-y-1">
            {hotPosts.map((post, index) => (
              <li key={post.id}>
                <Link
                  to={`/post/${post.id}`}
                  className="flex items-center gap-3 rounded-2xl px-3 py-2.5 transition-colors hover:bg-muted/60"
                >
                  <span
                    className={cn(
                      "flex h-6 w-6 shrink-0 items-center justify-center rounded-lg text-xs font-semibold tabular-nums",
                      index < 3
                        ? "bg-amber-500/12 text-amber-600 dark:bg-amber-400/12 dark:text-amber-400"
                        : "bg-muted text-muted-foreground",
                    )}
                  >
                    {index + 1}
                  </span>
                  <span className="min-w-0 flex-1 truncate text-sm font-medium text-foreground">
                    {post.title}
                  </span>
                  <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground/70">
                    {t("shell.list_heat", { heat: post.heat ?? 0 })}
                  </span>
                </Link>
              </li>
            ))}
          </ol>
        )}
      </section>
    </div>
  )
}
