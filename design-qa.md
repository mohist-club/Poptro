# Poptro 1.4.0 Settings Design QA

## Scope

- Reference: `design-reference-settings-general.png`
- Implementation: `design-qa-settings-general.png`
- Side-by-side evidence: `design-qa-comparison.png`
- Apple service evidence: `design-qa-settings-apple-service.png`
- Advanced settings evidence: `design-qa-settings-advanced.png`
- Tested build: Poptro 1.4.0 (build 9), installed at `/Applications/Poptro.app`

## Environment

- Native macOS SwiftUI/AppKit application
- Settings content size: 1200 × 800 pt
- Captured implementation image: 2492 × 1692 px including the native window shadow
- Appearance: system/light during primary comparison
- Verification date: 2026-09-21

## Comparison

| Area | Result | Notes |
| --- | --- | --- |
| Top navigation | Passed | Five large-icon destinations, restrained blue selection tile, monochrome inactive states. |
| General layout | Passed | Flat two-column rows, native controls, full-width dividers, compact supporting copy. |
| Typography | Passed | System type hierarchy and native control sizing remain legible at the minimum window size. |
| Services layout | Passed | Fixed add-service action, configured-provider list, split detail view, stable footer actions. |
| Advanced layout | Passed | Glass intensity and AI prompt moved out of provider configuration into a dedicated page. |
| Light/dark adaptability | Passed | Semantic system colors are used; no hard-coded black text is present in the settings views. |
| Window behavior | Passed | Resizable, minimum 1080 × 700 pt, default 1200 × 800 pt. |
| Accessibility | Passed | Toolbar items expose labels and selected state; controls use native keyboard navigation. |

## Intentional product-correct deviations

- The reference mock shows Accessibility, Screen Recording, and Input Monitoring. Poptro only requires Accessibility for selected-text access and hotkeys, so the implementation shows only that real permission. Adding unused permission rows would mislead users and create unnecessary privacy concern.
- The actual saved shortcut and configured default service are shown instead of hard-coded mock data.
- Native system control rendering follows the installed macOS version rather than reproducing pixels from the static mock.

## Functional verification

- `swift test`: 27 tests passed, 0 failures.
- Apple Translation framework support and configured-provider migration tests passed.
- Low-latency and high-fidelity Apple translations were exercised with installed on-device models before the UI merge.
- Apple service configuration visibly exposes both modes and explains availability requirements.
- Release app, DMG, and ZIP built successfully.

## QA history

1. Initial implementation exposed all navigation items but the toolbar overlapped the title bar.
2. Added native title-bar clearance and re-captured the complete icon row.
3. Unified SwiftUI Settings-scene and AppDelegate window sizing to eliminate the restored 900 pt legacy window.
4. Rebuilt, installed at the canonical `/Applications/Poptro.app` path, and captured final General, Apple service, and Advanced pages.

final result: passed
