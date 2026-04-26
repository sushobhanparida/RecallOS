---
name: Apricot Soft-Touch
colors:
  surface: '#fff8f6'
  surface-dim: '#e6d7d3'
  surface-bright: '#fff8f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1ed'
  surface-container: '#faebe6'
  surface-container-high: '#f4e5e1'
  surface-container-highest: '#eedfdb'
  on-surface: '#211a18'
  on-surface-variant: '#54433d'
  inverse-surface: '#372f2c'
  inverse-on-surface: '#fdeee9'
  outline: '#87736c'
  outline-variant: '#dac1ba'
  surface-tint: '#94492e'
  primary: '#94492e'
  on-primary: '#ffffff'
  primary-container: '#ff9e7d'
  on-primary-container: '#78331a'
  inverse-primary: '#ffb59c'
  secondary: '#75593e'
  on-secondary: '#ffffff'
  secondary-container: '#ffd9b7'
  on-secondary-container: '#795d42'
  tertiary: '#615e58'
  on-tertiary: '#ffffff'
  tertiary-container: '#bbb6af'
  on-tertiary-container: '#4a4742'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59c'
  on-primary-fixed: '#390c00'
  on-primary-fixed-variant: '#763219'
  secondary-fixed: '#ffdcbe'
  secondary-fixed-dim: '#e4c09f'
  on-secondary-fixed: '#2a1703'
  on-secondary-fixed-variant: '#5b4229'
  tertiary-fixed: '#e7e2da'
  tertiary-fixed-dim: '#cbc6be'
  on-tertiary-fixed: '#1d1b17'
  on-tertiary-fixed-variant: '#494641'
  background: '#fff8f6'
  on-background: '#211a18'
  surface-variant: '#eedfdb'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: '0'
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: '0'
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: '0'
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-margin: 32px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  section-padding: 64px
---

## Brand & Style

The design system is centered on radical approachability and a "soft-minimalist" aesthetic. It targets lifestyle, wellness, and social platforms that prioritize emotional comfort and clarity over high-density information. The brand personality is warm, inviting, and human-centric, moving away from clinical tech-coldness toward a tactile, organic feel.

The style leverages a **Modern Flat** movement, specifically avoiding heavy shadows or skeuomorphism in favor of clear tonal layering and generous whitespace. It borrows the airiness of Minimalism but replaces its typical austerity with a warm, sun-drenched palette and intentional roundedness to create an interface that feels safe and friendly to the touch.

## Colors

The palette is anchored in a monochromatic warmth, transitioning from a vibrant soft peach to a creamy off-white.

- **Primary (#FF9E7D):** A soft, muted peach used for call-to-action elements, active states, and brand-defining highlights.
- **Secondary (#FFD9B7):** A lighter apricot tint for secondary buttons, progress indicators, and decorative accents.
- **Surface/Tertiary (#FFF9F1):** The "Cream" base. This serves as the global background color, providing a softer, less straining experience than pure white.
- **Neutral (#5C524F):** A warm, desaturated cocoa-grey used for typography and icons to maintain high legibility without the harshness of pure black.

## Typography

The typography uses **Plus Jakarta Sans** exclusively to reinforce the modern, friendly character of the design system. The font's geometric yet soft curves mirror the roundedness of the UI components.

Headlines use a tighter letter-spacing and bold weights to command attention while remaining approachable. Body text is set with a generous line-height to ensure maximum readability against the cream background. Labels use slightly increased tracking and medium weights to differentiate them from body copy at smaller scales.

## Layout & Spacing

This design system utilizes a **Fluid Grid** model with a soft 8px rhythm. The layout philosophy prioritizes "breathability" over information density. Large internal paddings within cards and containers are essential to maintaining the minimalist aesthetic.

- **Margins:** Side margins are kept wide (minimum 32px) to prevent content from feeling cramped.
- **Gutter:** A 16px gutter is standard for grid-based content, allowing the rounded corners of cards to be clearly visible.
- **Rhythm:** Vertical spacing follows an exponential scale (8, 16, 32, 64) to create a clear visual hierarchy between sections.

## Elevation & Depth

Depth is conveyed through **Tonal Layers** and **Low-Contrast Outlines** rather than traditional shadows. This keeps the interface feeling "flat" but physically structured.

- **Surface Tiers:** The base layer is the Cream (#FFF9F1). Higher priority containers (like cards or modals) are rendered in pure White (#FFFFFF) to subtly lift them from the background.
- **Outlines:** Instead of shadows, components use 1px or 2px borders in a shade slightly darker than the surface they sit on (e.g., #F2EBE1).
- **Active States:** Depth is often signaled by color shifts (e.g., a button moving from Secondary Peach to Primary Peach) rather than a "pressed" shadow effect.

## Shapes

The design system utilizes **Rounded (Level 2)** geometry. Every interactive and container element must feel smooth, avoiding sharp edges while maintaining a structured, modern appearance.

- **Standard Elements:** Buttons, input fields, and tags use a standard 0.5rem (8px) radius for a balanced, friendly feel.
- **Containers:** Large cards and modals use an increased radius (1.5rem/24px) to create a soft, inviting container style.
- **Nested Shapes:** When nesting elements, the inner radius is reduced proportionally to maintain visual harmony and consistent concentricity.

## Components

- **Buttons:** Primary buttons are rounded (8px) with the Primary Peach background and Cocoa text. They utilize a subtle "grow" scale effect on hover (1.02x) rather than a shadow.
- **Input Fields:** These feature a solid off-white background with a soft peach border on focus. Icons within inputs are always rounded to match the system aesthetic.
- **Chips & Tags:** Small, rounded elements using the Secondary Peach background. Used for categorization without overwhelming the visual field.
- **Cards:** White containers with a 24px corner radius. Content inside should have at least 24px of internal padding to ensure it doesn't touch the curved edges.
- **Checkboxes & Radios:** Exaggerated size for touch-friendliness. Checkboxes use soft-radius corners to stay consistent with the system's overall geometry.
- **Modals:** Centered overlays with heavy backdrops (using a warm, low-opacity tint of the Neutral color). 
- **Navigation:** Bottom navigation bars (on mobile) or sidebars (on desktop) use rounded "active states" that look like soft, rectangular blobs behind icons.
