import { Outlet } from "react-router"
import { AdminGuard } from "./AdminGuard"
import { AdminLayout } from "../layout/AdminLayout"

/**
 * Combined admin route shell — lazy-loaded so AdminGuard + AdminLayout
 * are only downloaded when a user navigates to /admin.
 */
export function AdminShell() {
  return (
    <AdminGuard>
      <AdminLayout>
        <Outlet />
      </AdminLayout>
    </AdminGuard>
  )
}
