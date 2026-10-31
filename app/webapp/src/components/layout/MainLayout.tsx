import { Link } from "react-router"
import { useTranslation } from "react-i18next"
import { Navbar } from "./Navbar"
import { PageTransition } from "./PageTransition"
import { Separator } from "@/components/ui/separator"

interface MainLayoutProps {
  children: React.ReactNode
}

export function MainLayout({ children }: MainLayoutProps) {
  const { t } = useTranslation()
  const year = new Date().getFullYear()

  return (
    <div className="relative flex min-h-screen flex-col bg-background">
      <Navbar />
      <main className="flex-1">
        <PageTransition>
          <div className="mx-auto max-w-4xl px-4 py-8 sm:px-6 sm:py-12 lg:px-8 lg:py-14">
            {children}
          </div>
        </PageTransition>
      </main>
      <footer className="mt-auto border-t border-border/30">
        <div className="mx-auto max-w-4xl px-4 py-8 sm:px-6 lg:px-8">
          <div className="flex flex-col items-center gap-3 sm:flex-row sm:justify-between">
            <div className="flex items-center gap-2">
              <div className="flex h-6 w-6 items-center justify-center rounded-md bg-primary/10">
                <span className="text-[10px] font-bold text-primary">L</span>
              </div>
              <span className="text-sm font-medium text-foreground">{t("common.site_name")}</span>
              <Separator orientation="vertical" className="h-3 mx-1" />
              <p className="text-xs text-muted-foreground">
                &copy; {year} MarketOurs
              </p>
            </div>
            <nav className="flex items-center gap-4">
              <Link
                to="/terms"
                className="text-xs text-muted-foreground hover:text-foreground transition-colors"
              >
                {t("legal.terms")}
              </Link>
              <Link
                to="/privacy"
                className="text-xs text-muted-foreground hover:text-foreground transition-colors"
              >
                {t("legal.privacy")}
              </Link>
            </nav>
          </div>
        </div>
      </footer>
    </div>
  )
}
