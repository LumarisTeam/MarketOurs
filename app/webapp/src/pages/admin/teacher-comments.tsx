import { useEffect, useState } from "react"
import { CheckCircle, RotateCcw, Search, XCircle } from "lucide-react"
import { useTranslation } from "react-i18next"
import { adminService } from "../../services/adminService"
import { extractUserMessage } from "../../services/errorCodes"
import { toast } from "../../lib/toast"
import { formatLocalDateTime } from "../../lib/dateTime"
import type { PagedResult, TeacherCommentItem } from "../../types"
import { Badge } from "../../components/ui/badge"
import { Button } from "../../components/ui/button"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "../../components/ui/alert-dialog"

const PAGE_SIZE = 10

type ReviewFilter = "all" | "pending" | "approved"

function toReviewValue(filter: ReviewFilter) {
  if (filter === "pending") return false
  if (filter === "approved") return true
  return undefined
}

function Stars({ value }: { value: number }) {
  return <span className="font-semibold text-foreground">{value}/5</span>
}

export default function AdminTeacherCommentsPage() {
  const { t, i18n } = useTranslation()
  const [teacherName, setTeacherName] = useState("")
  const [courseName, setCourseName] = useState("")
  const [reviewFilter, setReviewFilter] = useState<ReviewFilter>("pending")
  const [minStar, setMinStar] = useState("")
  const [page, setPage] = useState(1)
  const [comments, setComments] = useState<PagedResult<TeacherCommentItem> | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeKey, setActiveKey] = useState<string | null>(null)
  const [reviewTarget, setReviewTarget] = useState<TeacherCommentItem | null>(null)

  const loadComments = async (nextPage = page) => {
    try {
      setIsLoading(true)
      setError(null)
      const response = await adminService.getTeacherComments({
        teacherName,
        courseName,
        isReview: toReviewValue(reviewFilter),
        minStar: minStar ? Number(minStar) : undefined,
        page: nextPage,
        pageSize: PAGE_SIZE,
      })
      setComments(response.data)
      setPage(nextPage)
    } catch (err) {
      setError(extractUserMessage(err, t("admin.common.load_error")))
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    void loadComments(1)
  }, [teacherName, courseName, reviewFilter, minStar, t])

  const handleReview = async () => {
    if (!reviewTarget) return
    const target = reviewTarget
    setReviewTarget(null)

    try {
      setActiveKey(target.key)
      await adminService.updateTeacherCommentReview(target.key, { isReview: !target.isReview })
      await loadComments(page)
      toast.success(t(target.isReview ? "admin.teacher_comments.review_reverted" : "admin.teacher_comments.review_approved"))
    } catch (err) {
      toast.error(extractUserMessage(err, t("admin.common.action_error")))
    } finally {
      setActiveKey(null)
    }
  }

  const resetFilters = () => {
    setTeacherName("")
    setCourseName("")
    setReviewFilter("pending")
    setMinStar("")
    setPage(1)
  }

  return (
    <div className="space-y-8">
      <header className="flex flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t("admin.teacher_comments.title")}</h1>
          <p className="mt-1 text-muted-foreground">{t("admin.teacher_comments.subtitle")}</p>
        </div>

        <div className="grid gap-3 sm:grid-cols-2 xl:flex">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
            <input
              value={teacherName}
              onChange={(event) => setTeacherName(event.target.value)}
              placeholder={t("admin.teacher_comments.teacher_placeholder")}
              className="w-full rounded-xl border border-border/50 bg-muted/50 py-2 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-primary/20 xl:w-52"
            />
          </div>
          <input
            value={courseName}
            onChange={(event) => setCourseName(event.target.value)}
            placeholder={t("admin.teacher_comments.course_placeholder")}
            className="w-full rounded-xl border border-border/50 bg-muted/50 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-primary/20 xl:w-48"
          />
          <select
            value={reviewFilter}
            onChange={(event) => setReviewFilter(event.target.value as ReviewFilter)}
            className="rounded-xl border border-border/50 bg-muted/50 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-primary/20"
          >
            <option value="all">{t("admin.teacher_comments.filter_all")}</option>
            <option value="pending">{t("admin.teacher_comments.filter_pending")}</option>
            <option value="approved">{t("admin.teacher_comments.filter_approved")}</option>
          </select>
          <select
            value={minStar}
            onChange={(event) => setMinStar(event.target.value)}
            className="rounded-xl border border-border/50 bg-muted/50 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-primary/20"
          >
            <option value="">{t("admin.teacher_comments.filter_star_all")}</option>
            {[5, 4, 3, 2, 1].map((star) => (
              <option key={star} value={star}>
                {t("admin.teacher_comments.filter_star_min", { count: star })}
              </option>
            ))}
          </select>
          <Button variant="outline" size="sm" onClick={resetFilters}>
            <RotateCcw data-icon="inline-start" />
            {t("admin.teacher_comments.reset")}
          </Button>
        </div>
      </header>

      {error && (
        <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      <div className="overflow-hidden rounded-[2rem] border border-border/50 bg-card">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-muted/30 text-xs uppercase text-muted-foreground">
              <tr>
                <th className="px-6 py-4 font-semibold">{t("admin.teacher_comments.table_teacher")}</th>
                <th className="px-6 py-4 font-semibold">{t("admin.teacher_comments.table_comment")}</th>
                <th className="px-6 py-4 font-semibold">{t("admin.teacher_comments.table_status")}</th>
                <th className="px-6 py-4 font-semibold">{t("admin.teacher_comments.table_audit")}</th>
                <th className="px-6 py-4 font-semibold">{t("admin.teacher_comments.table_date")}</th>
                <th className="px-6 py-4 text-right font-semibold">{t("admin.teacher_comments.table_actions")}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/50">
              {isLoading ? (
                Array.from({ length: 6 }).map((_, index) => (
                  <tr key={index}>
                    <td className="px-6 py-5" colSpan={6}>
                      <div className="h-12 animate-pulse rounded-xl bg-muted/50" />
                    </td>
                  </tr>
                ))
              ) : comments && comments.items.length > 0 ? (
                comments.items.map((item) => {
                  const isBusy = activeKey === item.key
                  return (
                    <tr key={item.key} className="align-top transition-colors hover:bg-muted/30">
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1">
                          <span className="font-bold text-foreground">{item.teacherName}</span>
                          <span className="text-xs text-muted-foreground">{item.courseName}</span>
                          <span className="text-xs text-muted-foreground">{item.userId.slice(0, 8)}</span>
                        </div>
                      </td>
                      <td className="max-w-lg px-6 py-4">
                        <div className="flex flex-col gap-2">
                          <Stars value={item.star} />
                          <p className="line-clamp-3 text-foreground">{item.comment || t("common.null")}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        {item.isReview ? (
                          <Badge variant="secondary">{t("admin.teacher_comments.status_active")}</Badge>
                        ) : (
                          <Badge variant="outline">{t("admin.teacher_comments.status_pending")}</Badge>
                        )}
                      </td>
                      <td className="max-w-sm px-6 py-4">
                        <div className="flex flex-col gap-1 text-xs text-muted-foreground">
                          <span>
                            {t("admin.teacher_comments.ai_reviewed")}: {item.aiReviewedOn ? formatLocalDateTime(item.aiReviewedOn, i18n.resolvedLanguage, { includeSeconds: false }) : t("common.null")}
                          </span>
                          <span>
                            {t("admin.teacher_comments.human_reviewed")}: {item.reviewedOn ? formatLocalDateTime(item.reviewedOn, i18n.resolvedLanguage, { includeSeconds: false }) : t("common.null")}
                          </span>
                          <span>
                            {t("admin.teacher_comments.reviewed_by")}: {item.reviewedBy || t("common.null")}
                          </span>
                          {item.aiReason && (
                            <span className="line-clamp-2 text-destructive">
                              {t("admin.teacher_comments.ai_reason")}: {item.aiReason}
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-muted-foreground">
                        {formatLocalDateTime(item.createdOn, i18n.resolvedLanguage, { includeSeconds: false })}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <Button
                          variant="ghost"
                          size="icon"
                          disabled={isBusy}
                          title={item.isReview ? t("admin.teacher_comments.action_unapprove") : t("admin.teacher_comments.action_approve")}
                          onClick={() => setReviewTarget(item)}
                        >
                          {item.isReview ? <XCircle /> : <CheckCircle />}
                        </Button>
                      </td>
                    </tr>
                  )
                })
              ) : (
                <tr>
                  <td className="px-6 py-16 text-center text-muted-foreground" colSpan={6}>
                    {t("admin.teacher_comments.no_items")}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="flex items-center justify-between border-t border-border/50 px-6 py-4 text-sm">
          <span className="text-muted-foreground">
            {comments ? t("admin.common.total_count", { count: comments.totalCount }) : ""}
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={!comments?.hasPreviousPage || isLoading}
              onClick={() => void loadComments(Math.max(1, page - 1))}
            >
              {t("admin.common.previous")}
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={!comments?.hasNextPage || isLoading}
              onClick={() => void loadComments(page + 1)}
            >
              {t("admin.common.next")}
            </Button>
          </div>
        </div>
      </div>

      <AlertDialog open={reviewTarget !== null} onOpenChange={(open) => { if (!open) setReviewTarget(null) }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {reviewTarget?.isReview ? t("admin.common.confirm_unapprove_title") : t("admin.common.confirm_approve_title")}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {reviewTarget?.isReview
                ? t("admin.common.confirm_unapprove_description", { item: t("admin.teacher_comments.item_name") })
                : t("admin.common.confirm_approve_description", { item: t("admin.teacher_comments.item_name") })}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t("admin.common.cancel")}</AlertDialogCancel>
            <AlertDialogAction onClick={() => void handleReview()}>
              {t("admin.common.confirm")}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
