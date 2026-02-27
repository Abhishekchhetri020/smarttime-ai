export function scrollToId(id: string) {
  if (!id) return;
  if (typeof window === 'undefined') return;
  requestAnimationFrame(() => {
    const el = document.getElementById(id);
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
}
