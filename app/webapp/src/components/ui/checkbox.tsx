import { cn } from "@/lib/utils"

function Checkbox({
  id,
  className,
  checked,
  onCheckedChange,
  ...props
}: Omit<React.InputHTMLAttributes<HTMLInputElement>, "onChange"> & {
  onCheckedChange?: (checked: boolean) => void
}) {
  return (
    <input
      id={id}
      type="checkbox"
      checked={checked}
      onChange={(e) => onCheckedChange?.(e.target.checked)}
      className={cn(
        "peer size-4 shrink-0 rounded border border-primary/60 shadow-sm",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
        "disabled:cursor-not-allowed disabled:opacity-50",
        "checked:bg-primary checked:border-primary",
        "cursor-pointer accent-primary",
        className
      )}
      {...props}
    />
  )
}

export { Checkbox }
