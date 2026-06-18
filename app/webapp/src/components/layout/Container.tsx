import * as React from "react"
import { cn } from "@/lib/utils"

interface ContainerProps extends React.ComponentProps<"div"> {
  size?: "default" | "wide" | "narrow" | "full"
}

function Container({ className, size = "default", children, ...props }: ContainerProps) {
  return (
    <div
      className={cn(
        "mx-auto w-full px-4 sm:px-6 lg:px-8",
        size === "narrow" && "max-w-2xl",
        size === "default" && "max-w-4xl",
        size === "wide" && "max-w-5xl",
        size === "full" && "max-w-[1400px]",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

export { Container }
