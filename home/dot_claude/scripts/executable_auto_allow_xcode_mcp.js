#!/usr/bin/env osascript -l JavaScript

// Auto-clicks "Allow" on Xcode's "Allow <agent> to access Xcode?" prompts.
//
// The prompt is a floating dialog window whose title text, checkbox and buttons
// are nested several groups deep, so inspecting only a window's direct children
// (staticTexts()/buttons()) finds nothing. Instead we flatten the dialog's whole
// subtree with entireContents() and search it. To stay fast we only deep-scan
// dialog-style windows (never Xcode's enormous main editor window).

const PROMPT_MARKER = 'to access Xcode'
const DIALOG_SUBROLES = [
  'AXDialog',
  'AXSystemDialog',
  'AXFloatingWindow',
  'AXSystemFloatingWindow',
]

// Read whatever human-readable label an element exposes.
function textOf(el) {
  for (const getter of ['value', 'title', 'description', 'name']) {
    try {
      const v = el[getter]()
      if (typeof v === 'string' && v) return v
    } catch (e) {}
  }
  return ''
}

function roleOf(el) {
  try {
    return el.role()
  } catch (e) {
    return ''
  }
}

function run() {
  const systemEvents = Application('System Events')

  let processes
  try {
    processes = systemEvents.applicationProcesses()
  } catch (e) {
    return 'Error listing processes: ' + e.message
  }

  let approvedCount = 0

  for (const proc of processes) {
    let windows
    try {
      windows = proc.windows()
    } catch (e) {
      continue
    }

    for (const window of windows) {
      // Cheap check first: only flatten windows that look like dialogs.
      let subrole = ''
      try {
        subrole = window.subrole()
      } catch (e) {}
      if (DIALOG_SUBROLES.indexOf(subrole) === -1) continue

      let elements
      try {
        elements = window.entireContents()
      } catch (e) {
        continue
      }

      // Is this our access prompt?
      let isPrompt = false
      for (const el of elements) {
        if (textOf(el).includes(PROMPT_MARKER)) {
          isPrompt = true
          break
        }
      }
      if (!isPrompt) continue

      // Tick "Don't ask again for this agent binary until Xcode restarts" so
      // the same binary stops re-prompting for the rest of the session.
      for (const el of elements) {
        if (roleOf(el) !== 'AXCheckBox') continue
        try {
          if (el.value() === 0) el.click()
        } catch (e) {}
        break
      }

      // Click "Allow".
      for (const el of elements) {
        if (roleOf(el) !== 'AXButton') continue
        if (textOf(el) === 'Allow') {
          try {
            el.click()
            approvedCount++
          } catch (e) {}
          break
        }
      }
    }
  }

  return approvedCount > 0
    ? `Approved ${approvedCount} Xcode access prompt(s)`
    : 'No pending Xcode access prompts'
}
