import { Bell } from "lucide-react"
import { useSelector, useDispatch } from "react-redux"
import { Link } from "react-router"
import { useEffect } from "react"
import type { RootState, AppDispatch } from "@/stores"
import { fetchUnreadCount } from "@/stores/notificationSlice"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"

export function NotificationBell() {
  const { unreadCount } = useSelector((state: RootState) => state.notification)
  const { isAuthenticated } = useSelector((state: RootState) => state.auth)
  const dispatch = useDispatch<AppDispatch>()

  useEffect(() => {
    if (isAuthenticated) {
      dispatch(fetchUnreadCount())
      
      // Optional: Set up polling or WebSocket for real-time notifications
      const interval = setInterval(() => {
        dispatch(fetchUnreadCount())
      }, 60000) // Every minute

      return () => clearInterval(interval)
    }
  }, [isAuthenticated, dispatch])

  if (!isAuthenticated) return null

  return (
    <Button
      variant="ghost"
      size="icon"
      className="relative rounded-xl text-muted-foreground hover:text-foreground"
      aria-label="Notifications"
      render={
        <Link to="/notifications" className="relative inline-flex items-center justify-center">
          <Bell size={18} />
          {unreadCount > 0 && (
            <span className={cn(
              "absolute top-0 right-0 -mr-0.5 -mt-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-destructive text-[10px] font-bold text-white",
              unreadCount > 9 && "w-5 px-0.5"
            )}>
              {unreadCount > 99 ? "99+" : unreadCount}
            </span>
          )}
        </Link>
      }
    />
  )
}
