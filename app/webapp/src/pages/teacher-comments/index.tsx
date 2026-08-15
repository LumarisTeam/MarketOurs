import { useEffect, useRef, useState } from "react"
import type { FormEvent } from "react"
import { Loader2, Plus, Search } from "lucide-react"
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
import {
  TeacherCommentCard,
  TeacherCommentCardSkeleton,
  TeacherCommentFormDialog,
  type CommentFormValues,
} from "@/components/teacher-comment"
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

const PAGE_SIZE = 20

export default function TeacherCommentsPage() {
  const { t, i18n } = useTranslation()
  const { user } = useSelector((state: RootState) => state.auth)
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
  const observerTargetRef = useRef<HTMLDivElement | null>(null)

  const isMine = (item: TeacherCommentItem) =>
    !!user && (item.userId.toLowerCase() === user.id.toLowerCase() || user.role === "Admin")

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

  useEffect(() => {
    void loadComments("", 1)
  }, [])

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
    await loadComments(activeKeyword, 1)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    const target = deleteTarget
    setDeleteTarget(null)

    try {
      await teacherCommentService.deleteMine(target.key)
      toast.success(t("teacher_comments.deleted"))
      await loadComments(activeKeyword, 1)
    } catch (err) {
      toast.error(extractUserMessage(err, t("teacher_comments.submit_error")))
    }
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 sm:px-0">
      <div className="space-y-5">
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
                isMine={isMine(item)}
                editText={t("teacher_comments.edit")}
                deleteText={t("teacher_comments.delete")}
                onEdit={setEditTarget}
                onDelete={setDeleteTarget}
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
      </div>

      <TeacherCommentFormDialog
        key="create"
        open={isCreateDialogOpen}
        onOpenChange={setIsCreateDialogOpen}
        isAuthenticated={!!user}
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
