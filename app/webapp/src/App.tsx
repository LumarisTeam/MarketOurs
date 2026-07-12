import { BrowserRouter, Routes, Route, Outlet } from "react-router"
import { Suspense, lazy, useEffect } from "react"
import { ThemeProvider } from "./components/theme-provider"
import { Toaster } from "./components/ui/sonner"
import { MainLayout } from "./components/layout/MainLayout"
import { PageLoading } from "./components/layout/PageLoading"

// Admin shell (Guard + Layout) is lazy-loaded — only downloaded for admin users
const AdminShell = lazy(() => import("./components/auth/AdminShell").then(m => ({ default: m.AdminShell })))

// Route-level code splitting — each page is loaded on demand
const HomePage = lazy(() => import("./pages/home"))
const HotPage = lazy(() => import("./pages/hot"))
const AdminDashboard = lazy(() => import("./pages/admin/dashboard"))
const AdminUsersPage = lazy(() => import("./pages/admin/users"))
const AdminPostsPage = lazy(() => import("./pages/admin/posts"))
const AdminTagsPage = lazy(() => import("./pages/admin/tags"))
const AdminCommentsPage = lazy(() => import("./pages/admin/comments"))
const AdminLogsPage = lazy(() => import("./pages/admin/logs"))
const AdminBlacklistPage = lazy(() => import("./pages/admin/blacklist"))
const LoginPage = lazy(() => import("./pages/login"))
const LoginCallbackPage = lazy(() => import("./pages/login/callback"))
const RegisterPage = lazy(() => import("./pages/register"))
const PostDetailPage = lazy(() => import("./pages/post/detail"))
const CreatePostPage = lazy(() => import("./pages/post/create"))
const NotificationsPage = lazy(() => import("./pages/notifications"))
const ProfilePage = lazy(() => import("./pages/profile"))
const PublicProfilePage = lazy(() => import("./pages/profile/public"))
const FollowingPage = lazy(() => import("./pages/profile/following"))
const ForgotPasswordPage = lazy(() => import("./pages/forgot-password"))
const ResetPasswordPage = lazy(() => import("./pages/profile/reset-password"))
const TermsPage = lazy(() => import("./pages/legal/terms"))
const PrivacyPage = lazy(() => import("./pages/legal/privacy"))
const TagPage = lazy(() => import("./pages/tag"))
import { useDispatch, useSelector } from "react-redux"
import type { RootState } from "./stores"
import { userService } from "./services/userService"
import { hydrateSession, logout, setUser } from "./stores/authSlice"
import { readAuthSession } from "./services/authSession"

export function App() {
  const dispatch = useDispatch()
  const { isAuthenticated, user, isHydrated } = useSelector((state: RootState) => state.auth)

  useEffect(() => {
    const initUser = async () => {
      const storedSession = readAuthSession()
      if (!storedSession.accessToken) {
        dispatch(hydrateSession({ user: null, accessToken: null }))
        return
      }

      try {
        const response = await userService.getProfile()
        if (response.data) {
          dispatch(setUser(response.data))
          dispatch(
            hydrateSession({
              user: response.data,
              accessToken: readAuthSession().accessToken,
            }),
          )
        }
      } catch (error) {
        console.error("Failed to initialize user:", error)
        dispatch(logout())
      }
    }

    if (!isHydrated) {
      initUser()
    } else if (isAuthenticated && !user) {
      initUser()
    }
  }, [dispatch, isAuthenticated, isHydrated, user])

  return (
    <ThemeProvider defaultTheme="system" storageKey="marketours-theme">
      <BrowserRouter>
        <Toaster richColors closeButton />
        <Suspense fallback={<PageLoading />}>
        <Routes>
          {/* Public Routes with MainLayout */}
          <Route element={<MainLayout><Outlet /></MainLayout>}>
            <Route path="/" element={<HomePage />} />
            <Route path="/hot" element={<HotPage />} />
            <Route path="/post/:id" element={<PostDetailPage />} />
            <Route path="/tag/:id" element={<TagPage />} />
            <Route path="/post/create" element={<CreatePostPage />} />
            <Route path="/notifications" element={<NotificationsPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/login-callback" element={<LoginCallbackPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/following" element={<FollowingPage />} />
            <Route path="/user/:id" element={<PublicProfilePage />} />
            <Route path="/profile/reset-password" element={<ResetPasswordPage />} />
            <Route path="/terms" element={<TermsPage />} />
            <Route path="/privacy" element={<PrivacyPage />} />
          </Route>

          {/* Admin Routes — lazy-loaded AdminShell (Guard + Layout) */}
          <Route
            path="/admin"
            element={<AdminShell />}
          >
            <Route index element={<AdminDashboard />} />
            <Route path="users" element={<AdminUsersPage />} />
            <Route path="posts" element={<AdminPostsPage />} />
            <Route path="tags" element={<AdminTagsPage />} />
            <Route path="comments" element={<AdminCommentsPage />} />
            <Route path="logs" element={<AdminLogsPage />} />
            <Route path="blacklist" element={<AdminBlacklistPage />} />
          </Route>
        </Routes>
        </Suspense>
      </BrowserRouter>
    </ThemeProvider>
  )
}
