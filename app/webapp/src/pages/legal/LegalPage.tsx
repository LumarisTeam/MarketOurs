import { useTranslation } from "react-i18next"

interface Section {
  title: string
  content: React.ReactNode
}

interface LegalPageProps {
  title: string
  lastUpdated: string
  sections: Section[]
}

export function LegalPage({ title, lastUpdated, sections }: LegalPageProps) {
  const { t } = useTranslation()

  return (
    <div className="max-w-3xl mx-auto py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight mb-2">{title}</h1>
        <p className="text-sm text-muted-foreground">
          {t("legal.last_updated")}: {lastUpdated}
        </p>
      </div>

      <div className="prose prose-neutral dark:prose-invert max-w-none">
        {sections.map((section, index) => (
          <section key={index} className="mb-8">
            <h2 className="text-xl font-semibold mb-3 text-foreground">
              {section.title}
            </h2>
            <div className="text-muted-foreground leading-relaxed space-y-2">
              {section.content}
            </div>
          </section>
        ))}
      </div>
    </div>
  )
}
