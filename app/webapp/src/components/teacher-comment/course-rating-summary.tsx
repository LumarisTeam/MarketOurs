import { useId } from "react"
import { Star } from "lucide-react"
import { useTranslation } from "react-i18next"
import type { CourseCommentSummary } from "@/types"

export function CourseRatingSummary({ summary }: { summary: CourseCommentSummary }) {
  const { t, i18n } = useTranslation()
  const titleId = useId()
  const distributionId = useId()
  const formatCount = new Intl.NumberFormat(i18n.resolvedLanguage)
  const average = new Intl.NumberFormat(i18n.resolvedLanguage, {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }).format(summary.averageStar)
  const distribution = summary.starDistribution.toSorted((a, b) => b.star - a.star)

  return (
    <section
      aria-labelledby={titleId}
      lang={i18n.resolvedLanguage}
      className="@container rounded-2xl border border-border bg-secondary text-foreground [font-family:system-ui,sans-serif] dark:bg-card contrast-more:border-current"
    >
      <div className="grid grid-cols-1 gap-4 p-5 @max-[12rem]:p-[5cqi] @md:grid-cols-[minmax(8rem,max-content)_minmax(0,1fr)] @md:gap-6 @md:p-6">
        <div className="@md:self-center">
          <h2 id={titleId} className="text-sm font-semibold">{t("teacher_comments.average_star")}</h2>
          <div className="mt-1 flex flex-wrap items-baseline gap-x-4 gap-y-1 @md:flex-col">
            <p className="flex flex-wrap items-baseline gap-1.5 tabular-nums">
              <span className="sr-only">{t("teacher_comments.score_out_of_five", { score: average })}</span>
              <span aria-hidden="true" className="text-5xl leading-none font-semibold tracking-[-0.045em]">{average}</span>
              <span aria-hidden="true" className="text-sm font-medium text-foreground/70 contrast-more:text-foreground">/ 5</span>
            </p>
            <p className="text-sm text-foreground/70 tabular-nums contrast-more:text-foreground">
              {t("teacher_comments.course_count", { count: summary.totalCount })}
            </p>
          </div>
        </div>

        <div className="min-w-0 border-t border-foreground/10 pt-4 @md:border-s @md:border-t-0 @md:ps-6 @md:pt-0 contrast-more:border-current">
          <h3 id={distributionId} className="mb-2 text-sm font-semibold">{t("teacher_comments.distribution")}</h3>
          <ul
            role="list"
            aria-labelledby={distributionId}
            className="grid grid-cols-[max-content_minmax(0,1fr)_max-content] gap-x-3 gap-y-1 text-sm text-foreground/70 tabular-nums @max-[12rem]:grid-cols-[minmax(0,1fr)_max-content] @max-[12rem]:gap-y-2 contrast-more:text-foreground"
          >
            {distribution.map(({ star, count }) => (
              <li key={star} className="col-span-full grid grid-cols-subgrid items-center @max-[12rem]:gap-y-1">
                <span className="sr-only">
                  {t("teacher_comments.rating_distribution_row", {
                    star,
                    reviews: t("teacher_comments.course_count", { count }),
                  })}
                </span>
                <span aria-hidden="true" className="flex items-center gap-1 font-medium">
                  {star}<Star className="size-[0.8em] fill-current" />
                </span>
                <span
                  aria-hidden="true"
                  className="h-1.5 overflow-hidden rounded-full bg-foreground/12 @max-[12rem]:col-span-full @max-[12rem]:row-start-2 contrast-more:outline contrast-more:-outline-offset-1 forced-colors:outline forced-colors:-outline-offset-1"
                >
                  <span
                    className="block h-full rounded-full bg-primary dark:bg-chart-2 forced-colors:bg-[Highlight] forced-colors:forced-color-adjust-none"
                    style={{ width: `${(count / summary.totalCount) * 100}%` }}
                  />
                </span>
                <span aria-hidden="true" className="min-w-[2ch] text-end @max-[12rem]:col-start-2 @max-[12rem]:row-start-1">
                  {formatCount.format(count)}
                </span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  )
}
