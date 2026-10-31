import { createContext, useContext } from "react"

/** 中间列表栏当前的数据源 */
export type FeedListState =
  | { kind: "latest" }
  | { kind: "hot" }
  | { kind: "tag"; tagId: string; tagName?: string }

export interface ListContextValue {
  list: FeedListState
  setTagName: (tagId: string, name: string) => void
}

export const ListContext = createContext<ListContextValue | null>(null)

/** 仅在 AppShell 内可用；phone 布局没有 Provider，返回 null。 */
export function useListContext() {
  return useContext(ListContext)
}
