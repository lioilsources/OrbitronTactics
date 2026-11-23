// F0 spike: the starting board of a hot-seat game, tap selects a piece of the player on turn.
// Deep links: ?board=hex6 (default classic8), ?seed=<n> (power-field draw), ?debug (FPS).
import { Engine } from '@babylonjs/core/Engines/engine';

import { resolveTap, tapReachFor } from '../rules/board-layout';
import { specById } from '../rules/board-spec';
import { generatePowerFields, lcg, startingBoard } from '../rules/board-state';
import { handleTap, NO_SELECTION, tapTargets, type Interaction, type LegalMoves } from '../rules/interaction';
import type { PlayerColor } from '../rules/piece';
import { byId, FpsMeter } from '../ui/hud';
import { BoardScene } from './board-scene';
import '../ui/style.css';

const params = new URLSearchParams(location.search);
const spec = specById(params.get('board') ?? 'classic8');
const seed = Number(params.get('seed') ?? Math.floor(Math.random() * 0x7fffffff));
const board = startingBoard(spec, generatePowerFields(spec, lcg(seed)));

/** Move rules arrive in F1 (validators/); the spike only selects. */
const legalMoves: LegalMoves = () => [];
const turn: PlayerColor = 'white';
let interaction: Interaction = NO_SELECTION;

const canvas = byId<HTMLCanvasElement>('game');
const engine = new Engine(canvas, true, { preserveDrawingBuffer: false, stencil: false, antialias: true }, true);
const view = new BoardScene(engine, board, interaction);
const fps = new FpsMeter(params.has('debug'));

// Tap = pointer down and up close together (GestureDetector.onTapUp). Not Babylon's POINTERTAP:
// with a catch-all observer it waits out the double-tap delay (300 ms) before firing.
const TAP_SLOP = 18; // CSS px (kTouchSlop)
let down: { id: number; x: number; y: number } | null = null;
canvas.addEventListener('pointerdown', (e) => {
  down = { id: e.pointerId, x: e.clientX, y: e.clientY };
});
canvas.addEventListener('pointerup', (e) => {
  const d = down;
  down = null;
  if (!d || d.id !== e.pointerId || Math.hypot(e.clientX - d.x, e.clientY - d.y) > TAP_SLOP) return;
  const rect = canvas.getBoundingClientRect();
  onTap(e.clientX - rect.left, e.clientY - rect.top);
});
canvas.addEventListener('pointercancel', () => (down = null));

function onTap(cssX: number, cssY: number): void {
  const point = view.toBoard(cssX, cssY);
  const reach = tapReachFor(view.layout);
  const tapped = reach > 0
    ? resolveTap(view.layout, point, tapTargets(board, interaction, turn, legalMoves, false), reach)
    : view.layout.positionAt(point);
  if (!tapped) return;
  interaction = handleTap(board, interaction, tapped, turn, legalMoves).interaction;
  view.setState(board, interaction);
}

engine.runRenderLoop(() => {
  view.scene.render();
  fps.update(engine.getFps(), performance.now());
});
window.addEventListener('resize', () => {
  engine.resize();
  view.fit();
});
// Hook for measurements (tools, not the game): first rendered frame.
view.scene.onAfterRenderObservable.addOnce(() => {
  performance.mark('archion-first-frame');
});
