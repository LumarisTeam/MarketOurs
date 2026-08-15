import { useEffect, useState } from "react"
import type { FormEvent } from "react"
import { Loader2, MoreHorizontal, Pencil, Send, Star, Trash2 } from "lucide-react"
import { Link } from "react-router"
import { useTranslation } from "react-i18next"
import type { TeacherCommentItem } from "@/types"
import { extractUserMessage } from "@/services/errorCodes"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Skeleton } from "@/components/ui/skeleton"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

export const COMMENT_MAX_LENGTH = 2000

export type CommentFormValues = {
  teacherName: string
  courseName: string
  comment: string | null
  star: number
}

export function TeacherCommentCard({
  comment,
  noCommentText,
  dateText,
  isMine = false,
  showStatus = false,
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
  isMine?: boolean
  showStatus?: boolean
  statusApprovedText?: string
  statusPendingText?: string
  editText?: string
  deleteText?: string
  onEdit?: (comment: TeacherCommentItem) => void
  onDelete?: (comment: TeacherCommentItem) => void
}) {
  const authorName = comment.author?.name?.trim() || comment.userId
  const authorAvatar = comment.author?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${comment.userId}`
  const authorInitials = authorName.slice(0, 2).toUpperCase()
  const hasActions = isMine && onEdit && onDelete

  return (
    <article className="group relative rounded-3xl border border-border/40 bg-card p-5 sm:p-6 transition-all duration-300 hover:border-primary/20 hover:shadow-md hover:shadow-primary/5 hover:-translate-y-0.5">
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

        {hasActions && (
          <DropdownMenu>
            <DropdownMenuTrigger
              render={
                <button
                  type="button"
                  className="rounded-xl p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
                  aria-label="more"
                >
                  <MoreHorizontal size={18} />
                </button>
              }
            />
            <DropdownMenuContent align="end" sideOffset={4} className="w-40">
              <DropdownMenuItem className="rounded-lg" onClick={() => onEdit(comment)}>
                <Pencil size={14} className="mr-2" />
                {editText}
              </DropdownMenuItem>
              <DropdownMenuItem variant="destructive" className="rounded-lg" onClick={() => onDelete(comment)}>
                <Trash2 size={14} className="mr-2" />
                {deleteText}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      </div>

      <div className="mb-5 space-y-2">
        <div className="flex items-center gap-2">
          <h2 className="min-w-0 flex-1 truncate text-lg font-semibold leading-snug text-foreground">
            {comment.teacherName} - {comment.courseName}
          </h2>
          {showStatus && (
            comment.isReview ? (
              <Badge variant="secondary">{statusApprovedText}</Badge>
            ) : (
              <Badge variant="outline">{statusPendingText}</Badge>
            )
          )}
        </div>
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

export function TeacherCommentCardSkeleton() {
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

export function TeacherCommentFormDialog({
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

export function StarRating({
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
