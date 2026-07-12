import { useState } from "react";
import {
  DndContext,
  DragOverlay,
  closestCenter,
  PointerSensor,
  TouchSensor,
  useSensor,
  useSensors,
  type DragStartEvent,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  useSortable,
  rectSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { X, GripVertical } from "lucide-react";
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";
import { OptimizedImage } from "@/components/ui/optimized-image";

export interface ImageItem {
  id: string;
  type: "existing" | "new";
  url: string;
  file?: File;
  originalUrl?: string;
}

interface SortableImageGridProps {
  items: ImageItem[];
  onReorder: (fromIndex: number, toIndex: number) => void;
  onRemove: (itemId: string) => void;
  disabled?: boolean;
}

function SortableImageTile({
  item,
  onRemove,
  isSingle,
  disabled,
}: {
  item: ImageItem;
  onRemove: (id: string) => void;
  isSingle: boolean;
  disabled?: boolean;
}) {
  const { t } = useTranslation();
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: item.id, disabled });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        "relative aspect-square rounded-2xl overflow-hidden border border-border group",
        isDragging && "z-10 shadow-xl"
      )}
    >
      <OptimizedImage
        src={item.url}
        alt=""
        className="w-full h-full object-cover"
        draggable={false}
      />

      {/* Drag handle — hidden when single image or disabled */}
      {!isSingle && !disabled && (
        <button
          type="button"
          {...attributes}
          {...listeners}
          className="absolute top-2 left-2 p-1 rounded-lg bg-background/80 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity hover:bg-background hover:text-foreground cursor-grab active:cursor-grabbing"
          aria-label={t("post.drag_to_reorder")}
        >
          <GripVertical size={14} />
        </button>
      )}

      {/* Remove button */}
      <button
        type="button"
        onClick={() => onRemove(item.id)}
        className="absolute top-2 right-2 p-1.5 rounded-full bg-background/80 text-foreground opacity-0 group-hover:opacity-100 transition-opacity hover:bg-destructive hover:text-destructive-foreground"
        aria-label={t("post.remove_image")}
      >
        <X size={14} />
      </button>
    </div>
  );
}

export default function SortableImageGrid({
  items,
  onReorder,
  onRemove,
  disabled = false,
}: SortableImageGridProps) {
  const [activeId, setActiveId] = useState<string | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 200, tolerance: 5 } })
  );

  if (items.length === 0) return null;

  const activeItem = items.find((item) => item.id === activeId);

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    setActiveId(null);
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = items.findIndex((item) => item.id === active.id);
    const newIndex = items.findIndex((item) => item.id === over.id);
    if (oldIndex === -1 || newIndex === -1) return;

    onReorder(oldIndex, newIndex);
  };

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <SortableContext items={items.map((item) => item.id)} strategy={rectSortingStrategy}>
        <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
          {items.map((item) => (
            <SortableImageTile
              key={item.id}
              item={item}
              onRemove={onRemove}
              isSingle={items.length <= 1}
              disabled={disabled}
            />
          ))}
        </div>
      </SortableContext>

      <DragOverlay>
        {activeItem ? (
          <div className="aspect-square w-full max-w-[120px] rounded-2xl overflow-hidden border-2 border-primary shadow-xl opacity-90">
            <OptimizedImage
              src={activeItem.url}
              alt=""
              className="w-full h-full object-cover"
            />
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  );
}
