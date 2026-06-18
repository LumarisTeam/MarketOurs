import { cn } from "@/lib/utils"
import { Sun, Moon, LogOut } from "lucide-react"
import { useTheme } from "@/components/theme-provider"
import { useDispatch, useSelector } from "react-redux"
import { logout } from "@/stores/authSlice"
import type { RootState } from "@/stores"
import { useTranslation } from "react-i18next"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { PageTransition } from "./PageTransition"
import { AdminSidebar } from "./AdminSidebar"
import {
  SidebarProvider,
  SidebarInset,
  SidebarTrigger,
} from "@/components/ui/sidebar"

interface AdminLayoutProps {
  children: React.ReactNode
}

export function AdminLayout({ children }: AdminLayoutProps) {
  const { t } = useTranslation()
  const { theme, setTheme } = useTheme()
  const dispatch = useDispatch()
  const user = useSelector((state: RootState) => state.auth.user)

  const handleLogout = () => {
    dispatch(logout())
  }

  const userInitials = user?.name
    ? user.name.slice(0, 2).toUpperCase()
    : "A"

  return (
    <SidebarProvider defaultOpen={true}>
      <AdminSidebar />
      <SidebarInset>
        {/* Topbar */}
        <header
          className={cn(
            "sticky top-0 z-40 flex h-14 items-center gap-4",
            "border-b border-border/20 bg-background/80 backdrop-blur-xl",
            "px-4 lg:px-6"
          )}
        >
          <SidebarTrigger className="rounded-xl text-muted-foreground" />

          {/* Spacer */}
          <div className="flex-1" />

          {/* Theme Toggle */}
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
            className="rounded-xl text-muted-foreground hover:text-foreground"
            aria-label={t("nav.toggle_theme")}
          >
            {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
          </Button>

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
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <div className="mx-auto max-w-6xl">
            <PageTransition>
              {children}
            </PageTransition>
          </div>
        </main>
      </SidebarInset>
    </SidebarProvider>
  )
}
