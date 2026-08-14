--!nonstrict

local snapshot = noctalia.state.get("github_snapshot") or {}

local function totalCount()
  return #(snapshot.issues or {}) + #(snapshot.reviewRequests or {}) + #(snapshot.notifications or {})
end

local function render()
  barWidget.setGlyph("brand-github")
  local showCount = noctalia.getConfig("show_count") == true
  if snapshot.loading then
    barWidget.setText(showCount and "" or "")
    barWidget.setTooltip("Refreshing GitHub dashboard")
  elseif snapshot.error ~= nil then
    barWidget.setText(showCount and "!" or "")
    barWidget.setTooltip(snapshot.error)
  else
    local count = totalCount()
    barWidget.setText(showCount and tostring(count) or "")
    barWidget.setTooltip(string.format(
      "%d issues · %d reviews · %d notifications",
      #(snapshot.issues or {}),
      #(snapshot.reviewRequests or {}),
      #(snapshot.notifications or {})
    ))
  end
end

noctalia.state.watch("github_snapshot", function(value)
  snapshot = value or {}
  render()
end)

function update()
  noctalia.setUpdateInterval(60000)
  render()
end

function onRightClick()
  noctalia.runAsync("noctalia msg plugin denunciated/github-dashboard:github-service all refresh")
end


function onClick()
  noctalia.runAsync("noctalia msg panel-toggle denunciated/github-dashboard:dashboard")
end
