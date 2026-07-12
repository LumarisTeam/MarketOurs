import { useEffect, useState } from "react"
import { adminService } from "../../services/adminService"
import type { PagedResult, ReportDto } from "../../types"
import { formatLocalDate } from "../../lib/dateTime"

const targetNames = ["帖子", "评论", "用户"]
const reasonNames = ["垃圾广告", "欺诈/交易风险", "色情低俗", "仇恨/骚扰", "其他"]
const statusNames = ["待处理", "已处理", "已驳回"]

export default function AdminReportsPage() {
  const [reports, setReports] = useState<PagedResult<ReportDto> | null>(null)
  const [status, setStatus] = useState<number | undefined>(0)
  const [targetType, setTargetType] = useState<number | undefined>()
  const [loading, setLoading] = useState(true)
  const [note, setNote] = useState("")
  const load = async () => { setLoading(true); try { setReports((await adminService.getReports(1, 20, status, targetType)).data) } finally { setLoading(false) } }
  useEffect(() => { void load() }, [status, targetType])
  const resolve = async (id: string, nextStatus: number) => { await adminService.updateReportStatus(id, { status: nextStatus, resolutionNote: note || undefined }); setNote(""); await load() }
  return <div className="space-y-6"><header><h1 className="text-3xl font-bold">举报中心</h1><p className="mt-1 text-muted-foreground">审核用户提交的内容与账号举报。</p></header>
    <div className="flex gap-3"><select value={status ?? ""} onChange={e => setStatus(e.target.value === "" ? undefined : Number(e.target.value))} className="rounded border p-2"><option value="">全部状态</option>{statusNames.map((x, i) => <option key={x} value={i}>{x}</option>)}</select><select value={targetType ?? ""} onChange={e => setTargetType(e.target.value === "" ? undefined : Number(e.target.value))} className="rounded border p-2"><option value="">全部目标</option>{targetNames.map((x, i) => <option key={x} value={i}>{x}</option>)}</select></div>
    <div className="overflow-x-auto rounded-2xl border"><table className="w-full text-sm"><thead className="bg-muted/30"><tr><th className="p-3 text-left">目标</th><th className="p-3 text-left">理由</th><th className="p-3 text-left">举报人</th><th className="p-3 text-left">状态</th><th className="p-3 text-left">时间</th><th className="p-3">操作</th></tr></thead><tbody>{loading ? <tr><td className="p-6" colSpan={6}>加载中…</td></tr> : reports?.items.map(r => <tr key={r.id} className="border-t"><td className="p-3"><div>{targetNames[r.targetType]}：{r.targetSummary}</div><div className="text-muted-foreground">{r.description}</div></td><td className="p-3">{reasonNames[r.reason]}</td><td className="p-3">{r.reporterName}</td><td className="p-3">{statusNames[r.status]}</td><td className="p-3">{formatLocalDate(r.createdAt)}</td><td className="p-3">{r.status === 0 && <div className="flex gap-2"><button onClick={() => void resolve(r.id, 1)} className="rounded bg-primary px-2 py-1 text-primary-foreground">处理</button><button onClick={() => void resolve(r.id, 2)} className="rounded border px-2 py-1">驳回</button></div>}</td></tr>)}</tbody></table></div>
    <textarea value={note} onChange={e => setNote(e.target.value)} placeholder="内部处理备注（可选）" className="min-h-20 w-full rounded border p-2" />
  </div>
}
