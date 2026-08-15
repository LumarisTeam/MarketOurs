import { useEffect, useMemo, useState } from "react"
import type { FormEvent } from "react"
import { GraduationCap, Loader2, Search, Send } from "lucide-react"
import { Link } from "react-router"
import { useSelector } from "react-redux"
import { useTranslation } from "react-i18next"
import type { RootState } from "@/stores"
import type { TeacherCommentItem, TeacherCommentSummary } from "@/types"
import { teacherCommentService } from "@/services/teacherCommentService"
import { extractUserMessage } from "@/services/errorCodes"
import { toast } from "@/lib/toast"
import { formatLocalDate } from "@/lib/dateTime"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Badge } from "@/components/ui/badge"

const COMMENT_MAX_LENGTH = 2000

export default function TeacherCommentsPage() {
  const { t, i18n } = useTranslation()
  const { isAuthenticated } = useSelector((state: RootState) => state.auth)
  const [searchTerm, setSearchTerm] = useState("")
  const [activeTeacherName, setActiveTeacherName] = useState("")
  const [summary, setSummary] = useState<TeacherCommentSummary | null>(null)
  const [comments, setComments] = useState<TeacherCommentItem[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [courseName, setCourseName] = useState("")
  const [comment, setComment] = useState("")
  const [star, setStar] = useState(5)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const displayedTeacherName = activeTeacherName || t("teacher_comments.empty_teacher")
  const courses = useMemo(() => summary?.courses ?? [], [summary])

  const loadTeacher = async (teacherName: string) => {
    const name = teacherName.trim()
    if (!name) return

    try {
      setIsLoading(true)
      setLoadError(null)
      const [summaryResponse, commentsResponse] = await Promise.all([
        teacherCommentService.getSummary(name),
        teacherCommentService.getByTeacher(name),
      ])
      setSummary(summaryResponse.data)
      setComments(commentsResponse.data ?? [])
      setActiveTeacherName(name)
    } catch (err) {
      setSummary(null)
      setComments([])
      setLoadError(extractUserMessage(err, t("teacher_comments.load_error")))
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    if (!activeTeacherName) return
    void loadTeacher(activeTeacherName)
  }, [i18n.resolvedLanguage])

  const handleSearch = (event: FormEvent) => {
    event.preventDefault()
    void loadTeacher(searchTerm)
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()

    const teacherName = (activeTeacherName || searchTerm).trim()
    if (!teacherName) {
      setFormError(t("teacher_comments.teacher_required"))
      return
    }
    if (!courseName.trim()) {
      setFormError(t("teacher_comments.course_required"))
      return
    }
    if (comment.length > COMMENT_MAX_LENGTH) {
      setFormError(t("teacher_comments.comment_too_long", { max: COMMENT_MAX_LENGTH }))
      return
    }

    try {
      setIsSubmitting(true)
      setFormError(null)
      await teacherCommentService.create({
        teacherName,
        courseName: courseName.trim(),
        comment: comment.trim() || null,
        star,
      })
      setActiveTeacherName(teacherName)
      setSearchTerm(teacherName)
      setCourseName("")
      setComment("")
      setStar(5)
      toast.success(t("teacher_comments.submitted"))
      await loadTeacher(teacherName)
    } catch (err) {
      setFormError(extractUserMessage(err, t("teacher_comments.submit_error")))
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8 px-4 py-8 sm:px-6 lg:px-8">
      <header className="flex flex-col gap-5">
        <div className="flex items-center gap-3">
          <div className="flex size-11 items-center justify-center rounded-2xl bg-primary text-primary-foreground">
            <GraduationCap />
          </div>
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t("teacher_comments.title")}</h1>
            <p className="mt-1 text-muted-foreground">{t("teacher_comments.subtitle")}</p>
          </div>
        </div>

        <form onSubmit={handleSearch} className="flex flex-col gap-3 rounded-[2rem] border border-border/50 bg-card p-4 sm:flex-row">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={18} />
            <Input
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder={t("teacher_comments.search_placeholder")}
              className="h-11 rounded-2xl pl-10"
            />
          </div>
          <Button type="submit" size="lg" disabled={isLoading || !searchTerm.trim()}>
            {isLoading ? <Loader2 className="animate-spin" data-icon="inline-start" /> : <Search data-icon="inline-start" />}
            {t("teacher_comments.search")}
          </Button>
        </form>
      </header>

      {loadError && (
        <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {loadError}
        </div>
      )}

      <section className="grid gap-4 md:grid-cols-3">
        <div className="rounded-[2rem] border border-border/50 bg-card p-5">
          <p className="text-sm text-muted-foreground">{t("teacher_comments.current_teacher")}</p>
          <p className="mt-2 text-2xl font-black">{displayedTeacherName}</p>
        </div>
        <div className="rounded-[2rem] border border-border/50 bg-card p-5">
          <p className="text-sm text-muted-foreground">{t("teacher_comments.average_star")}</p>
          <p className="mt-2 text-2xl font-black">
            {summary && summary.totalCount > 0 ? summary.averageStar.toFixed(1) : "-"}
          </p>
        </div>
        <div className="rounded-[2rem] border border-border/50 bg-card p-5">
          <p className="text-sm text-muted-foreground">{t("teacher_comments.total_count")}</p>
          <p className="mt-2 text-2xl font-black">{summary?.totalCount ?? 0}</p>
        </div>
      </section>

      <section className="grid gap-6 lg:grid-cols-[1fr_360px]">
        <div className="rounded-[2rem] border border-border/50 bg-card">
          <div className="border-b border-border/50 p-5">
            <h2 className="text-lg font-bold">{t("teacher_comments.approved_comments")}</h2>
            {courses.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-2">
                {courses.map((course) => (
                  <Badge key={course} variant="secondary">{course}</Badge>
                ))}
              </div>
            )}
          </div>

          <div className="divide-y divide-border/50">
            {isLoading ? (
              Array.from({ length: 3 }).map((_, index) => (
                <div key={index} className="p-5">
                  <div className="h-20 animate-pulse rounded-2xl bg-muted/50" />
                </div>
              ))
            ) : comments.length > 0 ? (
              comments.map((item) => (
                <article key={item.key} className="p-5">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge variant="outline">{item.courseName}</Badge>
                        <span className="text-sm font-bold">{item.star}/5</span>
                      </div>
                      <p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-foreground">
                        {item.comment || t("teacher_comments.no_comment")}
                      </p>
                    </div>
                    <span className="shrink-0 text-xs text-muted-foreground">
                      {formatLocalDate(item.createdOn, i18n.resolvedLanguage)}
                    </span>
                  </div>
                </article>
              ))
            ) : (
              <div className="p-10 text-center text-muted-foreground">
                {activeTeacherName ? t("teacher_comments.no_approved_comments") : t("teacher_comments.search_first")}
              </div>
            )}
          </div>
        </div>

        <aside className="rounded-[2rem] border border-border/50 bg-card p-5">
          <h2 className="text-lg font-bold">{t("teacher_comments.create_title")}</h2>
          <p className="mt-1 text-sm text-muted-foreground">{t("teacher_comments.create_subtitle")}</p>

          {isAuthenticated ? (
            <form onSubmit={handleSubmit} className="mt-5 flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium">{t("teacher_comments.teacher_label")}</label>
                <Input
                  value={activeTeacherName || searchTerm}
                  onChange={(event) => {
                    setActiveTeacherName("")
                    setSearchTerm(event.target.value)
                  }}
                  placeholder={t("teacher_comments.teacher_placeholder")}
                />
              </div>
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium">{t("teacher_comments.course_label")}</label>
                <Input
                  value={courseName}
                  onChange={(event) => setCourseName(event.target.value)}
                  placeholder={t("teacher_comments.course_placeholder")}
                />
              </div>
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium">{t("teacher_comments.star_label")}</label>
                <select
                  value={star}
                  onChange={(event) => setStar(Number(event.target.value))}
                  className="h-10 rounded-lg border border-input bg-background px-3 text-sm outline-none focus:ring-2 focus:ring-primary/20"
                >
                  {[5, 4, 3, 2, 1].map((value) => (
                    <option key={value} value={value}>{value}/5</option>
                  ))}
                </select>
              </div>
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium">{t("teacher_comments.comment_label")}</label>
                <Textarea
                  value={comment}
                  onChange={(event) => setComment(event.target.value)}
                  maxLength={COMMENT_MAX_LENGTH}
                  placeholder={t("teacher_comments.comment_placeholder")}
                  className="min-h-32 resize-none"
                />
                <span className="text-right text-xs text-muted-foreground">{comment.length}/{COMMENT_MAX_LENGTH}</span>
              </div>

              {formError && <p className="text-sm text-destructive">{formError}</p>}

              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? <Loader2 className="animate-spin" data-icon="inline-start" /> : <Send data-icon="inline-start" />}
                {t("teacher_comments.submit")}
              </Button>
            </form>
          ) : (
            <div className="mt-5 rounded-2xl bg-muted/50 p-4 text-sm text-muted-foreground">
              {t("teacher_comments.login_required")}{" "}
              <Link to="/login" className="font-medium text-primary hover:underline">
                {t("nav.login")}
              </Link>
            </div>
          )}
        </aside>
      </section>
    </div>
  )
}
