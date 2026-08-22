---
type: design-guidance
display-name: Asset Format Guidance
status: active
phase: phase-3
version: 1.0
updated: 2026-08-21
governed-by: "[[Neon Kitchen - Game Design Document]]"
source-decisions: "DEC-052, DEC-053, DEC-055"
tags:
  - neon-kitchen
  - art
  - assets
  - pipeline
---

# Asset Format Guidance

How to evaluate, transform and integrate visual assets without choosing an art
style merely because of the file format in which a candidate happens to ship.
This is a companion to [[Art Asset Brief]], which governs what is searched for,
and [[Visual Language]], which governs how the result must communicate.

This document deliberately does **not** select vector art, pixel art or painted
raster art for the game. That choice needs a representative visual proof at the
shipping screen size. The guidance here describes what a usable proof and a
repeatable production path look like for each format.

## 1. Separate the decisions

Five related choices are easy to collapse into one. Record them separately:

| Choice | Question |
|---|---|
| **Visual register** | What is the asset a picture of: top-down, elevated-oblique, strict front, portrait, full figure, or something else? |
| **Art style** | Pixel art, outlined illustration, painted raster, flat vector, or another treatment? |
| **Editable source** | What form is most useful while changing shapes, colours and composition? |
| **Runtime asset** | What does Godot load after the asset has been prepared and verified? |
| **Packaging** | Is it one file, separate sprites, a sprite sheet, an atlas, or layered parts? |

A vector source may ship to Godot as a PNG. Pixel art may arrive as individual
PNGs or one sprite sheet. A sprite sheet is packaging, not an art style. A small
raster image is not automatically pixel art: in pixel art, every pixel is an
intentional part of the drawing and the image is designed for integer scaling.

The visual register is chosen before format. A perfectly editable asset in the
wrong perspective remains the wrong asset.

## 2. Requirements shared by every format

A candidate is useful only when it passes all of these checks:

1. **Licence:** modification and embedding in a shipped game are allowed. Raw
   source redistribution is not required. Follow DEC-052 and record the source,
   licence, creator, acquisition method and required credit.
2. **Register:** its camera, visible planes and framing match the round's answer
   under DEC-055.
3. **Coverage:** it supplies enough of the required family that mixing unrelated
   packs will not become the main production method.
4. **Silhouette:** it remains recognisable at its real display size.
5. **Value structure:** the object survives desaturation and does not depend on
   hue alone to carry interaction or gameplay meaning.
6. **Transformability:** the needed recolour, crop, slice or shape adjustment can
   be written as a repeatable recipe rather than remembered by eye.
7. **Integration:** it can sit behind the game's controls without becoming the
   hit target, accessible name or gameplay identity.

Perspective, outline weight, light direction and detail density usually matter
more than whether two candidates share a file extension.

## 3. Format profiles

### Vector source

SVG, AI and EPS sources are strongest when geometry or individual material
planes need frequent editing.

**Good at**

- Scaling and cropping without losing edge quality.
- Replacing exact fills and strokes programmatically.
- Moving, removing or reshaping individual parts.
- Exporting several runtime sizes from one editable master.

**Watch for**

- Effects that do not survive Godot's SVG import, including some filters,
  masks, embedded fonts and blur treatments.
- Line weights that become inconsistent after aggressive scaling.
- Files whose useful shapes were flattened into one compound path.
- Marketplace selection being narrower than raster or pixel-art selection.

Treat element IDs as conveniences, not meaning. They are often generated and
unstable. Prefer a mapping based on the original fills, strokes and visible
material roles. When Godot renders the SVG differently from the editor, export
a verified transparent PNG and use that as the runtime asset.

### Pixel-art raster

Pixel art is strongest when a pack has a deliberate small palette, consistent
pixel density and broad coverage of the scene.

**Good at**

- Exact palette inspection and deterministic colour replacement.
- Compact sprite sheets and atlases.
- Crisp silhouettes at small logical resolutions.
- Programmatic ramp changes when shadows, midtones and highlights use stable
  source colours.

**Watch for**

- Incompatible native pixel densities between packs.
- Fractional scaling, filtering or camera movement that produces blur or
  shimmer.
- Different outline thicknesses becoming obvious after enlargement.
- Assuming that additional resolution can repair missing detail; enlarging
  pixel art reveals its authored pixels rather than inventing new ones.

Scale pixel art by whole numbers with nearest-neighbour filtering. One source
pixel becomes a `2×2`, `3×3` or `4×4` block. Choose the native logical scale for
the scene before resizing individual objects. A `32×32` label describes a common
prop or tile grid, not a requirement that every asset fit inside that box.

### Smooth raster illustration

Painted or anti-aliased PNG art is useful when a candidate already has the
right composition and needs limited adaptation.

**Good at**

- Rich material, lighting and hand-authored texture.
- Direct use when the source already fits the intended framing.
- Asset categories with many more raster choices than editable vector choices.

**Watch for**

- Resolution ceilings and softness after enlargement.
- Baked backgrounds, shadows or highlights that cannot move with the scene.
- Recolouring that changes unintended regions because many blended colours are
  shared.
- Compression damage or fringe pixels around transparency.

Prefer a source at least as large as its maximum display size. For non-pixel
raster art, a source around twice the display dimensions leaves useful room for
cropping and downsampling. More pixels do not compensate for the wrong camera or
silhouette.

## 4. Sizing and scaling

Search dimensions are not shipping dimensions. Evaluate the source according to
how its format scales:

| Source | Working rule |
|---|---|
| Vector | Preserve the aspect ratio; set a deliberate page or `viewBox`; verify the export at the real display size |
| Pixel art | Preserve the native pixel grid; use integer scaling and nearest-neighbour filtering |
| Smooth raster | Avoid enlargement; prefer roughly 2× the maximum display size when adaptation is expected |

Do not stretch width and height independently to fill a control. Crop, pad or
compose the asset inside the available area instead. The art may be visually
unequal while the interactive control maintains the required hit floor.

Every candidate is reviewed twice: isolated at its intended size, then inside
the complete shipping frame. A large editor preview cannot prove readability in
the game.

## 5. Transforming colour and material

Transform colours as **semantic value ramps**, not as an undifferentiated list
of hex replacements. A typical material ramp contains:

- outline or deepest seam;
- dark shadow or recess;
- main face or midtone;
- lit plane or rim;
- optional reflection or emissive accent.

For vector art, map source fills and strokes onto these roles. For palette-based
pixel art, inspect the exact colour histogram, group related shades into ramps,
then replace the ramp while preserving its order. For smooth raster art, use
masks or constrained hue/value adjustments rather than a global replacement.

Do not recolour solely by brightness. The same value may describe steel, food,
skin or an emissive display. A global light-to-dark conversion can preserve
contrast while destroying the identity of every material.

Preserve alpha, outline shape, light direction and the separation between
adjacent planes. Record the transformation recipe with the asset entry so a new
version can be regenerated instead of hand-matched.

## 6. Sprite sheets and atlases

A sheet is divided into rectangular regions; the complete sheet is not shown in
the scene. A region can be exported as its own transparent PNG or referenced as
an atlas region in Godot.

Use separate files while a candidate is still being edited heavily. Use an
atlas when the set is stable enough that shared packaging reduces repetitive
imports without obscuring where a sprite came from. Record each region's source
rectangle and intended integer scale. Do not infer gameplay identity from its
position in the sheet.

Embedded words deserve special review. Menu labels, shop names and interface
copy painted into a sprite may conflict with the game's voice, localisation or
mechanics even when the object itself fits. Remove, replace or treat that text
as unreadable background texture.

## 7. Godot integration

- Keep interaction, focus, selection, labels and accessibility on the owning
  `Control`; imported art is a non-interactive presentation layer.
- Choose nearest-neighbour filtering for pixel art. Use smooth filtering for
  vector-derived and painted raster assets unless a real-size proof says
  otherwise.
- Avoid fractional transforms for pixel art. Position and scale it on the
  chosen logical grid.
- Verify transparency and edge pixels against both light and dark grounds.
- Keep a constructed or shape-and-type fallback so an ignored sourced file is
  not required for a clean clone, import, test or editor load.
- Never use a file path, atlas index or Resource UID as gameplay identity.

Godot rasterises SVG input during import. The editable source and runtime asset
therefore do not need to be the same format. Choose the runtime form that has
the most predictable verified result.

## 8. Repository and licence handling

DEC-052 is format-independent. Licensed source art and its adapted runtime
files remain uncommitted under the ignored sourced-asset path and may be embedded
inside an exported game when the licence permits it. The repository's public
status until the class ends, and private status afterward, is load-bearing.

Commit only the information needed to reproduce and credit the result:

- source page and creator;
- licence and attribution string;
- acquisition or refetch instructions where legally possible;
- source filename or sprite-sheet region;
- crop, scale, palette and export recipe;
- intended presentation slot and fallback.

Never commit a purchased source, a derived sprite that would redistribute that
source, or a preview sheet merely to make setup convenient.

## 9. Candidate proof

Before an art style or pack becomes a production dependency, test a small but
representative set:

1. one large structural object;
2. one small interactive object;
3. one material with several value planes;
4. one organic or food form;
5. one character or background element when that slot is in scope.

Transform the set, place it at the shipping size, and judge coverage,
perspective, readability, palette fit and integration effort. Record what had to
be changed manually. The winning candidate is the one that makes the whole
screen coherent at sustainable effort, not the one with the most convenient
file extension.

