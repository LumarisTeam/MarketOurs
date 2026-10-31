import { PageTransition } from "./PageTransition"

interface PlainLayoutProps {
  children: React.ReactNode
}

/**
 * 无壳单页布局：登录 / 注册 / 找回密码 / 个人中心等表单页使用。
 * 不渲染 Navbar、footer 或分栏外壳，页面内容自身居中。
 */
export function PlainLayout({ children }: PlainLayoutProps) {
  return (
    <div className="relative flex min-h-dvh flex-col bg-background">
      <main className="flex min-h-dvh flex-col justify-center px-4 py-8 sm:px-6">
        <PageTransition>
          <div className="w-full">{children}</div>
        </PageTransition>
      </main>
    </div>
  )
}
