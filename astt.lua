if not game:IsLoaded() then
    game.Loaded:Wait()
end
local function loadLib(url)
    local lib
    for i = 1, 5 do
        local succ, res = pcall(function() return loadstring(game:HttpGet(url))() end)
        if succ and res then
            lib = res
            break
        end
        task.wait(1)
    end
    return lib
end

local Fluent = loadLib("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
local SaveManager = loadLib("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
local InterfaceManager = loadLib("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")

if not Fluent then
    warn("Failed to load Fluent UI library! Please check your internet connection or executor.")
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    pcall(function() game:GetService("ReplicatedStorage").Remotes.Players.prevent_afk:FireServer() end)
end)

task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() game:GetService("ReplicatedStorage").Remotes.Players.prevent_afk:FireServer() end)
    end
end)

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
        
        -- Dynamic Scraper for MATERIAL_DROPS
        _G.MATERIAL_DROPS = {}
        for worldId, world in pairs(Worlds) do
            if type(worldId) == "number" and world.name and world.Rewards then
                for mode, diffs in pairs(world.Rewards) do
                    for diff, acts in pairs(diffs) do
                        if type(acts) == "table" then
                            for act, items in pairs(acts) do
                                if type(items) == "table" then
                                    for itemName, _ in pairs(items) do
                                        local cleanName = string.lower(tostring(itemName))
                                        if cleanName ~= "gems" and cleanName ~= "xp" and cleanName ~= "gold" and cleanName ~= "trait shards" and cleanName ~= "senzu" and cleanName ~= "energy" then
                                            if not _G.MATERIAL_DROPS[cleanName] then
                                                _G.MATERIAL_DROPS[cleanName] = { world = world.name, mode = mode, acts = {act} }
                                            else
                                                local hasAct = false
                                                for _, v in ipairs(_G.MATERIAL_DROPS[cleanName].acts) do
                                                    if v == act then hasAct = true break end
                                                end
                                                if not hasAct then
                                                    table.insert(_G.MATERIAL_DROPS[cleanName].acts, act)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if isfile and writefile then
            pcall(function() writefile("AnimeSquadron_MatCache.json", HttpService:JSONEncode(_G.MATERIAL_DROPS)) end)
        end
    else
        local function loadCache()
            if isfile and readfile and isfile("AnimeSquadron_MatCache.json") then
                pcall(function() _G.MATERIAL_DROPS = HttpService:JSONDecode(readfile("AnimeSquadron_MatCache.json")) end)
            end
            if isfile and readfile and isfile("AnimeSquadron_MapsCache.json") then
                local succ2, data2 = pcall(function() return HttpService:JSONDecode(readfile("AnimeSquadron_MapsCache.json")) end)
                if succ2 and type(data2) == "table" then
                    traitMaps = data2
                end
            end
        end
        loadCache()
    end
else
    local function loadCache()
        if isfile and readfile and isfile("AnimeSquadron_MatCache.json") then
            pcall(function() _G.MATERIAL_DROPS = HttpService:JSONDecode(readfile("AnimeSquadron_MatCache.json")) end)
        end
        if isfile and readfile and isfile("AnimeSquadron_MapsCache.json") then
            local succ, data = pcall(function() return HttpService:JSONDecode(readfile("AnimeSquadron_MapsCache.json")) end)
            if succ and type(data) == "table" then
                traitMaps = data
            end
        end
    end
    loadCache()
end

local Window = Fluent:CreateWindow({
    Title = "Free HUB",
    SubTitle = "Anime Squadron",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "play" }),
    EvoCraft = Window:AddTab({ Title = "Evo & Craft", Icon = "hammer" }),
    ShopUpgrade = Window:AddTab({ Title = "Shop & Upgrades", Icon = "shopping-cart" }),
    Claims = Window:AddTab({ Title = "Claims & Misc", Icon = "gift" }),
    Sniper = Window:AddTab({ Title = "Challenge Sniper", Icon = "target" }),
    Maps = Window:AddTab({ Title = "Trait Maps", Icon = "map" }),
    Ingame = Window:AddTab({ Title = "Ingame Helper", Icon = "swords" }),
    Priority = Window:AddTab({ Title = "Priority Settings", Icon = "list-ordered" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "link" }),
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
                    if type(chData) == "table" and chData.rewards then
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
                        if type(chData) == "table" and chData.rewards then
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
local ToggleAutoPlay = Tabs.Ingame:AddToggle("AutoPlayToggle", { Title = "ENABLE Official Auto Play", Default = false })
local ToggleLeave = Tabs.Ingame:AddToggle("AutoLeaveToggle", { Title = "ENABLE Auto Leave (On Max Limit/Cant Replay)", Default = false })
local ToggleLeaveBase = Tabs.Ingame:AddToggle("AutoLeaveBaseFailsafe", { Title = "ENABLE Auto Leave (Base 0 HP Failsafe)", Default = false })
local ToggleReplay = Tabs.Ingame:AddToggle("AutoReplayToggle", { Title = "ENABLE Auto Replay", Default = false })
local ToggleReplayAtWave = Tabs.Ingame:AddToggle("AutoReplayAtWave", { Title = "ENABLE Auto Replay at Wave (Inf Mode)", Default = false })
local InputReplayWave = Tabs.Ingame:AddInput("ReplayWaveTarget", { Title = "Target Wave to Replay", Default = "30", Numeric = true, Finished = false })
local ToggleSpeed = Tabs.Ingame:AddToggle("AutoSpeedToggle", { Title = "ENABLE Auto Speed (Max 2x/3x)", Default = false })
local ToggleUltimate = Tabs.Ingame:AddToggle("AutoUltimateToggle", { Title = "ENABLE Auto Ultimate (Only when Enemies present)", Default = false })

Tabs.Ingame:AddParagraph({ Title = "Challenge Sniper Sync", Content = "Automatically return to lobby around XX:00 and XX:30 to check new challenges." })
local ToggleSniperSync = Tabs.Ingame:AddToggle("AutoSniperSync", { Title = "ENABLE Sniper Sync", Default = false })
local DropdownSniperSyncMode = Tabs.Ingame:AddDropdown("SniperSyncMode", {
    Title = "Sync Mode",
    Values = {"Safe (At EndScreen)", "Instant (Abort Match)"},
    Multi = false,
    Default = 1,
})


-- === EVO & CRAFT UI ===
Tabs.EvoCraft:AddParagraph({ Title = "Evo & Craft Priority", Content = "Runs in the Lobby. Lower priority than Auto Quest. Evo and Craft will NOT run simultaneously." })

local function getSavedTarget(key, defaultVal)
    local saved = defaultVal
    if isfile and readfile and isfile("AnimeSquadronSettings/AutoFarm/settings/AutoSave.json") then
        local succ, content = pcall(function() return readfile("AnimeSquadronSettings/AutoFarm/settings/AutoSave.json") end)
        if succ and type(content) == "string" then
            local match = string.match(content, '"idx"%s*:%s*"' .. key .. '".-"value"%s*:%s*"([^"]+)"')
            if match then saved = match end
        end
    end
    return saved
end

local initEvo = getSavedTarget("EvoTarget", "(Waiting for Inventory...)")
local DropdownEvoTarget = Tabs.EvoCraft:AddDropdown("EvoTarget", { Title = "Evo Target", Values = {initEvo}, Multi = false, Default = 1 })

if isLobby then
    task.spawn(function()
        local util
        while task.wait(5) do
            if not util then pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end) end
            if util and util.data and util.data.characters then
                local ownedEvos = {}
                local added = {}
                for id, char in pairs(util.data.characters) do
                    if char.name and not added[char.name] then
                        local template = game:GetService("ReplicatedStorage").Characters:FindFirstChild(char.name)
                        if template and template:FindFirstChild("data") then
                            local data = require(template.data)
                            if data.evolution or data.awakening or data.evolve or data.evo then
                                table.insert(ownedEvos, char.name)
                                added[char.name] = true
                            end
                        end
                    end
                end
                if #ownedEvos == 0 then table.insert(ownedEvos, "(No Evo Units Owned)") end
                DropdownEvoTarget:SetValues(ownedEvos)
            end
        end
    end)
end
local ToggleAutoEvo = Tabs.EvoCraft:AddToggle("AutoEvo", { Title = "ENABLE Auto Evo", Default = false })

Tabs.EvoCraft:AddParagraph({ Title = "---", Content = "" })

local initCraft = getSavedTarget("CraftTarget", "(Loading Craftables...)")
local DropdownCraftTarget = Tabs.EvoCraft:AddDropdown("CraftTarget", { Title = "Craft Target", Values = {initCraft}, Multi = false, Default = 1 })

task.spawn(function()
    local craftTargets = {}
    local get = game:GetService("ReplicatedStorage").Remotes.Crafting:WaitForChild("get", 5)
    if get then
        local succ, recipes = pcall(function() return get:InvokeServer() end)
        if succ and type(recipes) == "table" then
            for name, _ in pairs(recipes) do
                table.insert(craftTargets, name)
            end
        end
    end
    table.sort(craftTargets)
    if #craftTargets == 0 then table.insert(craftTargets, "(None)") end
    local currentCraft = Options.CraftTarget and Options.CraftTarget.Value
    DropdownCraftTarget:SetValues(craftTargets)
    if currentCraft then DropdownCraftTarget:SetValue(currentCraft) end
end)
local InputCraftQty = Tabs.EvoCraft:AddInput("CraftQty", { Title = "Quantity to Craft", Default = "1", Numeric = true, Finished = false })

_G.AnimeSquadron_CraftQueue = {}
if isfile and readfile and isfile("AnimeSquadron_CraftQueue.json") then
    pcall(function()
        local data = game:GetService("HttpService"):JSONDecode(readfile("AnimeSquadron_CraftQueue.json"))
        if type(data) == "table" then
            _G.AnimeSquadron_CraftQueue = data
        end
    end)
end

_G.AnimeSquadron_UpdateCraftQueueUI = function() end

local CraftQueuePara = Tabs.EvoCraft:AddParagraph({ Title = "Crafting Queue", Content = "Empty" })
_G.AnimeSquadron_UpdateCraftQueueUI = function()
    if #_G.AnimeSquadron_CraftQueue == 0 then
        CraftQueuePara:SetDesc("Empty")
    else
        local lines = {}
        for i, task in ipairs(_G.AnimeSquadron_CraftQueue) do
            table.insert(lines, tostring(i) .. ". " .. task.name .. " x" .. task.qty)
        end
        CraftQueuePara:SetDesc(table.concat(lines, "\n"))
    end
    if isfile and writefile then
        pcall(function() writefile("AnimeSquadron_CraftQueue.json", game:GetService("HttpService"):JSONEncode(_G.AnimeSquadron_CraftQueue)) end)
    end
end
_G.AnimeSquadron_UpdateCraftQueueUI()

Tabs.EvoCraft:AddButton({
    Title = "Add to Queue",
    Description = "Add currently selected item and quantity to queue.",
    Callback = function()
        local t = Options.CraftTarget.Value
        local q = tonumber(Options.CraftQty.Value) or 1
        if t and t ~= "(None)" and not string.find(t, "Loading") then
            local found = false
            for _, task in ipairs(_G.AnimeSquadron_CraftQueue) do
                if task.name == t then
                    task.qty = task.qty + q
                    found = true
                    break
                end
            end
            if not found then
                table.insert(_G.AnimeSquadron_CraftQueue, {name = t, qty = q})
            end
            _G.AnimeSquadron_UpdateCraftQueueUI()
            Fluent:Notify({ Title = "Craft Queue", Content = "Added " .. t .. " x" .. q, Duration = 2 })
        end
    end
})

Tabs.EvoCraft:AddButton({
    Title = "Clear Queue",
    Description = "Remove all items from queue.",
    Callback = function()
        _G.AnimeSquadron_CraftQueue = {}
        _G.AnimeSquadron_UpdateCraftQueueUI()
        Fluent:Notify({ Title = "Craft Queue", Content = "Queue cleared.", Duration = 2 })
    end
})

local ToggleAutoCraft = Tabs.EvoCraft:AddToggle("AutoCraft", { Title = "ENABLE Auto Craft", Default = false })

-- === SHOPS & UPGRADES UI ===
Tabs.ShopUpgrade:AddParagraph({ Title = "Dynamic Shops", Content = "Merchant lists all possible items. Raid/Event refresh automatically." })

local DropdownMerchantItem = Tabs.ShopUpgrade:AddDropdown("MerchantItem", { Title = "[Merchant] Target Item", Values = {"(Loading Items...)"}, Multi = true, Default = {} })

task.spawn(function()
    local allMerchantItems = {}
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local get = rep.Remotes.Shops:WaitForChild("get", 5)
        
        local blacklist = {}
        if get then
            local succ1, raid = pcall(function() return get:InvokeServer("gt_city_raid") end)
            if succ1 and type(raid) == "table" then for k,_ in pairs(raid) do blacklist[k] = true end end
            
            local succ2, event = pcall(function() return get:InvokeServer("baras_event") end)
            if succ2 and type(event) == "table" then for k,_ in pairs(event) do blacklist[k] = true end end
        end
        
        local whitelist = {
            ["Gold"] = true, ["Gems"] = true, ["Trait Shards"] = true, ["Reroll Cubes"] = true, ["Perfect Cubes"] = true
        }
        
        for _, folderName in ipairs({"Items", "Materials"}) do
            local folder = rep:FindFirstChild(folderName)
            if folder then
                for _, v in ipairs(folder:GetChildren()) do
                    local name = v.Name
                    if whitelist[name] then
                        if not table.find(allMerchantItems, name) then table.insert(allMerchantItems, name) end
                    else
                        if not blacklist[name] and not string.find(name, "XP") and not string.find(name, "Coin") then
                            if not table.find(allMerchantItems, name) then table.insert(allMerchantItems, name) end
                        end
                    end
                end
            end
        end
        table.sort(allMerchantItems)
    end)
    if #allMerchantItems == 0 then table.insert(allMerchantItems, "(Empty)") end
    local currentMerchant = Options.MerchantItem and Options.MerchantItem.Value
    DropdownMerchantItem:SetValues(allMerchantItems)
    if type(currentMerchant) == "table" then DropdownMerchantItem:SetValue(currentMerchant) end
end)
local ToggleAutoBuyMerchant = Tabs.ShopUpgrade:AddToggle("AutoBuyMerchant", { Title = "ENABLE Auto Buy [Merchant]", Default = false })

local DropdownRaidShopItem = Tabs.ShopUpgrade:AddDropdown("RaidShopItem", { Title = "[Raid] Target Item", Values = {"(Waiting...)"}, Multi = false, Default = 1 })
local ToggleAutoBuyRaid = Tabs.ShopUpgrade:AddToggle("AutoBuyRaid", { Title = "ENABLE Auto Buy [Raid Shop]", Default = false })

local DropdownEventShopItem = Tabs.ShopUpgrade:AddDropdown("EventShopItem", { Title = "[Event] Target Item", Values = {"(Waiting...)"}, Multi = false, Default = 1 })
local ToggleAutoBuyEvent = Tabs.ShopUpgrade:AddToggle("AutoBuyEvent", { Title = "ENABLE Auto Buy [Event Shop]", Default = false })

if isLobby then
    _G.AnimeSquadronShopLoop = (_G.AnimeSquadronShopLoop or 0) + 1
    local currentLoopId = _G.AnimeSquadronShopLoop
    task.spawn(function()
        local get = game:GetService("ReplicatedStorage").Remotes.Shops:WaitForChild("get", 5)
        if not get then return end
        
        while task.wait(10) do
            if _G.AnimeSquadronShopLoop ~= currentLoopId then return end
            local function updateShop(shopId, dropdown)
                local succ, data = pcall(function() return get:InvokeServer(shopId) end)
                if succ and type(data) == "table" then
                    local items = {}
                    for k,v in pairs(data) do
                        table.insert(items, tostring(k))
                    end
                    local currentShopItem = dropdown.Value
                    if #items == 0 then table.insert(items, "(Empty)") end
                    dropdown:SetValues(items)
                    if currentShopItem then dropdown:SetValue(currentShopItem) end
                end
            end
            
            updateShop("gt_city_raid", DropdownRaidShopItem)
            updateShop("baras_event", DropdownEventShopItem)
        end
    end)
end

Tabs.ShopUpgrade:AddParagraph({ Title = "Perks Upgrades", Content = "Auto upgrade your base stats." })
local DropdownPerkTarget = Tabs.ShopUpgrade:AddDropdown("PerkTarget", { Title = "Perk Target", Values = {"health", "yen_generation", "yen_max"}, Multi = false, Default = 1 })
local ToggleAutoPerk = Tabs.ShopUpgrade:AddToggle("AutoPerk", { Title = "ENABLE Auto Perk Upgrade", Default = false })

-- === CLAIMS & MISC UI ===
Tabs.Claims:AddParagraph({ Title = "Auto Claims", Content = "Automatically claims passive rewards." })
local ToggleAutoPass = Tabs.Claims:AddToggle("AutoPass", { Title = "ENABLE Auto Battlepass", Default = false })
local ToggleAutoMilestones = Tabs.Claims:AddToggle("AutoMilestones", { Title = "ENABLE Auto Level Milestones", Default = false })
local ToggleAutoDiscovery = Tabs.Claims:AddToggle("AutoDiscovery", { Title = "ENABLE Auto Discovery Index", Default = false })

Tabs.Claims:AddParagraph({ Title = "Code Redeemer", Content = "Auto redeem predefined codes and dynamically scan Update Log." })
Tabs.Claims:AddButton({
    Title = "Redeem All Codes",
    Description = "Sends all known codes to the server.",
    Callback = function()
        Window:Dialog({
            Title = "Redeeming Codes",
            Content = "Sending codes to server. Check game UI for rewards!",
            Buttons = { { Title = "OK", Callback = function() end } }
        })
        task.spawn(function()
            local codes = {
                "UPD0.75!", "TheHeroHunter!", "SryForLongMaintenance!!", "StrongestChallenger!", "EventChanges"
            }
            
            pcall(function()
                local el = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("UpdateLog", true)
                if el then
                    for _, lbl in ipairs(el:GetDescendants()) do
                        if lbl:IsA("TextLabel") then
                            local txt = lbl.Text
                            if string.sub(txt, 1, 2) == "- " then
                                local possibleCode = string.sub(txt, 3)
                                if not string.find(possibleCode, " ") then
                                    local alreadyHas = false
                                    for _, c in ipairs(codes) do if c == possibleCode then alreadyHas = true break end end
                                    if not alreadyHas then table.insert(codes, possibleCode) end
                                end
                            end
                        end
                    end
                end
            end)
            
            local use = game:GetService("ReplicatedStorage").Remotes.Codes:WaitForChild("use", 5)
            if use then
                for _, code in ipairs(codes) do
                    pcall(function() use:InvokeServer(code) end)
                    task.wait(1.5)
                end
            end
        end)
    end
})

local sendWebhookData
local StatusParagraph
if isLobby then
    StatusParagraph = Tabs.AutoFarm:AddParagraph({ Title = "Status: LOBBY", Content = "Master Auto Farm system is ready." })
else
    StatusParagraph = Tabs.AutoFarm:AddParagraph({ Title = "Status: INGAME", Content = "NOTE: Auto Farm functions will NOT operate while in-game. It will resume automatically in the Lobby." })
end

local SessionStats = {
    Date = os.date("%Y-%m-%d"),
    Matches = 0,
    TraitShards = 0, PerfectCubes = 0, RerollCubes = 0,
    StartTrait = -1, StartPerfect = -1, StartReroll = -1
}

local StatsParagraph = Tabs.AutoFarm:AddParagraph({
    Title = "Session Stats (Farmed Today)",
    Content = "Matches Played: 0\nTrait Shards: 0 + 0\nPerfect Cubes: 0 + 0\nReroll Cubes: 0 + 0"
})

local function saveSessionStats()
    if writefile then
        pcall(function() writefile("AnimeSquadron_DailyStats.json", game:GetService("HttpService"):JSONEncode(SessionStats)) end)
    end
end

local function updateStatsUI()
    if StatsParagraph then
        local t_base = SessionStats.StartTrait == -1 and 0 or SessionStats.StartTrait
        local p_base = SessionStats.StartPerfect == -1 and 0 or SessionStats.StartPerfect
        local r_base = SessionStats.StartReroll == -1 and 0 or SessionStats.StartReroll
        StatsParagraph:SetDesc(string.format("Matches Played: %d\nTrait Shards: %d + %d\nPerfect Cubes: %d + %d\nReroll Cubes: %d + %d", SessionStats.Matches, t_base, SessionStats.TraitShards, p_base, SessionStats.PerfectCubes, r_base, SessionStats.RerollCubes))
    end
end

local function resetSessionStats()
    SessionStats.Matches = 0
    SessionStats.TraitShards = 0
    SessionStats.PerfectCubes = 0
    SessionStats.RerollCubes = 0
    SessionStats.StartTrait = -1
    SessionStats.StartPerfect = -1
    SessionStats.StartReroll = -1
    SessionStats.Date = os.date("%Y-%m-%d")
    saveSessionStats()
    updateStatsUI()
end

local function loadSessionStats()
    if isfile and readfile and isfile("AnimeSquadron_DailyStats.json") then
        local s, res = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile("AnimeSquadron_DailyStats.json")) end)
        if s and type(res) == "table" then
            if res.Date == os.date("%Y-%m-%d") then
                SessionStats.Matches = res.Matches or 0
                SessionStats.TraitShards = res.TraitShards or 0
                SessionStats.PerfectCubes = res.PerfectCubes or 0
                SessionStats.RerollCubes = res.RerollCubes or 0
                SessionStats.StartTrait = res.StartTrait or -1
                SessionStats.StartPerfect = res.StartPerfect or -1
                SessionStats.StartReroll = res.StartReroll or -1
                updateStatsUI()
            else
                resetSessionStats()
            end
        end
    end
end
loadSessionStats()
local friendToggle = Tabs.AutoFarm:AddToggle("FriendsOnly", { Title = "Friends Only", Default = true })
local AutoClaimDaily = Tabs.AutoFarm:AddToggle("AutoClaimDaily", { Title = "Auto Claim Daily Rewards", Default = false })
local AutoClaimBundle = Tabs.AutoFarm:AddToggle("AutoClaimBundle", { Title = "Auto Claim Free Bundle", Default = false })
local AutoQuest = Tabs.AutoFarm:AddToggle("AutoQuest", { Title = "Auto Quest", Default = false })
local AutoToggle = Tabs.AutoFarm:AddToggle("MasterAutoRun", { Title = "ENABLE MASTER AUTO FARM", Default = false })

Tabs.Priority:AddParagraph({ Title = "Task Priority", Content = "Configure which auto farm tasks have priority over others. If a task has no work to do, it will fallback to the next priority. If all tasks are done, it defaults to Auto Farm Map." })
local PriorityList = {"Auto Quest", "Auto Craft", "Auto Evo", "None"}
Tabs.Priority:AddDropdown("Priority1", { Title = "Priority 1 (Highest)", Values = PriorityList, Multi = false, Default = "Auto Quest" })
Tabs.Priority:AddDropdown("Priority2", { Title = "Priority 2", Values = PriorityList, Multi = false, Default = "Auto Craft" })
Tabs.Priority:AddDropdown("Priority3", { Title = "Priority 3", Values = PriorityList, Multi = false, Default = "Auto Evo" })

Tabs.Webhook:AddParagraph({ Title = "Discord Webhook", Content = "Automatic status reporter" })
local WebhookURL = Tabs.Webhook:AddInput("WebhookURL", { Title = "Webhook URL", Default = "", Numeric = false, Finished = false, Placeholder = "https://discord.com/api/webhooks/..." })
local WebhookOnDrop = Tabs.Webhook:AddToggle("WebhookOnDrop", { Title = "Send on Item Drop (Traits/Cubes)", Default = false })
local WebhookOnMatchEnd = Tabs.Webhook:AddToggle("WebhookOnMatchEnd", { Title = "Send on Match End (Win/Loss)", Default = false })
local WebhookOnInterval = Tabs.Webhook:AddToggle("WebhookOnInterval", { Title = "Send on Interval", Default = false })
local WebhookOnEvoCraft = Tabs.Webhook:AddToggle("WebhookOnEvoCraft", { Title = "Send on Evo/Craft (Success/Fail)", Default = false })
local WebhookInterval = Tabs.Webhook:AddSlider("WebhookInterval", { Title = "Interval (Minutes)", Description = "How often to send", Default = 10, Min = 1, Max = 60, Rounding = 0 })

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
    
    local function joinRoom(act, diff, mode, world, rewards, capStr, maxCap, capType)
        if isfile and writefile then
            if capStr and maxCap then
                pcall(function()
                    local dataToSave = {
                        capStr = capStr,
                        maxCap = maxCap,
                        worldName = world,
                        capType = capType
                    }
                    writefile("AnimeSquadron_CurrentTarget.json", HttpService:JSONEncode(dataToSave))
                end)
            else
                if isfile("AnimeSquadron_CurrentTarget.json") and delfile then
                    pcall(function() delfile("AnimeSquadron_CurrentTarget.json") end)
                end
            end
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
    
    _G.AnimeSquadronMainLoop = (_G.AnimeSquadronMainLoop or 0) + 1
    local currentLoopId = _G.AnimeSquadronMainLoop
    task.spawn(function()
        local lastClaimTime = 0
        local buyingDebounce = {}
        while true do
            task.wait(3)
            if _G.AnimeSquadronMainLoop ~= currentLoopId then return end
            
            if os.time() - lastClaimTime > 60 then
                lastClaimTime = os.time()
                if Options.AutoClaimDaily and Options.AutoClaimDaily.Value then
                    pcall(function()
                        if util and util.data and util.data.daily_rewards and not util.data.daily_rewards.claimed then
                            local r = ReplicatedStorage.Remotes.Daily_Rewards.claim
                            local day = util.data.daily_rewards.day
                            if r:IsA("RemoteFunction") then r:InvokeServer(day) else r:FireServer(day) end
                        end
                    end)
                end
                if Options.AutoClaimBundle and Options.AutoClaimBundle.Value then
                    pcall(function()
                        local r = ReplicatedStorage.Remotes.Monetization.free_bundle
                        if r:IsA("RemoteFunction") then r:InvokeServer() else r:FireServer() end
                    end)
                end
            end
            
            local activeQuestMap = nil
            local activeQuestTexts = {}
            
            local function getInventoryAmount(matName)
                local have = 0
                if util and util.data then
                    if util.data.items then
                        for k, v in pairs(util.data.items) do
                            if string.lower(k) == string.lower(matName) then have = have + v end
                        end
                    end
                    if util.data.stats then
                        for k, v in pairs(util.data.stats) do
                            if string.lower(k) == string.lower(matName) then have = have + v end
                        end
                    end
                end
                return have
            end
            
            local function runAutoQuest()
                if not (Options.AutoQuest and Options.AutoQuest.Value and util and util.data and util.data.quests) then return false end
                local anyToClaim = false
                local needToMap = false
                for k, v in pairs(util.data.quests) do
                    if v.progress >= v.required then
                        anyToClaim = true
                    else
                        local lowerName = string.lower(v.name)
                        if string.find(lowerName, "summon") then
                            local diff = v.required - v.progress
                            if diff > 0 then
                                table.insert(activeQuestTexts, string.format("Quest: %s [%d/%d]", v.name, v.progress, v.required))
                                local currentGems = util.data.stats["Gems"] or 0
                                local requiredGems = diff * 50
                                if requiredGems < 500 then requiredGems = 500 end
                                
                                if currentGems >= requiredGems then
                                    pcall(function() game:GetService("ReplicatedStorage").Remotes.Summon.start:InvokeServer("Basic Banner", 10) end)
                                    task.wait(1)
                                end
                            end
                        elseif string.find(lowerName, "boss") or string.find(lowerName, "kill") or string.find(lowerName, "story") or string.find(lowerName, "any") or string.find(lowerName, "clear") then
                            if not activeQuestMap then
                                activeQuestMap = { act = 1, diff = "Normal", mode = "Story", world = "Ninja Village" }
                            end
                            table.insert(activeQuestTexts, string.format("Quest: %s [%d/%d]", v.name, v.progress, v.required))
                            needToMap = true
                        end
                    end
                end
                if anyToClaim then
                    pcall(function() game:GetService("ReplicatedStorage").Remotes.Quests.claim_all:InvokeServer() end)
                end
                return needToMap
            end
            
            -- Claims & Misc
            if Options.AutoPass and Options.AutoPass.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Battlepass.claim_all:InvokeServer() end)
            end
            if Options.AutoMilestones and Options.AutoMilestones.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Level_Milestones.claim:InvokeServer() end)
            end
            if Options.AutoDiscovery and Options.AutoDiscovery.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Characters.claim_all_index:InvokeServer() end)
            end
            
            -- Perks
            if Options.AutoPerk and Options.AutoPerk.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Perks.upgrade:InvokeServer(Options.PerkTarget.Value) end)
            end
            
            -- Shops
            local function tryBuyShop(toggleOpt, itemOpt, shopId)
                if toggleOpt and toggleOpt.Value then
                    local items = itemOpt and itemOpt.Value
                    if type(items) == "table" then
                        for itemName, isSelected in pairs(items) do
                            if isSelected and not string.find(itemName, "Waiting") and not string.find(itemName, "Empty") then
                                local id = shopId .. "_" .. itemName
                                if not buyingDebounce[id] then
                                    buyingDebounce[id] = true
                                    task.spawn(function()
                                        for i=1, 100 do
                                            local s, r = pcall(function() return game:GetService("ReplicatedStorage").Remotes.Shops.buy:InvokeServer(itemName, shopId, 1) end)
                                            if not s or not r then break end
                                            task.wait(0.2)
                                        end
                                        task.wait(5)
                                        buyingDebounce[id] = nil
                                    end)
                                end
                            end
                        end
                    elseif type(items) == "string" then
                        if not string.find(items, "Waiting") and not string.find(items, "Empty") then
                            local id = shopId .. "_" .. items
                            if not buyingDebounce[id] then
                                buyingDebounce[id] = true
                                task.spawn(function()
                                    for i=1, 100 do
                                        local s, r = pcall(function() return game:GetService("ReplicatedStorage").Remotes.Shops.buy:InvokeServer(items, shopId, 1) end)
                                        if not s or not r then break end
                                        task.wait(0.2)
                                    end
                                    task.wait(5)
                                    buyingDebounce[id] = nil
                                end)
                            end
                        end
                    end
                end
            end
            
            tryBuyShop(Options.AutoBuyMerchant, Options.MerchantItem, "merchant")
            tryBuyShop(Options.AutoBuyRaid, Options.RaidShopItem, "gt_city_raid")
            tryBuyShop(Options.AutoBuyEvent, Options.EventShopItem, "baras_event")
            
            local function runAutoCraft()
                if not (Options.AutoCraft and Options.AutoCraft.Value) then return false end
                if not (util and util.data and util.data.stats and util.data.stats.Gold) then return false end
                local currentTask = _G.AnimeSquadron_CraftQueue[1]
                if not currentTask then
                    ToggleAutoCraft:SetValue(false)
                    return false
                end
                
                local targetName = currentTask.name
                local targetQty = currentTask.qty
                local get = game:GetService("ReplicatedStorage").Remotes.Crafting:WaitForChild("get", 5)
                if not get then return false end
                
                local succ, recipes = pcall(function() return get:InvokeServer() end)
                if not succ or type(recipes) ~= "table" or not recipes[targetName] then return false end
                
                local recipe = recipes[targetName]
                local missingMats = {}
                local totalMissingCount = 0
                local isMissingGold = false
                
                for matName, requiredPerCraftStr in pairs(recipe) do
                    local requiredPerCraft = tonumber(requiredPerCraftStr) or 0
                    local totalRequired = requiredPerCraft * targetQty
                    local have = getInventoryAmount(matName)
                    if have < totalRequired then
                        totalMissingCount = totalMissingCount + 1
                        table.insert(missingMats, { name = matName, short = totalRequired - have, total = totalRequired })
                        if string.lower(matName) == "gold" then isMissingGold = true end
                    end
                end
                
                if isMissingGold then
                    ToggleAutoCraft:SetValue(false)
                    Fluent:Notify({ Title = "Auto Craft", Content = "Missing Gold! Cannot farm Gold. Auto Craft disabled.", Duration = 5 })
                    if Options.WebhookOnEvoCraft and Options.WebhookOnEvoCraft.Value then
                        if sendWebhookData then task.spawn(sendWebhookData, "CRAFT_FAIL", { name = targetName }) end
                    end
                    return true
                elseif totalMissingCount > 0 then
                    local mat = missingMats[1]
                    table.insert(activeQuestTexts, string.format("Craft Farming: %s (Need %d %s)", targetName, mat.short, mat.name))
                    local cleanMatName = string.lower(tostring(mat.name))
                    if _G.MATERIAL_DROPS and _G.MATERIAL_DROPS[cleanMatName] then
                        local dropInfo = _G.MATERIAL_DROPS[cleanMatName]
                        activeQuestMap = { mode = dropInfo.mode, world = dropInfo.world, act = dropInfo.acts[#dropInfo.acts], diff = "Hard", isMat = true, matName = mat.name, maxCap = mat.total }
                    end
                    return true
                else
                    table.insert(activeQuestTexts, string.format("Craft Ready: %s x%d", targetName, targetQty))
                    local craftedCount = 0
                    for i = 1, targetQty do
                        local succ, res = pcall(function() return game:GetService("ReplicatedStorage").Remotes.Crafting.craft:InvokeServer(targetName, 1) end)
                        if succ and res then craftedCount = craftedCount + 1 end
                        task.wait(0.5)
                    end
                    
                    if craftedCount > 0 then
                        if Options.WebhookOnEvoCraft and Options.WebhookOnEvoCraft.Value then
                            if sendWebhookData then task.spawn(sendWebhookData, "CRAFT_SUCCESS", { name = targetName, qty = craftedCount }) end
                        end
                        if _G.AnimeSquadron_CraftQueue[1] then
                            _G.AnimeSquadron_CraftQueue[1].qty = _G.AnimeSquadron_CraftQueue[1].qty - craftedCount
                            if _G.AnimeSquadron_CraftQueue[1].qty <= 0 then
                                table.remove(_G.AnimeSquadron_CraftQueue, 1)
                            end
                        end
                        pcall(function() _G.AnimeSquadron_UpdateCraftQueueUI() end)
                        if #_G.AnimeSquadron_CraftQueue == 0 then ToggleAutoCraft:SetValue(false) end
                    end
                    return true
                end
            end
            
            local function runAutoEvo()
                if not (Options.AutoEvo and Options.AutoEvo.Value) then return false end
                if not (util and util.data and util.data.stats and util.data.stats.Gold) then return false end
                local targetName = Options.EvoTarget and Options.EvoTarget.Value
                if not targetName or targetName == "(None)" or string.find(targetName, "Waiting") then return false end
                local targetQty = 1
                
                local template = game:GetService("ReplicatedStorage").Characters:FindFirstChild(targetName)
                if not template or not template:FindFirstChild("data") then return false end
                
                local data = require(template.data)
                local evoData = data.evolution or data.awakening or data.evolve or data.evo
                if not evoData or not evoData.cost then return false end
                
                local missingMats = {}
                local totalMissingCount = 0
                local isMissingGold = false
                
                for matName, requiredPerEvo in pairs(evoData.cost) do
                    local totalRequired = requiredPerEvo * targetQty
                    local have = getInventoryAmount(matName)
                    if have < totalRequired then
                        totalMissingCount = totalMissingCount + 1
                        table.insert(missingMats, { name = matName, short = totalRequired - have, total = totalRequired })
                        if string.lower(matName) == "gold" then isMissingGold = true end
                    end
                end
                
                if isMissingGold then
                    ToggleAutoEvo:SetValue(false)
                    Fluent:Notify({ Title = "Auto Evo", Content = "Missing Gold! Cannot farm Gold. Auto Evo disabled.", Duration = 5 })
                    if Options.WebhookOnEvoCraft and Options.WebhookOnEvoCraft.Value then
                        if sendWebhookData then task.spawn(sendWebhookData, "EVO_FAIL", { name = targetName }) end
                    end
                    return true
                elseif totalMissingCount > 0 then
                    local mat = missingMats[1]
                    table.insert(activeQuestTexts, string.format("Evo Farming: %s (Need %d %s)", targetName, mat.short, mat.name))
                    local cleanMatName = string.lower(tostring(mat.name))
                    if _G.MATERIAL_DROPS and _G.MATERIAL_DROPS[cleanMatName] then
                        local dropInfo = _G.MATERIAL_DROPS[cleanMatName]
                        activeQuestMap = { mode = dropInfo.mode, world = dropInfo.world, act = dropInfo.acts[#dropInfo.acts], diff = "Hard", isMat = true, matName = mat.name, maxCap = mat.total }
                    end
                    return true
                else
                    table.insert(activeQuestTexts, string.format("Evo Ready: %s x%d", targetName, targetQty))
                    local evolvedCount = 0
                    if util.data.characters then
                        for id, charData in pairs(util.data.characters) do
                            if charData.name == targetName then
                                local succ, res = pcall(function() return game:GetService("ReplicatedStorage").Remotes.Awakening.awaken:InvokeServer(id) end)
                                if succ and res then
                                    evolvedCount = evolvedCount + 1
                                    if Options.WebhookOnEvoCraft and Options.WebhookOnEvoCraft.Value then
                                        if sendWebhookData then task.spawn(sendWebhookData, "EVO_SUCCESS", { name = targetName, qty = targetQty }) end
                                    end
                                    if evolvedCount >= targetQty then ToggleAutoEvo:SetValue(false) break end
                                    task.wait(1)
                                end
                            end
                        end
                    end
                    return true
                end
            end
            
            local priorities = {
                Options.Priority1 and Options.Priority1.Value or "Auto Quest",
                Options.Priority2 and Options.Priority2.Value or "Auto Craft",
                Options.Priority3 and Options.Priority3.Value or "Auto Evo"
            }
            
            local handled = false
            for _, p in ipairs(priorities) do
                if not handled then
                    if p == "Auto Quest" then handled = runAutoQuest()
                    elseif p == "Auto Craft" then handled = runAutoCraft()
                    elseif p == "Auto Evo" then handled = runAutoEvo()
                    end
                end
            end
            
            if StatusParagraph then
                if #activeQuestTexts > 0 then
                    StatusParagraph:SetDesc("Master Auto Farm system is ready.\n" .. table.concat(activeQuestTexts, "\n"))
                else
                    StatusParagraph:SetDesc("Master Auto Farm system is ready.")
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
                end
                
                local shouldSnipe30m = false
                if succ and type(challengeData) == "table" and Options.AutoJoin30m.Value and challengeData["30m"] then
                    local chData = challengeData["30m"]
                    local targets = Options.TargetItem30m.Value
                    if chData.rewards and type(targets) == "table" then
                        for rewardName, _ in pairs(chData.rewards) do
                            if targets[rewardName] then
                                shouldSnipe30m = true
                                break
                            end
                        end
                    end
                end
                
                if succ and type(challengeData) == "table" and Options.AutoJoin1d.Value and challengeData["1d"] then
                    local chData = challengeData["1d"]
                    if chData.world ~= lastDailyWorld or chData.act ~= lastDailyAct then
                        dailyCompleted = false
                        lastDailyWorld = chData.world
                        lastDailyAct = chData.act
                    end
                end
                
                if activeQuestMap then
                    if activeQuestMap.isMat then
                        Fluent:Notify({ Title = "Auto Farm", Content = "Farming Material: " .. tostring(activeQuestMap.matName), Duration = 3 })
                        joinRoom(activeQuestMap.act, activeQuestMap.diff, activeQuestMap.mode, activeQuestMap.world, nil, activeQuestMap.matName, activeQuestMap.maxCap, "Item")
                    elseif activeQuestMap.mode == "Story" then
                        Fluent:Notify({ Title = "Auto Quest", Content = "Joining Ninja Village Act 1 for Quest!", Duration = 3 })
                        joinRoom(activeQuestMap.act, activeQuestMap.diff, activeQuestMap.mode, activeQuestMap.world, nil, nil, nil)
                    end
                elseif succ and type(challengeData) == "table" and Options.AutoJoin1d.Value and challengeData["1d"] and not dailyCompleted then
                    Fluent:Notify({ Title = "Sniper", Content = "Joining Daily Challenge!", Duration = 3 })
                    local s, err = joinRoom(challengeData["1d"].act, "1d", "Challenge", challengeData["1d"].world, challengeData["1d"].rewards, nil, nil)
                    if not s and err == "Already completed!" then
                        dailyCompleted = true
                    end
                elseif shouldSnipe30m then
                    Fluent:Notify({ Title = "Sniper", Content = "Target found! Joining Regular 30m!", Duration = 3 })
                    joinRoom(challengeData["30m"].act, "30m", "Challenge", challengeData["30m"].world, challengeData["30m"].rewards, nil, nil)
                else
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
                        joinRoom(targetData.cfg.mapData.act, targetData.difficulty, targetData.cfg.mapData.mode, targetData.cfg.mapData.world, nil, targetData.cfg.capStr, targetData.cfg.mapData.cap)
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
    local targetCapType = nil
    
    if isfile and readfile and isfile("AnimeSquadron_CurrentTarget.json") then
        local succ, parsed = pcall(function() return HttpService:JSONDecode(readfile("AnimeSquadron_CurrentTarget.json")) end)
        if succ and parsed then
            targetCapStr = parsed.capStr
            targetMaxCap = parsed.maxCap
            targetCapType = parsed.capType
            print("[AutoFarm] Limit data loaded: " .. tostring(targetCapStr) .. " (Max: " .. tostring(targetMaxCap) .. ") Type: " .. tostring(targetCapType))
        end
    end
    
    local startedWithIncompleteQuest = false
    _G.AnimeSquadronFarmRunning = (_G.AnimeSquadronFarmRunning or 0) + 1
    local currentFarmLoop = _G.AnimeSquadronFarmRunning
    task.spawn(function()
        local t = 0
        while true do
            if _G.AnimeSquadronFarmRunning ~= currentFarmLoop then return end
            if util and util.data and util.data.quests then
                for k, v in pairs(util.data.quests) do
                    if v.progress < v.required then
                        local lowerName = string.lower(v.name)
                        if string.find(lowerName, "boss") or string.find(lowerName, "kill") or string.find(lowerName, "story") or string.find(lowerName, "any") or string.find(lowerName, "clear") then
                            startedWithIncompleteQuest = true
                            break
                        end
                    end
                end
                break
            end
            task.wait(1)
            t = t + 1
        end
    end)
    
    local isTeleporting = false
    
    local function forceTeleportToLobby(notifyTitle, notifyContent)
        if isTeleporting then return end
        isTeleporting = true
        if notifyTitle and notifyContent then
            Fluent:Notify({ Title = notifyTitle, Content = notifyContent, Duration = 5 })
        end
        task.spawn(function()
            while true do
                local success, err = pcall(function()
                    local teleportRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if teleportRemote then teleportRemote = teleportRemote:FindFirstChild("Players") end
                    if teleportRemote then teleportRemote = teleportRemote:FindFirstChild("teleport") end
                    
                    if teleportRemote and teleportRemote:IsA("RemoteEvent") then
                        teleportRemote:FireServer()
                    else
                        warn("[AutoFarm] Không tìm thấy RemoteEvent teleport của game!")
                    end
                end)
                if not success then
                    warn("[AutoFarm] Lỗi Teleport: " .. tostring(err))
                end
                task.wait(5)
            end
        end)
    end
    
    if messageEvent then
        messageEvent.OnClientEvent:Connect(function(msg, msgType)
            if not isTeleporting and Options.AutoLeaveToggle.Value and type(msg) == "string" then
                if string.find(msg, "cant replay this challenge") or msg == "You cant replay this challenge!" then
                    forceTeleportToLobby("Auto Leave", "Replay denied! Teleporting to Lobby...")
                end
            end
        end)
    end
    
    local baseZeroTime = nil
    
    _G.AnimeSquadronMainLoop = (_G.AnimeSquadronMainLoop or 0) + 1
    local currentMainLoop = _G.AnimeSquadronMainLoop
    task.spawn(function()
        while true do
            if _G.AnimeSquadronMainLoop ~= currentMainLoop then return end
            task.wait(2)
            
            if Options.AutoQuest and Options.AutoQuest.Value and util and util.data and util.data.quests then
                local activeQuestTexts = {}
                for k, v in pairs(util.data.quests) do
                    if v.name ~= "Complete All" and v.name ~= "Weekly Complete All" then
                        if v.progress < v.required then
                            local lowerName = string.lower(v.name)
                            if string.find(lowerName, "boss") or string.find(lowerName, "kill") or string.find(lowerName, "story") or string.find(lowerName, "any") or string.find(lowerName, "clear") or string.find(lowerName, "summon") then
                                table.insert(activeQuestTexts, string.format("Quest: %s [%d/%d]", v.name, v.progress, v.required))
                            end
                        end
                    end
                end
            end
            
            local activeTexts = {}
            if targetCapStr and targetMaxCap and util and util.data then
                local currentVal = 0
                if targetCapType == "Item" then
                    currentVal = (util.data.items and util.data.items[targetCapStr] or 0) + (util.data.stats and util.data.stats[targetCapStr] or 0)
                else
                    currentVal = util.data.caps and util.data.caps[targetCapStr] or 0
                end
                table.insert(activeTexts, "Current Goal: " .. tostring(targetCapStr) .. " [" .. currentVal .. " / " .. targetMaxCap .. "]")
                
                if currentVal >= targetMaxCap and not isTeleporting then
                    forceTeleportToLobby("Auto Farm", "Goal reached! Teleporting to Lobby...")
                end
            end
            
            if StatusParagraph then
                local fullText = "NOTE: Auto Farm functions will NOT operate while in-game. It will resume automatically in the Lobby."
                if activeQuestTexts and #activeQuestTexts > 0 then
                    fullText = fullText .. "\n" .. table.concat(activeQuestTexts, "\n")
                end
                if #activeTexts > 0 then
                    fullText = fullText .. "\n" .. table.concat(activeTexts, "\n")
                end
                StatusParagraph:SetDesc(fullText)
            end
            
            if Options.AutoSpeedToggle and Options.AutoSpeedToggle.Value then
                pcall(function()
                    local Event = game:GetService("ReplicatedStorage").Remotes.Game.change_speed
                    local res, msg = Event:InvokeServer(3)
                    if res == false and type(msg) == "string" and string.find(string.lower(msg), "pass") then
                        Event:InvokeServer(2)
                    end
                end)
            end
            
            if Options.AutoPlayToggle and Options.AutoPlayToggle.Value then
                pcall(function()
                    if util and util.data and not util.data.autoplay then
                        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if Event then Event = Event:FindFirstChild("Characters") end
                        if Event then Event = Event:FindFirstChild("autoplay") end
                        if Event and Event:IsA("RemoteFunction") then
                            Event:InvokeServer()
                        end
                    end
                end)
            end
            
            if Options.AutoUltimateToggle and Options.AutoUltimateToggle.Value then
                local hasEnemy = false
                if workspace:FindFirstChild("Enemies") and #workspace.Enemies:GetChildren() > 0 then
                    hasEnemy = true
                end
                
                if hasEnemy then
                    local hotbar = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Hotbar")
                    if hotbar and hotbar:FindFirstChild("BottomUI") and hotbar.BottomUI:FindFirstChild("Towers") then
                        for _, towerUi in pairs(hotbar.BottomUI.Towers:GetChildren()) do
                            local btn = towerUi:FindFirstChild("Button")
                            if btn and btn:GetAttribute("ult") == true then
                                local startEvent = game:GetService("ReplicatedStorage").Remotes.Ultimates:FindFirstChild("start")
                                if startEvent then
                                    pcall(function() startEvent:InvokeServer(towerUi.Name) end)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end
            
            if Options.AutoReplayAtWave and Options.AutoReplayAtWave.Value and not isTeleporting then
                pcall(function()
                    local waveGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Wave", true)
                    if waveGui then
                        local amountLbl = waveGui:FindFirstChild("Amount") or waveGui:FindFirstChild("WaveInfo")
                        if amountLbl and amountLbl:IsA("TextLabel") then
                            local currentWave = tonumber(amountLbl.Text)
                            local targetWave = tonumber(Options.ReplayWaveTarget.Value) or 30
                            if currentWave and currentWave >= targetWave then
                                isTeleporting = true
                                Fluent:Notify({ Title = "Auto Inf", Content = "Reached Wave " .. currentWave .. "! Replaying...", Duration = 5 })
                                if replayEvent then
                                    pcall(function() replayEvent:FireServer() end)
                                    task.spawn(function()
                                        task.wait(10)
                                        isTeleporting = false
                                    end)
                                end
                            end
                        end
                    end
                end)
            end
            
            if not isTeleporting and Options.AutoLeaveBaseFailsafe and Options.AutoLeaveBaseFailsafe.Value then
                local baseDead = false
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == "Base" or v.Name == "EnemyBase" or v.Name == "base" then
                        local hp = v:FindFirstChild("Health") or v:FindFirstChild("health") or v:FindFirstChild("HP")
                        if hp and (type(hp.Value) == "number") and hp.Value <= 0 then
                            baseDead = true
                            break
                        end
                        local hum = v:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then
                            baseDead = true
                            break
                        end
                    end
                end
                
                local menus = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Menus")
                local endScreen = menus and menus:FindFirstChild("EndScreen")
                local hasEndScreen = endScreen and endScreen.Visible
                
                if baseDead and not hasEndScreen then
                    if not baseZeroTime then
                        baseZeroTime = os.time()
                    elseif os.time() - baseZeroTime >= 10 then
                        forceTeleportToLobby("Failsafe Abort", "Base reached 0 HP (waited 10s, no EndScreen)! Teleporting to Lobby...")
                        baseZeroTime = nil
                    end
                else
                    baseZeroTime = nil
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
            
            if not isTeleporting and Options.AutoSniperSync and Options.AutoSniperSync.Value and Options.SniperSyncMode.Value == "Instant (Abort Match)" then
                local currentBoundary = math.floor(os.time() / 1800)
                local lastCheck = 0
                if isfile and readfile and isfile("AnimeSquadron_LastSnipeCheck.txt") then
                    pcall(function() lastCheck = tonumber(readfile("AnimeSquadron_LastSnipeCheck.txt")) or 0 end)
                end
                
                if currentBoundary > lastCheck then
                    forceTeleportToLobby("Sniper Sync", "New 30m window! Instant aborting to check challenges...")
                end
            end
        end
    end)
    
    local webhookSentForMatch = false
    _G.AnimeSquadronMatchLoop = (_G.AnimeSquadronMatchLoop or 0) + 1
    local currentMatchLoop = _G.AnimeSquadronMatchLoop
    task.spawn(function()
        while true do
            if _G.AnimeSquadronMatchLoop ~= currentMatchLoop then return end
            task.wait(2)
            local menus = Players.LocalPlayer.PlayerGui:FindFirstChild("Menus")
            if menus then
                local endScreen = menus:FindFirstChild("EndScreen")
                if endScreen and endScreen.Visible then
                    if not webhookSentForMatch then
                        webhookSentForMatch = true
                        SessionStats.Matches = SessionStats.Matches + 1
                        saveSessionStats()
                        updateStatsUI()
                        
                        if Options.WebhookOnMatchEnd and Options.WebhookOnMatchEnd.Value and type(sendWebhookData) == "function" then
                            local matchStatus = "WIN"
                            for _, child in pairs(endScreen:GetDescendants()) do
                                if child:IsA("TextLabel") then
                                    local text = string.lower(child.Text)
                                    if string.find(text, "defeat") or string.find(text, "lose") or string.find(text, "fail") then
                                        matchStatus = "LOSS"
                                        break
                                    end
                                end
                            end
                            sendWebhookData(matchStatus)
                        end
                    end
                    
                    if not isTeleporting and Options.AutoSniperSync and Options.AutoSniperSync.Value and Options.SniperSyncMode.Value == "Safe (At EndScreen)" then
                        local currentBoundary = math.floor(os.time() / 1800)
                        local lastCheck = 0
                        if isfile and readfile and isfile("AnimeSquadron_LastSnipeCheck.txt") then
                            pcall(function() lastCheck = tonumber(readfile("AnimeSquadron_LastSnipeCheck.txt")) or 0 end)
                        end
                        if currentBoundary > lastCheck then
                            forceTeleportToLobby("Sniper Sync", "New 30m window! Returning to lobby for challenges...")
                        end
                    end
                    
                    if not isTeleporting and Options.AutoQuest and Options.AutoQuest.Value and startedWithIncompleteQuest and util and util.data and util.data.quests then
                        local hasIncompleteQuest = false
                        for k, v in pairs(util.data.quests) do
                            if v.progress < v.required then
                                local lowerName = string.lower(v.name)
                                if string.find(lowerName, "boss") or string.find(lowerName, "kill") or string.find(lowerName, "story") or string.find(lowerName, "any") or string.find(lowerName, "clear") then
                                    hasIncompleteQuest = true
                                    break
                                end
                            end
                        end
                        if not hasIncompleteQuest then
                            forceTeleportToLobby("Quest Completed!", "All farmable quests finished! Teleporting to Lobby...")
                        end
                    end
                    
                    if not isTeleporting and Options.AutoLeaveToggle.Value and targetCapStr and targetMaxCap and util and util.data and util.data.caps then
                        local currentVal = util.data.caps[targetCapStr] or 0
                        print("[AutoFarm] Current Limit post-match: " .. currentVal .. " / " .. targetMaxCap)
                        
                        if currentVal >= targetMaxCap then
                            forceTeleportToLobby("Limit Reached!", "Trait Shards reached " .. currentVal .. "/" .. targetMaxCap .. ". Teleporting to Lobby!")
                        end
                    end
                    
                    if not isTeleporting and Options.AutoReplayToggle.Value and replayEvent then
                        Fluent:Notify({ Title = "Auto Replay", Content = "Replaying immediately...", Duration = 3 })
                        pcall(function() replayEvent:FireServer() end)
                        task.wait(10)
                    end
                else
                    webhookSentForMatch = false
                end
            end
        end
    end)
end
    sendWebhookData = function(status, diffs)
    if WebhookURL.Value == "" then return false, "No URL configured" end
    
    local util
    pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end)
    
    local gems = util and util.data and util.data.stats and util.data.stats.Gems or 0
    local gold = util and util.data and util.data.stats and util.data.stats.Gold or 0
    local level = util and util.data and util.data.stats and util.data.stats.level or 0
    local traitShards = util and util.data and util.data.stats and util.data.stats["Trait Shards"] or 0
    local perfectCubes = util and util.data and util.data.stats and util.data.stats["Perfect Cubes"] or 0
    local rerollCubes = util and util.data and util.data.stats and util.data.stats["Reroll Cubes"] or 0
    
    local strTrait = tostring(traitShards)
    local strPerfect = tostring(perfectCubes)
    local strReroll = tostring(rerollCubes)
    local droppedItems = {}
    
    if status == "DROP" and type(diffs) == "table" then
        if diffs.trait and diffs.trait > 0 then
            table.insert(droppedItems, "Trait Shards +" .. diffs.trait)
            strTrait = tostring(traitShards - diffs.trait) .. " + " .. diffs.trait
        end
        if diffs.perfect and diffs.perfect > 0 then
            table.insert(droppedItems, "Perfect Cubes +" .. diffs.perfect)
            strPerfect = tostring(perfectCubes - diffs.perfect) .. " + " .. diffs.perfect
        end
        if diffs.reroll and diffs.reroll > 0 then
            table.insert(droppedItems, "Reroll Cubes +" .. diffs.reroll)
            strReroll = tostring(rerollCubes - diffs.reroll) .. " + " .. diffs.reroll
        end
        if diffs.units and type(diffs.units) == "table" and #diffs.units > 0 then
            for _, unitName in ipairs(diffs.units) do
                table.insert(droppedItems, "Unit Drop: " .. tostring(unitName))
            end
        end
    end
    
    local mapName = "Lobby"
    if game.PlaceId ~= 71132543521245 then
        local mode = util and util.data and util.data.ingame and util.data.ingame.mode or "Unknown"
        local world = util and util.data and util.data.ingame and util.data.ingame.world or "Map"
        local act = util and util.data and util.data.ingame and util.data.ingame.act or "1"
        mapName = string.format("%s (Act %s) [%s]", world, tostring(act), mode)
    end

    local embedColor = 16776960
    local statusText = "Idle (Checking...)"
    if status == "WIN" then 
        embedColor = 65280
        statusText = "Victory"
    elseif status == "LOSS" then 
        embedColor = 16711680
        statusText = "Defeat"
    elseif status == "DROP" then
        embedColor = 65280
        statusText = "Item Dropped!"
        if #droppedItems > 0 then
            statusText = "Item Dropped! (" .. table.concat(droppedItems, ", ") .. ")"
        end
    elseif status == "EVO_SUCCESS" then
        embedColor = 65280
        statusText = "Evolved: " .. (diffs.qty or 1) .. "x " .. (diffs.name or "Unit")
    elseif status == "EVO_FAIL" then
        embedColor = 16711680
        statusText = "Evo Failed: " .. (diffs.name or "Unit") .. " (Missing Gold)"
    elseif status == "CRAFT_SUCCESS" then
        embedColor = 45055
        statusText = "Crafted: " .. (diffs.qty or 1) .. "x " .. (diffs.name or "Gear")
    elseif status == "CRAFT_FAIL" then
        embedColor = 16711680
        statusText = "Craft Failed: " .. (diffs.name or "Gear") .. " (Missing Gold)"
    end
    
    local req = nil
    if type(http_request) == "function" then req = http_request
    elseif type(request) == "function" then req = request
    elseif type(syn) == "table" and type(syn.request) == "function" then req = syn.request
    elseif type(fluxus) == "table" and type(fluxus.request) == "function" then req = fluxus.request end

    if not _G.AnimeSquadron_GameIconUrl and req then
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local res = req({
                Url = "https://thumbnails.roblox.com/v1/places/gameicons?placeIds=71132543521245&returnPolicy=PlaceHolder&size=256x256&format=Png&isCircular=false",
                Method = "GET"
            })
            if res and res.StatusCode == 200 then
                local data = HttpService:JSONDecode(res.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    _G.AnimeSquadron_GameIconUrl = data.data[1].imageUrl
                end
            end
        end)
    end
    
    local playerName = game.Players.LocalPlayer.Name
    local gameIconUrl = _G.AnimeSquadron_GameIconUrl or "https://tr.rbxcdn.com/180DAY-be958a6a9a4cd62dd39ea378da75a165/256/256/Image/Webp/noFilter"
    
    local embed = {
        title = "Anime Squadron - Auto Farm Update",
        color = embedColor,
        thumbnail = { url = gameIconUrl },
        fields = {
            { name = "👤 Player", value = playerName, inline = true },
            { name = "⭐ Level", value = tostring(level), inline = true },
            { name = "🗺️ Map", value = mapName, inline = true },
            { name = "<:Gems:1521405276127760434> Gems", value = tostring(gems), inline = true },
            { name = "<:Gold:1521405249988989008> Gold", value = tostring(gold), inline = true },
            { name = "<:TraitShards:1521405216346607697> Trait Shards", value = strTrait, inline = true },
            { name = "<:PerfectCubes:1521405365416099950> Perfect Cubes", value = strPerfect, inline = true },
            { name = "<:RerollCubes:1521405341667954789> Reroll Cubes", value = strReroll, inline = true },
            { name = "📊 Status", value = statusText, inline = true }
        },
        footer = { text = "Free HUB • " .. os.date("%Y-%m-%d %H:%M:%S") }
    }
    
    local msg = {
        username = "Anime Squadron",
        avatar_url = gameIconUrl,
        embeds = { embed }
    }
    
    if req then
        local success, res = pcall(function()
            local HttpService = game:GetService("HttpService")
            return req({
                Url = WebhookURL.Value,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(msg)
            })
        end)
        return success, res
    else
        return false, "Executor does not support HTTP requests"
    end
end

Tabs.Webhook:AddButton({
    Title = "Test Send Webhook",
    Description = "Send a test message now",
    Callback = function()
        Fluent:Notify({ Title = "Webhook", Content = "Sending...", Duration = 2 })
        local success, err = sendWebhookData("INTERVAL")
        if success then
            Fluent:Notify({ Title = "Webhook", Content = "Sent successfully!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Webhook Error", Content = tostring(err), Duration = 5 })
        end
    end
})

_G.AnimeSquadronIntervalLoop = (_G.AnimeSquadronIntervalLoop or 0) + 1
local currentIntervalLoop = _G.AnimeSquadronIntervalLoop
task.spawn(function()
    while true do
        if _G.AnimeSquadronIntervalLoop ~= currentIntervalLoop then return end
        task.wait(60)
        if Options.WebhookOnInterval and Options.WebhookOnInterval.Value and Options.WebhookURL and Options.WebhookURL.Value ~= "" then
            local interval = tonumber(Options.WebhookInterval.Value) or 10
            local lastSend = 0
            if isfile and readfile and isfile("AnimeSquadron_LastWebhook.txt") then
                pcall(function() lastSend = tonumber(readfile("AnimeSquadron_LastWebhook.txt")) or 0 end)
            end
            
            if os.time() - lastSend >= (interval * 60) then
                local success = sendWebhookData("INTERVAL")
                if success and writefile then
                    pcall(function() writefile("AnimeSquadron_LastWebhook.txt", tostring(os.time())) end)
                end
            end
        end
    end
end)

_G.AnimeSquadronStatsLoop = (_G.AnimeSquadronStatsLoop or 0) + 1
local currentStatsLoop = _G.AnimeSquadronStatsLoop
task.spawn(function()
    local util
    local lastTrait, lastPerfect, lastReroll = -1, -1, -1
    local knownChars = nil
    while true do
        if _G.AnimeSquadronStatsLoop ~= currentStatsLoop then return end
        task.wait(5)
        pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end)
        if util and util.data and util.data.stats then
            local currentTrait = util.data.stats["Trait Shards"] or 0
            local currentPerfect = util.data.stats["Perfect Cubes"] or 0
            local currentReroll = util.data.stats["Reroll Cubes"] or 0
            
            local currentChars = {}
            if util.data.characters then
                for k, v in pairs(util.data.characters) do
                    currentChars[k] = v.name
                end
            end
            
            if lastTrait ~= -1 and lastPerfect ~= -1 and lastReroll ~= -1 and knownChars ~= nil then
                if SessionStats.StartTrait == -1 then
                    SessionStats.StartTrait = currentTrait
                    SessionStats.StartPerfect = currentPerfect
                    SessionStats.StartReroll = currentReroll
                    saveSessionStats()
                    updateStatsUI()
                end
                
                local diffTrait = currentTrait - lastTrait
                local diffPerfect = currentPerfect - lastPerfect
                local diffReroll = currentReroll - lastReroll
                
                local droppedUnits = {}
                for k, v in pairs(currentChars) do
                    if not knownChars[k] then
                        table.insert(droppedUnits, v)
                    end
                end
                
                if diffTrait > 0 or diffPerfect > 0 or diffReroll > 0 or #droppedUnits > 0 then
                    if diffTrait > 0 then SessionStats.TraitShards = SessionStats.TraitShards + diffTrait end
                    if diffPerfect > 0 then SessionStats.PerfectCubes = SessionStats.PerfectCubes + diffPerfect end
                    if diffReroll > 0 then SessionStats.RerollCubes = SessionStats.RerollCubes + diffReroll end
                    
                    saveSessionStats()
                    updateStatsUI()
                    
                    if Options.WebhookOnDrop and Options.WebhookOnDrop.Value and Options.WebhookURL and Options.WebhookURL.Value ~= "" then
                        sendWebhookData("DROP", {
                            trait = diffTrait,
                            perfect = diffPerfect,
                            reroll = diffReroll,
                            units = droppedUnits
                        })
                        task.wait(10)
                    end
                end
            end
            lastTrait = currentTrait
            lastPerfect = currentPerfect
            lastReroll = currentReroll
            knownChars = currentChars
        end
    end
end)

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
