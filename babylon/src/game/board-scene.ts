// Babylon scene: the board seen straight from above (orthographic, as GameBoard in Flutter).
// Layers are textured planes on z, front to back: pieces, overlay, power-field fill, cells.
// World units = board units of BoardLayout (width BOARD_W), y flipped (Flutter's y points down).
import { Engine } from '@babylonjs/core/Engines/engine';
import { Scene } from '@babylonjs/core/scene';
import { FreeCamera } from '@babylonjs/core/Cameras/freeCamera';
import { Camera } from '@babylonjs/core/Cameras/camera';
import { Color3, Color4 } from '@babylonjs/core/Maths/math.color';
import { Vector3 } from '@babylonjs/core/Maths/math.vector';
import { StandardMaterial } from '@babylonjs/core/Materials/standardMaterial';
import { DynamicTexture } from '@babylonjs/core/Materials/Textures/dynamicTexture';
import { CreatePlane } from '@babylonjs/core/Meshes/Builders/planeBuilder';
import type { Mesh } from '@babylonjs/core/Meshes/mesh';
// Bundle the StandardMaterial shaders up front: saves lazy-load round trips before the first frame.
import '@babylonjs/core/Shaders/default.vertex';
import '@babylonjs/core/Shaders/default.fragment';

import { BoardLayout, type Point } from '../rules/board-layout';
import { type BoardState, pieceAt } from '../rules/board-state';
import type { Interaction } from '../rules/interaction';
import type { Piece } from '../rules/piece';
import { paintCells, paintFieldFills, paintOverlay } from '../ui/board-paint';
import { rgb01, SCREEN_BG } from '../ui/palette';
import { paintClassicPiece } from '../ui/piece-paint';

const BOARD_W = 10;
/** Free space around the board, as a fraction of the shorter screen side. */
const MARGIN = 0.03;
/** Power-field glow (game_board.dart): 0.3 → 0.6 and back, 1500 ms each way, ease in-out. */
const GLOW_MS = 1500;
export const glowAt = (ms: number): number => {
  const phase = (ms / GLOW_MS) % 2;
  const t = phase < 1 ? phase : 2 - phase;
  return 0.3 + 0.3 * (0.5 - 0.5 * Math.cos(Math.PI * t));
};

export class BoardScene {
  readonly scene: Scene;
  readonly layout: BoardLayout;
  private readonly camera: FreeCamera;
  private readonly cells: { mesh: Mesh; tex: DynamicTexture };
  private readonly fills: { mesh: Mesh; tex: DynamicTexture; mat: StandardMaterial };
  private readonly overlay: { mesh: Mesh; tex: DynamicTexture };
  private readonly pieceTextures = new Map<string, DynamicTexture>();
  private pieceMeshes: Mesh[] = [];
  private texScale = 0;

  constructor(readonly engine: Engine, private board: BoardState, private interaction: Interaction) {
    const scene = (this.scene = new Scene(engine));
    scene.clearColor = Color4.FromArray([...rgb01(SCREEN_BG), 1]);
    scene.skipPointerMovePicking = true;
    scene.autoClear = true;

    const cam = (this.camera = new FreeCamera('cam', new Vector3(0, 0, -10), scene));
    cam.mode = Camera.ORTHOGRAPHIC_CAMERA;
    cam.setTarget(new Vector3(0, 0, 0));
    cam.minZ = 0.1;
    cam.maxZ = 100;

    this.layout = BoardLayout.fit(board.spec.geometry, BOARD_W);
    this.cells = this.layer('cells', 0.4, 0);
    const fills = this.layer('fills', 0.3, 1);
    this.fills = { ...fills, mat: fills.mesh.material as StandardMaterial };
    this.overlay = this.layer('overlay', 0.2, 2);

    this.fit();
    this.repaint();
    this.placePieces();
    scene.onBeforeRenderObservable.add(() => {
      this.fills.mat.alpha = glowAt(performance.now());
    });
  }

  /** A board-sized textured plane at depth z (smaller = nearer); alphaIndex keeps the draw order. */
  private layer(name: string, z: number, order: number): { mesh: Mesh; tex: DynamicTexture } {
    const { width: w, height: h } = this.layout;
    const mesh = CreatePlane(name, { width: w, height: h }, this.scene);
    mesh.position.set(w / 2, -h / 2, z);
    mesh.alphaIndex = order;
    mesh.isPickable = false;
    const tex = new DynamicTexture(name, { width: 16, height: 16 }, this.scene, true);
    tex.hasAlpha = true;
    const mat = new StandardMaterial(name, this.scene);
    mat.disableLighting = true;
    mat.emissiveColor = Color3.White();
    mat.diffuseTexture = tex;
    mat.emissiveTexture = tex;
    mat.useAlphaFromDiffuseTexture = true;
    mat.backFaceCulling = false;
    mesh.material = mat;
    return { mesh, tex };
  }

  /** Orthographic frame: the whole board, centred, with a small margin. */
  fit(): void {
    const cw = this.engine.getRenderWidth();
    const ch = this.engine.getRenderHeight();
    const { width: w, height: h } = this.layout;
    const pad = MARGIN * Math.min(cw, ch);
    const k = Math.min((cw - 2 * pad) / w, (ch - 2 * pad) / h); // render px per world unit
    const halfW = cw / k / 2;
    const halfH = ch / k / 2;
    const cam = this.camera;
    cam.position.set(w / 2, -h / 2, -10);
    cam.setTarget(new Vector3(w / 2, -h / 2, 0));
    cam.orthoLeft = -halfW;
    cam.orthoRight = halfW;
    cam.orthoTop = halfH;
    cam.orthoBottom = -halfH;
    // Texture resolution follows the board's size on screen (capped for phones' GPU memory).
    const scale = Math.min(2048 / w, Math.ceil(k));
    if (scale !== this.texScale) {
      this.texScale = scale;
      this.repaint();
      this.repaintPieces();
    }
  }

  /** Screen point (CSS px relative to the canvas) → board point (BoardLayout units, y down). */
  toBoard(cssX: number, cssY: number): Point {
    const canvas = this.engine.getRenderingCanvas();
    const rect = canvas?.getBoundingClientRect();
    const cw = rect?.width || 1;
    const ch = rect?.height || 1;
    const cam = this.camera;
    const wx = cam.position.x + (cam.orthoLeft ?? 0) + (cssX / cw) * ((cam.orthoRight ?? 0) - (cam.orthoLeft ?? 0));
    const wy = cam.position.y + (cam.orthoTop ?? 0) - (cssY / ch) * ((cam.orthoTop ?? 0) - (cam.orthoBottom ?? 0));
    return { x: wx, y: -wy };
  }

  setState(board: BoardState, interaction: Interaction): void {
    const boardChanged = board !== this.board;
    this.board = board;
    this.interaction = interaction;
    if (boardChanged) {
      this.paintLayer(this.fills.tex, (ctx, s) => paintFieldFills(ctx, this.layout, this.board, s));
      this.placePieces();
    }
    this.paintLayer(this.overlay.tex, (ctx, s) => paintOverlay(ctx, this.layout, this.board, this.interaction, s));
  }

  private paintLayer(tex: DynamicTexture, paint: (ctx: CanvasRenderingContext2D, scale: number) => void): void {
    const s = this.texScale || 64;
    const w = Math.ceil(this.layout.width * s);
    const h = Math.ceil(this.layout.height * s);
    const size = tex.getSize();
    if (size.width !== w || size.height !== h) tex.scaleTo(w, h);
    paint(tex.getContext() as unknown as CanvasRenderingContext2D, s);
    tex.update(true);
  }

  private repaint(): void {
    this.paintLayer(this.cells.tex, (ctx, s) => paintCells(ctx, this.layout, this.board, s));
    this.paintLayer(this.fills.tex, (ctx, s) => paintFieldFills(ctx, this.layout, this.board, s));
    this.paintLayer(this.overlay.tex, (ctx, s) => paintOverlay(ctx, this.layout, this.board, this.interaction, s));
  }

  private pieceTexture(pc: Piece): DynamicTexture {
    const key = `${pc.type}-${pc.color}-${pc.isLastWarrior}`;
    let tex = this.pieceTextures.get(key);
    if (!tex) {
      tex = new DynamicTexture(key, { width: 16, height: 16 }, this.scene, true);
      tex.hasAlpha = true;
      this.pieceTextures.set(key, tex);
      this.paintPiece(tex, pc);
    }
    return tex;
  }

  private paintPiece(tex: DynamicTexture, pc: Piece): void {
    const px = Math.min(512, Math.max(32, Math.ceil(this.layout.cellSize * (this.texScale || 64))));
    tex.scaleTo(px, px);
    paintClassicPiece(tex.getContext() as unknown as CanvasRenderingContext2D, pc, px);
    tex.update(true);
  }

  private repaintPieces(): void {
    for (const [key, tex] of this.pieceTextures) {
      const [type, color, lw] = key.split('-');
      this.paintPiece(tex, { type, color, isLastWarrior: lw === 'true' } as Piece);
    }
  }

  /** One plane per piece, sharing a texture per piece look. */
  private placePieces(): void {
    for (const m of this.pieceMeshes) m.dispose(false, false);
    this.pieceMeshes = [];
    const cs = this.layout.cellSize;
    for (const cell of this.board.spec.geometry.cells) {
      const pc = pieceAt(this.board, cell);
      if (!pc) continue;
      const c = this.layout.centreOf(cell);
      const mesh = CreatePlane(`piece-${cell.row}-${cell.col}`, { size: cs }, this.scene);
      mesh.position.set(c.x, -c.y, 0.1);
      mesh.alphaIndex = 3;
      mesh.isPickable = false;
      const key = `${pc.type}-${pc.color}-${pc.isLastWarrior}`;
      let mat = this.scene.getMaterialByName(`m-${key}`) as StandardMaterial | null;
      if (!mat) {
        mat = new StandardMaterial(`m-${key}`, this.scene);
        mat.disableLighting = true;
        mat.emissiveColor = Color3.White();
        const tex = this.pieceTexture(pc);
        mat.diffuseTexture = tex;
        mat.emissiveTexture = tex;
        mat.useAlphaFromDiffuseTexture = true;
        mat.backFaceCulling = false;
      }
      mesh.material = mat;
      this.pieceMeshes.push(mesh);
    }
  }
}
