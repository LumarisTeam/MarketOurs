import { useState, useRef, useEffect, useCallback } from "react";
import { apiClient } from "@/services/apiClient";
import { Loader2, ChevronRight, RefreshCw } from "lucide-react";

interface CaptchaChallenge {
  token: string;
  backgroundImage: string;
  puzzleImage: string;
  puzzleWidth: number;
  puzzleHeight: number;
  puzzleY: number;
}

interface SliderCaptchaProps {
  onVerify: (token: string) => void;
  onCancel: () => void;
}

const DISPLAY_WIDTH = 280;

export function SliderCaptcha({ onVerify, onCancel }: SliderCaptchaProps) {
  const [challenge, setChallenge] = useState<CaptchaChallenge | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [sliderValue, setSliderValue] = useState(0);
  const [canvasHeight, setCanvasHeight] = useState(60);
  const [verifying, setVerifying] = useState(false);
  const [success, setSuccess] = useState(false);
  const trackRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const scaleRef = useRef(1);
  const dragRef = useRef(false);
  const trackWidth = DISPLAY_WIDTH;

  const fetchChallenge = useCallback(async () => {
    setLoading(true);
    setError("");
    setSliderValue(0);
    setSuccess(false);
    try {
      const res = await apiClient.get<CaptchaChallenge>("/Auth/captcha-challenge");
      if (res.data) {
        setChallenge(res.data);
        drawImages(res.data, 0);
      }
    } catch {
      setError("获取验证失败，请重试");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchChallenge();
  }, [fetchChallenge]);

  const drawImages = (ch: CaptchaChallenge, offsetPx: number) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const bgImg = new Image();
    bgImg.onload = () => {
      const scale = DISPLAY_WIDTH / bgImg.naturalWidth;
      scaleRef.current = scale;
      const displayH = Math.round(bgImg.naturalHeight * scale);

      canvas.width = DISPLAY_WIDTH;
      canvas.height = displayH;
      setCanvasHeight(displayH);

      ctx.clearRect(0, 0, DISPLAY_WIDTH, displayH);
      ctx.drawImage(bgImg, 0, 0, DISPLAY_WIDTH, displayH);

      const puzzleImg = new Image();
      puzzleImg.onload = () => {
        const pw = Math.round(ch.puzzleWidth * scale);
        const ph = Math.round(ch.puzzleHeight * scale);
        const px = offsetPx;
        const py = Math.round(ch.puzzleY * scale);
        ctx.drawImage(puzzleImg, px, py, pw, ph);
      };
      puzzleImg.src = `data:image/png;base64,${ch.puzzleImage}`;
    };
    bgImg.src = `data:image/png;base64,${ch.backgroundImage}`;
  };

  const handlePointerDown = (e: React.PointerEvent) => {
    if (verifying || success) return;
    e.preventDefault();
    dragRef.current = true;
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragRef.current || verifying || success || !trackRef.current) return;
    const rect = trackRef.current.getBoundingClientRect();
    let x = e.clientX - rect.left;
    x = Math.max(0, Math.min(x, trackWidth));
    setSliderValue(x);
    if (challenge) drawImages(challenge, x);
  };

  const handlePointerUp = async () => {
    if (!dragRef.current || verifying || success) return;
    dragRef.current = false;
    if (!challenge || sliderValue < 2) {
      setSliderValue(0);
      if (challenge) drawImages(challenge, 0);
      return;
    }

    setVerifying(true);
    try {
      const res = await apiClient.post<string>("/Auth/verify-captcha", {
        token: challenge.token,
        x: Math.round(sliderValue / scaleRef.current),
      });
      if (res.data) {
        setSuccess(true);
        setTimeout(() => onVerify(res.data!), 500);
      }
    } catch {
      setError("验证失败，请重试");
      setSliderValue(0);
      if (challenge) drawImages(challenge, 0);
    } finally {
      setVerifying(false);
    }
  };

  const progress = sliderValue / trackWidth;
  const knobLeft = Math.min(sliderValue, trackWidth - 48);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={onCancel}>
      <div
        className="glass-card rounded-3xl p-6 space-y-5 animate-in fade-in zoom-in-95 duration-300"
        style={{ width: DISPLAY_WIDTH + 48 }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="text-center space-y-1">
          <h3 className="text-lg font-semibold">请完成验证</h3>
          <p className="text-xs text-muted-foreground">拖动滑块使拼图对齐</p>
        </div>

        {error && (
          <div className="rounded-2xl bg-destructive/10 px-3 py-2 text-xs font-medium text-destructive text-center">
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center py-10">
            <Loader2 className="animate-spin text-muted-foreground" size={28} />
          </div>
        ) : challenge ? (
          <>
            <canvas
              ref={canvasRef}
              className="w-full rounded-xl border border-border/50 block"
              style={{ height: canvasHeight }}
            />

            <div className="space-y-3">
              <div
                ref={trackRef}
                className="relative h-12 rounded-2xl bg-muted/60 overflow-hidden select-none touch-none"
              >
                <div
                  className="absolute inset-y-0 left-0 bg-primary/20 rounded-2xl transition-all duration-75"
                  style={{ width: `${(progress * 100).toFixed(0)}%` }}
                />
                <div
                  className="absolute top-0 rounded-2xl h-12 w-12 bg-primary flex items-center justify-center cursor-grab active:cursor-grabbing shadow-md"
                  style={{ left: `${knobLeft}px` }}
                  onPointerDown={handlePointerDown}
                  onPointerMove={handlePointerMove}
                  onPointerUp={handlePointerUp}
                >
                  {verifying ? (
                    <Loader2 className="animate-spin text-primary-foreground" size={18} />
                  ) : success ? (
                    <span className="text-primary-foreground text-lg">✓</span>
                  ) : (
                    <ChevronRight className="text-primary-foreground" size={20} />
                  )}
                </div>
                {!success && !verifying && (
                  <span className="absolute inset-0 flex items-center justify-center text-xs text-muted-foreground font-medium pointer-events-none">
                    拖动滑块完成拼图
                  </span>
                )}
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={fetchChallenge}
                  disabled={verifying}
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl py-2 text-xs font-medium text-muted-foreground hover:bg-muted transition-colors"
                >
                  <RefreshCw size={14} />
                  刷新
                </button>
                <button
                  type="button"
                  onClick={onCancel}
                  className="flex-1 rounded-xl py-2 text-xs font-medium text-muted-foreground hover:bg-muted transition-colors"
                >
                  取消
                </button>
              </div>
            </div>
          </>
        ) : null}
      </div>
    </div>
  );
}
