import { Skeleton } from "@/components/ui/skeleton"

export function PageLoading() {
  return (
    <div className="mx-auto max-w-4xl px-4 py-8 space-y-6">
      {/* Header skeleton */}
      <div className="space-y-2">
        <Skeleton className="h-8 w-2/3" />
        <Skeleton className="h-4 w-1/3" />
      </div>
      {/* Content skeletons */}
      <div className="space-y-4 pt-4">
        <Skeleton className="h-32 w-full rounded-lg" />
        <Skeleton className="h-32 w-full rounded-lg" />
        <Skeleton className="h-32 w-full rounded-lg" />
      </div>
    </div>
  )
}
