# Poptro 1.4.2 Safari Toolbar Design QA

## Scope

- Source visual truth: `/var/folders/t7/c_5qt52s0_1df6sq472d197h0000gn/T/codex-clipboard-08f89b1c-3204-41cb-b154-9787226c78c0.png`
- Rendered implementation: `/private/tmp/poptro-1.4.2-toolbar-v2.png`
- Combined comparison: `/private/tmp/poptro-toolbar-comparison.png`
- Tested build: Poptro 1.4.2 (build 11)
- Packaging policy: local compile and UI verification only; GitHub Actions produces release DMG/ZIP

## Environment

- Native macOS SwiftUI/AppKit application
- Source image: 1570 × 158 px at Retina density; toolbar content is approximately 785 × 79 pt
- Implementation image: 1800 × 1240 px for a 900 × 620 pt view at 2× density
- Focused comparison: implementation center-cropped to 1570 × 158 px; no resampling
- Settings default size: 900 × 620 pt
- Settings minimum size: 836 × 560 pt, matching Safari's compact preference-window scale
- Appearance: system/light during primary comparison
- Verification date: 2026-09-21

## Comparison

| Area | Result | Notes |
| --- | --- | --- |
| Top navigation | Passed | Safari-style icon-above-label toolbar with the same 63 pt bar height, 56 × 49 pt selected tile, 56 pt item pitch, 22 pt symbol scale, 11 pt labels, 7 pt radius, system gray inactive state, and accent-color selected state. |
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

- Safari has thirteen product-specific panes; Poptro has five real settings destinations. The same item dimensions and spacing are retained, with the shorter group centered rather than stretched.
- Poptro only shows the Accessibility permission it actually needs. Adding Safari-like but unused permission rows would be misleading.
- Native rendering intentionally follows the installed macOS version, so macOS 26/27 supplies its own Liquid Glass appearance without a simulated custom gradient.

## Functional verification

- `swift test`: 29 tests passed, 0 failures after the toolbar replacement.
- Added rendering coverage for both General and Translation Services at 900 × 620 pt, with assertions for the 836 × 560 pt minimum.
- Apple Translation framework support and configured-provider migration tests passed.
- `git diff --check` passed.
- No local installer was generated; release packaging remains delegated to GitHub Actions.

## QA history

1. The 1.4.1 automatic `TabView` interpretation did not visually reproduce the supplied Safari toolbar and was classified as P1 drift.
2. Replaced it with the explicit icon-above-label preference toolbar shown in the source.
3. First pass used a 110 pt bar and 98 × 86 pt item, which was too large after Retina normalization.
4. Corrected the bar to 63 pt and the selected tile to 56 × 49 pt, matching the source's 126 px divider position and 112 px item pitch at 2× density.
5. Re-rendered the full General view and produced a same-density focused comparison; no P0/P1/P2 toolbar mismatch remains.

final result: passed
