---
name: Evergreen Modern
colors:
  surface: '#fcf9f2'
  surface-dim: '#dcdad3'
  surface-bright: '#fcf9f2'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3ed'
  surface-container: '#f0eee7'
  surface-container-high: '#ebe8e1'
  surface-container-highest: '#e5e2dc'
  on-surface: '#1c1c18'
  on-surface-variant: '#444844'
  inverse-surface: '#31312c'
  inverse-on-surface: '#f3f0ea'
  outline: '#757873'
  outline-variant: '#c5c7c2'
  surface-tint: '#4b6450'
  primary: '#4b6450'
  on-primary: '#ffffff'
  primary-container: '#daf7dd'
  on-primary-container: '#59735e'
  inverse-primary: '#b1ceb5'
  secondary: '#7a5645'
  on-secondary: '#ffffff'
  secondary-container: '#fdcdb7'
  on-secondary-container: '#795544'
  tertiary: '#a43d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#ffece5'
  on-tertiary-container: '#bb4700'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cdead0'
  primary-fixed-dim: '#b1ceb5'
  on-primary-fixed: '#072010'
  on-primary-fixed-variant: '#334c3a'
  secondary-fixed: '#ffdbcb'
  secondary-fixed-dim: '#ebbca7'
  on-secondary-fixed: '#2e1508'
  on-secondary-fixed-variant: '#603f2f'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb597'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7d2d00'
  background: '#fcf9f2'
  on-background: '#1c1c18'
  surface-variant: '#e5e2dc'
typography:
  h1:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.2'
  h2:
    fontFamily: Montserrat
    fontSize: 36px
    fontWeight: '600'
    lineHeight: '1.3'
  h3:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  gutter: 24px
  margin: 32px
---

# Design System: Evergreen Modern

## Brand & Style
Evergreen Modern is a sophisticated and grounded visual identity that balances organic stability with modern precision. It is designed to evoke feelings of trust, longevity, and professional calm. By combining a deep, forest-inspired palette with geometric typography and soft, approachable shapes, the brand appeals to users seeking both reliability and contemporary elegance. 

The style is a blend of **Minimalism** and **Corporate Modern**, utilizing generous whitespace to allow the rich primary colors to serve as anchors. It avoids the harshness of industrial design in favor of a more "human-centric" professional aesthetic.

## Colors
The color palette is anchored by a deep forest green (#37503D) which serves as the primary brand color, signifying growth and stability. The secondary warm taupe (#bd927e) provides a soft, earthen contrast, while the vibrant tertiary orange (#ff660d) is used sparingly for high-priority calls to action. 

The neutral palette is grounded in a near-black charcoal (#262622) for text and deep accents, set against a warm, off-white seed background (#F0F0EC). This "light mode" approach reduces eye strain by avoiding pure white backgrounds, opting instead for a more parchment-like, organic surface.

## Typography
The typography system uses **Montserrat** for headlines to provide a bold, geometric, and authoritative presence. Its wide character set and clean lines give the brand a modern architectural feel. 

For body text and labels, **Inter** is utilized for its exceptional legibility and neutral tone. Inter ensures that long-form content is easy to digest, while its technical precision complements the more expressive Montserrat. Hierarchy is established through significant weight shifts in headlines and generous line heights in body text to maintain an airy, premium feel.

## Layout & Spacing
The system employs a **Fluid Grid** logic based on an 8px rhythmic scale. Content is organized within a flexible 12-column structure with 24px gutters to ensure significant breathing room between elements. 

Margins are generous (32px minimum on mobile, expanding on desktop) to reinforce the minimalist brand personality. The spacing scale is used consistently to define the relationship between elements: smaller gaps (4px-8px) for related items within a component, and larger gaps (24px-48px) for distinct sections of a page.

## Elevation & Depth
Depth is conveyed primarily through **Tonal Layers** and extremely subtle, soft shadows. Rather than using heavy drop shadows, the system uses variations in surface color (using the warm neutral palette) to indicate hierarchy. 

When elevation is necessary for interactive elements (like modals or floating action buttons), use "Ambient Shadows"—diffused, low-opacity shadows with a slight tint of the neutral-color-hex to make them feel integrated into the environment. Most surfaces remain flat to keep the interface clean and focused on content.

## Shapes
The shape language is defined by high **Roundedness (Level 3)**. UI elements such as buttons, tags, and input fields utilize "pill" shapes (fully rounded corners). Larger containers like cards and modals use a generous 2rem to 3rem corner radius. 

This extreme roundedness softens the professional tone of the brand, making the interface feel friendly, approachable, and tactile. It contrasts beautifully with the sharp, geometric lines of the Montserrat headlines.

## Components
- **Buttons:** Primary buttons are pill-shaped, using the deep green (#37503D) with white text. Secondary buttons use the taupe (#bd927e) or an outline style. Tertiary actions use the vibrant orange (#ff660d).
- **Cards:** Use large 2rem corner radii. Borders should be minimal or replaced by subtle tonal shifts against the off-white background.
- **Inputs:** Fully rounded (pill-shaped) borders with Inter medium for labels. Focus states should use a 2px solid stroke of the primary green.
- **Chips/Tags:** Always pill-shaped with Inter small/bold typography. Use light tints of the primary or secondary colors for backgrounds.
- **Lists:** Clean, separated by subtle 1px lines in a lightened neutral shade or generous vertical spacing rather than hard dividers.