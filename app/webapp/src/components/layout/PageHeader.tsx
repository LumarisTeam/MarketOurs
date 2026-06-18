import * as React from "react"
import { cn } from "@/lib/utils"

interface PageHeaderProps extends React.ComponentProps<"div"> {
  title: string
  subtitle?: string
  actions?: React.ReactNode
}

function PageHeader({ className, title, subtitle, actions, children, ...props }: PageHeaderProps) {
  return (
    <div className={cn("mb-8 sm:mb-10", className)} {...props}>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div className="space-y-1.5">
          <h1 className="text-2xl font-semibold tracking-tight text-foreground sm:text-3xl lg:text-4xl">
            {title}
          </h1>
          {subtitle && (
            <p className="text-base text-muted-foreground leading-relaxed max-w-2xl">
              {subtitle}
            </p>
          )}
        </div>
        {actions && (
          <div className="flex shrink-0 items-center gap-2 self-start sm:self-end">
            {actions}
          </div>
        )}
      </div>
      {children}
    </div>
  )
}

export { PageHeader }
