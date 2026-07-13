import { useState } from "react"
import { reportService, type ReportReason, type ReportTargetType } from "@/services/reportService"
import { extractUserMessage } from "@/services/errorCodes"
import { toast } from "@/lib/toast"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"

const reasons: Array<{ value: ReportReason; label: string }> = [
  { value: 0, label: "垃圾广告" }, { value: 1, label: "欺诈/交易风险" }, { value: 2, label: "色情低俗" }, { value: 3, label: "仇恨/骚扰" }, { value: 4, label: "其他" },
]

export function ReportDialog({ target, onClose }: { target: { type: ReportTargetType; id: string; label: string } | null; onClose: () => void }) {
  const [reason, setReason] = useState<ReportReason>(0)
  const [description, setDescription] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const submit = async () => {
    if (!target) return
    if (reason === 4 && !description.trim()) { toast.error("选择“其他”时请填写说明"); return }
    setSubmitting(true)
    try { await reportService.create({ targetType: target.type, targetId: target.id, reason, description: description.trim() || undefined }); toast.success("举报已提交"); onClose() }
    catch (error) { toast.error(extractUserMessage(error, "举报提交失败")) }
    finally { setSubmitting(false) }
  }
  return <Dialog open={target !== null} onOpenChange={(open) => !open && onClose()}><DialogContent>
    <DialogHeader><DialogTitle>举报{target?.label}</DialogTitle><DialogDescription>请选择举报理由；管理员会进行人工审核。</DialogDescription></DialogHeader>
    <div className="space-y-3"><select value={reason} onChange={(e) => setReason(Number(e.target.value) as ReportReason)} className="w-full rounded-lg border bg-background p-2">{reasons.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}</select>
    <textarea value={description} onChange={(e) => setDescription(e.target.value)} maxLength={500} placeholder={reason === 4 ? "请说明原因（必填）" : "补充说明（可选）"} className="min-h-24 w-full rounded-lg border bg-background p-3" /></div>
    <DialogFooter><Button variant="outline" onClick={onClose}>取消</Button><Button variant="destructive" disabled={submitting} onClick={() => void submit()}>{submitting ? "提交中…" : "提交举报"}</Button></DialogFooter>
  </DialogContent></Dialog>
}
