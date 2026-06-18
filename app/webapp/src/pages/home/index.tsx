import { PostFeed } from "@/components/post/PostFeed"
import { PageHeader } from "@/components/layout/PageHeader"
import { useTranslation } from "react-i18next"

export default function HomePage() {
  const { t } = useTranslation()

  return (
    <PostFeed
      header={
        <PageHeader
          title={t("nav.home")}
          subtitle={t("home.subtitle", { defaultValue: "发现校园里的精彩内容" })}
        />
      }
    />
  )
}
