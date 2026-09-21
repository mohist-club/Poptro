# Poptro 1.4.1 Safari-Style Settings Design QA

## Scope

- Primary reference: the current macOS Safari Settings window (General and Websites panes)
- Implementation surfaces: General and Translation Services at the minimum supported window size
- Tested build: Poptro 1.4.1 (build 10)
- Packaging policy: local compile and UI verification only; GitHub Actions produces release DMG/ZIP

## Environment

- Native macOS SwiftUI/AppKit application
- Settings default size: 900 × 620 pt
- Settings minimum size: 836 × 560 pt, matching Safari's compact preference-window scale
- Appearance: system/light during primary comparison
- Verification date: 2026-09-21

## Comparison

| Area | Result | Notes |
| --- | --- | --- |
| Top navigation | Passed | Native SwiftUI `TabView` tab items replace the hand-drawn toolbar, allowing macOS to supply Safari-equivalent selection and Liquid Glass styling. |
| General layout | Passed | Right-aligned 13 pt labels, compact 34 pt rows, native pop-up buttons and checkboxes, and grouped vertical whitespace match Safari General. |
| Typography | Passed | System semantic fonts are used throughout; headings, labels, help copy, and status text follow the native hierarchy. |
| Services layout | Passed | Native `HSplitView`, sidebar `List`, column `Form`, `LabeledContent`, `Picker`, `Menu`, and standard footer buttons match Safari Websites-style information architecture. |
| Service overflow | Passed | API fields use a bounded 300 pt control width and service details use a 520 pt content column at the minimum window size. |
| Advanced layout | Passed | Glass transparency and AI prompt use the same aligned preference grid and standard bordered text editor. |
| About layout | Passed | Compact 44 pt app icon, column form, native checkbox, buttons, and links replace the oversized grouped cards. |
| Light/dark adaptability | Passed | Semantic system colors are used; no hard-coded black text is present in the settings views. |
| Glass behavior | Passed | System `NSVisualEffectView` material is used when enabled; disabling glass restores the native solid window background. Transparency overlays only the background, not text or controls. |
| Window behavior | Passed | Resizable, minimum 836 × 560 pt, default 900 × 620 pt, with a transparent native title bar. |
| Accessibility | Passed | Native tabs, lists, forms, labels, checkboxes, menus, and keyboard navigation retain system accessibility behavior. |

## Intentional product-correct deviations

- Safari has product-specific panes and controls; Poptro keeps its own information architecture while using the same native component grammar, density, alignment, and material behavior.
- Poptro only shows the Accessibility permission it actually needs. Adding Safari-like but unused permission rows would be misleading.
- Native rendering intentionally follows the installed macOS version, so macOS 26/27 supplies its own Liquid Glass appearance without a simulated custom gradient.

## Functional verification

- `swift test`: 29 tests passed, 0 failures.
- Added rendering coverage for both General and Translation Services at 900 × 620 pt, with assertions for the 836 × 560 pt minimum.
- Apple Translation framework support and configured-provider migration tests passed.
- `git diff --check` passed.
- No local installer was generated; release packaging remains delegated to GitHub Actions.

## QA history

1. Replaced the custom icon toolbar with a native settings `TabView`.
2. Removed card-heavy preference layouts and matched Safari's compact label/control grid.
3. Rebuilt Translation Services with native split view, sidebar list, column form, and footer controls.
4. Shortened long Apple service explanations and bounded the form column to prevent minimum-width overflow.
5. Reworked Advanced and About into compact native forms.
6. Connected settings appearance, glass enablement, and transparency to the settings window background itself.
7. Added rendering regression coverage and ran the complete test suite.

final result: passed
