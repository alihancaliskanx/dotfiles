#!/usr/bin/env bash
#
# fixes/fix-key-visualizer-turkish.sh
# ------------------------------------------------------------------------------
# Fixes omarchy-key-visualizer to automatically detect active keyboard layout
# (Turkish TR-Q / TR-F / US) and render accurate Turkish characters and UTF-8 keycaps.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'

echo -e "${INFO} Applying Turkish Keyboard Layout support to Key Visualizer..."

PLUGIN_DIR="$HOME/.config/omarchy/plugins/felixzsh.key-visualizer"
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo -e "${INFO} Plugin directory not found at $PLUGIN_DIR, skipping."
  exit 0
fi

cp "$PLUGIN_DIR/key-visualizer.lua" "$PLUGIN_DIR/key-visualizer.lua.bak" 2>/dev/null || true

cat << 'LUA' > "$PLUGIN_DIR/key-visualizer.lua"
-- Key Visualizer for Omarchy — shows the keys you press on screen.
--
-- Enhanced with robust file-based Layout Detection & full Turkish (TR-Q / TR-F) keyboard support.

local function shell_quote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

local function effective_uid()
  local f = io.open("/proc/self/status", "r")
  if not f then return nil end
  for line in f:lines() do
    local uid = line:match("^Uid:%s+%d+%s+(%d+)")
    if uid then
      f:close()
      return uid
    end
  end
  f:close()
  return nil
end

local function is_runtime_secure(r)
  if not r or r == "" then return false end
  if r == "/tmp" then return false end
  if r:sub(1, 1) ~= "/" then return false end
  local uid = effective_uid()
  return uid ~= nil and r == "/run/user/" .. uid
end

local runtime = os.getenv("XDG_RUNTIME_DIR")
if not is_runtime_secure(runtime) then
  if runtime and runtime ~= "" then
    print("[key-visualizer] insecure XDG_RUNTIME_DIR, disabling capture: " .. tostring(runtime))
  else
    print("[key-visualizer] XDG_RUNTIME_DIR not set, disabling capture")
  end
  runtime = nil
end
local STATE_FILE = runtime and (runtime .. "/omarchy-key-visualizer.json") or nil
local SUPER_FLAG = runtime and (runtime .. "/omarchy-key-visualizer-super") or nil

local function secure_write(path, content)
  if not runtime or (path ~= STATE_FILE and path ~= SUPER_FLAG) then return false end
  local f = io.open(path, "w")
  if not f then return false end
  f:write(content)
  f:close()
  os.execute("chmod 600 " .. shell_quote(path) .. " 2>/dev/null")
  return true
end

local MODS = {
  [50] = "Shift",  [62] = "Shift",
  [37] = "Ctrl",   [105] = "Ctrl",
  [64] = "Alt",    [108] = "Alt",
  [133] = "Super", [134] = "Super",
  [135] = "Menu",
  [109] = "AltGr",
}

local MOD_ORDER = { "Super", "Ctrl", "Alt", "Shift", "Menu", "AltGr" }

local KEYS = {
  [9] = "Esc", [22] = "Backspace", [23] = "Tab", [36] = "Enter", [66] = "Caps",
  [67] = "F1", [68] = "F2", [69] = "F3", [70] = "F4", [71] = "F5", [72] = "F6",
  [73] = "F7", [74] = "F8", [75] = "F9", [76] = "F10", [95] = "F11", [96] = "F12",
  [107] = "Print", [78] = "Scroll", [127] = "Pause",
  [118] = "Ins", [110] = "Home", [112] = "PgUp", [119] = "Del", [115] = "End", [117] = "PgDn",
  [111] = "Up", [113] = "Left", [116] = "Down", [114] = "Right",
  [65] = "Space",
  [77] = "Num", [106] = "KP/", [63] = "KP*", [82] = "KP-", [86] = "KP+",
  [104] = "KP Enter", [125] = "KP=",
  [79] = "KP7", [80] = "KP8", [81] = "KP9", [83] = "KP4", [84] = "KP5", [85] = "KP6",
  [87] = "KP1", [88] = "KP2", [89] = "KP3", [90] = "KP0", [91] = "KP.",
  [121] = "Mute", [122] = "Vol-", [123] = "Vol+",
}

local UTF8_UPPER = {
  ["a"] = "A", ["b"] = "B", ["c"] = "C", ["ç"] = "Ç", ["d"] = "D",
  ["e"] = "E", ["f"] = "F", ["g"] = "G", ["ğ"] = "Ğ", ["h"] = "H",
  ["ı"] = "I", ["i"] = "İ", ["j"] = "J", ["k"] = "K", ["l"] = "L",
  ["m"] = "M", ["n"] = "N", ["o"] = "O", ["ö"] = "Ö", ["p"] = "P",
  ["q"] = "Q", ["r"] = "R", ["s"] = "S", ["ş"] = "Ş", ["t"] = "T",
  ["u"] = "U", ["ü"] = "Ü", ["v"] = "V", ["w"] = "W", ["x"] = "X",
  ["y"] = "Y", ["z"] = "Z",
  ["é"] = "É",
}

local function to_upper_utf8(str)
  if not str then return nil end
  return UTF8_UPPER[str] or string.upper(str)
end

local LAYOUT_US = {
  CHARS = {
    [10] = "1", [11] = "2", [12] = "3", [13] = "4", [14] = "5", [15] = "6",
    [16] = "7", [17] = "8", [18] = "9", [19] = "0", [20] = "-", [21] = "=",
    [24] = "q", [25] = "w", [26] = "e", [27] = "r", [28] = "t", [29] = "y",
    [30] = "u", [31] = "i", [32] = "o", [33] = "p", [34] = "[", [35] = "]",
    [38] = "a", [39] = "s", [40] = "d", [41] = "f", [42] = "g", [43] = "h",
    [44] = "j", [45] = "k", [46] = "l", [47] = ";", [48] = "'", [49] = "`",
    [51] = "\\", [94] = "\\",
    [52] = "z", [53] = "x", [54] = "c", [55] = "v", [56] = "b", [57] = "n",
    [58] = "m", [59] = ",", [60] = ".", [61] = "/",
  },
  SHIFTED = {
    [10] = "!", [11] = "@", [12] = "#", [13] = "$", [14] = "%", [15] = "^",
    [16] = "&", [17] = "*", [18] = "(", [19] = ")", [20] = "_", [21] = "+",
    [34] = "{", [35] = "}", [47] = ":", [48] = '"', [49] = "~",
    [51] = "|", [94] = "|",
    [59] = "<", [60] = ">", [61] = "?",
  },
}

local LAYOUT_TR_Q = {
  CHARS = {
    [10] = "1", [11] = "2", [12] = "3", [13] = "4", [14] = "5", [15] = "6",
    [16] = "7", [17] = "8", [18] = "9", [19] = "0", [20] = "*", [21] = "-",
    [49] = '"',
    [24] = "q", [25] = "w", [26] = "e", [27] = "r", [28] = "t", [29] = "y",
    [30] = "u", [31] = "ı", [32] = "o", [33] = "p", [34] = "ğ", [35] = "ü",
    [38] = "a", [39] = "s", [40] = "d", [41] = "f", [42] = "g", [43] = "h",
    [44] = "j", [45] = "k", [46] = "l", [47] = "ş", [48] = "i", [51] = ",",
    [94] = "<",
    [52] = "z", [53] = "x", [54] = "c", [55] = "v", [56] = "b", [57] = "n",
    [58] = "m", [59] = "ö", [60] = "ç", [61] = ".",
  },
  SHIFTED = {
    [10] = "!", [11] = "'", [12] = "^", [13] = "+", [14] = "%", [15] = "&",
    [16] = "/", [17] = "(", [18] = ")", [19] = "=", [20] = "?", [21] = "_",
    [49] = "é",
    [34] = "Ğ", [35] = "Ü", [47] = "Ş", [48] = "İ", [51] = ";",
    [94] = ">",
    [59] = "Ö", [60] = "Ç", [61] = ":",
  },
}

local LAYOUT_TR_F = {
  CHARS = {
    [10] = "1", [11] = "2", [12] = "3", [13] = "4", [14] = "5", [15] = "6",
    [16] = "7", [17] = "8", [18] = "9", [19] = "0", [20] = "/", [21] = "-",
    [49] = "+",
    [24] = "f", [25] = "g", [26] = "ğ", [27] = "ı", [28] = "o", [29] = "d",
    [30] = "r", [31] = "n", [32] = "h", [33] = "p", [34] = "q", [35] = "w",
    [38] = "u", [39] = "i", [40] = "e", [41] = "a", [42] = "ü", [43] = "t",
    [44] = "k", [45] = "m", [46] = "l", [47] = "y", [48] = "ş", [51] = "x",
    [94] = "<",
    [52] = "j", [53] = "ö", [54] = "v", [55] = "c", [56] = "ç", [57] = "z",
    [58] = "s", [59] = "b", [60] = ".", [61] = ",",
  },
  SHIFTED = {
    [10] = "!", [11] = '"', [12] = "^", [13] = "$", [14] = "%", [15] = "&",
    [16] = "'", [17] = "(", [18] = ")", [19] = "=", [20] = "?", [21] = "_",
    [26] = "Ğ", [34] = "Q", [35] = "W",
    [42] = "Ü", [48] = "Ş", [51] = "X",
    [94] = ">",
    [53] = "Ö", [56] = "Ç", [60] = ":", [61] = ";",
  },
}

local function detect_active_layout()
  local home = os.getenv("HOME") or ""

  local f1 = io.open(home .. "/.config/hypr/input.lua", "r")
  if f1 then
    local content = f1:read("*a") or ""
    f1:close()
    local kb = content:match("kb_layout%s*=%s*[\x22\x27]([^\x22\x27]+)[\x22\x27]")
    if kb and kb ~= "" then
      local k = kb:lower()
      if k:find("tr") or k:find("turkish") then
        if k:find("f") and not k:find("q") then return LAYOUT_TR_F end
        return LAYOUT_TR_Q
      end
      if k:find("us") then return LAYOUT_US end
    end
  end

  local f2 = io.open("/etc/vconsole.conf", "r")
  if f2 then
    for line in f2:lines() do
      local k = line:match("^XKBLAYOUT=[\x22\x27]?([^\x22\x27\r\n]+)") or line:match("^KEYMAP=[\x22\x27]?([^\x22\x27\r\n]+)")
      if k and k ~= "" then
        f2:close()
        local kl = k:lower()
        if kl:find("tr") or kl:find("turkish") then
          if kl:find("f") and not kl:find("q") then return LAYOUT_TR_F end
          return LAYOUT_TR_Q
        end
        break
      end
    end
    f2:close()
  end

  local env_layout = os.getenv("XKB_DEFAULT_LAYOUT")
  if env_layout and env_layout ~= "" then
    local el = env_layout:lower()
    if el:find("tr") or el:find("turkish") then
      if el:find("f") and not el:find("q") then return LAYOUT_TR_F end
      return LAYOUT_TR_Q
    end
  end

  return LAYOUT_TR_Q
end

local ACTIVE_LAYOUT = detect_active_layout()

local pressed = {}
local combo = {}

local function shift_down()
  return pressed[50] or pressed[62]
end

local function non_shift_mods_down()
  local seen = {}
  for kc, down in pairs(pressed) do
    local name = MODS[kc]
    if down and name and name ~= "Shift" then seen[name] = true end
  end
  local out = {}
  for _, name in ipairs(MOD_ORDER) do
    if seen[name] then out[#out + 1] = name end
  end
  return out
end

local function any_printable()
  for _, kc in ipairs(combo) do
    if ACTIVE_LAYOUT.CHARS[kc] then return true end
  end
  return false
end

local function key_label(kc, binding)
  local label = KEYS[kc]
  if label then return label end
  local ch = ACTIVE_LAYOUT.CHARS[kc]
  if not ch then return nil end
  if binding then return to_upper_utf8(ch) end
  if shift_down() then
    return ACTIVE_LAYOUT.SHIFTED[kc] or to_upper_utf8(ch)
  end
  return ch
end

local function labels()
  local parts = {}
  local ns = non_shift_mods_down()
  for _, m in ipairs(ns) do parts[#parts + 1] = m end
  local binding = #ns > 0
  if shift_down() and (binding or not any_printable()) then
    parts[#parts + 1] = "Shift"
  end
  for _, kc in ipairs(combo) do
    local label = key_label(kc, binding)
    if label then parts[#parts + 1] = label end
  end
  return parts
end

local last_payload = ""
local function emit()
  if not STATE_FILE then return end
  local parts = labels()
  local payload = '{"keys":['
  if #parts > 0 then
    payload = payload .. '"' .. table.concat(parts, '","') .. '"'
  end
  payload = payload .. '],"t":' .. os.time() .. '}'
  if payload == last_payload then return end
  last_payload = payload
  secure_write(STATE_FILE, payload)
end

local last_super = nil
local function super_down()
  return pressed[133] or pressed[134]
end
local function emit_super()
  if not SUPER_FLAG then return end
  local down = super_down()
  if down == last_super then return end
  last_super = down
  secure_write(SUPER_FLAG, down and "1" or "0")
end

emit()
emit_super()

hl.on("input.keyboard.key", function(keycode, timeMs, state)
  if state == 2 then return end

  if state == 1 then
    pressed[keycode] = true
    if not MODS[keycode] then
      local found = false
      for _, kc in ipairs(combo) do
        if kc == keycode then found = true break end
      end
      if not found then combo[#combo + 1] = keycode end
    end
    emit_super()
    emit()
  else
    pressed[keycode] = false
    emit_super()
    if not MODS[keycode] then
      for i, kc in ipairs(combo) do
        if kc == keycode then
          table.remove(combo, i)
          break
        end
      end
    end
    local any_down = false
    for _, down in pairs(pressed) do
      if down then any_down = true break end
    end
    if not any_down then emit() end
  end
end)
LUA

echo -e "${SUCCESS} Turkish keyboard layout support applied to Key Visualizer!"
