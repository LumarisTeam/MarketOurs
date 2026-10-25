import { useState } from "react"
import { ChevronLeft, ChevronRight, X } from "lucide-react"
import { useTranslation } from "react-i18next"
import { cn } from "@/lib/utils"
import { OptimizedImage } from "@/components/ui/optimized-image"

const MAX_GRID_IMAGES = 9

interface PostImageGridProps {
  images: string[]
  imageLabel?: string
  enableViewer?: boolean
  compact?: boolean
  className?: string
}

/** A Moments-style image gallery for image-only posts. */
export function PostImageGrid({
  images,
  imageLabel = "Post image",
  enableViewer = true,
  compact = false,
  className,
}: PostImageGridProps) {
  const { t } = useTranslation()
  const [viewerIndex, setViewerIndex] = useState<number | null>(null)
  const visibleImages = images.slice(0, MAX_GRID_IMAGES)
  const columns = visibleImages.length === 4 ? 2 : 3
  const widthPercent = visibleImages.length === 4 ? 66 : 87

  if (visibleImages.length === 0) return null

  const showPrevious = () => {
    setViewerIndex((index) =>
      index === null ? index : Math.max(0, index - 1),
    )
  }
  const showNext = () => {
    setViewerIndex((index) =>
      index === null ? index : Math.min(images.length - 1, index + 1),
    )
  }

  return (
    <>
      <div
        className={cn(
          "mx-auto grid overflow-hidden",
          compact ? "gap-1 rounded-xl" : "gap-2 rounded-2xl",
          className,
        )}
        style={{
          width: `${widthPercent}%`,
          gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
        }}
      >
        {visibleImages.map((image, index) => {
          const tileContent = (
            <>
              <OptimizedImage
                src={image}
                alt={`${imageLabel} ${index + 1}`}
                className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-[1.03]"
                loading={index === 0 ? "eager" : "lazy"}
                fetchPriority={index === 0 ? "high" : "low"}
              />
              {index === MAX_GRID_IMAGES - 1 && images.length > MAX_GRID_IMAGES && (
                <span className="absolute inset-0 grid place-items-center bg-black/45 text-lg font-semibold text-white">
                  +{images.length - MAX_GRID_IMAGES}
                </span>
              )}
            </>
          )
          const tileClassName = cn(
            "group relative aspect-square overflow-hidden bg-muted text-left",
            compact ? "rounded-md" : "rounded-xl",
          )

          if (!enableViewer) {
            return (
              <div key={`${image}-${index}`} className={tileClassName}>
                {tileContent}
              </div>
            )
          }

          return (
            <button
              key={`${image}-${index}`}
              type="button"
              onClick={(event) => {
                event.stopPropagation()
                setViewerIndex(index)
              }}
              className={tileClassName}
            >
              {tileContent}
            </button>
          )
        })}
      </div>

      {enableViewer && viewerIndex !== null && (
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
          {images.length > 1 && (
            <button
              type="button"
              onClick={(event) => {
                event.stopPropagation()
                showPrevious()
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
          {images.length > 1 && (
            <>
              <button
                type="button"
                onClick={(event) => {
                  event.stopPropagation()
                  showNext()
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
  )
}

