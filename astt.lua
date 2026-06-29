if not game:IsLoaded() then
    game.Loaded:Wait()
end
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LobbyID = 71132543521245
local isLobby = (game.PlaceId == LobbyID)

local function get_cap_string(mode, world, act, item)
    return string.lower(mode .. " " .. world .. " " .. tostring(act) .. " " .. item):gsub(" ", "_")
end

local traitMaps = {}

if isLobby then
    local succ, Worlds = pcall(function() return require(Players.LocalPlayer.PlayerScripts.Client.Play.Worlds) end)
    if succ and Worlds then
        for worldId, world in pairs(Worlds) do
            if type(worldId) == "number" and world.Rewards then
                for mode, diffs in pairs(world.Rewards) do
                    if mode == "Challenge" or mode == "Raid" then
                        local diffsToCheck = diffs["Normal"] or diffs["Hard"]
                        if diffsToCheck then
                            for act, drops in pairs(diffsToCheck) do
                                for dropName, dropData in pairs(drops) do
                                    if dropName == "Trait Shards" and dropData.cap then
                                        table.insert(traitMaps, {
                                            world = world.name,
                                            mode = mode,
                                            act = act,
                                            cap = dropData.cap
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(traitMaps, function(a, b)
            if a.mode == b.mode then return a.world < b.world end
            return a.mode < b.mode
        end)
        
        if isfile and writefile then
            pcall(function()
                writefile("AnimeSquadron_MapsCache.json", HttpService:JSONEncode(traitMaps))
            end)
        end
    end
else
    if isfile and readfile and isfile("AnimeSquadron_MapsCache.json") then
        local succ, data = pcall(function() return HttpService:JSONDecode(readfile("AnimeSquadron_MapsCache.json")) end)
        if succ and type(data) == "table" then
            traitMaps = data
        end
    end
end

local Window = Fluent:CreateWindow({
    Title = "Universal Auto Farm",
    SubTitle = "Anime Squadron",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "play" }),
    Sniper = Window:AddTab({ Title = "Challenge Sniper", Icon = "target" }),
    Maps = Window:AddTab({ Title = "Trait Maps", Icon = "map" }),
    Ingame = Window:AddTab({ Title = "Ingame Helper", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local itemsList = {"Trait Shards", "Reroll Cubes", "Perfect Cubes", "Gems", "Gold"}

Tabs.Sniper:AddParagraph({ Title = "Sniper Configuration", Content = "Used in Lobby. Checked with highest priority." })

local Toggle1d = Tabs.Sniper:AddToggle("AutoJoin1d", { Title = "Enable Daily Challenge (1d)", Default = false })
local Toggle30m = Tabs.Sniper:AddToggle("AutoJoin30m", { Title = "Enable Regular Challenge (30m)", Default = false })

local itemDropdown = Tabs.Sniper:AddDropdown("TargetItem30m", {
    Title = "Target Items (Regular 30m)",
    Values = itemsList,
    Multi = true,
    Default = {},
})

if isLobby then
    task.spawn(function()
        local get_challenges = ReplicatedStorage.Remotes.Play:WaitForChild("get_challenges", 5)
        local send_challenges = ReplicatedStorage.Remotes.Play:WaitForChild("send_challenges", 5)
        
        if get_challenges and send_challenges then
            local succ, data = pcall(function() return get_challenges:InvokeServer() end)
            if succ and type(data) == "table" then
                for chType, chData in pairs(data) do
                    if chData.rewards then
                        for rewardName, _ in pairs(chData.rewards) do
                            if not table.find(itemsList, rewardName) then
                                table.insert(itemsList, rewardName)
                            end
                        end
                    end
                end
                itemDropdown:SetValues(itemsList)
            end
            
            send_challenges.OnClientEvent:Connect(function(data)
                if type(data) == "table" then
                    for chType, chData in pairs(data) do
                        if chData.rewards then
                            for rewardName, _ in pairs(chData.rewards) do
                                if not table.find(itemDropdown.Values, rewardName) then
                                    local current = itemDropdown.Values
                                    table.insert(current, rewardName)
                                    itemDropdown:SetValues(current)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

local mapConfigs = {}
Tabs.Maps:AddParagraph({ Title = "Configuration Guide", Content = "Enter 'Priority' (lower number = higher priority). Enter 0 to skip." })

if #traitMaps == 0 then
    Tabs.Maps:AddParagraph({ Title = "No Data Found", Content = "Execute this script in the Lobby at least once to cache Map data!" })
else
    for i, map in ipairs(traitMaps) do
        local capStr = get_cap_string(map.mode, map.world, map.act, "Trait Shards")
        local titleStr = string.format("[%s] %s (Act %d)", map.mode, map.world, map.act)
        
        local paragraph = Tabs.Maps:AddParagraph({ Title = titleStr, Content = "Tracking current limit." })
        
        local input = Tabs.Maps:AddInput("Priority_"..i, {
            Title = "Priority (0 = Skip)",
            Default = tostring(i),
            Numeric = true,
            Finished = false,
        })
        
        local diff = Tabs.Maps:AddDropdown("Diff_"..i, {
            Title = "Difficulty",
            Values = {"Normal", "Hard"},
            Multi = false,
            Default = 1,
        })
        
        mapConfigs[i] = {
            mapData = map,
            capStr = capStr,
            paragraph = paragraph
        }
    end
end

Tabs.Ingame:AddParagraph({ Title = "Ingame Utilities", Content = "Only active during a match." })
local ToggleLeave = Tabs.Ingame:AddToggle("AutoLeaveToggle", { Title = "ENABLE Auto Leave to Lobby", Default = false })
local ToggleReplay = Tabs.Ingame:AddToggle("AutoReplayToggle", { Title = "ENABLE Auto Replay", Default = false })

Tabs.Ingame:AddParagraph({ Title = "Challenge Sniper Sync", Content = "Automatically return to lobby around XX:00 and XX:30 to check new challenges." })
local ToggleSniperSync = Tabs.Ingame:AddToggle("AutoSniperSync", { Title = "ENABLE Sniper Sync", Default = false })
local DropdownSniperSyncMode = Tabs.Ingame:AddDropdown("SniperSyncMode", {
    Title = "Sync Mode",
    Values = {"Safe (At EndScreen)", "Instant (Abort Match)"},
    Multi = false,
    Default = 1,
})


if isLobby then
    Tabs.AutoFarm:AddParagraph({ Title = "Status: LOBBY", Content = "Master Auto Farm system is ready." })
else
    Tabs.AutoFarm:AddParagraph({ Title = "Status: INGAME", Content = "NOTE: Auto Farm functions will NOT operate while in-game. It will resume automatically in the Lobby." })
end
local friendToggle = Tabs.AutoFarm:AddToggle("FriendsOnly", { Title = "Friends Only", Default = true })
local AutoClaimDaily = Tabs.AutoFarm:AddToggle("AutoClaimDaily", { Title = "Auto Claim Daily Rewards", Default = false })
local AutoClaimBundle = Tabs.AutoFarm:AddToggle("AutoClaimBundle", { Title = "Auto Claim Free Bundle", Default = false })
local AutoToggle = Tabs.AutoFarm:AddToggle("MasterAutoRun", { Title = "ENABLE MASTER AUTO FARM", Default = false })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AnimeSquadronSettings")
SaveManager:SetFolder("AnimeSquadronSettings/AutoFarm")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

pcall(function()
    SaveManager:Load("AutoSave")
end)

local saveDebounce = false
for name, option in pairs(Fluent.Options) do
    option:OnChanged(function()
        if not saveDebounce then
            saveDebounce = true
            task.delay(2, function()
                pcall(function()
                    SaveManager:Save("AutoSave")
                end)
                saveDebounce = false
            end)
        end
    end)
end

if isLobby then
    print("[UniversalAutoFarm] LOBBY mode initialized")
    
    local create_room = ReplicatedStorage.Remotes.Play:WaitForChild("create_room", 10)
    local start_remote = ReplicatedStorage.Remotes.Play:WaitForChild("start", 10)
    local get_challenges = ReplicatedStorage.Remotes.Play:WaitForChild("get_challenges", 10)
    
    local dailyCompleted = false
    local lastDailyWorld = ""
    local lastDailyAct = -1
    
    local util
    pcall(function() util = require(Players.LocalPlayer.PlayerScripts.Client.Utility) end)
    
    local function joinRoom(act, diff, mode, world, rewards, capStr, maxCap)
        if capStr and maxCap and isfile and writefile then
            pcall(function()
                local dataToSave = {
                    capStr = capStr,
                    maxCap = maxCap,
                    worldName = world
                }
                writefile("AnimeSquadron_CurrentTarget.json", HttpService:JSONEncode(dataToSave))
            end)
        end

        local success, err = create_room:InvokeServer({
            boosted = true,
            act = act,
            difficulty = diff,
            mode = mode,
            rewards = rewards,
            only_friends = Options.FriendsOnly.Value,
            world = world
        })
        
        if success then
            task.wait(1.5)
            pcall(function() start_remote:InvokeServer() end)
            task.wait(10)
            return true
        else
            return false, err
        end
    end
    
    local function getSortedValidTraitMaps()
        local validMaps = {}
        for i, cfg in ipairs(mapConfigs) do
            local prio = tonumber(Options["Priority_"..i].Value) or 0
            if prio > 0 then
                validMaps[#validMaps + 1] = {
                    cfg = cfg,
                    priority = prio,
                    difficulty = Options["Diff_"..i].Value
                }
            end
        end
        table.sort(validMaps, function(a, b) return a.priority < b.priority end)
        return validMaps
    end
    
    task.spawn(function()
        local lastClaimTime = 0
        while true do
            task.wait(3)
            
            if os.time() - lastClaimTime > 60 then
                lastClaimTime = os.time()
                if Options.AutoClaimDaily and Options.AutoClaimDaily.Value then
                    pcall(function()
                        local r = ReplicatedStorage.Remotes.Daily_Rewards.claim
                        if r:IsA("RemoteFunction") then r:InvokeServer() else r:FireServer() end
                    end)
                end
                if Options.AutoClaimBundle and Options.AutoClaimBundle.Value then
                    pcall(function()
                        local r = ReplicatedStorage.Remotes.Monetization.free_bundle
                        if r:IsA("RemoteFunction") then r:InvokeServer() else r:FireServer() end
                    end)
                end
            end
            
            for i, cfg in ipairs(mapConfigs) do
                local currentCap = util and util.data and util.data.caps and util.data.caps[cfg.capStr] or 0
                local isFull = (currentCap >= cfg.mapData.cap)
                local prio = tonumber(Options["Priority_"..i].Value) or 0
                
                local contentStr = string.format("Limit: %d / %d", currentCap, cfg.mapData.cap)
                if isFull then contentStr = contentStr .. " [FULL - SKIPPED]" end
                if prio == 0 then contentStr = contentStr .. " [SKIPPED]" end
                cfg.paragraph:SetDesc(contentStr)
            end
            
            if Options.MasterAutoRun.Value and get_challenges and create_room then
                local succ, challengeData = pcall(function() return get_challenges:InvokeServer() end)
                local joinedSomething = false
                
                if succ and type(challengeData) == "table" then
                    if isfile and writefile then
                        pcall(function() writefile("AnimeSquadron_LastSnipeCheck.txt", tostring(math.floor(os.time() / 1800))) end)
                    end
                    
                    if Options.AutoJoin1d.Value and challengeData["1d"] then
                        local chData = challengeData["1d"]
                        if chData.world ~= lastDailyWorld or chData.act ~= lastDailyAct then
                            dailyCompleted = false
                            lastDailyWorld = chData.world
                            lastDailyAct = chData.act
                        end
                        
                        if not dailyCompleted then
                            Fluent:Notify({ Title = "Sniper", Content = "Joining Daily Challenge!", Duration = 3 })
                            local s, err = joinRoom(chData.act, "1d", "Challenge", chData.world, chData.rewards, nil, nil)
                            if not s then
                                if err == "Already completed!" then
                                    dailyCompleted = true
                                end
                            else
                                joinedSomething = true
                            end
                        end
                    end
                    
                    if not joinedSomething and Options.AutoJoin30m.Value and challengeData["30m"] then
                        local chData = challengeData["30m"]
                        local shouldJoin = false
                        local targets = Options.TargetItem30m.Value
                        
                        if chData.rewards and type(targets) == "table" then
                            for rewardName, _ in pairs(chData.rewards) do
                                if targets[rewardName] then
                                    shouldJoin = true
                                    break
                                end
                            end
                        end
                        
                        if shouldJoin then
                            Fluent:Notify({ Title = "Sniper", Content = "Target found! Joining Regular 30m!", Duration = 3 })
                            local s, err = joinRoom(chData.act, "30m", "Challenge", chData.world, chData.rewards, nil, nil)
                            if s then joinedSomething = true end
                        end
                    end
                end
                
                if not joinedSomething then
                    local targetData = nil
                    local sortedMaps = getSortedValidTraitMaps()
                    
                    for _, data in ipairs(sortedMaps) do
                        local currentCap = util and util.data and util.data.caps and util.data.caps[data.cfg.capStr] or 0
                        if currentCap < data.cfg.mapData.cap then
                            targetData = data
                            break
                        end
                    end
                    
                    if targetData then
                        Fluent:Notify({ Title = "Trait Farm", Content = "Joining: " .. targetData.cfg.mapData.world .. " (" .. targetData.difficulty .. ")", Duration = 3 })
                        local s, err = joinRoom(targetData.cfg.mapData.act, targetData.difficulty, targetData.cfg.mapData.mode, targetData.cfg.mapData.world, nil, targetData.cfg.capStr, targetData.cfg.mapData.cap)
                        if s then joinedSomething = true end
                    end
                end
            end
        end
    end)
    
else
    print("[UniversalAutoFarm] INGAME mode initialized")
    
    local messageEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Players"):WaitForChild("message", 10)
    local replayEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game"):WaitForChild("replay", 10)
    
    local util
    pcall(function() util = require(Players.LocalPlayer.PlayerScripts.Client.Utility) end)
    
    local targetCapStr = nil
    local targetMaxCap = nil
    
    if isfile and readfile and isfile("AnimeSquadron_CurrentTarget.json") then
        local succ, parsed = pcall(function() return HttpService:JSONDecode(readfile("AnimeSquadron_CurrentTarget.json")) end)
        if succ and parsed then
            targetCapStr = parsed.capStr
            targetMaxCap = parsed.maxCap
            print("[AutoFarm] Limit data loaded: " .. tostring(targetCapStr) .. " (Max: " .. tostring(targetMaxCap) .. ")")
        end
    end
    
    if messageEvent then
        messageEvent.OnClientEvent:Connect(function(msg, msgType)
            if Options.AutoLeaveToggle.Value and type(msg) == "string" then
                if string.find(msg, "cant replay this challenge") or msg == "You cant replay this challenge!" then
                    Fluent:Notify({ Title = "Auto Leave", Content = "Replay denied! Teleporting to Lobby...", Duration = 5 })
                    task.wait(2)
                    game:GetService("TeleportService"):Teleport(71132543521245)
                end
            end
        end)
    end
    
    task.spawn(function()
        while true do
            task.wait(2)
            if Options.AutoSniperSync and Options.AutoSniperSync.Value and Options.SniperSyncMode.Value == "Instant (Abort Match)" then
                local currentBoundary = math.floor(os.time() / 1800)
                local lastCheck = 0
                if isfile and readfile and isfile("AnimeSquadron_LastSnipeCheck.txt") then
                    pcall(function() lastCheck = tonumber(readfile("AnimeSquadron_LastSnipeCheck.txt")) or 0 end)
                end
                
                if currentBoundary > lastCheck then
                    Fluent:Notify({ Title = "Sniper Sync", Content = "New 30m window! Instant aborting to check challenges...", Duration = 5 })
                    task.wait(2)
                    game:GetService("TeleportService"):Teleport(71132543521245)
                end
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(2)
            local menus = Players.LocalPlayer.PlayerGui:FindFirstChild("Menus")
            if menus then
                local endScreen = menus:FindFirstChild("EndScreen")
                if endScreen and endScreen.Visible then
                    local shouldLeave = false
                    
                    if Options.AutoSniperSync and Options.AutoSniperSync.Value and Options.SniperSyncMode.Value == "Safe (At EndScreen)" then
                        local currentBoundary = math.floor(os.time() / 1800)
                        local lastCheck = 0
                        if isfile and readfile and isfile("AnimeSquadron_LastSnipeCheck.txt") then
                            pcall(function() lastCheck = tonumber(readfile("AnimeSquadron_LastSnipeCheck.txt")) or 0 end)
                        end
                        if currentBoundary > lastCheck then
                            shouldLeave = true
                            Fluent:Notify({ Title = "Sniper Sync", Content = "New 30m window! Returning to lobby for challenges...", Duration = 5 })
                        end
                    end
                    
                    if Options.AutoLeaveToggle.Value and targetCapStr and targetMaxCap and util and util.data and util.data.caps then
                        local currentVal = util.data.caps[targetCapStr] or 0
                        print("[AutoFarm] Current Limit post-match: " .. currentVal .. " / " .. targetMaxCap)
                        
                        if currentVal >= targetMaxCap then
                            shouldLeave = true
                            Fluent:Notify({ Title = "Limit Reached!", Content = "Trait Shards reached " .. currentVal .. "/" .. targetMaxCap .. ". Teleporting to Lobby!", Duration = 5 })
                        end
                    end
                    
                    if shouldLeave then
                        task.wait(2)
                        game:GetService("TeleportService"):Teleport(71132543521245)
                        task.wait(10)
                    elseif Options.AutoReplayToggle.Value and replayEvent then
                        Fluent:Notify({ Title = "Auto Replay", Content = "Replaying immediately...", Duration = 3 })
                        pcall(function() replayEvent:FireServer() end)
                        task.wait(10)
                    end
                end
            end
        end
    end)
end

local function createMobileToggle()
    local guiParent = pcall(function() return gethui() end) and gethui() or game:GetService("CoreGui")
    if not pcall(function() local _ = guiParent.Name end) then
        guiParent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    if guiParent:FindFirstChild("FluentMobileToggle") then return end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FluentMobileToggle"
    ScreenGui.Parent = guiParent
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleBtn.BackgroundTransparency = 0.3
    ToggleBtn.Position = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = ToggleBtn

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(60, 60, 60)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = ToggleBtn

    local Icon = Instance.new("ImageLabel")
    Icon.Name = "Icon"
    Icon.Parent = ToggleBtn
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.5, -12, 0.5, -12)
    Icon.Size = UDim2.new(0, 24, 0, 24)
    Icon.Image = "rbxassetid://10734900011"
    
    local dragging = false
    local dragInput, dragStart, startPos

    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ToggleBtn.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    ToggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    ToggleBtn.MouseButton1Click:Connect(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait()
            vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end)
end
createMobileToggle()
