// DOM overlay: FPS readout for `?debug` (F0). The game HUD (players, power-field score, turn) comes in F2.

export const byId = <T extends HTMLElement>(id: string): T => {
  const el = document.getElementById(id);
  if (!el) throw new Error(`#${id} missing in index.html`);
  return el as T;
};

export class FpsMeter {
  private readonly el: HTMLElement;
  private last = 0;

  constructor(enabled: boolean) {
    this.el = byId('fps');
    this.el.hidden = !enabled;
  }

  update(fps: number, now: number): void {
    if (this.el.hidden || now - this.last < 500) return;
    this.last = now;
    this.el.textContent = `${fps.toFixed(0)} fps`;
  }
}
