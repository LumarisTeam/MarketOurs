import * as React from "react"
import { cn } from "@/lib/utils"

/* ─── Apple Glass Panel ─── */
function AppleGlassPanel({
  className,
  children,
  ...props
}: React.ComponentProps<"div">) {
  return (
    <div
      className={cn(
        "glass-card rounded-3xl p-6",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

/* ─── Page Container ─── */
function PageContainer({
  className,
  size = "default",
  children,
  ...props
}: React.ComponentProps<"div"> & { size?: "default" | "wide" | "narrow" }) {
  return (
    <div
      className={cn(
        "mx-auto w-full px-4 sm:px-6 lg:px-8",
        size === "narrow" && "max-w-2xl",
        size === "default" && "max-w-4xl",
        size === "wide" && "max-w-5xl",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

/* ─── Section Heading ─── */
function SectionHeading({
  className,
  title,
  subtitle,
  children,
  ...props
}: React.ComponentProps<"div"> & {
  title?: string
  subtitle?: string
}) {
  return (
    <div className={cn("mb-8", className)} {...props}>
      {title && (
        <h2 className="text-2xl font-semibold tracking-tight text-foreground sm:text-3xl">
          {title}
        </h2>
      )}
      {subtitle && (
        <p className="mt-2 text-base text-muted-foreground leading-relaxed">
          {subtitle}
        </p>
      )}
      {children}
    </div>
  )
}

/* ─── Apple-style Link ─── */
function AppleLink({
  className,
  ...props
}: React.ComponentProps<"a">) {
  return (
    <a
      className={cn(
        "text-primary hover:text-primary/80 transition-colors decoration-primary/30 hover:decoration-primary underline-offset-4",
        className
      )}
      {...props}
    />
  )
}

export { AppleGlassPanel, PageContainer, SectionHeading, AppleLink }
