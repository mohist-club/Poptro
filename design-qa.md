# Poptro 1.5.0 Settings Design QA

## Scope

- Visual source of truth: `/var/folders/t7/c_5qt52s0_1df6sq472d197h0000gn/T/codex-clipboard-08f89b1c-3204-41cb-b154-9787226c78c0.png`
- Toolbar comparison: `/private/tmp/poptro-toolbar-comparison.png`
- Rendered General: `/private/tmp/poptro-1.5.0-general.png`
- Rendered Shortcuts: `/private/tmp/poptro-1.5.0-shortcuts-v2.png`
- Rendered Services: `/private/tmp/poptro-1.5.0-services.png`
- Rendered Appearance: `/private/tmp/poptro-1.5.0-appearance.png`
- Tested build: Poptro 1.5.0 (build 12)
- Packaging policy: compile and UI verification locally; GitHub Actions produces release DMG/ZIP

## Visual review

| Area | Result | Notes |
| --- | --- | --- |
| Settings toolbar | Passed | Retains the approved Safari geometry: 63 pt bar, 56 × 49 pt selected tile, 22 pt monochrome symbols, 11 pt labels, native accent selection and system-gray inactive state. |
| General alignment | Passed | All labels share the same 220 pt right-aligned column and all controls begin on one vertical axis. Permission status, Recheck and System Settings actions form a single aligned row. |
| Appearance organization | Passed | The former Advanced destination is now Appearance. Theme, glass enablement and transparency are grouped in the same aligned preference grid. |
| Services layout | Passed | Uses native split view, sidebar list, column Form, LabeledContent, Picker, DisclosureGroup and standard footer controls. The AI prompt moved into the service form and remains width-bounded. |
| Shortcut layout | Passed | Uses native List sections and one shared row geometry for applications, Shortcuts workflows, system actions and scripts. Recorder, enable checkbox and remove button occupy fixed aligned columns. |
| Add-action sheets | Passed | Application, Shortcuts, system action and script sheets use native lists/forms, standard headers and trailing action buttons. Script source is displayed with a monospaced editor. |
| Typography and color | Passed | System semantic fonts and colors only; light/dark appearance remains automatic and no hard-coded black body text was introduced. |
| Glass behavior | Passed | Native `NSVisualEffectView` material remains version-adaptive. The transparency overlay affects only the background, not text or controls. |
| Resizing and overflow | Passed | Minimum size remains 836 × 560 pt. API fields, model controls and prompt editor are bounded within the Services detail column. |

## Functional and safety review

- Apple Translation UI, services, bridge code and tests were removed.
- Legacy `apple` provider values migrate to Zhipu without resetting language, prompt, model or appearance settings.
- Legacy Apple and Zhipu benchmark entries are de-duplicated during migration instead of crashing the Settings view.
- Existing application shortcut JSON decodes as the new application action type without user intervention.
- Shortcuts workflows are invoked with `/usr/bin/shortcuts run` using an argument array.
- Shell, AppleScript and JXA payloads are only created from explicit user input and are not interpolated into executable paths.
- Empty Trash, Log Out, Restart and Shut Down always require confirmation; Lock Screen and Sleep do not.
- Accessibility status is re-read only when the user presses Recheck or revisits General; the check does not trigger another permission prompt.

## Verification

- `swift test`: 33 tests passed, 0 failures.
- Settings rendering coverage now includes General, Shortcuts, Services and Appearance at 900 × 620 pt.
- `git diff --check`: passed.
- No local installer was generated.

## Intentional deviations

- Poptro exposes five real settings destinations rather than copying Safari's product-specific pane count.
- Settings are centered in the content region because the source Safari toolbar group is centered.
- SwiftUI `List` rows are virtualized when rendered by an unattached test hosting view; structural row alignment is therefore covered by shared row code and compile tests, while the screenshot validates the native toolbar, section and footer geometry.

final result: passed
