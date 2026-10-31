import { useTranslation } from "react-i18next"
import { useListContext } from "./ListContext"
import { FeedListPane } from "./FeedListPane"

export function ListColumn() {
  const { t } = useTranslation()
  const context = useListContext()
  const list = context?.list ?? { kind: "latest" as const }

  const title =
    list.kind === "latest"
      ? t("shell.list_latest_title")
      : list.kind === "hot"
        ? t("shell.list_hot_title")
        : list.tagName ?? t("shell.list_tag_title")

  const subtitle =
    list.kind === "latest"
      ? t("shell.list_latest_subtitle")
      : list.kind === "hot"
        ? t("shell.list_hot_subtitle")
        : list.tagName
          ? t("shell.list_tag_subtitle", { name: list.tagName })
          : ""

  return (
    <aside className="fixed inset-y-0 left-[72px] z-30 flex w-80 flex-col border-r border-border/40 bg-card/40 backdrop-blur-xl xl:w-[340px]">
      <header className="flex h-16 shrink-0 flex-col justify-center border-b border-border/40 px-4">
        <h2 className="truncate text-[15px] font-semibold tracking-tight text-foreground">
          {title}
        </h2>
        {subtitle ? (
          <p className="mt-0.5 truncate text-xs text-muted-foreground">{subtitle}</p>
        ) : null}
      </header>
      <div className="min-h-0 flex-1">
        <FeedListPane
          key={list.kind === "tag" ? `tag:${list.tagId}` : list.kind}
          list={list}
        />
      </div>
    </aside>
  )
}
