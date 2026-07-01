---
name: Void Trader
colors:
  surface: '#0e1416'
  surface-dim: '#0e1416'
  surface-bright: '#343a3c'
  surface-container-lowest: '#090f11'
  surface-container-low: '#161d1e'
  surface-container: '#1a2122'
  surface-container-high: '#242b2d'
  surface-container-highest: '#2f3638'
  on-surface: '#dde4e5'
  on-surface-variant: '#bbc9cd'
  inverse-surface: '#dde4e5'
  inverse-on-surface: '#2b3233'
  outline: '#859397'
  outline-variant: '#3c494c'
  surface-tint: '#2fd9f4'
  primary: '#8aebff'
  on-primary: '#00363e'
  primary-container: '#22d3ee'
  on-primary-container: '#005763'
  inverse-primary: '#006877'
  secondary: '#ffb95f'
  on-secondary: '#472a00'
  secondary-container: '#ee9800'
  on-secondary-container: '#5b3800'
  tertiary: '#cfdef6'
  on-tertiary: '#233144'
  tertiary-container: '#b3c2d9'
  on-tertiary-container: '#425063'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#a2eeff'
  primary-fixed-dim: '#2fd9f4'
  on-primary-fixed: '#001f25'
  on-primary-fixed-variant: '#004e5a'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#d5e3fc'
  tertiary-fixed-dim: '#b9c7df'
  on-tertiary-fixed: '#0d1c2e'
  on-tertiary-fixed-variant: '#3a485b'
  background: '#0e1416'
  on-background: '#dde4e5'
  surface-variant: '#2f3638'
typography:
  headline-lg:
    fontFamily: Archivo Narrow
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: 0.05em
  headline-md:
    fontFamily: Archivo Narrow
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: 0.02em
  body-lg:
    fontFamily: JetBrains Mono
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
  headline-lg-mobile:
    fontFamily: Archivo Narrow
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  gutter: 12px
  margin: 16px
---

## Brand & Style
The design system for this product is rooted in a "Tactical Cyber-Industrial" aesthetic. It targets mobile gamers engaged in deep-space exploration and resource management. The UI must evoke a sense of high-stakes technical operation, reminiscent of a futuristic starship terminal. 

The style combines elements of **Minimalism** with **Retro-Futuristic** details. It utilizes high-contrast color pairings, thin vector-based borders, and subtle digital artifacts like scanlines and chromatic aberration to create a sense of hardware immersion without sacrificing clarity. While the game world consists of pixel-art viewports, the interface remains crisp and utilitarian to ensure data-heavy menus are readable on small screens.

## Colors
The palette is dominated by "Deep Space Black" to provide maximum contrast for tactical overlays. 

- **Primary (Cyan):** Used for interactive elements, active ship systems, and navigation paths. This color should feature a subtle glow (outer shadow) when active.
- **Secondary (Amber):** Reserved for critical warnings, fuel/resource shortages, and hazard zones. 
- **Muted Gray:** Used for inactive modules, disabled buttons, and secondary metadata.
- **Text (Off-White):** Provides high legibility against the dark background.

Apply a 5% opacity cyan tint to container backgrounds to differentiate them from the "Void" (pure background).

## Typography
This design system utilizes two distinct typefaces to balance technical data with hierarchical clarity. 

- **Archivo Narrow (Condensed):** Used for all headings and major UI labels. Its verticality maximizes screen real estate for ship titles and system headers. Use Uppercase for `headline-lg` and `label-sm`.
- **JetBrains Mono:** Used for all quantitative data, coordinates, inventory counts, and terminal logs. The monospaced nature ensures that shifting numbers (like currency or coordinates) do not cause layout "jitter."

All typography should be rendered with high-contrast white, except for labels and metadata, which use the Muted Gray.

## Layout & Spacing
The layout follows a **Fluid Grid** model optimized for portrait mobile devices. 

- **The HUD Margin:** Maintain a strict 16px safe area on the left and right edges. 
- **Density:** The design system prioritizes "Information Density." Gutters are tight (12px) to allow for multiple data columns.
- **Scanning Rhythm:** Use horizontal dividers (1px thickness) with 10% opacity cyan to separate list items in market or inventory views.
- **Bottom-Heavy Controls:** Place primary interaction nodes (Joystick, Action Buttons) within the bottom 30% of the screen for thumb-reachability.

## Elevation & Depth
Depth is conveyed through **Bold Borders** and **Tonal Layering** rather than traditional shadows. 

- **Level 0 (The Void):** Background color #0a0e1a.
- **Level 1 (Panels):** Surface with a 1px border (#475569) and a subtle scanline pattern overlay.
- **Level 2 (Active Elements):** Cyan borders (#22d3ee) with a 4px blur outer glow.
- **Chromatic Aberration:** Apply a subtle 1px horizontal offset of Red/Blue channels only to the edges of the screen or critical warning pop-ups to simulate hardware glitching.
- **Glassmorphism:** Use only for the HUD overlays (Hull/Shield bars) with a backdrop blur of 8px to ensure the game viewport remains visible behind the UI.

## Shapes
The shape language is strictly **Sharp (0px)**. 

To reinforce the industrial/tech aesthetic:
- **Clipped Corners:** Larger panels should feature a 45-degree "clipped corner" (12px chamfer) on the top-right or bottom-left to break the rectangular monotony.
- **Framing:** Use "brackets" (L-shaped corners) for targeting reticles and selected inventory slots instead of full boxes.
- **Connectors:** Lines in the node-graph or block-coding interface must be orthogonal (90-degree angles).

## Components

### Buttons
- **Primary:** No fill. 1px Cyan border. Text in Cyan. 4px outer Cyan glow.
- **Danger:** No fill. 1px Amber border. Text in Amber. 
- **Inactive:** No fill. 1px Muted Gray border. Text in Muted Gray.

### Progress Bars (Hull / Shields)
- **Container:** 1px border. 
- **Fill:** Solid Cyan (Shields) or Amber (Hull). 
- **Segmenting:** Divide bars into 10 discrete blocks to make incremental damage visually clear.

### Inventory Slots & Chips
- **Slot:** Square aspect ratio. 1px Muted Gray border. 
- **Quantity Label:** Positioned bottom-right using `label-sm` in JetBrains Mono.
- **Rarity Chips:** Small vertical strip on the left edge of the slot (Cyan for Common, Amber for Rare).

### Market Lists
- Rows separated by 1px dividers.
- Price data aligned to the right using `body-md` Monospace.
- "Buy" actions represented by a chevron `>` icon for compactness.

### Node-Graph / Block-Coding
- Nodes are rectangular containers with a "header" bar in Primary Cyan.
- Input/Output ports are 8x8px squares on the left/right edges.
- Lines between nodes use "step" routing (horizontal/vertical only).