--!nonstrict

local refreshing = false
local pending = 0
local snapshot = {
  authenticated = false,
  loading = true,
  error = nil,
  sectionErrors = {},
  fetchedAt = 0,
  issues = {},
  reviewRequests = {},
  myPullRequests = {},
  notifications = {},
}

local function publish()
  noctalia.state.set("github_snapshot", snapshot)
end

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function repoQualifier()
  local repositories = noctalia.getConfig("repositories") or {}
  local parts = {}
  for _, repo in ipairs(repositories) do
    local clean = noctalia.string.trim(repo)
    if clean ~= "" then
      table.insert(parts, "repo:" .. clean)
    end
  end
  if #parts == 0 then return "" end
  return " (" .. table.concat(parts, " OR ") .. ")"
end

local function decodeArray(raw)
  local value, err = noctalia.json.decode(raw or "")
  if value == nil then return nil, err or "Invalid JSON" end
  if type(value) ~= "table" then return nil, "Expected a JSON array" end
  return value, nil
end

local function normalizeSearch(items, kind)
  local out = {}
  for _, item in ipairs(items or {}) do
    local repo = ""
    if type(item.repository) == "table" then
      repo = item.repository.nameWithOwner or item.repository.name or ""
    elseif type(item.repository) == "string" then
      repo = item.repository
    end
    table.insert(out, {
      kind = kind,
      number = item.number or 0,
      title = item.title or "Untitled",
      url = item.url or "",
      repo = repo,
      updatedAt = item.updatedAt or "",
      state = item.state or "OPEN",
      isDraft = item.isDraft == true,
      author = type(item.author) == "table" and (item.author.login or "") or "",
      labels = item.labels or {},
    })
  end
  return out
end

local function normalizeNotifications(items)
  local out = {}
  for _, item in ipairs(items or {}) do
    local subject = item.subject or {}
    local repo = item.repository or {}
    local apiUrl = subject.latest_comment_url or subject.url or ""
    local htmlUrl = ""
    if apiUrl ~= "" then
      htmlUrl = apiUrl:gsub("https://api.github.com/repos/", "https://github.com/")
        :gsub("/issues/comments/%d+$", "")
        :gsub("/pulls/", "/pull/")
    end
    table.insert(out, {
      kind = "notification",
      id = item.id or "",
      title = subject.title or "GitHub notification",
      reason = item.reason or "",
      type = subject.type or "",
      repo = repo.full_name or "",
      url = htmlUrl,
      updatedAt = item.updated_at or "",
      unread = item.unread ~= false,
    })
  end
  return out
end

local function finishOne()
  pending -= 1
  if pending <= 0 then
    refreshing = false
    snapshot.loading = false
    snapshot.fetchedAt = os.time()
    publish()
  end
end

local function runJson(section, command, assign)
  pending += 1
  local accepted = noctalia.runAsync(command, function(result)
    if result.exitCode ~= 0 then
      snapshot.sectionErrors[section] = noctalia.string.trim(result.stderr or "GitHub command failed")
      finishOne()
      return
    end
    local decoded, err = decodeArray(result.stdout)
    if decoded == nil then
      snapshot.sectionErrors[section] = err
    else
      snapshot.sectionErrors[section] = nil
      assign(decoded)
    end
    finishOne()
  end)
  if not accepted then
    snapshot.sectionErrors[section] = "Noctalia could not start the GitHub command."
    finishOne()
  end
end

local function refresh()
  if refreshing then return end
  refreshing = true
  pending = 0
  snapshot.loading = true
  snapshot.error = nil
  snapshot.sectionErrors = {}
  publish()

  if not noctalia.commandExists("gh") then
    snapshot.loading = false
    snapshot.error = "GitHub CLI (gh) is not installed."
    refreshing = false
    publish()
    return
  end

  noctalia.runAsync("gh auth status", function(auth)
    if auth.exitCode ~= 0 then
      snapshot.authenticated = false
      snapshot.loading = false
      snapshot.error = "GitHub CLI is not authenticated. Run: gh auth login"
      refreshing = false
      publish()
      return
    end

    snapshot.authenticated = true
    local limit = math.max(5, math.min(100, tonumber(noctalia.getConfig("item_limit")) or 20))
    local qualifier = repoQualifier()
    local fields = "number,title,url,repository,labels,updatedAt,state,author"

    runJson("issues",
      "gh search issues assignee:@me state:open" .. qualifier ..
      " --limit " .. tostring(limit) .. " --json " .. fields,
      function(items) snapshot.issues = normalizeSearch(items, "issue") end
    )

    runJson("reviewRequests",
      "gh search prs review-requested:@me state:open" .. qualifier ..
      " --limit " .. tostring(limit) .. " --json " .. fields .. ",isDraft",
      function(items) snapshot.reviewRequests = normalizeSearch(items, "review") end
    )

    runJson("myPullRequests",
      "gh search prs author:@me state:open" .. qualifier ..
      " --limit " .. tostring(limit) .. " --json " .. fields .. ",isDraft",
      function(items) snapshot.myPullRequests = normalizeSearch(items, "pull") end
    )

    if noctalia.getConfig("show_notifications") == true then
      runJson("notifications",
        "gh api notifications --method GET --paginate -f per_page=" .. tostring(limit),
        function(items) snapshot.notifications = normalizeNotifications(items) end
      )
    else
      snapshot.notifications = {}
    end

    if pending == 0 then
      refreshing = false
      snapshot.loading = false
      snapshot.fetchedAt = os.time()
      publish()
    end
  end)
end

local function configureInterval()
  local minutes = math.max(1, math.min(60, tonumber(noctalia.getConfig("refresh_minutes")) or 5))
  noctalia.setUpdateInterval(minutes * 60 * 1000)
end

configureInterval()
refresh()

function update()
  refresh()
end

function onConfigChanged()
  configureInterval()
  refresh()
end

function onIpc(event, _payload)
  if event == "refresh" then refresh() end
end
