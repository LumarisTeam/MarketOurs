import { PostFeed } from "@/components/post/PostFeed"
import { WelcomePane } from "@/components/layout/shell/WelcomePane"
import { useBreakpoint } from "@/components/layout/shell/useBreakpoint"

export default function HomePage() {
  const breakpoint = useBreakpoint()

  // 桌面端右侧内容区展示欢迎页，列表在中间列表栏
  if (breakpoint === "desktop") {
    return <WelcomePane />
  }

  return (
    <PostFeed/>
  )
}
