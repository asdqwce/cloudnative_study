# Design System: MediKong Presentation

**Project ID:** image-derived-medikong-cloud-native-medical-platform

This design system was extracted from the provided slide screenshots. It describes the visual language of a minimalist Korean presentation for a cloud-native medical information platform.

## 1. Visual Theme & Atmosphere

The presentation uses a stark, editorial, monochrome style: generous white space, heavy black typography, restrained gray accents, and large geometric markers. The mood is professional, academic, technical, and intentionally quiet. Visual interest comes from scale, asymmetry, and spacing rather than color decoration.

The design should feel like a clean architecture review deck:

- Minimalist and high-contrast.
- Spacious, calm, and presentation-friendly.
- Technical, but not visually dense.
- Formal enough for a project defense or seminar.
- Korean-first typography with occasional English technical terms.

Avoid decorative gradients, colorful accents, rounded cards, glossy UI effects, and busy backgrounds. The purple outline visible in some screenshots appears to be an editor selection frame and should not be rendered as part of the final slide design.

## 2. Color Palette & Roles

| Role             | Color                 | Hex       | Usage                                                  |
| ---------------- | --------------------- | --------- | ------------------------------------------------------ |
| Canvas White     | White                 | `#FFFFFF` | Main slide background.                                 |
| Primary Ink      | Black                 | `#000000` | Main titles, body emphasis, circular section badges.   |
| Heading Gray     | Dark Gray             | `#555555` | Section titles and subdued headings.                   |
| Body Gray        | Medium Gray           | `#5B5B5B` | Body copy, bullet text, secondary labels.              |
| Structural Rail  | Light Gray            | `#D9D9D9` | Persistent vertical rail on the left edge.             |
| Divider Gray     | Soft Gray             | `#D6D6D6` | Horizontal band on closing slide and subtle structure. |
| Dotted Connector | Neutral Gray          | `#707070` | Dotted lines between content circles.                  |
| Diagram Blue     | Technical Blue        | `#356DBF` | Architecture diagram strokes and service boxes.        |
| Terminal Navy    | Deep Terminal Navy    | `#061B2D` | Code block background.                                 |
| Terminal Text    | Desaturated Blue Gray | `#8FA3B5` | Code block text and low-contrast syntax.               |
| Terminal Accent  | Muted Copper          | `#C36F4B` | YAML keys and syntax highlights.                       |

Use monochrome tokens as the default. Blue is reserved only for technical diagrams, and dark navy is reserved only for terminal/code screenshots.

## 3. Typography Rules

Use a Korean sans-serif family with strong Hangul rendering. Recommended stack:

```css
font-family: "Pretendard", "Noto Sans KR", "Apple SD Gothic Neo", sans-serif;
```

### Type Scale

| Token          |    Size |  Weight | Line Height | Usage                                          |
| -------------- | ------: | ------: | ----------: | ---------------------------------------------- |
| Cover Title    | 52-60px | 800-900 |        1.15 | Main cover title.                              |
| Cover Subtitle | 30-36px | 400-500 |        1.35 | Cover subtitle.                                |
| Slide Title    | 42-50px | 600-700 |         1.2 | Main slide heading.                            |
| Section Title  | 36-44px | 500-700 |        1.25 | Content slide section headings.                |
| English Title  | 56-64px | 400-500 |         1.1 | `CONTENT` and similar centered English titles. |
| Body Text      | 26-32px | 400-500 |    1.75-1.9 | Korean bullet text.                            |
| Badge Number   | 24-30px | 400-500 |         1.1 | Small number inside circular badges.           |
| Badge Label    | 22-30px | 600-800 |        1.25 | Label inside circular badges.                  |
| Code Text      | 18-22px |     600 |        1.45 | Code snippets in terminal panels.              |

### Typographic Behavior

- Use very bold weight for cover names and author names.
- Use medium weight for body text; avoid thin Korean body type.
- Keep letter spacing at `0`.
- Use black for primary titles and dark gray for content headings.
- Preserve mixed Korean-English terms inline, such as `MSA`, `Kubernetes`, `Service Mesh`, and `Rate Limiting`.
- Body bullets should have roomy line height and moderate paragraph gaps.

## 4. Component Stylings

### Slide Canvas

- Aspect ratio: 16:9.
- Reference size: 1600 x 900.
- Background: solid white.
- Keep a persistent vertical gray rail on the far left.
- The rail is approximately 50-64px wide on a 1600px slide.
- Main content begins after a large left margin, usually 95-130px from the slide edge.

### Left Structural Rail

- Position: fixed to the left edge, full slide height.
- Width: 50-64px.
- Color: `#D9D9D9`.
- No border, shadow, text, or icon.
- Treat it as a quiet brand/layout anchor.

### Circular Section Badge

- Shape: perfect circle.
- Fill: `#000000`.
- Text: white, centered.
- Typical size: 130-170px diameter.
- Placement:
  - Top-right on section/detail slides.
  - Center row on content overview slides.
- Internal hierarchy:
  - Small number on top.
  - Larger Korean label below.
- Avoid shadows and outlines.

### Content Overview Timeline

- Use four large black circles in a horizontal row.
- Connect circles with a dotted gray horizontal line.
- Dotted connector should visually pass behind or between circles.
- Circles use centered white labels.
- The section number sits above the label inside each circle.
- Place the `CONTENT` title centered above the row with large, light-weight English type.

### Bullet Lists

- Use native round bullets.
- Bullet text color: `#555555` to `#5B5B5B`.
- Body size: 26-32px.
- Line height: approximately 1.8.
- Keep bullets short and presentation-readable.
- Use wide left indentation so text aligns cleanly after the bullet marker.

### Two-Column Text Layout

- Use for background/problem-definition slides.
- Columns should be balanced horizontally with a large central gutter.
- Column headings use dark gray, bold or semibold text.
- Body bullets remain medium gray with generous line spacing.
- Avoid boxes or cards around columns.

### Architecture Diagram Panel

- Diagrams use white interiors with blue strokes.
- Stroke color: `#356DBF`.
- Use rounded rectangles only inside diagrams.
- Labels should use blue text and a technical diagram style.
- Keep diagrams visually separate through whitespace rather than card borders.

### Code Terminal Panel

- Use dark navy terminal windows with slight radius.
- Background: `#061B2D`.
- Code text: muted blue-gray with copper/orange syntax accents.
- Include small red, yellow, and green macOS window dots at top-left.
- Add soft, diffused shadow when the code panel is placed over a gray image/background.
- Keep code blocks as visual examples, not dense readable source dumps.

### Closing Image Treatment

- Use a light gray horizontal band across the upper slide.
- Place a grayscale architectural image in the upper-right area.
- Image should be rectangular, cleanly cropped, and not heavily stylized.
- Closing text is centered or slightly left of center, using large black Korean type.

## 5. Layout Principles

### Spacing

- Prefer large open areas and asymmetrical composition.
- Use whitespace as the primary layout device.
- Keep most slide content in the central-left or central-right zones, not flush to edges.
- Leave large quiet zones around titles and diagrams.

### Alignment

- Cover slide:
  - Title and subtitle align left near the upper-left quadrant.
  - Team and author text align right in the lower-right quadrant.
- Content overview:
  - Title centered horizontally.
  - Circle timeline centered across the slide.
- Detail slides:
  - Section badge lives in the upper-right corner.
  - Main title and body content align left.
- Diagram slides:
  - Diagram block on the left, explanatory text on the right.
- Closing slide:
  - Top gray band and upper-right image create structure.
  - Main thanks text sits around the visual center.

### Density

- Use one main idea per slide.
- Prefer 3-4 bullets per section.
- Use two columns only when comparing background and problem definition.
- Diagrams and code examples should occupy substantial space and remain visually legible.

## 6. Slide Patterns

### Cover Slide

- White canvas with left gray rail.
- Large bold Korean project title in the upper-left.
- Subtitle directly below in smaller regular-weight text.
- Brand or team name in gray near lower-right.
- Author names in bold black below the brand/team name.

### Table of Contents Slide

- Centered English title `CONTENT`.
- Four circular black markers arranged horizontally.
- Dotted gray connector line between markers.
- Each circle contains a section number and Korean label.

### Section Intro / Text Slide

- Upper-right circular badge shows section number and label.
- Large gray Korean heading on the left.
- Bullet list below with relaxed spacing.
- Keep the right half mostly open unless using a two-column pattern.

### Problem Definition Slide

- Large gray title on the left.
- Two content columns below:
  - Left column: background.
  - Right column: problem definition.
- Each column has a bold dark-gray subheading and 3 bullets.

### Architecture Detail Slide

- Upper-right circular badge uses subsection numbering, such as `4-1`.
- Left side contains architecture diagram.
- Right side contains large gray title and bullet explanation.
- Use black bullets for high-emphasis technical points.

### Code / Policy Slide

- Left side contains one or two terminal code panels.
- Right side contains a small architecture diagram image above a large topic title.
- Body bullets explain policy behavior in Korean.
- Use the circular badge in the upper-right.

### Closing Slide

- White canvas with left rail.
- Light gray band across the top.
- Grayscale architectural image placed in the upper-right.
- Large centered Korean thank-you message.

## 7. Generation Guidance for Stitch

When generating new screens or slides from this system, use the following design prompt:

```markdown
Create a minimalist Korean technical presentation slide for a cloud-native medical information platform. Use a stark editorial monochrome design with a white 16:9 canvas, a fixed light-gray vertical rail on the far left, large Korean sans-serif typography, generous whitespace, and black circular section badges. Keep the layout calm, spacious, and formal. Use dark gray for headings and body text, black for emphasis and badges, blue only for architecture diagrams, and dark navy only for terminal code panels. Avoid colorful decoration, gradient backgrounds, card-heavy UI, and unnecessary shadows.
```

## 8. Implementation Notes

- Render at 16:9, ideally 1600 x 900 or equivalent.
- Treat the left gray rail as a mandatory layout element.
- Do not render the purple frame from the screenshots unless explicitly showing an editor selection/debug state.
- Keep all Korean text readable at presentation distance.
- Use images and diagrams sparingly; they should support the technical explanation, not decorate the slide.
