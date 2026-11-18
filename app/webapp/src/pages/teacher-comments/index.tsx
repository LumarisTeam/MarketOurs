import { useCallback, useEffect, useRef, useState } from "react"
import { ArrowLeft, Loader2, Plus, Search, Star } from "lucide-react"
import { Link, useLocation, useSearchParams } from "react-router"
import { useSelector } from "react-redux"
import { useTranslation } from "react-i18next"
import type { RootState } from "@/stores"
import type { CourseCommentSummary, TeacherCommentItem } from "@/types"
import { teacherCommentService } from "@/services/teacherCommentService"
import { extractUserMessage } from "@/services/errorCodes"
import { toast } from "@/lib/toast"
import { formatPostRelativeDate } from "@/lib/postDisplay"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { CourseRatingSummary } from "@/components/teacher-comment/course-rating-summary"
import {
  TeacherCommentCard, TeacherCommentCardSkeleton, TeacherCommentFormDialog,
  type CommentFormValues,
} from "@/components/teacher-comment"
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from "@/components/ui/alert-dialog"

const PAGE_SIZE = 20

export default function TeacherCommentsPage() {
  const { t, i18n } = useTranslation()
  const { user } = useSelector((state: RootState) => state.auth)
  const location = useLocation()
  const [params, setParams] = useSearchParams()
  const isDetail = location.pathname.endsWith("/course")
  const courseName = params.get("courseName")?.trim() ?? ""
  const keyword = params.get("keyword")?.trim() ?? ""
  // Route transitions discard requests from the previous course/search, including append requests.
  const requestId = useRef(0)
  const loadingRef = useRef(false)
  const observerTarget = useRef<HTMLDivElement>(null)
  const [courses, setCourses] = useState<CourseCommentSummary[]>([])
  const [summary, setSummary] = useState<CourseCommentSummary | null>(null)
  const [comments, setComments] = useState<TeacherCommentItem[]>([])
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [failedPage, setFailedPage] = useState(1)
  const [createOpen, setCreateOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<TeacherCommentItem | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<TeacherCommentItem | null>(null)

  const loadPage = useCallback(async (nextPage = 1) => {
    const append = nextPage > 1
    if (append && loadingRef.current) return
    const id = ++requestId.current
    loadingRef.current = true
    setIsLoading(!append)
    setIsLoadingMore(append)
    setLoadError(null)
    try {
      if (isDetail) {
        if (!courseName) throw new Error(t("teacher_comments.course_required"))
        const [reviewsResponse, summaryResponse] = await Promise.all([
          teacherCommentService.getCourseComments(courseName, nextPage, PAGE_SIZE),
          append ? Promise.resolve(null) : teacherCommentService.getCourseSummary(courseName),
        ])
        if (id !== requestId.current) return
        const data = reviewsResponse.data
        setComments(current => append ? [...current, ...(data?.items ?? [])] : data?.items ?? [])
        if (summaryResponse) setSummary(summaryResponse.data ?? null)
        setHasMore(data?.hasNextPage ?? false)
      } else {
        const response = await teacherCommentService.getCourses(keyword, nextPage, PAGE_SIZE)
        if (id !== requestId.current) return
        const data = response.data
        setCourses(current => append ? [...current, ...(data?.items ?? [])] : data?.items ?? [])
        setHasMore(data?.hasNextPage ?? false)
      }
      setPage(nextPage)
    } catch (error) {
      if (id !== requestId.current) return
      setFailedPage(nextPage)
      setLoadError(extractUserMessage(error, t("teacher_comments.load_error")))
    } finally {
      if (id === requestId.current) {
        loadingRef.current = false
        setIsLoading(false)
        setIsLoadingMore(false)
      }
    }
  }, [isDetail, courseName, keyword, t])

  useEffect(() => {
    setComments([])
    setCourses([])
    setSummary(null)
    setPage(1)
    setHasMore(false)
    void loadPage()
    const requests = requestId
    const loading = loadingRef
    return () => { requests.current++; loading.current = false }
  }, [loadPage, location.key])

  useEffect(() => {
    const target = observerTarget.current
    if (!target || !hasMore || loadError || isLoading || isLoadingMore) return
    const observer = new IntersectionObserver(entries => {
      if (entries[0]?.isIntersecting) void loadPage(page + 1)
    }, { rootMargin: "0px 0px 320px 0px" })
    observer.observe(target)
    return () => observer.disconnect()
  }, [hasMore, loadError, isLoading, isLoadingMore, page, loadPage])

  const submitCreate = async (values: CommentFormValues) => {
    await teacherCommentService.create(values)
    toast.success(t("teacher_comments.submitted"))
    await loadPage()
  }
  const submitEdit = async (values: CommentFormValues) => {
    if (!editTarget) return
    await teacherCommentService.update(editTarget.key, values)
    toast.success(t("teacher_comments.updated"))
    await loadPage()
  }
  const deleteComment = async () => {
    if (!deleteTarget) return
    const target = deleteTarget
    setDeleteTarget(null)
    try {
      await teacherCommentService.deleteMine(target.key)
      toast.success(t("teacher_comments.deleted"))
      await loadPage()
    } catch (error) {
      toast.error(extractUserMessage(error, t("teacher_comments.submit_error")))
    }
  }
  const count = isDetail ? comments.length : courses.length
  const listUrl = `/teacher-comments?${new URLSearchParams(keyword ? { keyword } : {})}`

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-5 px-4 py-8 sm:px-0">
      {isDetail ? (
        <Link to={listUrl} className="flex items-center gap-2 text-sm text-muted-foreground hover:underline">
          <ArrowLeft size={16} aria-hidden="true" />{t("teacher_comments.back_courses")}
        </Link>
      ) : null}
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h1 className="break-words text-2xl font-semibold">{isDetail ? courseName : t("teacher_comments.title")}</h1>
          <p className="mt-2 text-sm text-muted-foreground">{t(isDetail ? "teacher_comments.all_teachers" : "teacher_comments.subtitle")}</p>
        </div>
        <Button onClick={() => setCreateOpen(true)} aria-label={t("teacher_comments.create_title")}>
          <Plus data-icon="inline-start" />{t("teacher_comments.create_title")}
        </Button>
      </div>
      {!isDetail ? (
        <form className="flex gap-2" onSubmit={event => {
          event.preventDefault()
          const term = String(new FormData(event.currentTarget).get("keyword") ?? "").trim()
          setParams(term ? { keyword: term } : {})
        }}>
          <Input key={keyword} name="keyword" defaultValue={keyword}
            placeholder={t("teacher_comments.search_placeholder")}
            aria-label={t("teacher_comments.search_placeholder")} />
          <Button type="submit" variant="outline"><Search data-icon="inline-start" />{t("teacher_comments.search")}</Button>
        </form>
      ) : null}
      {isLoading ? <div className="flex flex-col gap-5" aria-busy="true">
        {[0, 1, 2].map(item => <TeacherCommentCardSkeleton key={item} />)}
      </div> : (
        <>
          {isDetail && summary && summary.totalCount > 0 ? <CourseRatingSummary summary={summary} /> : null}
          {isDetail ? comments.map(item => (
            <TeacherCommentCard key={item.key} comment={item}
              noCommentText={t("teacher_comments.no_comment")}
              dateText={formatPostRelativeDate(item.createdOn, i18n)}
              isMine={!!user && (item.userId.toLowerCase() === user.id.toLowerCase() || user.role === "Admin")}
              editText={t("teacher_comments.edit")} deleteText={t("teacher_comments.delete")}
              onEdit={setEditTarget}
              onDelete={user && item.userId.toLowerCase() === user.id.toLowerCase() ? setDeleteTarget : undefined} />
          )) : courses.map(course => (
            <Card key={course.courseName}>
              <CardHeader>
                <CardTitle><Link className="break-words hover:underline" to={`/teacher-comments/course?${new URLSearchParams({ courseName: course.courseName, ...(keyword ? { keyword } : {}) })}`}>
                  {course.courseName}
                </Link></CardTitle>
                <CardDescription>{t("teacher_comments.course_count", { count: course.totalCount })}</CardDescription>
              </CardHeader>
              <CardContent className="flex items-center gap-2">
                <Star className="text-primary" size={18} aria-hidden="true" />
                <span className="font-semibold tabular-nums">{course.averageStar.toFixed(1)} / 5</span>
                <span className="text-muted-foreground">{t("teacher_comments.average_star")}</span>
              </CardContent>
            </Card>
          ))}
          {!loadError && count === 0 ? <p className="py-12 text-center text-sm text-muted-foreground" role="status">
            {t(isDetail ? "teacher_comments.no_approved_comments" : "teacher_comments.empty_courses")}
          </p> : null}
        </>
      )}
      {loadError ? <div className="flex flex-col items-center gap-3" role="alert">
        <p className="text-sm text-destructive">{loadError}</p>
        <Button variant="outline" onClick={() => void loadPage(failedPage)}>{t("teacher_comments.retry")}</Button>
      </div> : null}
      <div ref={observerTarget} className="flex justify-center py-4">
        {isLoadingMore ? <Loader2 className="animate-spin" aria-label={t("teacher_comments.load_more")} /> :
          hasMore && !isLoading && !loadError ? <Button variant="outline" onClick={() => void loadPage(page + 1)}>{t("teacher_comments.load_more")}</Button> :
          !hasMore && count > 0 && !isLoading ? <p className="text-sm text-muted-foreground">{t(isDetail ? "teacher_comments.no_more_reviews" : "teacher_comments.no_more_courses")}</p> : null}
      </div>
      <TeacherCommentFormDialog key={`create-${courseName}`} open={createOpen} onOpenChange={setCreateOpen}
        initialCourseName={isDetail ? courseName : ""} isAuthenticated={!!user} onSubmit={submitCreate} />
      <TeacherCommentFormDialog key={editTarget?.key ?? "edit"} open={editTarget !== null}
        onOpenChange={open => { if (!open) setEditTarget(null) }} initial={editTarget} isAuthenticated onSubmit={submitEdit} />
      <AlertDialog open={deleteTarget !== null} onOpenChange={open => { if (!open) setDeleteTarget(null) }}>
        <AlertDialogContent>
          <AlertDialogHeader><AlertDialogTitle>{t("teacher_comments.delete_title")}</AlertDialogTitle>
            <AlertDialogDescription>{t("teacher_comments.delete_description")}</AlertDialogDescription></AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t("post.cancel")}</AlertDialogCancel>
            <AlertDialogAction onClick={() => void deleteComment()}>{t("teacher_comments.delete")}</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
