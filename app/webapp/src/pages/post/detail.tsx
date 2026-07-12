import { Link, useParams, useNavigate } from "react-router"
import { Heart, Share2, ArrowLeft, MoreHorizontal, Send, Loader2, ChevronLeft, ChevronRight, X, ImagePlus } from "lucide-react"
import { useState, useEffect, useRef, useMemo, useCallback } from "react"
import { postService } from "@/services/postService"
import { commentService } from "@/services/commentService"
import { fileService } from "@/services/fileService"
import { compressImages } from "@/services/imageCompression"
import type { PostDto, CommentDto } from "@/types"
import { useSelector } from "react-redux"
import type { RootState } from "@/stores"
import { useTranslation } from "react-i18next"
import { extractUserMessage } from "@/services/errorCodes"
import type { i18n, TFunction } from "i18next"
import { cn } from "@/lib/utils"
import { sharePost } from "@/lib/postShare"
import { DTO_LIMITS, requiredMax } from "@/lib/dtoValidation"
import { PostTagBadge } from "@/components/post/PostTagBadge"
import { formatEditedRelativeTime } from "@/lib/dateTime"
import SortableImageGrid, { type ImageItem } from "@/components/ui/sortable-image-grid"
import { OptimizedImage } from "@/components/ui/optimized-image"
import { arrayMove } from "@dnd-kit/sortable"
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
const MAX_COMMENT_IMAGES = 3;


// 一条被展平的回复：comment 是回复本身，replyTo 是它直接回复的那条评论；
// 当 replyTo 为 null 时表示它是直接回复顶层评论(不显示 @)，否则显示 @对方。
type FlatReply = { comment: CommentDto; replyTo: CommentDto | null };

// 将一条顶层评论下的所有后代回复展平成单层列表(只保留两级:顶层评论 + 其下所有回复)。
// 直接回复顶层评论的 replyTo 记为 null;回复某条回复的则记录被回复者,用于渲染 @对方。
// 列表按创建时间从早到晚排序,读起来像一段对话。
function flattenReplies(root: CommentDto): FlatReply[] {
  const out: FlatReply[] = [];
  const walk = (nodes: CommentDto[] | undefined, parent: CommentDto, parentIsRoot: boolean) => {
    if (!nodes) return;
    for (const child of nodes) {
      out.push({ comment: child, replyTo: parentIsRoot ? null : parent });
      walk(child.repliedComments, child, false);
    }
  };
  walk(root.repliedComments, root, true);
  out.sort(
    (a, b) => new Date(a.comment.createdAt).getTime() - new Date(b.comment.createdAt).getTime()
  );
  return out;
}

async function uploadCommentImageFiles(
  files: File[],
  onProgress?: (fraction: number) => void,
): Promise<string[]> {
  if (files.length === 0) return [];

  const keyResponse = await fileService.getUploadKey();
  const uploadKey = keyResponse.data?.key;
  const compressed = await compressImages(files, {
    quality: 0.75,
    maxWidth: 1920,
    maxHeight: 1920,
  });
  return (await fileService.uploadStream(compressed, uploadKey, onProgress)).data ?? [];
}

function CommentImageGrid({ images, imageLabel }: { images: string[]; imageLabel: string }) {
  const { t } = useTranslation();
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);
  if (images.length === 0) return null;

  return (
    <>
      <div className={cn("mt-3 grid gap-2", images.length === 1 ? "max-w-[220px] grid-cols-1" : "grid-cols-3 max-w-[300px]")}>
        {images.map((image, index) => (
          <button
            key={`${image}-${index}`}
            type="button"
            onClick={() => setViewerIndex(index)}
            className="aspect-square overflow-hidden rounded-xl border border-border/50 bg-muted"
          >
            <OptimizedImage src={image} alt={`${imageLabel} ${index + 1}`} className="h-full w-full object-cover" loading="lazy" />
          </button>
        ))}
      </div>

      {viewerIndex !== null && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-background/95 p-4 backdrop-blur-sm animate-in fade-in duration-200"
          role="dialog"
          aria-modal="true"
          onClick={() => setViewerIndex(null)}
        >
          <button
            type="button"
            onClick={() => setViewerIndex(null)}
            className="absolute right-4 top-4 grid size-11 place-items-center rounded-full bg-muted text-foreground transition-colors hover:bg-border"
            aria-label={t("post.close_image_viewer")}
          >
            <X size={22} />
          </button>
          <OptimizedImage
            src={images[viewerIndex]}
            className="max-h-[88vh] max-w-[92vw] rounded-2xl object-contain shadow-2xl"
            alt={`${imageLabel} ${viewerIndex + 1}`}
            onClick={(event) => event.stopPropagation()}
            loading="eager"
            fetchPriority="high"
          />
        </div>
      )}
    </>
  );
}

function PostImageCarousel({ images, imageLabel }: { images: string[]; imageLabel: string }) {
  const { t } = useTranslation();
  const [currentIndex, setCurrentIndex] = useState(0);
  const [viewerIndex, setViewerIndex] = useState<number | null>(null);
  const hasMultipleImages = images.length > 1;
  const safeCurrentIndex = Math.min(currentIndex, images.length - 1);

  useEffect(() => {
    if (viewerIndex === null) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setViewerIndex(null);
      } else if (event.key === "ArrowLeft") {
        setViewerIndex((index) => (index === null ? index : Math.max(0, index - 1)));
      } else if (event.key === "ArrowRight") {
        setViewerIndex((index) => (index === null ? index : Math.min(images.length - 1, index + 1)));
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [images.length, viewerIndex]);

  const goToPrevious = () => {
    setCurrentIndex((index) => Math.max(0, index - 1));
  };

  const goToNext = () => {
    setCurrentIndex((index) => Math.min(images.length - 1, index + 1));
  };

  const goToViewerPrevious = () => {
    setViewerIndex((index) => (index === null ? index : Math.max(0, index - 1)));
  };

  const goToViewerNext = () => {
    setViewerIndex((index) => (index === null ? index : Math.min(images.length - 1, index + 1)));
  };

  return (
    <>
      <div className="my-8 space-y-4">
        <div className="relative overflow-hidden rounded-[2rem] border border-border/50 bg-muted">
          <div
            className="flex transition-transform duration-500 ease-out"
            style={{ transform: `translateX(-${safeCurrentIndex * 100}%)` }}
          >
            {images.map((img, idx) => (
              <button
                key={`${img}-${idx}`}
                type="button"
                onClick={() => setViewerIndex(idx)}
                className="group relative min-w-full aspect-video overflow-hidden bg-muted text-left"
              >
                <OptimizedImage
                  src={img}
                  className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.02]"
                  alt={`${imageLabel} ${idx + 1}`}
                  loading={idx === 0 ? "eager" : "lazy"}
                  fetchPriority={idx === 0 ? "high" : "low"}
                />
              </button>
            ))}
          </div>

          {hasMultipleImages && (
            <>
              <button
                type="button"
                onClick={goToPrevious}
                disabled={safeCurrentIndex === 0}
                className="absolute left-3 top-1/2 grid size-10 -translate-y-1/2 place-items-center rounded-full bg-background/85 text-foreground shadow-lg backdrop-blur transition-all hover:bg-background disabled:pointer-events-none disabled:opacity-35"
                aria-label={t("post.previous_image")}
              >
                <ChevronLeft size={20} />
              </button>
              <button
                type="button"
                onClick={goToNext}
                disabled={safeCurrentIndex === images.length - 1}
                className="absolute right-3 top-1/2 grid size-10 -translate-y-1/2 place-items-center rounded-full bg-background/85 text-foreground shadow-lg backdrop-blur transition-all hover:bg-background disabled:pointer-events-none disabled:opacity-35"
                aria-label={t("post.next_image")}
              >
                <ChevronRight size={20} />
              </button>
              <div className="absolute bottom-3 left-1/2 flex -translate-x-1/2 items-center gap-2 rounded-full bg-background/85 px-3 py-2 shadow-lg backdrop-blur">
                {images.map((_, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => setCurrentIndex(idx)}
                    className={cn(
                      "size-2 rounded-full transition-all",
                      idx === safeCurrentIndex ? "w-5 bg-primary" : "bg-muted-foreground/40 hover:bg-muted-foreground/70"
                    )}
                    aria-label={`Go to image ${idx + 1}`}
                  />
                ))}
              </div>
              <div className="absolute right-3 top-3 rounded-full bg-background/85 px-3 py-1.5 text-xs font-bold text-foreground shadow-lg backdrop-blur">
                {safeCurrentIndex + 1} / {images.length}
              </div>
            </>
          )}
        </div>
      </div>

      {viewerIndex !== null && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-background/95 p-4 backdrop-blur-sm animate-in fade-in duration-200"
          role="dialog"
          aria-modal="true"
          onClick={() => setViewerIndex(null)}
        >
          <button
            type="button"
            onClick={() => setViewerIndex(null)}
            className="absolute right-4 top-4 grid size-11 place-items-center rounded-full bg-muted text-foreground transition-colors hover:bg-border"
            aria-label={t("post.close_image_viewer")}
          >
            <X size={22} />
          </button>
          {hasMultipleImages && (
            <button
              type="button"
              onClick={(event) => {
                event.stopPropagation();
                goToViewerPrevious();
              }}
              disabled={viewerIndex === 0}
              className="absolute left-4 top-1/2 grid size-11 -translate-y-1/2 place-items-center rounded-full bg-muted text-foreground transition-colors hover:bg-border disabled:opacity-35"
              aria-label={t("post.previous_image")}
            >
              <ChevronLeft size={24} />
            </button>
          )}
          <OptimizedImage
            src={images[viewerIndex]}
            className="max-h-[88vh] max-w-[92vw] rounded-2xl object-contain shadow-2xl"
            alt={`${imageLabel} ${viewerIndex + 1}`}
            onClick={(event) => event.stopPropagation()}
            loading="eager"
            fetchPriority="high"
          />
          {hasMultipleImages && (
            <>
              <button
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  goToViewerNext();
                }}
                disabled={viewerIndex === images.length - 1}
                className="absolute right-4 top-1/2 grid size-11 -translate-y-1/2 place-items-center rounded-full bg-muted text-foreground transition-colors hover:bg-border disabled:opacity-35"
                aria-label={t("post.next_image")}
              >
                <ChevronRight size={24} />
              </button>
              <div className="absolute bottom-4 left-1/2 -translate-x-1/2 rounded-full bg-muted px-4 py-2 text-sm font-bold text-foreground">
                {viewerIndex + 1} / {images.length}
              </div>
            </>
          )}
        </div>
      )}
    </>
  );
}

function CommentItem({
  comment,
  replyTo,
  replies,
  user,
  i18n,
  t,
  onUpdate,
  onReply,
  onDelete,
  onLike,
  likedComments,
}: {
  comment: CommentDto;
  // 该评论直接回复的对象;有值时在内容前显示 @对方(仅楼中楼的回复-回复场景)
  replyTo?: CommentDto | null;
  // 仅顶层评论传入:其下被展平的所有回复
  replies?: FlatReply[];
  user: RootState["auth"]["user"];
  i18n: i18n;
  t: TFunction;
  onUpdate: (id: string, content: string, images: string[]) => Promise<void>;
  onReply: (parentId: string, content: string, images: string[]) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
  onLike: (id: string) => Promise<void>;
  likedComments: Set<string>;
}) {
  const [isEditing, setIsEditing] = useState(false);
  const [editContent, setEditContent] = useState(comment.content);
  const [editExistingImages, setEditExistingImages] = useState<string[]>(comment.images || []);
  const [editImageItems, setEditImageItems] = useState<ImageItem[]>([]);
  const [editUploadProgress, setEditUploadProgress] = useState<number | null>(null);
  const [isReplying, setIsReplying] = useState(false);
  const [replyContent, setReplyContent] = useState("");
  const [replyImageFiles, setReplyImageFiles] = useState<File[]>([]);
  const [replyImagePreviews, setReplyImagePreviews] = useState<string[]>([]);
  const [replyImageIds, setReplyImageIds] = useState<string[]>([]);
  const [replyUploadProgress, setReplyUploadProgress] = useState<number | null>(null);
  const [replySubmitting, setReplySubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const editPreviewRef = useRef<ImageItem[]>([]);
  const replyPreviewRef = useRef<string[]>([]);

  useEffect(() => {
    editPreviewRef.current = editImageItems;
  }, [editImageItems]);

  useEffect(() => {
    replyPreviewRef.current = replyImagePreviews;
  }, [replyImagePreviews]);

  useEffect(() => {
    return () => {
      editPreviewRef.current.forEach((item) => {
        if (item.type === 'new') URL.revokeObjectURL(item.url);
      });
      replyPreviewRef.current.forEach((preview) => URL.revokeObjectURL(preview));
    };
  }, []);

  // Initialize editImageItems when entering edit mode
  useEffect(() => {
    if (isEditing) {
      setEditImageItems(
        editExistingImages.map((url) => ({
          id: url,
          type: 'existing' as const,
          url,
          originalUrl: url,
        }))
      );
    }
  }, [isEditing]); // eslint-disable-line react-hooks/exhaustive-deps

  const isMe = user && comment.userId.toLowerCase() === user.id.toLowerCase();
  const isAdmin = user && user.role === 'Admin';
  
  const authorName = comment.author?.name || `${t("common.user")} ${comment.userId.slice(0, 4)}`;
  const displayName = isMe ? `${authorName} (${t("common.me")})` : authorName;
  const authorAvatar = comment.author?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${comment.userId}`;

  const handleSave = async () => {
    const existingUrls = editImageItems.filter((i) => i.type === 'existing').map((i) => i.originalUrl!);
    const newFiles = editImageItems.filter((i) => i.type === 'new').map((i) => i.file!);
    if (!editContent.trim() && existingUrls.length === 0 && newFiles.length === 0) return;
    if (editContent.trim().length > DTO_LIMITS.commentContentMax) return;
    try {
      setEditUploadProgress(newFiles.length > 0 ? 0 : null);
      const uploadedUrls = await uploadCommentImageFiles(newFiles, setEditUploadProgress);
      // Build final images preserving merged order
      let uploadedIdx = 0;
      const allImages = editImageItems.map((item) => {
        if (item.type === 'existing') return item.originalUrl!;
        return uploadedUrls[uploadedIdx++] ?? '';
      });
      await onUpdate(comment.id, editContent, allImages);
      editImageItems.forEach((item) => {
        if (item.type === 'new') URL.revokeObjectURL(item.url);
      });
      setEditImageItems([]);
      setIsEditing(false);
    } finally {
      setEditUploadProgress(null);
    }
  };

  const handleDelete = async () => {
    setIsDeleting(true);
    try {
      await onDelete(comment.id);
    } finally {
      setIsDeleting(false);
    }
  };

  const handleSubmitReply = async () => {
    if (!replyContent.trim() && replyImageFiles.length === 0) return;
    if (replyContent.trim().length > DTO_LIMITS.commentContentMax) return;
    setReplySubmitting(true);
    try {
      setReplyUploadProgress(replyImageFiles.length > 0 ? 0 : null);
      const uploadedImages = await uploadCommentImageFiles(replyImageFiles, setReplyUploadProgress);
      await onReply(comment.id, replyContent, uploadedImages);
      setReplyContent("");
      replyImagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
      setReplyImageFiles([]);
      setReplyImagePreviews([]);
      setReplyImageIds([]);
      setIsReplying(false);
    } finally {
      setReplySubmitting(false);
      setReplyUploadProgress(null);
    }
  };

  const addEditImages = (files: FileList | null) => {
    if (!files) return;
    const totalCount = editImageItems.length;
    const remaining = MAX_COMMENT_IMAGES - totalCount;
    const nextFiles = Array.from(files).slice(0, Math.max(0, remaining));
    if (nextFiles.length === 0) return;
    const nextItems: ImageItem[] = nextFiles.map((file) => ({
      id: crypto.randomUUID(),
      type: 'new' as const,
      url: URL.createObjectURL(file),
      file,
    }));
    setEditImageItems((prev) => [...prev, ...nextItems]);
  };

  const addReplyImages = (files: FileList | null) => {
    if (!files) return;
    const remaining = MAX_COMMENT_IMAGES - replyImageFiles.length;
    const nextFiles = Array.from(files).slice(0, Math.max(0, remaining));
    if (nextFiles.length === 0) return;
    setReplyImageFiles((prev) => [...prev, ...nextFiles]);
    setReplyImagePreviews((prev) => [...prev, ...nextFiles.map((file) => URL.createObjectURL(file))]);
    setReplyImageIds((prev) => [...prev, ...nextFiles.map(() => crypto.randomUUID())]);
  };

  const handleEditImageRemove = useCallback((itemId: string) => {
    setEditImageItems((prev) => {
      const item = prev.find((i) => i.id === itemId);
      if (item?.type === 'new') {
        URL.revokeObjectURL(item.url);
      }
      return prev.filter((i) => i.id !== itemId);
    });
  }, []);

  const handleEditImageReorder = useCallback((fromIndex: number, toIndex: number) => {
    setEditImageItems((prev) => arrayMove(prev, fromIndex, toIndex));
  }, []);

  const removeReplyFile = useCallback((itemId: string) => {
    const index = replyImageIds.indexOf(itemId);
    if (index === -1) return;
    URL.revokeObjectURL(replyImagePreviews[index]);
    setReplyImageFiles((prev) => prev.filter((_, i) => i !== index));
    setReplyImagePreviews((prev) => prev.filter((_, i) => i !== index));
    setReplyImageIds((prev) => prev.filter((_, i) => i !== index));
  }, [replyImageIds, replyImagePreviews]);

  const handleReplyImageReorder = useCallback((fromIndex: number, toIndex: number) => {
    setReplyImageFiles((prev) => arrayMove(prev, fromIndex, toIndex));
    setReplyImagePreviews((prev) => arrayMove(prev, fromIndex, toIndex));
    setReplyImageIds((prev) => arrayMove(prev, fromIndex, toIndex));
  }, []);

  const replyImageItems: ImageItem[] = useMemo(() =>
    replyImageIds.map((id, i) => ({
      id,
      type: 'new' as const,
      url: replyImagePreviews[i] ?? '',
      file: replyImageFiles[i],
    })),
    [replyImageIds, replyImagePreviews, replyImageFiles]
  );

  return (
    <div className={cn("flex gap-4 group transition-opacity", isDeleting && "opacity-50 pointer-events-none")}>
      <Link to={`/user/${comment.userId}`} className="flex-shrink-0">
        <OptimizedImage src={authorAvatar} alt={authorName} className="w-10 h-10 rounded-full bg-muted shadow-sm" />
      </Link>
      <div className="flex-1 space-y-2">
        <div className="p-5 rounded-[1.5rem] bg-card border border-border/40 shadow-sm group-hover:border-primary/20 transition-colors">
          <div className="flex items-center justify-between mb-1">
            <Link to={`/user/${comment.userId}`} className="font-bold text-sm transition-colors hover:text-primary">
              {displayName}
            </Link>
            <p className="text-xs text-muted-foreground">
              {formatEditedRelativeTime(comment.createdAt, i18n.resolvedLanguage, comment.updatedAt, t("post.edited"))}
            </p>
          </div>
          
          {isEditing ? (
            <div className="space-y-4 mt-2">
              <textarea
                value={editContent}
                onChange={(e) => setEditContent(e.target.value)}
                maxLength={DTO_LIMITS.commentContentMax}
                className="w-full min-h-[100px] bg-transparent border border-border/50 rounded-xl p-3 outline-none focus:border-primary transition-colors resize-none text-sm"
              />
              <div className="space-y-3">
                <SortableImageGrid
                  items={editImageItems}
                  onReorder={handleEditImageReorder}
                  onRemove={handleEditImageRemove}
                  disabled={editUploadProgress !== null}
                />
                <div className="flex items-center gap-3">
                  <label className={cn(
                    "grid size-9 place-items-center rounded-xl border border-border bg-muted transition-colors",
                    editImageItems.length < MAX_COMMENT_IMAGES ? "cursor-pointer hover:border-primary hover:text-primary" : "opacity-40"
                  )}>
                    <ImagePlus size={16} />
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      disabled={editImageItems.length >= MAX_COMMENT_IMAGES}
                      onChange={(event) => {
                        addEditImages(event.target.files);
                        event.target.value = "";
                      }}
                      className="hidden"
                    />
                  </label>
                  <span className="text-xs text-muted-foreground">{editImageItems.length} / {MAX_COMMENT_IMAGES}</span>
                </div>
                {editUploadProgress !== null && (
                  <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
                    <div className="h-full bg-primary transition-all" style={{ width: `${editUploadProgress * 100}%` }} />
                  </div>
                )}
              </div>
              <div className="flex gap-2">
                <button
                  onClick={handleSave}
                  disabled={!editContent.trim() && editImageItems.length === 0}
                  className="text-xs font-bold px-3 py-1.5 rounded-lg bg-primary text-primary-foreground hover:opacity-90 transition-opacity"
                >
                  {t("post.save")}
                </button>
                <button
                  onClick={() => {
                    setIsEditing(false);
                    setEditContent(comment.content);
                    setEditExistingImages(comment.images || []);
                    editImageItems.forEach((item) => {
                      if (item.type === 'new') URL.revokeObjectURL(item.url);
                    });
                    setEditImageItems([]);
                  }}
                  className="text-xs font-bold px-3 py-1.5 rounded-lg bg-muted hover:bg-border transition-colors"
                >
                  {t("post.cancel")}
                </button>
              </div>
            </div>
          ) : (
            <p className="text-muted-foreground leading-relaxed text-sm whitespace-pre-wrap">
              {replyTo && (
                <Link
                  to={`/user/${replyTo.userId}`}
                  className="font-bold text-primary hover:underline mr-1"
                >
                  @{replyTo.author?.name || `${t("common.user")} ${replyTo.userId.slice(0, 4)}`}
                </Link>
              )}
              {comment.content}
            </p>
          )}
          {!isEditing && <CommentImageGrid images={comment.images || []} imageLabel="Comment image" />}
        </div>
        
        <div className="flex items-center gap-4 ml-2">
          <button 
            onClick={() => onLike(comment.id)}
            disabled={!user}
            className={cn(
              "text-xs font-bold transition-colors flex items-center gap-1.5 px-2 py-1 rounded-md",
              user ? "hover:bg-primary/10 hover:text-primary text-muted-foreground" : "text-muted-foreground/50 cursor-not-allowed"
            )}
          >
            <Heart size={14} className={cn(likedComments.has(comment.id) && "fill-primary text-primary")} />
            {comment.likes}
          </button>
          
          {user && (
            <button 
              onClick={() => setIsReplying(!isReplying)}
              className={cn("text-xs font-bold transition-colors", isReplying ? "text-primary" : "text-muted-foreground hover:text-primary")}
            >
              {t("post.reply")}
            </button>
          )}
          
          {(isMe || isAdmin) && !isEditing && (
            <div className="flex gap-4">
              {isMe && (
                <button 
                  onClick={() => setIsEditing(true)}
                  className="text-xs font-bold text-primary/70 hover:text-primary transition-colors"
                >
                  {t("post.edit")}
                </button>
              )}
              <button
                onClick={() => setShowDeleteDialog(true)}
                className="text-xs font-bold text-destructive/70 hover:text-destructive transition-colors"
              >
                {t("post.delete")}
              </button>
            </div>
          )}
        </div>

        <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{t("post.delete")}</AlertDialogTitle>
              <AlertDialogDescription>{t("post.confirm_delete")}</AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t("post.cancel")}</AlertDialogCancel>
              <AlertDialogAction variant="destructive" onClick={handleDelete}>
                {t("post.delete")}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>

        {isReplying && (
          <div className="mt-4 space-y-3 animate-in slide-in-from-top-2 duration-300">
            <textarea
              placeholder={`${t("post.reply")} @${authorName}...`}
              value={replyContent}
              onChange={(e) => setReplyContent(e.target.value)}
              maxLength={DTO_LIMITS.commentContentMax}
              className="w-full min-h-[80px] bg-muted/30 border border-border/50 rounded-2xl p-3 outline-none focus:border-primary transition-all text-sm resize-none"
              autoFocus
            />
            <SortableImageGrid
              items={replyImageItems}
              onReorder={handleReplyImageReorder}
              onRemove={removeReplyFile}
              disabled={replySubmitting}
            />
            <div className="flex items-center gap-3">
              <label className={cn(
                "grid size-9 place-items-center rounded-xl border border-border bg-muted transition-colors",
                replyImageFiles.length < MAX_COMMENT_IMAGES ? "cursor-pointer hover:border-primary hover:text-primary" : "opacity-40"
              )}>
                <ImagePlus size={16} />
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  disabled={replyImageFiles.length >= MAX_COMMENT_IMAGES}
                  onChange={(event) => {
                    addReplyImages(event.target.files);
                    event.target.value = "";
                  }}
                  className="hidden"
                />
              </label>
              <span className="text-xs text-muted-foreground">{replyImageFiles.length} / {MAX_COMMENT_IMAGES}</span>
            </div>
            {replyUploadProgress !== null && (
              <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
                <div className="h-full bg-primary transition-all" style={{ width: `${replyUploadProgress * 100}%` }} />
              </div>
            )}
            <div className="flex gap-2">
              <button
                onClick={handleSubmitReply}
                disabled={(!replyContent.trim() && replyImageFiles.length === 0) || replySubmitting}
                className="text-xs font-bold px-4 py-2 rounded-xl bg-primary text-primary-foreground hover:opacity-90 disabled:opacity-50 transition-all flex items-center gap-2"
              >
                {replySubmitting ? <Loader2 size={14} className="animate-spin" /> : <Send size={14} />}
                {t("post.submit")}
              </button>
              <button
                onClick={() => {
                  setIsReplying(false);
                  replyImagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
                  setReplyImageFiles([]);
                  setReplyImagePreviews([]);
                  setReplyImageIds([]);
                }}
                className="text-xs font-bold px-4 py-2 rounded-xl bg-muted hover:bg-border transition-all"
              >
                {t("post.cancel")}
              </button>
            </div>
          </div>
        )}

        {/* 渲染回复:只展开到两级,更深的回复被展平到这里并用 @对方 标注 */}
        {replies && replies.length > 0 && (
          <div className="mt-4 space-y-6 pl-4 border-l-2 border-border/20">
            {replies.map(({ comment: reply, replyTo: target }) => (
              <CommentItem
                key={reply.id}
                comment={reply}
                replyTo={target}
                user={user}
                i18n={i18n}
                t={t}
                onUpdate={onUpdate}
                onReply={onReply}
                onDelete={onDelete}
                onLike={onLike}
                likedComments={likedComments}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default function PostDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { t, i18n } = useTranslation()
  const { user } = useSelector((state: RootState) => state.auth)

  const [post, setPost] = useState<PostDto | null>(null)
  const [comments, setComments] = useState<CommentDto[]>([])
  const [commentContent, setCommentContent] = useState("")
  const [commentImageFiles, setCommentImageFiles] = useState<File[]>([])
  const [commentImagePreviews, setCommentImagePreviews] = useState<string[]>([])
  const [commentImageIds, setCommentImageIds] = useState<string[]>([])
  const [commentUploadProgress, setCommentUploadProgress] = useState<number | null>(null)
  const commentPreviewRef = useRef<string[]>([])
  const [loading, setLoading] = useState(true)
  const [commentsLoading, setCommentsLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [commentSort, setCommentSort] = useState<"recent" | "hot">("recent")
  const [postLiked, setPostLiked] = useState(false)
  const [likedComments, setLikedComments] = useState<Set<string>>(new Set())
  const [shareFeedback, setShareFeedback] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [showPostDeleteDialog, setShowPostDeleteDialog] = useState(false)

  // Editing state for post
  const [isEditingPost, setIsEditingPost] = useState(false)
  const [editTitle, setEditTitle] = useState("")
  const [editContent, setEditContent] = useState("")
  const [editImageItems, setEditImageItems] = useState<ImageItem[]>([])
  const [editUploadProgress, setEditUploadProgress] = useState<number | null>(null)
  const editPostPreviewRef = useRef<ImageItem[]>([])

  useEffect(() => {
    if (!id) return;
    const controller = new AbortController();
    const fetchPostData = async () => {
      setLoading(true)
      try {
        const postRes = await postService.getPost(id, { signal: controller.signal })
        setPost(postRes.data)
        setPostLiked(postRes.data.isLiked ?? false)
        setEditTitle(postRes.data.title)
        setEditContent(postRes.data.content)
        setEditImageItems((postRes.data.images || []).map((url) => ({
          id: url,
          type: 'existing' as const,
          url,
          originalUrl: url,
        })))
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') return;
      console.error(err)
      setActionError(extractUserMessage(err, t("common.error")));
    } finally {
      if (!controller.signal.aborted) setLoading(false)
      }
    }
    fetchPostData()
    return () => controller.abort()
  }, [id, t])

  useEffect(() => {
    if (!id) return;
    const controller = new AbortController();
    const fetchComments = async () => {
      setCommentsLoading(true)
      try {
        const commentsRes = await postService.getPostComments(id, commentSort, { signal: controller.signal })
        const nextComments = Array.isArray(commentsRes.data) ? commentsRes.data : [];
        setComments(nextComments)
        const nextLikedComments = new Set<string>();
        const collectLiked = (items: CommentDto[]) => {
          items.forEach((comment) => {
            if (comment.isLiked) nextLikedComments.add(comment.id);
            if (comment.repliedComments?.length) collectLiked(comment.repliedComments);
          });
        };
        collectLiked(nextComments);
        setLikedComments(nextLikedComments);
      } catch (err) {
        if (err instanceof Error && err.name === 'AbortError') return;
        console.error("Failed to fetch comments", err)
        setActionError(extractUserMessage(err, t("common.error")));
      } finally {
        if (!controller.signal.aborted) setCommentsLoading(false)
      }
    }
    fetchComments()
    return () => controller.abort()
  }, [id, commentSort, t])

  useEffect(() => {
    commentPreviewRef.current = commentImagePreviews;
  }, [commentImagePreviews]);

  useEffect(() => {
    editPostPreviewRef.current = editImageItems;
  }, [editImageItems]);

  useEffect(() => {
    return () => {
      commentPreviewRef.current.forEach((preview) => URL.revokeObjectURL(preview));
      editPostPreviewRef.current.forEach((item) => {
        if (item.type === 'new') URL.revokeObjectURL(item.url);
      });
    };
  }, []);

  const addCommentImages = (files: FileList | null) => {
    if (!files) return;
    const remaining = MAX_COMMENT_IMAGES - commentImageFiles.length;
    const nextFiles = Array.from(files).slice(0, Math.max(0, remaining));
    if (nextFiles.length === 0) return;
    setCommentImageFiles((prev) => [...prev, ...nextFiles]);
    setCommentImagePreviews((prev) => [...prev, ...nextFiles.map((file) => URL.createObjectURL(file))]);
    setCommentImageIds((prev) => [...prev, ...nextFiles.map(() => crypto.randomUUID())]);
  };

  const handleCommentImageRemove = useCallback((itemId: string) => {
    const index = commentImageIds.indexOf(itemId);
    if (index === -1) return;
    URL.revokeObjectURL(commentImagePreviews[index]);
    setCommentImageFiles((prev) => prev.filter((_, i) => i !== index));
    setCommentImagePreviews((prev) => prev.filter((_, i) => i !== index));
    setCommentImageIds((prev) => prev.filter((_, i) => i !== index));
  }, [commentImageIds, commentImagePreviews]);

  const handleCommentImageReorder = useCallback((fromIndex: number, toIndex: number) => {
    setCommentImageFiles((prev) => arrayMove(prev, fromIndex, toIndex));
    setCommentImagePreviews((prev) => arrayMove(prev, fromIndex, toIndex));
    setCommentImageIds((prev) => arrayMove(prev, fromIndex, toIndex));
  }, []);

  const commentImageItems: ImageItem[] = useMemo(() =>
    commentImageIds.map((id, i) => ({
      id,
      type: 'new' as const,
      url: commentImagePreviews[i] ?? '',
      file: commentImageFiles[i],
    })),
    [commentImageIds, commentImagePreviews, commentImageFiles]
  );

  const addEditPostImages = (files: FileList | null) => {
    if (!files) return;
    const nextItems: ImageItem[] = Array.from(files).map((file) => ({
      id: crypto.randomUUID(),
      type: 'new' as const,
      url: URL.createObjectURL(file),
      file,
    }));
    setEditImageItems((prev) => [...prev, ...nextItems]);
  };

  const handleEditImageRemove = useCallback((itemId: string) => {
    setEditImageItems((prev) => {
      const item = prev.find((i) => i.id === itemId);
      if (item?.type === 'new') {
        URL.revokeObjectURL(item.url);
      }
      return prev.filter((i) => i.id !== itemId);
    });
  }, []);

  const handleEditImageReorder = useCallback((fromIndex: number, toIndex: number) => {
    setEditImageItems((prev) => arrayMove(prev, fromIndex, toIndex));
  }, []);

  const handlePostUpdate = async () => {
    if (!id) return;
    const titleError = requiredMax(
      editTitle,
      DTO_LIMITS.postTitleMax,
      t("validation.post_title_required"),
      t("validation.post_title_too_long", { max: DTO_LIMITS.postTitleMax }),
    );
    const contentError = requiredMax(
      editContent,
      DTO_LIMITS.postContentMax,
      t("validation.post_content_required"),
      t("validation.post_content_too_long", { max: DTO_LIMITS.postContentMax }),
    );
    if (titleError || contentError) {
      setActionError(titleError || contentError);
      return;
    }
    setSubmitting(true)
    try {
      let uploadKey: string | undefined;
      let uploadedUrls: string[] = [];

      const newFiles = editImageItems.filter((i) => i.type === 'new').map((i) => i.file!);

      if (newFiles.length > 0) {
        const keyResponse = await fileService.getUploadKey();
        uploadKey = keyResponse.data?.key;

        setEditUploadProgress(0);
        const compressed = await compressImages(newFiles, {
          quality: 0.75,
          maxWidth: 1920,
          maxHeight: 1920,
        });
        uploadedUrls = (await fileService.uploadStream(compressed, uploadKey, setEditUploadProgress)).data ?? [];
      }

      // Build final images list preserving the merged order
      let uploadedIdx = 0;
      const allImages = editImageItems.map((item) => {
        if (item.type === 'existing') return item.originalUrl!;
        return uploadedUrls[uploadedIdx++] ?? '';
      });

      const res = await postService.updatePost(id, {
        title: editTitle,
        content: editContent,
        images: allImages,
        uploadKey,
      });
      if (res.data) {
        setPost(res.data);
        setIsEditingPost(false);
        // Clean up new image previews
        editImageItems.forEach((item) => {
          if (item.type === 'new') URL.revokeObjectURL(item.url);
        });
        setEditImageItems([]);
      }
    } catch (err) {
      console.error(err);
      setActionError(extractUserMessage(err, t("common.error")));
    } finally {
      setSubmitting(false);
      setEditUploadProgress(null);
    }
  }

  const handlePostDelete = async () => {
    if (!id) return;
    setSubmitting(true);
    try {
      await postService.deletePost(id);
      navigate("/");
    } catch (err) {
      console.error(err);
      setActionError(extractUserMessage(err, t("common.error")));
    } finally {
      setSubmitting(false);
    }
  }

  const handleShare = async () => {
    if (!post) return;

    try {
      const outcome = await sharePost(post);
      if (outcome === "shared") {
        setShareFeedback(t("post.share_panel_opened"));
      } else if (outcome === "copied") {
        setShareFeedback(t("post.share_link_copied"));
      }
    } catch (error) {
      console.error(error);
      setShareFeedback(extractUserMessage(error, t("post.share_failed")));
    } finally {
      window.setTimeout(() => setShareFeedback(null), 2500);
    }
  }

  const handlePostLike = async () => {
    if (!id || !user || !post) return;
    try {
      const res = await postService.likePost(id);
      const { likeCount, dislikeCount, isLiked } = res.data;
      setPost({ ...post, likes: likeCount, dislikes: dislikeCount });
      setPostLiked(isLiked);
    } catch (err) {
      console.error("Failed to like post", err);
      setActionError(extractUserMessage(err, t("common.error")));
    }
  }

  const handleCommentLike = async (commentId: string) => {
    if (!user) return;
    try {
      const res = await commentService.likeComment(commentId);
      const { likeCount, dislikeCount, isLiked } = res.data;
      const updateInTree = (list: CommentDto[]): CommentDto[] => {
        return list.map(c => {
          if (c.id === commentId) {
            return { ...c, likes: likeCount, dislikes: dislikeCount };
          }
          if (c.repliedComments && c.repliedComments.length > 0) {
            return { ...c, repliedComments: updateInTree(c.repliedComments) };
          }
          return c;
        });
      };
      setComments(updateInTree(comments));
      setLikedComments(prev => {
        const next = new Set(prev);
        if (isLiked) next.add(commentId);
        else next.delete(commentId);
        return next;
      });
    } catch (err) {
      console.error("Failed to like comment", err);
      setActionError(extractUserMessage(err, t("common.error")));
    }
  }

  const handleCommentDelete = async (commentId: string) => {
    try {
      await commentService.deleteComment(commentId);
      // Remove the comment from the local state tree
      const removeFromTree = (list: CommentDto[]): CommentDto[] => {
        return list.filter(c => c.id !== commentId).map(c => {
          if (c.repliedComments && c.repliedComments.length > 0) {
            return { ...c, repliedComments: removeFromTree(c.repliedComments) };
          }
          return c;
        });
      };
      setComments(removeFromTree(comments));
    } catch (err) {
      console.error("Failed to delete comment", err);
      setActionError(extractUserMessage(err, t("common.error")));
    }
  }

  const handleCommentUpdate = async (commentId: string, content: string, images: string[]) => {
    if (content.trim().length > DTO_LIMITS.commentContentMax) {
      setActionError(t("validation.comment_too_long", { max: DTO_LIMITS.commentContentMax }));
      return;
    }
    try {
      const res = await commentService.updateComment(commentId, { content, images });
      if (res.data) {
        // Update the comment in the local state tree
        const updateInTree = (list: CommentDto[]): CommentDto[] => {
          return list.map(c => {
            if (c.id === commentId) {
              return { ...res.data, author: c.author, repliedComments: c.repliedComments };
            }
            if (c.repliedComments && c.repliedComments.length > 0) {
              return { ...c, repliedComments: updateInTree(c.repliedComments) };
            }
            return c;
          });
        };
        setComments(updateInTree(comments));
      }
    } catch (err) {
      console.error("Failed to update comment", err);
      setActionError(extractUserMessage(err, t("common.error")));
    }
  }

  const handleCommentReply = async (parentId: string, content: string, images: string[]) => {
    if (!id || !user) return;
    if (content.trim().length > DTO_LIMITS.commentContentMax) {
      setActionError(t("validation.comment_too_long", { max: DTO_LIMITS.commentContentMax }));
      return;
    }
    try {
      const res = await commentService.createComment({
        content,
        images,
        userId: user.id,
        postId: id,
        parentCommentId: parentId
      });
      if (res.data) {
        const newReply = { 
          ...res.data, 
          author: { id: user.id, name: user.name, avatar: user.avatar },
          repliedComments: [] 
        };
        
        const insertInTree = (list: CommentDto[]): CommentDto[] => {
          return list.map(c => {
            if (c.id === parentId) {
              return { 
                ...c, 
                repliedComments: [newReply, ...(c.repliedComments || [])] 
              };
            }
            if (c.repliedComments && c.repliedComments.length > 0) {
              return { ...c, repliedComments: insertInTree(c.repliedComments) };
            }
            return c;
          });
        };
        setComments(insertInTree(comments));
      }
    } catch (err) {
      console.error("Failed to reply to comment", err);
      setActionError(extractUserMessage(err, t("common.error")));
    }
  }

  const handleCommentSubmit = async () => {
    if ((!commentContent.trim() && commentImageFiles.length === 0) || !user || !id) return;
    if (commentContent.trim().length > DTO_LIMITS.commentContentMax) {
      setActionError(t("validation.comment_too_long", { max: DTO_LIMITS.commentContentMax }));
      return;
    }
    setSubmitting(true)
    try {
      setCommentUploadProgress(commentImageFiles.length > 0 ? 0 : null);
      const uploadedImages = await uploadCommentImageFiles(commentImageFiles, setCommentUploadProgress);
      const res = await commentService.createComment({
        content: commentContent,
        images: uploadedImages,
        userId: user.id,
        postId: id
      });
      if (res.data) {
        setComments([{ ...res.data, author: { id: user.id, name: user.name, avatar: user.avatar } }, ...comments]);
        setCommentContent("");
        commentImagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
        setCommentImageFiles([]);
        setCommentImagePreviews([]);
        setCommentImageIds([]);
      }
    } catch (err) {
      console.error(err)
      setActionError(extractUserMessage(err, t("common.error")));
    } finally {
      setSubmitting(false)
      setCommentUploadProgress(null)
    }
  }

  if (loading) {
    return <div className="flex justify-center items-center h-64"><Loader2 className="animate-spin text-primary" size={48} /></div>
  }

  if (!post) {
    return <div className="text-center py-20 text-muted-foreground">{t("post.not_found")}</div>
  }

  const isMe = user && post.userId.toLowerCase() === user.id.toLowerCase();
  const isAdmin = user && user.role === 'Admin';
  const authorName = post.author?.name || `${t("common.user")} ${post.userId.slice(0, 4)}`;
  const displayName = isMe ? `${authorName} (${t("common.me")})` : authorName;
  const authorAvatar = post.author?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${post.userId}`;

  return (
    <div className="max-w-3xl mx-auto space-y-8 pb-20">
      <button
        onClick={() => navigate(-1)}
        className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors group"
      >
        <ArrowLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
        {t("post.back_to_feed")}
      </button>

      <article className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
        <header className="space-y-6">
          {isEditingPost ? (
            <input
              type="text"
              value={editTitle}
              onChange={(e) => setEditTitle(e.target.value)}
              maxLength={DTO_LIMITS.postTitleMax}
              className="w-full text-4xl sm:text-5xl font-black tracking-tight leading-[1.1] bg-transparent border-b border-primary/30 outline-none focus:border-primary transition-colors"
            />
          ) : (
            <h1 className="text-4xl sm:text-5xl font-black tracking-tight leading-[1.1]">
              {post.title}
            </h1>
          )}
          
          <div className="flex items-center gap-4 py-6 border-y border-border/30">
            <Link to={`/user/${post.userId}`} className="shrink-0">
              <OptimizedImage src={authorAvatar} alt={authorName} className="w-12 h-12 rounded-full bg-muted shadow-inner" />
            </Link>
            <div className="flex-1">
              <Link to={`/user/${post.userId}`} className="font-bold text-lg transition-colors hover:text-primary">
                {displayName}
              </Link>
              <p className="text-sm text-muted-foreground">
                {formatEditedRelativeTime(post.createdAt, i18n.resolvedLanguage, post.updatedAt, t("post.edited"))}
              </p>
            </div>
            {(isMe || isAdmin) && !isEditingPost && (
              <div className="flex gap-2">
                {isMe && (
                  <button
                    onClick={() => {
                      setIsEditingPost(true);
                      setEditTitle(post.title);
                      setEditContent(post.content);
                      setEditImageItems((post.images || []).map((url) => ({
                        id: url,
                        type: 'existing' as const,
                        url,
                        originalUrl: url,
                      })));
                    }}
                    className="px-4 py-1.5 rounded-full bg-muted hover:bg-primary/10 hover:text-primary transition-all text-sm font-bold"
                  >
                    {t("post.edit")}
                  </button>
                )}
                <button
                  onClick={() => setShowPostDeleteDialog(true)}
                  className="px-4 py-1.5 rounded-full bg-muted hover:bg-destructive/10 hover:text-destructive transition-all text-sm font-bold"
                >
                  {t("post.delete")}
                </button>
              </div>
            )}
            <button className="p-2 rounded-full hover:bg-muted transition-colors">
              <MoreHorizontal size={20} />
            </button>
          </div>
        </header>

        <AlertDialog open={showPostDeleteDialog} onOpenChange={setShowPostDeleteDialog}>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{t("post.delete")}</AlertDialogTitle>
              <AlertDialogDescription>{t("post.confirm_delete")}</AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t("post.cancel")}</AlertDialogCancel>
              <AlertDialogAction variant="destructive" onClick={handlePostDelete}>
                {t("post.delete")}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>

        {!isEditingPost && post.images && post.images.length > 0 && (
          <PostImageCarousel key={post.id} images={post.images} imageLabel={`${t("nav.post")} image`} />
        )}

        <PostTagBadge tag={post.tag} />

        <div className="prose prose-lg dark:prose-invert max-w-none">
          {isEditingPost ? (
            <textarea
              value={editContent}
              onChange={(e) => setEditContent(e.target.value)}
              maxLength={DTO_LIMITS.postContentMax}
              className="w-full min-h-[300px] text-lg leading-relaxed bg-transparent border border-border/50 rounded-2xl p-4 outline-none focus:border-primary transition-colors resize-none"
            />
          ) : (
            <div className="space-y-6 text-lg leading-relaxed text-foreground whitespace-pre-wrap">
              {post.content}
            </div>
          )}
        </div>

        {isEditingPost && (
          <div className="space-y-4 mt-6">
            <SortableImageGrid
              items={editImageItems}
              onReorder={handleEditImageReorder}
              onRemove={handleEditImageRemove}
              disabled={submitting}
            />
            <div className="flex items-center gap-3">
              <label className="grid size-10 place-items-center rounded-2xl border border-border bg-background/70 cursor-pointer hover:border-primary hover:text-primary transition-colors">
                <ImagePlus size={18} />
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={(event) => {
                    addEditPostImages(event.target.files);
                    event.target.value = "";
                  }}
                  className="hidden"
                />
              </label>
              <span className="text-xs text-muted-foreground">
                {editImageItems.length} image{editImageItems.length !== 1 ? "s" : ""}
              </span>
            </div>
            {editUploadProgress !== null && (
              <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
                <div className="h-full bg-primary transition-all" style={{ width: `${editUploadProgress * 100}%` }} />
              </div>
            )}
          </div>
        )}

        {isEditingPost && (
          <div className="flex gap-4">
            <button
              onClick={handlePostUpdate}
              disabled={submitting}
              className="flex-1 py-3 rounded-2xl bg-primary text-primary-foreground font-bold hover:opacity-90 transition-all shadow-lg shadow-primary/20 flex items-center justify-center gap-2"
            >
              {submitting ? <Loader2 className="animate-spin" size={20} /> : t("post.save")}
            </button>
            <button
              onClick={() => {
                setIsEditingPost(false);
                if (post) {
                  setEditTitle(post.title);
                  setEditContent(post.content);
                }
                // Clean up new image previews
                editImageItems.forEach((item) => {
                  if (item.type === 'new') URL.revokeObjectURL(item.url);
                });
                setEditImageItems([]);
              }}
              className="flex-1 py-3 rounded-2xl bg-muted font-bold hover:bg-border transition-all"
            >
              {t("post.cancel")}
            </button>
          </div>
        )}

        <footer className="flex items-center gap-6 py-8 border-t border-border/30">
          <button 
            onClick={handlePostLike}
            disabled={!user}
            className={cn(
              "flex items-center gap-2 px-6 py-2.5 rounded-full transition-all font-bold group",
              user ? "bg-primary/10 text-primary hover:bg-primary/20" : "bg-muted text-muted-foreground/50 cursor-not-allowed"
            )}
          >
            <Heart size={20} className={cn("group-hover:scale-110 transition-transform", postLiked && "fill-primary")} />
            <span>{post.likes} {t("post.likes")}</span>
          </button>
          <button
            onClick={handleShare}
            className="flex items-center gap-2 px-6 py-2.5 rounded-full hover:bg-muted transition-all font-bold text-muted-foreground group"
          >
            <Share2 size={20} className="group-hover:scale-110 transition-transform" />
            <span>{t("post.share")}</span>
          </button>
        </footer>
        {shareFeedback ? <p className="text-sm font-medium text-primary">{shareFeedback}</p> : null}
      </article>

      {actionError && (
        <div className="p-4 rounded-2xl bg-destructive/10 text-destructive text-sm font-medium text-center animate-in fade-in duration-300">
          {actionError}
        </div>
      )}

      <section className="space-y-8 animate-in fade-in slide-in-from-bottom-6 duration-700 delay-200">
        <div className="flex items-center justify-between">
          <h3 className="flex items-center gap-3 text-2xl font-bold tracking-tight">
            {t("post.comments_count", { count: comments.length })}
            {commentsLoading ? <Loader2 className="animate-spin text-primary" size={18} /> : null}
          </h3>
          <div className="flex items-center gap-2 p-1 rounded-xl bg-muted/50 border border-border/50">
            <button
              onClick={() => setCommentSort("recent")}
              disabled={commentsLoading && commentSort === "recent"}
              className={cn(
                "px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-70",
                commentSort === "recent" ? "bg-background shadow-sm text-foreground" : "text-muted-foreground hover:text-foreground"
              )}
            >
              {t("post.sort_recent")}
            </button>
            <button
              onClick={() => setCommentSort("hot")}
              disabled={commentsLoading && commentSort === "hot"}
              className={cn(
                "px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-70",
                commentSort === "hot" ? "bg-background shadow-sm text-foreground" : "text-muted-foreground hover:text-foreground"
              )}
            >
              {t("post.sort_hot")}
            </button>
          </div>
        </div>

        {user ? (
          <div className="space-y-3 rounded-3xl bg-muted/50 border border-border/50 p-3 focus-within:border-primary/30 focus-within:ring-4 focus-within:ring-primary/5 transition-all">
            <textarea
              placeholder={t("post.comment_placeholder")}
              value={commentContent}
              onChange={(e) => setCommentContent(e.target.value)}
              maxLength={DTO_LIMITS.commentContentMax}
              className="min-h-[76px] w-full resize-none bg-transparent border-none outline-none px-2 py-2 text-sm"
            />
            <SortableImageGrid
              items={commentImageItems}
              onReorder={handleCommentImageReorder}
              onRemove={handleCommentImageRemove}
              disabled={submitting}
            />
            {commentUploadProgress !== null && (
              <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
                <div className="h-full bg-primary transition-all" style={{ width: `${commentUploadProgress * 100}%` }} />
              </div>
            )}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <label className={cn(
                  "grid size-10 place-items-center rounded-2xl border border-border bg-background/70 transition-colors",
                  commentImageFiles.length < MAX_COMMENT_IMAGES ? "cursor-pointer hover:border-primary hover:text-primary" : "opacity-40"
                )}>
                  <ImagePlus size={18} />
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    disabled={commentImageFiles.length >= MAX_COMMENT_IMAGES}
                    onChange={(event) => {
                      addCommentImages(event.target.files);
                      event.target.value = "";
                    }}
                    className="hidden"
                  />
                </label>
                <span className="text-xs text-muted-foreground">{commentImageFiles.length} / {MAX_COMMENT_IMAGES}</span>
              </div>
              <button 
                onClick={handleCommentSubmit}
                disabled={(!commentContent.trim() && commentImageFiles.length === 0) || submitting}
                className="p-3 rounded-2xl bg-primary text-primary-foreground hover:opacity-90 disabled:opacity-50 transition-all shadow-lg shadow-primary/20"
              >
                {submitting ? <Loader2 size={18} className="animate-spin" /> : <Send size={18} />}
              </button>
            </div>
          </div>
        ) : (
          <div className="p-4 rounded-[2rem] bg-muted/50 border border-border/50 text-center">
            <p className="text-muted-foreground text-sm">{t("post.login_to_comment")}</p>
          </div>
        )}

        <div className="space-y-10">
          {comments.map((c) => (
            <CommentItem
              key={c.id}
              comment={c}
              replies={flattenReplies(c)}
              user={user}
              i18n={i18n}
              t={t}
              onUpdate={handleCommentUpdate}
              onReply={handleCommentReply}
              onDelete={handleCommentDelete}
              onLike={handleCommentLike}
              likedComments={likedComments}
            />
          ))}
          {comments.length === 0 && !commentsLoading && (
            <p className="text-center text-muted-foreground py-8">{t("post.no_comments")}</p>
          )}
        </div>
      </section>
    </div>
  )
}
