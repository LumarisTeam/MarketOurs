import { Link, useLocation } from "react-router"
import { useTranslation } from "react-i18next"
import { useSelector } from "react-redux"
import {
  Flame,
  GraduationCap,
  Home,
  Languages,
  LogIn,
  Moon,
  PlusSquare,
  Sun,
  type LucideIcon,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useTheme } from "@/components/theme-provider"
import type { RootState } from "@/stores"
import { NotificationBell } from "@/components/layout/NotificationBell"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"

const railItemClass =
  "flex h-11 w-11 items-center justify-center rounded-2xl transition-colors"

function RailLink({
  href,
  label,
  icon: Icon,
  active,
}: {
  href: string
  label: string
  icon: LucideIcon
  active: boolean
}) {
  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <Link
            to={href}
            aria-label={label}
            className={cn(
              railItemClass,
              active
                ? "bg-primary/10 text-primary"
                : "text-muted-foreground hover:bg-muted hover:text-foreground",
            )}
          >
            <Icon size={20} />
          </Link>
        }
      />
      <TooltipContent side="right">{label}</TooltipContent>
    </Tooltip>
  )
}

function RailButton({
  label,
  icon: Icon,
  onClick,
}: {
  label: string
  icon: LucideIcon
  onClick: () => void
}) {
  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <Button
            variant="ghost"
            size="icon"
            aria-label={label}
            onClick={onClick}
            className="h-11 w-11 rounded-2xl text-muted-foreground hover:text-foreground"
          >
            <Icon size={18} />
          </Button>
        }
      />
      <TooltipContent side="right">{label}</TooltipContent>
    </Tooltip>
  )
}

export function AppRail() {
  const { t, i18n } = useTranslation()
  const { theme, setTheme } = useTheme()
  const location = useLocation()
  const { isAuthenticated, user } = useSelector((state: RootState) => state.auth)

  const isActive = (href: string) => {
    if (href === "/") return location.pathname === "/"
    return location.pathname.startsWith(href)
  }

  const toggleLanguage = () => {
    i18n.changeLanguage(i18n.language === "en" ? "zh" : "en")
  }

  const userInitials = user?.name ? user.name.slice(0, 2).toUpperCase() : "U"

  return (
    <aside className="fixed inset-y-0 left-0 z-40 flex w-[72px] flex-col items-center border-r border-border/40 bg-background/70 backdrop-blur-xl">
      {/* 与列表栏头部同为 64px，保证两条分割线在同一水平线 */}
      <div className="flex h-16 w-full shrink-0 items-center justify-center border-b border-border/40">
        <Link
          to="/"
          aria-label={t("common.site_name")}
          className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary shadow-sm shadow-primary/20"
        >
          <span className="text-sm font-bold text-primary-foreground">L</span>
        </Link>
      </div>

      <nav className="flex w-full flex-col items-center gap-1.5 pt-3">
        <RailLink href="/" label={t("nav.home")} icon={Home} active={isActive("/")} />
        <RailLink href="/hot" label={t("nav.hot")} icon={Flame} active={isActive("/hot")} />
        <RailLink
          href="/teacher-comments"
          label={t("nav.teacher_comments")}
          icon={GraduationCap}
          active={isActive("/teacher-comments")}
        />
        {isAuthenticated && (
          <RailLink
            href="/post/create"
            label={t("nav.post")}
            icon={PlusSquare}
            active={isActive("/post/create")}
          />
        )}
        {isAuthenticated && (
          <div className="flex h-11 w-11 items-center justify-center">
            <NotificationBell />
          </div>
        )}
      </nav>

      <div className="mt-auto flex w-full flex-col items-center gap-1.5 pb-4">
        <RailButton
          label={t("nav.toggle_language")}
          icon={Languages}
          onClick={toggleLanguage}
        />
        <RailButton
          label={t("nav.toggle_theme")}
          icon={theme === "dark" ? Sun : Moon}
          onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
        />

        <Separator className="my-1 w-10" />

        {isAuthenticated ? (
          <Tooltip>
            <TooltipTrigger
              render={
                <Link
                  to="/profile"
                  aria-label={t("nav.profile")}
                  className={cn(
                    "flex h-11 w-11 items-center justify-center rounded-2xl transition-colors",
                    isActive("/profile") ? "bg-primary/10" : "hover:bg-muted",
                  )}
                >
                  <Avatar className="h-8 w-8 rounded-full ring-2 ring-border/30">
                    <AvatarImage src={user?.avatar} alt={user?.name} />
                    <AvatarFallback className="bg-primary/10 text-[10px] font-medium text-primary">
                      {userInitials}
                    </AvatarFallback>
                  </Avatar>
                </Link>
              }
            />
            <TooltipContent side="right">{t("nav.profile")}</TooltipContent>
          </Tooltip>
        ) : (
          <RailLink
            href="/login"
            label={t("nav.login")}
            icon={LogIn}
            active={isActive("/login")}
          />
        )}
      </div>
    </aside>
  )
}
