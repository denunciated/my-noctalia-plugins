--!nonstrict

local snapshot = noctalia.state.get("github_snapshot") or {
  loading = true,
  issues = {}, reviewRequests = {}, myPullRequests = {}, notifications = {},
}
local selectedTab = 0
local selectedIssueLabel = nil
local tabs = { "Issues", "Reviews", "My PRs", "Notifications" }
local tabIcons = { "circle-dot", "code", "git-pull-request", "bell" }
local sectionKeys = { "issues", "reviewRequests", "myPullRequests", "notifications" }

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function labelName(label)
  if type(label) == "table" then return label.name or "" end
  if type(label) == "string" then return label end
  return ""
end

local function itemHasLabel(item, wanted)
  if wanted == nil then return true end
  for _, label in ipairs(item.labels or {}) do
    if labelName(label) == wanted then return true end
  end
  return false
end

local function issueLabels()
  local seen = {}
  local labels = {}
  for _, item in ipairs(snapshot.issues or {}) do
    for _, label in ipairs(item.labels or {}) do
      local name = labelName(label)
      if name ~= "" and not seen[name] then
        seen[name] = true
        table.insert(labels, name)
      end
    end
  end
  table.sort(labels, function(a, b) return string.lower(a) < string.lower(b) end)
  return labels
end

local function currentItems()
  if selectedTab == 0 then
    local filtered = {}
    for _, item in ipairs(snapshot.issues or {}) do
      if itemHasLabel(item, selectedIssueLabel) then table.insert(filtered, item) end
    end
    return filtered
  end
  if selectedTab == 1 then return snapshot.reviewRequests or {} end
  if selectedTab == 2 then return snapshot.myPullRequests or {} end
  return snapshot.notifications or {}
end

local function subtitle(item)
  local left = item.repo or ""
  if item.number and item.number ~= 0 then left = left .. " #" .. tostring(item.number) end
  local extra = item.reason or (item.isDraft and "Draft" or "")
  if extra ~= "" then left = left .. " · " .. extra end
  return left
end

local function openItem(item)
  if item.url == nil or item.url == "" then
    noctalia.notifyError("GitHub Dashboard", "This item has no browser URL.")
    return
  end
  noctalia.runAsync("xdg-open " .. shellQuote(item.url))
end

local function itemRow(item, index)
  local icon = "circle-dot"
  if item.kind == "review" then icon = "git-pull-request" end
  if item.kind == "pull" then icon = item.isDraft and "git-pull-request-draft" or "git-pull-request" end
  if item.kind == "notification" then icon = "bell" end

  return ui.column({
    key = (item.kind or "item") .. "-" .. tostring(item.id or item.number or index),
    gap = 5,
    padding = 11,
    radius = 10,
    fill = "surface_variant/0.45",
    onClick = function() openItem(item) end,
  }, {
    ui.row({ gap = 9, align = "center" }, {
      ui.glyph({ name = icon, size = 17, color = "primary" }),
      ui.label({ text = item.title or "Untitled", fontWeight = "medium", maxLines = 2, flexGrow = 1 }),
      ui.glyph({ name = "external-link", size = 14, color = "on_surface_variant" }),
    }),
    ui.label({ text = subtitle(item), fontSize = 12, color = "on_surface_variant", maxLines = 1 }),
  })
end

local function render()
  local body = {}
  local items = currentItems()
  local sectionError = (snapshot.sectionErrors or {})[sectionKeys[selectedTab + 1]]

  if snapshot.error ~= nil then
    table.insert(body, ui.column({ gap = 10, padding = 16, radius = 10, fill = "error_container" }, {
      ui.label({ text = "GitHub unavailable", fontWeight = "bold", color = "on_error_container" }),
      ui.label({ text = snapshot.error, color = "on_error_container", maxLines = 4 }),
      ui.button({ text = "Open terminal for login", glyph = "terminal-2", onClick = "onLogin", variant = "outline" }),
    }))
  elseif sectionError ~= nil and #items == 0 then
    table.insert(body, ui.column({ gap = 10, padding = 16, radius = 10, fill = "error_container" }, {
      ui.label({ text = tabs[selectedTab + 1] .. " unavailable", fontWeight = "bold", color = "on_error_container" }),
      ui.label({ text = sectionError, color = "on_error_container", maxLines = 4 }),
    }))
  elseif snapshot.loading and #items == 0 then
    table.insert(body, ui.column({ align = "center", gap = 10, padding = 28 }, {
      ui.glyph({ name = "loader-2", size = 26, color = "primary" }),
      ui.label({ text = "Loading GitHub data…", color = "on_surface_variant" }),
    }))
  elseif #items == 0 then
    table.insert(body, ui.column({ align = "center", gap = 10, padding = 28 }, {
      ui.glyph({ name = "circle-check", size = 28, color = "primary" }),
      ui.label({ text = "Nothing here", fontWeight = "bold" }),
      ui.label({ text = "This section currently has no matching GitHub items.", color = "on_surface_variant", textAlign = "center" }),
    }))
  else
    if sectionError ~= nil then
      table.insert(body, ui.label({
        text = "Could not refresh " .. string.lower(tabs[selectedTab + 1]) .. ". Showing previous results.",
        color = "error",
        fontSize = 12,
      }))
    end
    for index, item in ipairs(items) do table.insert(body, itemRow(item, index)) end
  end

  local tabButtons = {}
  local counts = {
    #(snapshot.issues or {}), #(snapshot.reviewRequests or {}),
    #(snapshot.myPullRequests or {}), #(snapshot.notifications or {}),
  }
  for i, label in ipairs(tabs) do
    local tabIndex = i - 1
    table.insert(tabButtons, ui.button({
      key = "tab-" .. tostring(tabIndex),
      glyph = tabIcons[i],
      text = label .. " " .. tostring(counts[i]),
      controlSize = "sm",
      selected = selectedTab == tabIndex,
      variant = selectedTab == tabIndex and "primary" or "ghost",
      onClick = function() selectedTab = tabIndex; render() end,
    }))
  end

  local fetched = snapshot.fetchedAt and snapshot.fetchedAt > 0
    and ("Updated " .. os.date("%H:%M", snapshot.fetchedAt)) or "Not updated yet"

  panel.render(ui.column({ flexGrow = 1, gap = 12 }, {
    ui.row({ align = "center", gap = 9 }, {
      ui.glyph({ name = "brand-github", size = 22 }),
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = "GitHub Dashboard", fontSize = 17, fontWeight = "bold" }),
        ui.label({ text = fetched, fontSize = 11, color = "on_surface_variant" }),
      }),
      ui.button({ glyph = "refresh", tooltip = "Refresh", onClick = "onRefresh", variant = "ghost" }),
      ui.button({ glyph = "close", tooltip = "Close", onClick = "onCloseClicked", variant = "ghost" }),
    }),
    ui.row({ gap = 4, align = "center" }, tabButtons),
    selectedTab == 0 and (function()
      local labels = issueLabels()
      local options = { "All labels" }
      local selectedIndex = 0

      for index, label in ipairs(labels) do
        table.insert(options, label)
        if selectedIssueLabel == label then selectedIndex = index end
      end

      return ui.row({ gap = 10, align = "center" }, {
        ui.label({ text = "Label", color = "on_surface_variant", fontWeight = "medium" }),
        ui.select({
          key = "issue-label-filter",
          options = options,
          selectedIndex = selectedIndex,
          controlSize = "sm",
          width = 240,
          onChange = function(index, _text)
            local value = tonumber(index) or 0
            selectedIssueLabel = value == 0 and nil or labels[value]
            render()
          end,
        }),
        ui.label({
          text = tostring(#items) .. " shown",
          color = "on_surface_variant",
          fontSize = 12,
          flexGrow = 1,
          textAlign = "right",
        }),
      })
    end)() or ui.column({}, {}),
    ui.separator({ spacing = 2 }),
    ui.scroll({ flexGrow = 1, gap = 8 }, body),
  }))
end

noctalia.state.watch("github_snapshot", function(value)
  snapshot = value or snapshot
  render()
end)

function onOpen(_context) render() end
function update() render() end
function onCloseClicked() panel.close() end
function onRefresh()
  noctalia.runAsync("noctalia msg plugin denunciated/github-dashboard:github-service all refresh")
end
function onLogin()
  noctalia.runInTerminal("gh auth login")
end
