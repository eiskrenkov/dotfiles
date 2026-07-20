-- Hammerspoon config.
--
-- Claude Code attention notifications: the Notification hook
-- (~/.claude/hooks/notify.sh) opens a URL like
--   hammerspoon://claude-notify?session=<name>&pane=<%id>&message=<text>
-- and this handler shows a native notification tagged with the tmux session.
-- Clicking it switches tmux to the exact pane and raises Ghostty.
--
-- The notice is also withdrawn when you reach the pane *without* clicking it: a
-- tmux pane-focus-in hook opens hammerspoon://claude-clear?pane=<%id> whenever a
-- pane gains focus (see ~/.config/tmux/scripts/claude-notify-clear.sh), so
-- navigating to the pane in tmux dismisses its notification too.

local TMUX = "/opt/homebrew/bin/tmux"

-- Single-quote a value for safe embedding in a /bin/sh command.
local function shq(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Focus a tmux pane by id: point the attached client at its session, select the
-- window and the pane (a pane id resolves its own window/session), then raise
-- Ghostty. Absolute tmux path since hs.execute runs with a minimal environment.
local function focusPane(session, pane)
  if pane and pane ~= "" then
    hs.execute(string.format(
      "%s switch-client -t %s; %s select-window -t %s; %s select-pane -t %s",
      TMUX, shq(session), TMUX, shq(pane), TMUX, shq(pane)), false)
  end
  hs.application.launchOrFocus("Ghostty")
end

-- Pending attention notifications, keyed by tmux pane id (e.g. "%5"), so a later
-- claude-clear (fired when the pane gains focus in tmux) can withdraw the exact
-- notice that pane raised. Keying by pane also collapses repeats: a new notice
-- for a pane withdraws the previous one first, so a pane never stacks duplicates.
local pending = {}

-- Withdraw and forget any pending notice for a pane (no-op if there is none).
local function clearPane(pane)
  if pane and pending[pane] then
    pending[pane]:withdraw()
    pending[pane] = nil
  end
end

-- URL handler: hammerspoon://claude-notify?session=..&pane=..&message=..
-- Hammerspoon URL-decodes the query params into `params`.
hs.urlevent.bind("claude-notify", function(_, params)
  local session = params.session or "tmux"
  local pane = params.pane or ""
  local message = params.message or "needs your attention"

  clearPane(pane) -- replace any notice this pane already has pending

  local n = hs.notify.new(function()
    clearPane(pane)
    focusPane(session, pane)
  end, {
    title = "Claude Code",
    subTitle = session,
    informativeText = message,
    withdrawAfter = 0, -- stay in Notification Center until clicked or dismissed
  })
  if pane ~= "" then pending[pane] = n end
  n:send()
end)

-- URL handler: hammerspoon://claude-clear?pane=..
-- Fired by the tmux pane-focus-in hook: reaching the pane in tmux withdraws its
-- pending notice, so you don't have to click the notification to clear it.
hs.urlevent.bind("claude-clear", function(_, params)
  clearPane(params.pane or "")
end)

-- Auto-reload this config when any .lua file under ~/.hammerspoon changes.
hs.pathwatcher.new(hs.configdir, function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

hs.notify.new({ title = "Hammerspoon", informativeText = "Config loaded" }):send()
