import { Link } from "react-router"
import { useTranslation } from "react-i18next"
import { Navbar } from "./Navbar"

interface MainLayoutProps {
  children: React.ReactNode
}

export function MainLayout({ children }: MainLayoutProps) {
  const { t } = useTranslation()

  return (
    <div className="relative min-h-screen bg-background">
      <Navbar />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-in fade-in duration-500">
        {children}
      </main>
      <footer className="border-t border-border/40 py-12 mt-auto">
        <div className="container mx-auto px-4 text-center">
          <p className="text-sm text-muted-foreground">
            &copy; {new Date().getFullYear()} 光汇. Designed with a minimalist touch.
          </p>
          <div className="flex items-center justify-center gap-4 mt-3">
            <Link
              to="/terms"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              {t("legal.terms")}
            </Link>
            <Link
              to="/privacy"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              {t("legal.privacy")}
            </Link>
          </div>
        </div>
      </footer>
    </div>
  )
}
