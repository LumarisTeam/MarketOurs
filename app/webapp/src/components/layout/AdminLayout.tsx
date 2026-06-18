import { Link, useLocation } from "react-router"
import { cn } from "@/lib/utils"
import {
  LayoutDashboard, Users, FileText, Home, LogOut, Menu,
  Sun, Moon, ScrollText, ShieldBan, MessageSquare, Tags
} from "lucide-react"
import { useState } from "react"
import { useTheme } from "@/components/theme-provider"
import { useDispatch, useSelector } from "react-redux"
import { logout } from "@/stores/authSlice"
import type { RootState } from "@/stores"
import { useTranslation } from "react-i18next"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { Button } from "@/components/ui/button"
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet"
import { PageTransition } from "./PageTransition"

interface AdminLayoutProps {
  children: React.ReactNode
}

export function AdminLayout({ children }: AdminLayoutProps) {
  const { t } = useTranslation()
  const location = useLocation()
  const { theme, setTheme } = useTheme()
  const dispatch = useDispatch()
  const user = useSelector((state: RootState) => state.auth.user)
  const [isSidebarOpen, setIsSidebarOpen] = useState(false)

  const navItems = [
    { name: t("admin.sidebar.dashboard"), href: "/admin", icon: LayoutDashboard },
    { name: t("admin.sidebar.users"), href: "/admin/users", icon: Users },
    { name: t("admin.sidebar.posts"), href: "/admin/posts", icon: FileText },
    { name: t("admin.sidebar.tags"), href: "/admin/tags", icon: Tags },
    { name: t("admin.sidebar.comments"), href: "/admin/comments", icon: MessageSquare },
    { name: t("admin.sidebar.logs"), href: "/admin/logs", icon: ScrollText },
    { name: t("admin.sidebar.blacklist"), href: "/admin/blacklist", icon: ShieldBan },
  ]

  const handleLogout = () => {
    dispatch(logout())
  }

  const userInitials = user?.name
    ? user.name.slice(0, 2).toUpperCase()
    : "A"

  const isActiveRoute = (href: string) => {
    if (href === "/admin") return location.pathname === "/admin"
    return location.pathname.startsWith(href)
  }

  const SidebarContent = () => (
    <div className="flex h-full flex-col">
      {/* Logo */}
      <div className="flex h-14 items-center gap-2.5 px-5">
        <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-primary shadow-sm">
          <span className="text-sm font-bold text-primary-foreground">A</span>
        </div>
        <span className="font-semibold text-foreground tracking-tight">
          {t("admin.panel")}
        </span>
      </div>

      <Separator />

      {/* Nav Items */}
      <nav className="flex-1 space-y-0.5 px-3 py-4">
        {navItems.map((item) => {
          const isActive = isActiveRoute(item.href)
          return (
            <Link
              key={item.href}
              to={item.href}
              onClick={() => setIsSidebarOpen(false)}
              className={cn(
                "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                isActive
                  ? "bg-primary/10 text-primary"
                  : "text-muted-foreground hover:bg-muted/80 hover:text-foreground"
              )}
            >
              <item.icon size={18} className={cn(isActive && "text-primary")} />
              {item.name}
            </Link>
          )
        })}
      </nav>

      <Separator />

      {/* Bottom */}
      <div className="space-y-1 p-3">
        <Link
          to="/"
          className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-muted-foreground hover:bg-muted/80 hover:text-foreground transition-colors"
        >
          <Home size={18} />
          {t("admin.sidebar.back_to_site")}
        </Link>
      </div>
    </div>
  )

  return (
    <div className="flex min-h-screen bg-background">
      {/* Desktop Sidebar */}
      <aside className="hidden lg:flex w-60 flex-col border-r border-border/30 bg-card/60 backdrop-blur-xl">
        <SidebarContent />
      </aside>

      {/* Main Content Area */}
      <div className="flex flex-1 flex-col min-w-0">
        {/* Topbar */}
        <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-border/20 bg-background/80 backdrop-blur-xl px-4 lg:px-6">
          <div className="flex items-center gap-3 lg:hidden">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setIsSidebarOpen(true)}
              className="rounded-xl text-muted-foreground"
            >
              <Menu size={20} />
            </Button>
            <span className="font-semibold text-foreground tracking-tight">
              {t("admin.topbar.admin")}
            </span>
          </div>

          {/* Spacer on desktop */}
          <div className="hidden lg:block" />

          <div className="flex items-center gap-1 ml-auto">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              className="rounded-xl text-muted-foreground hover:text-foreground"
              aria-label="Toggle theme"
            >
              {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
            </Button>

            <Separator orientation="vertical" className="mx-1 h-5" />

            {/* User Info */}
            <div className="hidden sm:flex flex-col items-end mr-1">
              <span className="text-xs font-medium leading-tight text-foreground">
                {user?.name}
              </span>
              <span className="text-[10px] text-muted-foreground leading-tight">
                {t("admin.topbar.admin")}
              </span>
            </div>

            <Avatar className="h-7 w-7 rounded-full ring-2 ring-border/30">
              <AvatarImage src={user?.avatar} alt={user?.name} />
              <AvatarFallback className="text-[10px] bg-primary/10 text-primary font-medium">
                {userInitials}
              </AvatarFallback>
            </Avatar>

            <Button
              variant="ghost"
              size="icon"
              onClick={handleLogout}
              className="rounded-xl text-muted-foreground hover:text-destructive ml-0.5"
              title={t("nav.logout")}
            >
              <LogOut size={16} />
            </Button>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <div className="mx-auto max-w-6xl">
            <PageTransition>
              {children}
            </PageTransition>
          </div>
        </main>
      </div>

      {/* Mobile Sidebar */}
      <Sheet open={isSidebarOpen} onOpenChange={setIsSidebarOpen}>
        <SheetContent side="left" className="w-64 rounded-r-3xl pt-12 p-0">
          <SheetHeader className="sr-only">
            <SheetTitle>{t("admin.panel")}</SheetTitle>
          </SheetHeader>
          <SidebarContent />
        </SheetContent>
      </Sheet>
    </div>
  )
}
