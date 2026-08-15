import { useEffect, useRef, useState } from "react"
import type { FormEvent } from "react"
import { Loader2, Pencil, Plus, Search, Send, Star, Trash2 } from "lucide-react"
import { Link } from "react-router"
import { useSelector } from "react-redux"
import { useTranslation } from "react-i18next"
import type { RootState } from "@/stores"
import type { TeacherCommentItem } from "@/types"
import { teacherCommentService } from "@/services/teacherCommentService"
import { extractUserMessage } from "@/services/errorCodes"
import { toast } from "@/lib/toast"
import { formatPostRelativeDate } from "@/lib/postDisplay"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Skeleton } from "@/components/ui/skeleton"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

const COMMENT_MAX_LENGTH = 2000
const PAGE_SIZE = 20

type CommentFormValues = {
  teacherName: string
  courseName: string
  comment: string | null
  star: number
}

export default function TeacherCommentsPage() {
  const { t, i18n } = useTranslation()
  const { isAuthenticated } = useSelector((state: RootState) => state.auth)
  const [view, setView] = useState<"browse" | "mine">("browse")
  const [searchTerm, setSearchTerm] = useState("")
  const [activeKeyword, setActiveKeyword] = useState("")
  const [page, setPage] = useState(1)
  const [comments, setComments] = useState<TeacherCommentItem[]>([])
  const [hasMore, setHasMore] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<TeacherCommentItem | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<TeacherCommentItem | null>(null)
  const [mine, setMine] = useState<TeacherCommentItem[]>([])
  const [isLoadingMine, setIsLoadingMine] = useState(false)
  const [mineError, setMineError] = useState<string | null>(null)
  const observerTargetRef = useRef<HTMLDivElement | null>(null)

  const loadComments = async (keyword = activeKeyword, nextPage = 1, append = false) => {
    try {
      if (append) {
        setIsLoadingMore(true)
      } else {
        setIsLoading(true)
      }
      setLoadError(null)
      const response = await teacherCommentService.searchApproved(keyword, nextPage, PAGE_SIZE)
      const data = response.data
      const nextItems = data?.items ?? []
      setComments((current) => (append ? [...current, ...nextItems] : nextItems))
      setHasMore(data?.hasNextPage ?? false)
      setActiveKeyword(keyword)
      setPage(nextPage)
    } catch (err) {
      if (!append) {
        setComments([])
        setHasMore(false)
      }
      setLoadError(extractUserMessage(err, t("teacher_comments.load_error")))
    } finally {
      setIsLoading(false)
      setIsLoadingMore(false)
    }
  }

  const loadMine = async () => {
    setIsLoadingMine(true)
    setMineError(null)
    try {
      const response = await teacherCommentService.getMine()
      setMine(response.data ?? [])
    } catch (err) {
      setMineError(extractUserMessage(err, t("teacher_comments.mine_load_error")))
    } finally {
      setIsLoadingMine(false)
    }
  }

  useEffect(() => {
    void loadComments("", 1)
  }, [])

  useEffect(() => {
    if (view === "mine" && isAuthenticated) {
      void loadMine()
    }
  }, [view, isAuthenticated])

  useEffect(() => {
    const target = observerTargetRef.current
    if (!target) return

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (!entry?.isIntersecting || !hasMore || isLoading || isLoadingMore) return
        void loadComments(activeKeyword, page + 1, true)
      },
      { rootMargin: "0px 0px 320px 0px", threshold: 0 },
    )

    observer.observe(target)
    return () => observer.disconnect()
  }, [activeKeyword, hasMore, isLoading, isLoadingMore, page])

  const handleSearch = (event: FormEvent) => {
    event.preventDefault()
    void loadComments(searchTerm.trim(), 1)
  }

  const handleCreateSubmit = async (values: CommentFormValues) => {
    await teacherCommentService.create(values)
    toast.success(t("teacher_comments.submitted"))
    await loadComments(activeKeyword, 1)
  }

  const handleEditSubmit = async (values: CommentFormValues) => {
    if (!editTarget) return
    await teacherCommentService.update(editTarget.key, values)
    toast.success(t("teacher_comments.updated"))
    await loadMine()
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    const target = deleteTarget
    setDeleteTarget(null)

    try {
      await teacherCommentService.deleteMine(target.key)
      toast.success(t("teacher_comments.deleted"))
      await loadMine()
    } catch (err) {
      toast.error(extractUserMessage(err, t("teacher_comments.submit_error")))
    }
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 sm:px-0">
      <div className="space-y-5">
        <div className="flex items-center justify-between gap-4">
          <div className="flex rounded-2xl bg-muted/60 p-1">
            <button
              type="button"
              onClick={() => setView("browse")}
              className={`rounded-xl px-4 py-1.5 text-sm font-medium transition-colors ${
                view === "browse" ? "bg-card text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              {t("teacher_comments.browse")}
            </button>
            <button
              type="button"
              onClick={() => setView("mine")}
              className={`rounded-xl px-4 py-1.5 text-sm font-medium transition-colors ${
                view === "mine" ? "bg-card text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              {t("teacher_comments.my_comments")}
            </button>
          </div>
        </div>

        {view === "browse" ? (
          <>
            <div className="flex gap-4">
              <form onSubmit={handleSearch} className="relative flex-1">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" size={18} />
                <Input
                  type="text"
                  value={searchTerm}
                  onChange={(event) => setSearchTerm(event.target.value)}
                  placeholder={t("teacher_comments.search_placeholder")}
                  className="h-12 rounded-2xl border-border/50 bg-card pl-11 pr-12 text-sm shadow-sm transition-all focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/20"
                  aria-busy={isLoading}
                />
                {isLoading ? (
                  <Loader2
                    className="absolute right-4 top-1/2 -translate-y-1/2 animate-spin text-primary"
                    size={18}
                    aria-hidden="true"
                  />
                ) : null}
                <button type="submit" className="hidden">{t("teacher_comments.search")}</button>
              </form>
              <div className="flex items-center justify-center">
                <Button className="" onClick={() => setIsCreateDialogOpen(true)}>
                  <Plus />
                </Button>
              </div>
            </div>

            {loadError && (
              <div className="animate-in rounded-2xl bg-destructive/10 p-4 text-center text-sm font-medium text-destructive fade-in duration-300">
                {loadError}
              </div>
            )}

            {isLoading && (
              <div className="space-y-5">
                {Array.from({ length: 3 }).map((_, index) => <TeacherCommentCardSkeleton key={index} />)}
              </div>
            )}

            {!isLoading && comments.length > 0 && (
              <div className="space-y-5">
                {comments.map((item) => (
                  <TeacherCommentCard
                    key={item.key}
                    comment={item}
                    noCommentText={t("teacher_comments.no_comment")}
                    dateText={formatPostRelativeDate(item.createdOn, i18n)}
                  />
                ))}
              </div>
            )}

            {!isLoading && comments.length === 0 && (
              <div className="flex flex-col items-center gap-3 py-12 text-center">
                <div className="rounded-2xl bg-muted/50 p-4">
                  <Search size={24} className="text-muted-foreground/60" />
                </div>
                <p className="text-sm text-muted-foreground">
                  {activeKeyword ? t("teacher_comments.no_approved_comments") : t("teacher_comments.empty_list")}
                </p>
              </div>
            )}

            <div ref={observerTargetRef} className="flex justify-center py-8">
              {isLoadingMore && <Loader2 className="animate-spin text-primary" size={28} />}
              {!hasMore && comments.length > 0 && (
                <span className="text-sm text-muted-foreground">{t("teacher_comments.no_more_reviews")}</span>
              )}
            </div>
          </>
        ) : (
          <MyCommentsSection
            mine={mine}
            isLoading={isLoadingMine}
            error={mineError}
            isAuthenticated={isAuthenticated}
            noCommentText={t("teacher_comments.no_comment")}
            emptyText={t("teacher_comments.mine_empty")}
            statusApprovedText={t("teacher_comments.status_approved")}
            statusPendingText={t("teacher_comments.status_pending")}
            editText={t("teacher_comments.edit")}
            deleteText={t("teacher_comments.delete")}
            dateFormatter={(value) => formatPostRelativeDate(value, i18n)}
            onEdit={setEditTarget}
            onDelete={setDeleteTarget}
          />
        )}
      </div>

      <TeacherCommentFormDialog
        key="create"
        open={isCreateDialogOpen}
        onOpenChange={setIsCreateDialogOpen}
        isAuthenticated={isAuthenticated}
        onSubmit={handleCreateSubmit}
      />

      <TeacherCommentFormDialog
        key={editTarget?.key ?? "edit"}
        open={editTarget !== null}
        onOpenChange={(open) => { if (!open) setEditTarget(null) }}
        initial={editTarget}
        isAuthenticated
        onSubmit={handleEditSubmit}
      />

      <AlertDialog open={deleteTarget !== null} onOpenChange={(open) => { if (!open) setDeleteTarget(null) }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t("teacher_comments.delete_title")}</AlertDialogTitle>
            <AlertDialogDescription>{t("teacher_comments.delete_description")}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t("post.cancel")}</AlertDialogCancel>
            <AlertDialogAction onClick={() => void handleDelete()}>
              {t("teacher_comments.delete")}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

function MyCommentsSection({
  mine,
  isLoading,
  error,
  isAuthenticated,
  noCommentText,
  emptyText,
  statusApprovedText,
  statusPendingText,
  editText,
  deleteText,
  dateFormatter,
  onEdit,
  onDelete,
}: {
  mine: TeacherCommentItem[]
  isLoading: boolean
  error: string | null
  isAuthenticated: boolean
  noCommentText: string
  emptyText: string
  statusApprovedText: string
  statusPendingText: string
  editText: string
  deleteText: string
  dateFormatter: (value: string) => string
  onEdit: (item: TeacherCommentItem) => void
  onDelete: (item: TeacherCommentItem) => void
}) {
  if (!isAuthenticated) {
    return (
      <div className="flex flex-col items-center gap-3 py-12 text-center">
        <p className="text-sm text-muted-foreground">{emptyText}</p>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="space-y-5">
        {Array.from({ length: 3 }).map((_, index) => <TeacherCommentCardSkeleton key={index} />)}
      </div>
    )
  }

  if (error) {
    return (
      <div className="animate-in rounded-2xl bg-destructive/10 p-4 text-center text-sm font-medium text-destructive fade-in duration-300">
        {error}
      </div>
    )
  }

  if (mine.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-12 text-center">
        <p className="text-sm text-muted-foreground">{emptyText}</p>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      {mine.map((item) => (
        <MyCommentCard
          key={item.key}
          comment={item}
          noCommentText={noCommentText}
          dateText={dateFormatter(item.createdOn)}
          statusApprovedText={statusApprovedText}
          statusPendingText={statusPendingText}
          editText={editText}
          deleteText={deleteText}
          onEdit={() => onEdit(item)}
          onDelete={() => onDelete(item)}
        />
      ))}
    </div>
  )
}

function MyCommentCard({
  comment,
  noCommentText,
  dateText,
  statusApprovedText,
  statusPendingText,
  editText,
  deleteText,
  onEdit,
  onDelete,
}: {
  comment: TeacherCommentItem
  noCommentText: string
  dateText: string
  statusApprovedText: string
  statusPendingText: string
  editText: string
  deleteText: string
  onEdit: () => void
  onDelete: () => void
}) {
  return (
    <article className="rounded-3xl border border-border/40 bg-card p-5 sm:p-6">
      <div className="mb-4 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="truncate text-lg font-semibold leading-snug text-foreground">
            {comment.teacherName} - {comment.courseName}
          </h2>
          <p className="text-xs text-muted-foreground">{dateText}</p>
        </div>
        {comment.isReview ? (
          <Badge variant="secondary">{statusApprovedText}</Badge>
        ) : (
          <Badge variant="outline">{statusPendingText}</Badge>
        )}
      </div>

      <p className="whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">
        {comment.comment || noCommentText}
      </p>

      <div className="mt-5 flex items-center justify-between gap-2 border-t border-border/20 pt-4">
        <StarRating value={comment.star} readOnly />
        <div className="flex items-center gap-1">
          <Button variant="ghost" size="sm" onClick={onEdit}>
            <Pencil data-icon="inline-start" />
            {editText}
          </Button>
          <Button variant="ghost" size="sm" className="text-destructive hover:text-destructive" onClick={onDelete}>
            <Trash2 data-icon="inline-start" />
            {deleteText}
          </Button>
        </div>
      </div>
    </article>
  )
}

function TeacherCommentFormDialog({
  open,
  onOpenChange,
  initial,
  isAuthenticated,
  onSubmit,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  initial?: TeacherCommentItem | null
  isAuthenticated: boolean
  onSubmit: (values: CommentFormValues) => Promise<void>
}) {
  const { t } = useTranslation()
  const isEditing = initial != null
  const [teacherName, setTeacherName] = useState("")
  const [courseName, setCourseName] = useState("")
  const [comment, setComment] = useState("")
  const [star, setStar] = useState(5)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  useEffect(() => {
    if (open) {
      setTeacherName(initial?.teacherName ?? "")
      setCourseName(initial?.courseName ?? "")
      setComment(initial?.comment ?? "")
      setStar(initial?.star ?? 5)
      setFormError(null)
      setIsSubmitting(false)
    }
  }, [open, initial])

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()

    if (!teacherName.trim()) {
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
      await onSubmit({
        teacherName: teacherName.trim(),
        courseName: courseName.trim(),
        comment: comment.trim() || null,
        star,
      })
      onOpenChange(false)
    } catch (err) {
      setFormError(extractUserMessage(err, t("teacher_comments.submit_error")))
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{isEditing ? t("teacher_comments.edit_title") : t("teacher_comments.create_title")}</DialogTitle>
          <DialogDescription>{isEditing ? t("teacher_comments.edit_subtitle") : t("teacher_comments.create_subtitle")}</DialogDescription>
        </DialogHeader>
        {!isEditing && !isAuthenticated ? (
          <div className="mt-5 rounded-2xl bg-muted/50 p-4 text-sm text-muted-foreground">
            {t("teacher_comments.login_required")}{" "}
            <Link to="/login" className="font-medium text-primary hover:underline">
              {t("nav.login")}
            </Link>
          </div>
        ) : (
          <form id="teacher-comment-form" onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <label className="text-sm font-medium">{t("teacher_comments.teacher_label")}</label>
              <Input
                value={teacherName}
                onChange={(event) => setTeacherName(event.target.value)}
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
              <StarRating value={star} onChange={setStar} />
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
          </form>
        )}
        <DialogFooter>
          <Button variant="outline" type="button" onClick={() => onOpenChange(false)}>
            {t("post.cancel")}
          </Button>
          <Button form="teacher-comment-form" type="submit" disabled={isSubmitting}>
            {isSubmitting ? <Loader2 className="animate-spin" data-icon="inline-start" /> : isEditing ? <Pencil data-icon="inline-start" /> : <Send data-icon="inline-start" />}
            {isEditing ? t("teacher_comments.save") : t("teacher_comments.submit")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function TeacherCommentCard({
  comment,
  noCommentText,
  dateText,
}: {
  comment: TeacherCommentItem
  noCommentText: string
  dateText: string
}) {
  const authorName = comment.author?.name?.trim() || comment.userId
  const authorAvatar = comment.author?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${comment.userId}`
  const authorInitials = authorName.slice(0, 2).toUpperCase()

  return (
    <article className="group rounded-3xl border border-border/40 bg-card p-5 sm:p-6 transition-all duration-300 hover:border-primary/20 hover:shadow-md hover:shadow-primary/5 hover:-translate-y-0.5">
      <div className="mb-4 flex items-center gap-3">
        <Avatar className="h-10 w-10 rounded-full ring-2 ring-border/20">
          <AvatarImage src={authorAvatar} alt={authorName} />
          <AvatarFallback className="bg-primary/10 text-primary text-xs font-medium">
            {authorInitials}
          </AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold">{authorName}</p>
          <p className="text-xs text-muted-foreground">{dateText}</p>
        </div>
      </div>

      <div className="mb-5 space-y-2">
        <h2 className="truncate text-lg font-semibold leading-snug text-foreground">
          {comment.teacherName} - {comment.courseName}
        </h2>
        <p className="whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">
          {comment.comment || noCommentText}
        </p>
      </div>

      <div className="flex items-center gap-2 border-t border-border/20 pt-4">
        <StarRating value={comment.star} readOnly />
      </div>
    </article>
  )
}

function TeacherCommentCardSkeleton() {
  return (
    <div className="space-y-4 rounded-3xl border border-border/40 bg-card p-5 sm:p-6">
      <div className="flex items-center gap-3">
        <Skeleton className="h-10 w-10 rounded-full" />
        <div className="space-y-1.5">
          <Skeleton className="h-4 w-28" />
          <Skeleton className="h-3 w-20" />
        </div>
      </div>
      <div className="space-y-2">
        <Skeleton className="h-5 w-16 rounded-full" />
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-2/3" />
      </div>
      <div className="flex items-center gap-1.5 border-t border-border/20 pt-4">
        <Skeleton className="h-4 w-20" />
      </div>
    </div>
  )
}

function StarRating({
  value,
  onChange,
  readOnly = false,
}: {
  value: number
  onChange?: (value: number) => void
  readOnly?: boolean
}) {
  const roundedValue = Math.round(value)
  return (
    <div className="flex items-center gap-0.5" role={readOnly ? "img" : "radiogroup"}>
      {[1, 2, 3, 4, 5].map((item) => {
        const isActive = item <= roundedValue
        if (readOnly) {
          return (
            <Star
              key={item}
              className={isActive ? "fill-primary text-primary" : "text-muted-foreground/40"}
              size={16}
            />
          )
        }

        return (
          <button
            key={item}
            type="button"
            className={isActive ? "text-primary" : "text-muted-foreground/40"}
            onClick={() => onChange?.(item)}
            aria-checked={item === value}
            role="radio"
          >
            <Star className={isActive ? "fill-current" : ""} size={24} />
          </button>
        )
      })}
    </div>
  )
}
