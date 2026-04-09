# Design System Document: The Sacred Editorial

## 1. Overview & Creative North Star: "The Digital Sanctuary"
This design system moves away from the clinical, "app-like" feel of standard educational tools and moves toward a high-end, editorial experience. We are not building a utility; we are building a sanctuary.

**Creative North Star: The Digital Sanctuary**
The interface should feel like a premium, leather-bound volume translated into a digital medium. We achieve this through "Organic Editorial" layouts—utilizing intentional asymmetry, large serif typography, and a "No-Line" philosophy that relies on tonal depth rather than structural boxes. Every screen should feel like a curated page, providing a sense of calm, reverence, and purposeful progress.

---

## 2. Colors & Surface Philosophy
The palette is rooted in earth tones and natural light. We use color not just for decoration, but to signify the "weight" of the content.

### The Color Palette (Material Tokens)
*   **Primary (`#94492c`):** Use for active states and brand moments.
*   **Secondary (`#3b665f`):** Use for steady, calming elements like progress tracking.
*   **Tertiary/Gold (`#735c00`):** Reserved exclusively for "Sacred Moments"—achievements, scripture mastery milestones, and premium features.
*   **Surface (`#fff8f6`):** Our foundational "paper" color.

### The "No-Line" Rule
**Explicit Instruction:** Prohibit 1px solid borders for sectioning. Boundaries must be defined solely through background color shifts.
*   Instead of a line, place a `surface-container-low` section on a `surface` background.
*   To separate scripture from commentary, use a tonal shift, never a divider line.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—stacked sheets of fine, translucent paper.
*   **Base:** `surface`
*   **Sections:** `surface-container-low`
*   **Floating Cards:** `surface-container-lowest` (creates a "lifted" feel against a darker background)
*   **Interactive Elements:** Use `surface-bright` to draw the eye toward actionable components.

### The "Glass & Gradient" Rule
To avoid a "flat" appearance, use subtle gradients for Hero sections and primary CTAs. Transition from `primary` to `primary_container` at a 135-degree angle. For floating navigation or overlays, apply **Glassmorphism**: use a semi-transparent surface color with a `20px` backdrop-blur to allow the warmth of the background colors to bleed through.

---

## 3. Typography: Editorial Authority
We pair the timeless authority of `Merriweather` (Scriptural) with the modern clarity of `Inter` (Functional).

*   **Display & Headlines (Merriweather):** These are your "Scriptural" voices. They should be large, with generous leading. Use `headline-lg` for verse numbers and key doctrine to give them weight.
*   **Titles & Body (Inter):** These are the "Guide" voices. They provide instructions and context.
*   **Intentional Asymmetry:** Don't center-align everything. Use left-aligned display text with wide right margins to create an editorial, "un-templated" look.

---

## 4. Elevation & Depth
In this system, depth is "felt" through light and shadow, not "seen" through lines.

### The Layering Principle
Achieve hierarchy by stacking tiers. Place a `surface-container-lowest` card on a `surface-container-low` section. This creates a soft, natural lift that feels organic rather than digital.

### Ambient Shadows
Shadows must be "Ambient," mimicking natural sunlight.
*   **Soft Lift:** `0px 4px 20px rgba(34, 26, 23, 0.06)`
*   **Floating State:** `0px 12px 40px rgba(34, 26, 23, 0.04)`
*   Shadows should use a tint of the `on-surface` color, never pure black.

### The "Ghost Border" Fallback
If a border is required for accessibility, it must be a **Ghost Border**: use the `outline-variant` token at **15% opacity**.

---

## 5. Components

### Cards & Containers
*   **Rule:** Forbid divider lines.
*   **Style:** Use the `lg` (2rem) or `xl` (3rem) corner radius. Cards should feel like smooth stones.
*   **Layout:** Use vertical white space (32px+) to separate content within cards.

### Buttons (The "Soulful" Button)
*   **Primary:** A subtle gradient from `primary` to `primary_container`. No border. Rounded `full`.
*   **Secondary:** `surface-container-high` background with `on-secondary-container` text.
*   **Tertiary:** Text-only with an underline that appears only on hover.

### Progress & Achievements
*   **Scripture Mastery Chips:** Use `secondary_container` for steady progress.
*   **Gold Accents:** Use the `tertiary` (Gold) token for "Scripture Mastery" streaks. Apply a subtle outer glow rather than a drop shadow to gold elements.

### Input Fields
*   **Style:** Minimalist. No bottom line. Use a `surface-container-low` fill with a `md` (1.5rem) radius.
*   **Focus State:** Shift background to `surface-container-lowest` and apply a Ghost Border of the `primary` color.

---

## 6. Do’s and Don'ts

### Do:
*   **Do** use extreme whitespace. If you think there is enough space, add 8px more.
*   **Do** use overlapping elements (e.g., a floating badge overlapping the edge of a card) to break the "grid" feel.
*   **Do** use `Merriweather` for anything that is a direct quote from scripture.
*   **Do** use "High-Contrast Scale": Pair a `display-lg` headline with a `label-md` caption for a high-end feel.

### Don’t:
*   **Don’t** use pure black `#000000`. Use `on-surface` for all "black" text.
*   **Don’t** use 1px solid dividers. If you need a separator, use a 48px gap or a subtle background color change.
*   **Don’t** use "cartoonish" or "bubbly" icons. Use thin-stroke, elegant line icons (approx. 1.5pt weight).
*   **Don’t** crowd the edges. The content should "breathe" from the center of the screen.

## 7. Dark Mode Strategy
In Dark Mode, we do not use pure black. We shift to a "Deep Parchment" feel.
*   **Background:** Use a deep, desaturated version of the rust/orange (`#221a17`).
*   **Surfaces:** Instead of shadows, use "Luminance Layering"—inner containers become *lighter* as they get closer to the user.
*   **Typography:** Soften the `on-surface` white to 90% opacity to reduce eye strain during evening study sessions.