---
name: Void Trader
colors:
  surface: '#131315'
  surface-dim: '#131315'
  surface-bright: '#39393b'
  surface-container-lowest: '#0e0e10'
  surface-container-low: '#1b1b1d'
  surface-container: '#1f1f21'
  surface-container-high: '#2a2a2c'
  surface-container-highest: '#353437'
  on-surface: '#e4e2e4'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#e4e2e4'
  inverse-on-surface: '#303032'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#bcc7dd'
  on-secondary: '#263142'
  secondary-container: '#3c475a'
  on-secondary-container: '#aab6cc'
  tertiary: '#ffe9d9'
  on-tertiary: '#4c2700'
  tertiary-container: '#ffc594'
  on-tertiary-container: '#864a00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#d8e3fa'
  secondary-fixed-dim: '#bcc7dd'
  on-secondary-fixed: '#111c2c'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#ffdcc1'
  tertiary-fixed-dim: '#ffb778'
  on-tertiary-fixed: '#2e1500'
  on-tertiary-fixed-variant: '#6c3a00'
  background: '#131315'
  on-background: '#e4e2e4'
  surface-variant: '#353437'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: 0.05em
  title-sm:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: 0.02em
  body-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '800'
    lineHeight: 16px
    letterSpacing: 0.1em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
spacing:
  unit: 4px
  gutter: 12px
  margin-mobile: 16px
  margin-desktop: 32px
  panel-padding: 16px
---

## Brand & Style
The design system embodies a rugged, industrial "used-universe" aesthetic. It is built to simulate a high-density pilot or engineer console found on a deep-space freighter. The personality is utilitarian, resilient, and technical, focusing on information density and tactile feedback over aesthetic softness.

The design style leans heavily into **Industrial Brutalism** mixed with **Functional High-Contrast**. It avoids smooth gradients and rounded corners in favor of hard edges, visible structural borders, and "glow-on-dark" sensor aesthetics. Surfaces should feel like heavy graphite plating, while interactive elements pulse with the low-hum energy of ship instrumentation.

## Colors
The palette is rooted in the "Deep Space Black" void, providing maximum contrast for glowing UI elements. 

- **Background & Surface:** Use the deep black for the core canvas. Graphite panels create the structural skeleton of the UI.
- **Interactive Layers:** Cyan is reserved for primary sensors, active navigation, and "ready" states. Amber is utilized for profit margins, trade routes, and high-value data highlights.
- **System States:** Red is strictly for structural damage or critical alerts. Soft green represents stable life support and successful transactions.
- **Faction Accents:** Use muted purple (#6B46C1), deep gold (#B8860B), and teal (#008080) sparingly to denote cargo ownership or regional influence.

## Typography
Typography is treated as a readout from a ship's computer. **JetBrains Mono** is the workhorse font, used for all data, labels, and instructional text to maintain a technical, monospaced rhythm. **Space Grotesk** is used for high-level headers to add a futuristic, geometric edge to the industrial setting.

All labels should be displayed in uppercase (`label-caps`) to mimic hardware-etched identifiers. Large data readouts (like credits or fuel) should use the `display-lg` setting to ensure immediate legibility against the dark background.

## Layout & Spacing
The layout follows a **Rigid Grid** philosophy. Content should feel "locked-in" to a 4px baseline grid, suggesting modular hardware components being slotted into a rack. 

- **Information Density:** Keep margins tight (12px to 16px) to maximize the amount of data visible on screen. 
- **Modular Blocks:** Use defined Graphite UI panels to group related data (e.g., Engine Specs, Cargo Manifest). 
- **Responsive Behavior:** On mobile, the UI collapses into a single-column vertical scroll of modules. On desktop, the UI expands into a multi-pane dashboard with a persistent left-hand "Navigation Rail" for quick ship-system access.

## Elevation & Depth
In this design system, depth is achieved through **Tonal Layering** and **Technical Borders** rather than shadows. 

- **Surfaces:** Use #1C1C1E for primary containers. For nested elements, use a slightly lighter steel-blue tint at 5-10% opacity.
- **Borders:** Every panel should have a 1px solid border using Muted Steel Blue. 
- **Inner Glow:** Interactive or active panels should feature a subtle 2px inner-shadow/glow in Cyan to suggest a powered-on state.
- **The "Glass" Effect:** For modal overlays, use a heavy backdrop blur (20px) with a 60% opacity black tint to simulate looking through a reinforced cockpit viewport.

## Shapes
The shape language is strictly **Sharp**. In an industrial environment, curves are a luxury; efficiency and modularity are key. 

- **Corners:** 0px radius on all buttons, panels, and input fields.
- **Clipped Corners:** Use a 45-degree "snipped" corner (8px) on primary navigation buttons and main headers to reinforce the "military-grade" hardware feel.
- **Status Bars:** Linear and rectangular. No rounded caps on progress bars.

## Components
- **Buttons:** Hard-edged blocks. Default state has a Steel Blue border. Active/Hover states trigger a solid Cyan fill with black text.
- **Status Bars:** Gauges for Oxygen, Water, and Heat use a segmented "segmented-LED" look. Use 10-12 vertical blocks that fill from left to right.
- **Resource Chips:** Small rectangular containers with a 1px border. They must include a 16x16 pixel-art icon for the specific resource (e.g., Ore, Fuel, Tech-Scrap).
- **Technical Headers:** Use a "bracketed" style (e.g., `[ SYSTEM LOGS ]`) with a subtle scanning line animation moving vertically through the text.
- **Navigation Rail:** A slim vertical bar on the left with high-contrast icons. Active icons should "pulse" with a Cyan glow.
- **Input Fields:** Styled like console prompts. Use a blinking underscore cursor `_` at the end of the text.
- **Cards:** Used for Trading Market items. Features a heavy top-border in Amber if the item is "High Profit."