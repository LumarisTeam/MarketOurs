import { cn } from "@/lib/utils"

/**
 * OptimizedImage — wraps native <img> with performance best practices:
 * - lazy loading for off-screen images
 * - async decoding to keep the main thread responsive
 * - fetchpriority hint (low for lazy, high for eager)
 * - explicit dimensions or aspect-ratio to prevent CLS
 *
 * Prefer this component over raw <img> in lists and galleries.
 */
export function OptimizedImage({
  src,
  alt = "",
  className,
  loading = "lazy",
  decoding = "async",
  fetchPriority,
  width,
  height,
  ...rest
}: React.ImgHTMLAttributes<HTMLImageElement> & {
  loading?: "lazy" | "eager"
  decoding?: "async" | "sync" | "auto"
  fetchPriority?: "high" | "low" | "auto"
}) {
  const resolvedFetchPriority =
    fetchPriority ?? (loading === "lazy" ? "low" : undefined)

  // Ensure the image has aspect-ratio or dimensions to prevent CLS.
  // If neither width/height nor an aspect-ratio class is set,
  // add a safe square fallback hint — this won't override
  // container-imposed sizing, it only reserves space.
  const needsAspectRatio =
    width == null &&
    height == null &&
    !(typeof className === "string" && /aspect-/.test(className))

  return (
    <img
      src={src}
      alt={alt}
      loading={loading}
      decoding={decoding}
      {...(resolvedFetchPriority ? { fetchPriority: resolvedFetchPriority } : {})}
      width={width}
      height={height}
      className={cn(needsAspectRatio && "aspect-square", className)}
      {...rest}
    />
  )
}
