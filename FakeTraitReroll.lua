-- Anime Squadron - local fake trait reroll visual only.
-- Does not call ReplicatedStorage.Remotes.Traits.reroll.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Menus = PlayerGui:WaitForChild("Menus", 30)
local TraitsUI = Menus and Menus:WaitForChild("Traits", 30)

local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end

local basePath = "as_free/as_" .. tostring(LP.UserId)
local savePath = basePath .. "/FakeTraitReroll.json"

local function ensureFolder(path)
    local current = ""
    for part in string.gmatch(path, "[^/]+") do
        current = current == "" and part or current .. "/" .. part
        if not isfolder(current) then
            pcall(makefolder, current)
        end
    end
end

pcall(function()
    if not isfolder("as_free") then makefolder("as_free") end
    ensureFolder(basePath)
end)

local state = {
    targetTrait = "Superior",
    targetSubTrait = "",
    rollsToHit = 10,
    rollDelay = 0.16,
    fakeTraitShards = 9999,
    shardCostPerRoll = 1,
    subTraitRollChance = 0.35,
    fakeGems = 999999,
    fakeSummonBanner = "Basic Banner",
    fakeSummonUnits = "Gometa (SSJ4),Fastwagon,Ramuru",
    fakeSummonShiny = "",
    visualEnabled = false,
    fakeUnits = {}
}

local function loadState()
    if not isfile(savePath) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(savePath))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            state[k] = v
        end
        state.fakeUnits = state.fakeUnits or {}
    end
end

local function saveState()
    pcall(function()
        writefile(savePath, HttpService:JSONEncode(state))
    end)
end

loadState()
state.fakeUnits = state.fakeUnits or {}
state.fakeTraitShards = tonumber(state.fakeTraitShards) or 9999
state.shardCostPerRoll = tonumber(state.shardCostPerRoll) or 1
state.subTraitRollChance = tonumber(state.subTraitRollChance) or 0.35
state.rollsToHit = tonumber(state.rollsToHit) or 10
state.rollDelay = tonumber(state.rollDelay) or 0.16
if state.rollDelay < 0.12 then state.rollDelay = 0.16 end
state.targetSubTrait = state.targetSubTrait or ""
state.fakeGems = tonumber(state.fakeGems) or 999999
state.fakeSummonBanner = state.fakeSummonBanner or "Basic Banner"
state.fakeSummonUnits = state.fakeSummonUnits or "Gometa (SSJ4),Fastwagon,Ramuru"
state.fakeSummonShiny = state.fakeSummonShiny or ""
state.visualEnabled = state.visualEnabled == true
_G.ASFakeTraitReroll_VisualEnabled = state.visualEnabled == true
for _, saved in pairs(state.fakeUnits or {}) do
    if type(saved) == "table" and saved.baseDisplays and saved.baseDisplays.version ~= 3 then
        saved.baseDisplays = nil
    end
end

local traitsByTier = {
    Rare = { "Endure", "Sight", "Powerful" },
    Epic = { "Ranger", "Tank", "Knight" },
    Legendary = { "Wealthy", "Lethal", "Sniper", "Juggernaut" },
    Mythic = { "Rebirth", "Entrepreneur", "Cloner" },
    Secret = { "Superior" }
}

local traitStats = {}
pcall(function()
    traitStats = require(ReplicatedStorage.Shared.Data.DB_Traits)
end)

local traitDescriptions = {}
pcall(function()
    traitDescriptions = require(LP.PlayerScripts.Client.Utility.Descriptions)
end)

if type(traitStats) ~= "table" then
    traitStats = {
        Superior = { damage = 3, health = 4, range = 1.3, cooldown = 0.85 },
        Cloner = { damage = 1.4, health = 1.6 },
        Entrepreneur = { cost = 0.6, damage = 1.4, health = 1.3 },
        Rebirth = { damage = 1.35, health = 1.5, range = 1.2 },
        Juggernaut = { health = 1.5 },
        Sniper = { damage = 1.2, range = 1.4 },
        Lethal = { damage = 1.2, cooldown = 0.9 },
        Wealthy = { cost = 0.85, damage = 1.1 },
        Knight = { damage = 1.2, health = 1.05 },
        Tank = { health = 1.3 },
        Ranger = { range = 1.25 },
        Powerful = { damage = 1.1 },
        Sight = { range = 1.1 },
        Endure = { health = 1.1 }
    }
end

local tierByTrait = {}
local allTraits = {}
for tier, list in pairs(traitsByTier) do
    for _, trait in ipairs(list) do
        tierByTrait[trait] = tier
        table.insert(allTraits, trait)
    end
end
table.sort(allTraits)

local fallbackColors = {
    Rare = Color3.fromRGB(88, 190, 255),
    Epic = Color3.fromRGB(188, 88, 255),
    Legendary = Color3.fromRGB(255, 210, 64),
    Mythic = Color3.fromRGB(255, 77, 128),
    Secret = Color3.fromRGB(255, 255, 255)
}

local function getTierColor(tier)
    local folder = ReplicatedStorage:FindFirstChild("Rarities")
    local rarity = folder and folder:FindFirstChild(tier)
    if rarity and rarity:IsA("UIGradient") then
        return rarity.Color
    end
    local gradient = rarity and rarity:FindFirstChildWhichIsA("UIGradient", true)
    return gradient and gradient.Color or ColorSequence.new(fallbackColors[tier] or Color3.new(1, 1, 1))
end

local function findTraitGradient(trait)
    local tierColor = getTierColor(tierByTrait[trait] or "Rare")
    if tierColor then return tierColor end

    if TraitsUI then
        local config = TraitsUI:FindFirstChild("Config")
        local scroll = config and config:FindFirstChild("ScrollingFrame")
        local traitButton = scroll and scroll:FindFirstChild(trait)
        local gradient = traitButton and traitButton:FindFirstChildWhichIsA("UIGradient", true)
        if gradient then return gradient.Color end
    end

    local traitFolder = ReplicatedStorage:FindFirstChild("Traits")
    local traitIcon = traitFolder and traitFolder:FindFirstChild(trait)
    local gradient = traitIcon and traitIcon:FindFirstChildWhichIsA("UIGradient", true)
    if gradient then return gradient.Color end

    return ColorSequence.new(fallbackColors[tierByTrait[trait] or "Rare"] or Color3.new(1, 1, 1))
end

local function popScale(guiObject, big)
    if not guiObject then return end
    local scale = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    scale.Parent = guiObject
    scale.Scale = 0.35
    TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = big or 1 }):Play()
end

local function getTraitImage(trait)
    local folder = ReplicatedStorage:FindFirstChild("Traits")
    local icon = folder and folder:FindFirstChild(trait)
    return icon and icon.Image or ""
end

local function getUtility()
    local ok, util = pcall(function()
        return require(LP.PlayerScripts.Client.Utility)
    end)
    return ok and util or nil
end

local function getClientModule(name)
    local ok, mod = pcall(function()
        return require(LP.PlayerScripts.Client[name])
    end)
    return ok and mod or nil
end

local function getHelper()
    local ok, helper = pcall(function()
        return require(LP.PlayerScripts.Client.Helper)
    end)
    if ok and helper then return helper end

    local ok2, utilityFolder = pcall(function()
        return LP.PlayerScripts.Client.Utility
    end)
    if ok2 and utilityFolder and utilityFolder:FindFirstChild("Helper") then
        local ok3, helper2 = pcall(require, utilityFolder.Helper)
        if ok3 then return helper2 end
    end
    return nil
end

local function currentViewportUnitName()
    if not TraitsUI then return nil end
    local viewport = TraitsUI:FindFirstChild("ViewportFrame")
    if not viewport then return nil end
    for _, child in ipairs(viewport:GetChildren()) do
        if child:IsA("Model") and child.Name ~= "black_dummy" then
            return child.Name
        end
    end
    return nil
end

local function getCurrentUnit()
    local util = getUtility()
    local traitsModule = getClientModule("Traits")
    if traitsModule and traitsModule.selected then
        local unit = traitsModule.selected
        return tostring(unit.id or unit.name), unit, util
    end

    local charactersModule = getClientModule("Characters")
    if charactersModule and charactersModule.selected then
        local unit = charactersModule.selected
        return tostring(unit.id or unit.name), unit, util
    end

    local unitName = currentViewportUnitName()
    if not (util and util.data and util.data.characters and unitName) then
        return nil, nil, util
    end

    for id, unit in pairs(util.data.characters) do
        if unit.name == unitName then
            return tostring(id), unit, util
        end
    end

    return unitName, { name = unitName }, util
end

local function cloneStats(stats)
    local out = {}
    for k, v in pairs(stats or {}) do
        out[k] = v
    end
    return out
end

local function applyTraitToFrame(frame, trait)
    if not frame then return end
    local color = findTraitGradient(trait)
    local inner = frame:FindFirstChild("Frame") or frame
    local text = inner:FindFirstChild("TextLabel", true)
    local img = inner:FindFirstChild("ImageLabel", true)

    frame.Visible = true
    if inner:IsA("GuiObject") then inner.Visible = true end
    if text then
        text.Text = trait
        local tg = text:FindFirstChildOfClass("UIGradient")
        if tg then tg.Color = color end
    end
    if img then
        img.Image = getTraitImage(trait)
        local ig = img:FindFirstChildOfClass("UIGradient")
        if ig then ig.Color = color end
    end
    local fg = inner:FindFirstChildOfClass("UIGradient")
    if fg then fg.Color = color end
    popScale(inner, 1)
end

local function applyDetailsIcon(trait)
    local details = Menus and Menus:FindFirstChild("Details")
    details = details and details:FindFirstChild("Details")
    local icon = details and details:FindFirstChild("trait_1")
    if not icon then return end

    icon.Visible = true
    icon.Image = getTraitImage(trait)
    local gradient = icon:FindFirstChildOfClass("UIGradient")
    if gradient then
        gradient.Color = findTraitGradient(trait)
    end
end

local function setTraitIcon(icon, trait)
    if not icon then return end
    icon.Visible = true

    local inner = icon:FindFirstChild("ImageLabel")
    if inner and inner:IsA("ImageLabel") then
        -- Select.Trait1/Trait2 use a fixed outer frame; only the inner ImageLabel is the trait icon.
        icon.Image = "rbxassetid://128711533436829"
        local gradient = icon:FindFirstChildOfClass("UIGradient")
        if gradient then gradient.Color = findTraitGradient(trait) end
        inner.Image = getTraitImage(trait)
        local innerGradient = inner:FindFirstChildOfClass("UIGradient")
        if innerGradient then innerGradient.Color = findTraitGradient(trait) end
    else
        icon.Image = getTraitImage(trait)
        local gradient = icon:FindFirstChildOfClass("UIGradient")
        if gradient then gradient.Color = findTraitGradient(trait) end
    end
end

local function updateTraitTooltip(trait)
    local info = Menus and Menus:FindFirstChild("unit_info")
    if not info then return end

    local color = findTraitGradient(trait)
    local title = info:FindFirstChild("title")
    local desc = info:FindFirstChild("description")
    local outer = info:FindFirstChildOfClass("UIGradient")
    local inner = info:FindFirstChild("InnerStroke")

    if title then
        title.Text = trait
        local gradient = title:FindFirstChildOfClass("UIGradient")
        if gradient then gradient.Color = color end
    end
    if desc then
        desc.Text = traitDescriptions[trait] or ""
    end
    if outer then outer.Color = color end
    if inner then
        local gradient = inner:FindFirstChildOfClass("UIGradient")
        if gradient then gradient.Color = color end
    end
end

local function convertNumber(n)
    local util = getUtility()
    if util and util.convert_number then
        local ok, text = pcall(util.convert_number, n)
        if ok then return text end
    end
    n = tonumber(n) or 0
    if math.abs(n) >= 1000000 then
        return string.format("%.2fm", n / 1000000):gsub("%.?0+m", "m")
    elseif math.abs(n) >= 1000 then
        return string.format("%.2fk", n / 1000):gsub("%.?0+k", "k")
    end
    local rounded = math.floor(n * 10 + 0.5) / 10
    return tostring(rounded):gsub("%.0$", "")
end

local function parseDisplayNumber(text)
    text = tostring(text or ""):lower():gsub(",", "")
    local number = tonumber(text:match("%-?[%d%.]+"))
    if not number then return nil end
    if text:find("m") then
        number *= 1000000
    elseif text:find("k") then
        number *= 1000
    end
    return number
end

local function statMultiplierFor(trait, statName)
    local stats = traitStats[trait]
    if not stats then return 1 end
    if stats[statName] then return stats[statName] end
    if statName == "ability_dmg" then return stats.damage or 1 end
    if statName == "ability_cd" then return stats.cooldown or 1 end
    return 1
end

local function getCharacterData(unitName)
    local folder = ReplicatedStorage:FindFirstChild("Characters")
    local model = folder and folder:FindFirstChild(unitName or "")
    local dataModule = model and model:FindFirstChild("data")
    if not dataModule then return nil end
    local ok, data = pcall(require, dataModule)
    return ok and data or nil
end

local function getBaseCost(unit)
    if not unit then return nil end
    local data = getCharacterData(unit.name)
    if data and type(data.cost) == "number" then
        return data.cost
    end

    if type(unit.cost) == "number" then return unit.cost end
    if type(unit.base_cost) == "number" then return unit.base_cost end
    return nil
end

local function getBaseStats(unit)
    local out = {}
    if not unit then return out end
    local data = getCharacterData(unit.name)
    for _, statName in ipairs({ "damage", "health", "range", "cooldown", "speed", "defense" }) do
        local value = unit[statName]
        if type(value) ~= "number" and unit.stats then value = unit.stats[statName] end
        if type(value) ~= "number" and data then value = data[statName] end
        if type(value) == "number" then out[statName] = value end
    end
    if out.damage then out.ability_dmg = out.damage end
    if out.cooldown then out.ability_cd = out.cooldown end
    return out
end

local function getCalculatedStat(unit, statName)
    local base = unit and (unit[statName] or (unit.stats and unit.stats[statName]))
    if type(base) ~= "number" then
        local data = unit and getCharacterData(unit.name)
        base = data and data[statName]
    end
    if type(base) ~= "number" then return nil end
    local trait = unit.trait and traitStats[unit.trait]
    local trait2 = unit.trait_2 and traitStats[unit.trait_2]
    local mult = 1
    if trait and trait[statName] then mult *= trait[statName] end
    if trait2 and trait2[statName] then mult *= trait2[statName] end
    return base * mult
end

local function captureStatsFrom(root)
    local out = {}
    if not root then return out end
    for _, frame in ipairs(root:GetChildren()) do
        if frame:IsA("Frame") then
            local amount = frame:FindFirstChild("Amount")
            if amount and amount:IsA("TextLabel") then
                out[string.lower(frame.Name)] = parseDisplayNumber(amount.Text)
            end
        end
    end
    return out
end

local function combinedMultiplier(trait, subTrait, statName)
    return statMultiplierFor(trait, statName) * statMultiplierFor(subTrait, statName)
end

local function unapplyTraitMultipliers(stats, trait, subTrait)
    local out = {}
    for statName, value in pairs(stats or {}) do
        local mult = combinedMultiplier(trait, subTrait, statName)
        if type(value) == "number" and mult ~= 0 then
            out[statName] = value / mult
        end
    end
    return out
end

local function getFakeBaseDisplays(id, unit)
    local existing = state.fakeUnits[id]
    local base = existing and existing.baseDisplays or {}
    local unitName = unit and unit.name

    -- Old versions cached already-faked UI values and caused exponential stat growth.
    -- Keep only cache that belongs to the same unit and was captured by the fixed logic.
    if base.unitName ~= unitName or base.version ~= 3 then
        base = { unitName = unitName, version = 3 }
    end

    local characters = Menus and Menus:FindFirstChild("Characters")
    local statScreen = characters and characters:FindFirstChild("StatScreen")
    local details = Menus and Menus:FindFirstChild("Details")

    local currentStatScreen = captureStatsFrom(statScreen and statScreen:FindFirstChild("Stats"))
    local currentDetails = captureStatsFrom(details and details:FindFirstChild("Stats"))
    local rawStats = getBaseStats(unit)
    local sourceTrait = existing and existing.trait or unit.trait
    local sourceSubTrait = existing and existing.trait_2 or unit.trait_2

    base.statScreen = base.statScreen or (next(currentStatScreen) and unapplyTraitMultipliers(currentStatScreen, sourceTrait, sourceSubTrait)) or (next(rawStats) and rawStats) or {}
    base.details = base.details or (next(currentDetails) and unapplyTraitMultipliers(currentDetails, sourceTrait, sourceSubTrait)) or (next(rawStats) and rawStats) or {}
    base.unitStats = base.unitStats or captureStatsFrom(details and details:FindFirstChild("UnitStats"))
    base.cost = getBaseCost(unit) or base.cost
    return base
end

local function renderCost(unit, baseDisplays)
    if not unit or not baseDisplays or not baseDisplays.cost then return end
    local cost = baseDisplays.cost * statMultiplierFor(unit.trait, "cost") * statMultiplierFor(unit.trait_2, "cost")
    local text = convertNumber(cost) .. "¥"

    local hotbar = PlayerGui:FindFirstChild("Hotbar")
    hotbar = hotbar and hotbar:FindFirstChild("BottomUI")
    hotbar = hotbar and hotbar:FindFirstChild("Characters")
    local card = hotbar and unit.index and hotbar:FindFirstChild(tostring(unit.index))
    if not card and hotbar then
        for _, child in ipairs(hotbar:GetChildren()) do
            local name = child:FindFirstChild("UnitName")
            if name and name:IsA("TextLabel") and name.Text == unit.name then
                card = child
                break
            end
        end
    end
    local costLabel = card and card:FindFirstChild("UnitCost")
    if costLabel and costLabel:IsA("TextLabel") then costLabel.Text = text end

    local detailsUnits = Menus and Menus:FindFirstChild("Details")
    local extras = detailsUnits and detailsUnits:FindFirstChild("Extras")
    extras = extras and extras:FindFirstChild("ScrollingFrame")
    local costFrame = extras and extras:FindFirstChild("cost")
    local amount = costFrame and costFrame:FindFirstChild("Amount")
    if amount and amount:IsA("TextLabel") then amount.Text = text end

    local characters = Menus and Menus:FindFirstChild("Characters")
    local selectCost = characters and characters:FindFirstChild("Select") and characters.Select:FindFirstChild("Cost")
    if selectCost and selectCost:IsA("TextLabel") then
        selectCost.Text = "Cost: <font color='rgb(255, 213, 0)'>" .. text .. "</font>"
    end
end

local function renderStatsIn(root, unit, baseStats)
    if not root or not unit then return end
    for _, frame in ipairs(root:GetChildren()) do
        if frame:IsA("Frame") then
            local statName = string.lower(frame.Name)
            local amount = frame:FindFirstChild("Amount")
            local value = baseStats and baseStats[statName]
            if value then
                value *= statMultiplierFor(unit.trait, statName)
                value *= statMultiplierFor(unit.trait_2, statName)
            else
                value = getCalculatedStat(unit, statName)
            end
            if amount and value then
                local suffix = (statName == "cooldown" or statName == "ability_cd") and "s" or ""
                amount.Text = convertNumber(value) .. suffix
            end
        end
    end
end

local function updateVisibleUnitCards(unit, trait, subTrait)
    if not unit then return end
    local targets = {}
    local hotbar = PlayerGui:FindFirstChild("Hotbar")
    hotbar = hotbar and hotbar:FindFirstChild("BottomUI")
    hotbar = hotbar and hotbar:FindFirstChild("Characters")
    if hotbar and unit.index then table.insert(targets, hotbar:FindFirstChild(tostring(unit.index))) end
    if hotbar then
        for _, card in ipairs(hotbar:GetChildren()) do
            if card:IsA("GuiObject") then
                local name = card:FindFirstChild("UnitName")
                if name and name:IsA("TextLabel") and name.Text == unit.name then
                    table.insert(targets, card)
                end
            end
        end
    end

    local detailsUnits = Menus and Menus:FindFirstChild("Details")
    detailsUnits = detailsUnits and detailsUnits:FindFirstChild("Units")
    detailsUnits = detailsUnits and detailsUnits:FindFirstChild("ScrollingFrame")
    if detailsUnits and unit.index then table.insert(targets, detailsUnits:FindFirstChild(tostring(unit.index))) end

    local characters = Menus and Menus:FindFirstChild("Characters")
    local scroll = characters and characters:FindFirstChild("ScrollingFrame")
    if scroll then
        if unit.id then table.insert(targets, scroll:FindFirstChild(tostring(unit.id))) end
        for _, card in ipairs(scroll:GetChildren()) do
            if card:IsA("GuiObject") then
                local name = card:FindFirstChild("UnitName")
                if name and name:IsA("TextLabel") and name.Text == unit.name then
                    table.insert(targets, card)
                end
            end
        end
    end

    for _, card in ipairs(targets) do
        if card and card.Parent then
            local traits = card:FindFirstChild("Traits")
            if traits then
                setTraitIcon(traits:FindFirstChild("1"), trait)
                local second = traits:FindFirstChild("2")
                if second then
                    if subTrait and subTrait ~= "" then
                        setTraitIcon(second, subTrait)
                    else
                        second.Visible = false
                    end
                end
            end

            local hoverInfo = card:FindFirstChild("hover_info")
            if hoverInfo then
                setTraitIcon(hoverInfo:FindFirstChild("trait_1"), trait)
                local hoverTrait2 = hoverInfo:FindFirstChild("trait_2")
                if hoverTrait2 then
                    if subTrait and subTrait ~= "" then
                        setTraitIcon(hoverTrait2, subTrait)
                    else
                        hoverTrait2.Visible = false
                    end
                end
                renderStatsIn(hoverInfo:FindFirstChild("Stats"), unit, nil)
            end
        end
    end
end

local function findUnitBySavedId(util, savedId, saved)
    if not (util and util.data and util.data.characters) then return nil end
    local unit = util.data.characters[savedId]
    if unit then return unit end
    for id, candidate in pairs(util.data.characters) do
        if saved and saved.name and candidate.name == saved.name then
            return candidate, tostring(id)
        end
    end
    return nil
end

local function refreshAllSavedHotbarUnits()
    local util = getUtility()
    if not (util and util.data and util.data.characters) then return end

    for savedId, saved in pairs(state.fakeUnits or {}) do
        if type(saved) == "table" and saved.trait then
            local unit, realId = findUnitBySavedId(util, savedId, saved)
            if unit then
                local id = realId or savedId
                unit.trait = saved.trait
                unit.trait_2 = saved.trait_2
                unit.fake_trait = saved.trait
                unit.fake_sub_trait = saved.trait_2
                util.data.characters[id].trait = saved.trait
                util.data.characters[id].trait_2 = saved.trait_2
                if not saved.baseDisplays or saved.baseDisplays.version ~= 3 or saved.baseDisplays.unitName ~= unit.name then
                    saved.baseDisplays = getFakeBaseDisplays(id, unit)
                    saveState()
                end
                if util.update_char then pcall(util.update_char, unit) end
                updateVisibleUnitCards(unit, saved.trait, saved.trait_2)
                renderCost(unit, saved.baseDisplays)
            end
        end
    end
end

local function refreshCharacterPanels(unit, trait, subTrait, baseDisplays)
    if not unit then return end
    local util = getUtility()
    if util and util.update_char then
        pcall(util.update_char, unit)
    end

    updateVisibleUnitCards(unit, trait, subTrait)
    applyDetailsIcon(trait)

    local characters = Menus and Menus:FindFirstChild("Characters")
    local statScreen = characters and characters:FindFirstChild("StatScreen")
    local selectPanel = characters and characters:FindFirstChild("Select")
    if selectPanel then
        setTraitIcon(selectPanel:FindFirstChild("Trait1"), trait)
        local trait2 = selectPanel:FindFirstChild("Trait2")
        if trait2 then
            if subTrait and subTrait ~= "" then
                setTraitIcon(trait2, subTrait)
            else
                trait2.Visible = false
            end
        end
    end

    if statScreen then
        local traitIcon = statScreen:FindFirstChild("Trait")
        setTraitIcon(traitIcon, trait)
        renderStatsIn(statScreen:FindFirstChild("Stats"), unit, baseDisplays and baseDisplays.statScreen)
    end

    local details = Menus and Menus:FindFirstChild("Details")
    if details then
        renderStatsIn(details:FindFirstChild("Stats"), unit, baseDisplays and baseDisplays.details)
        renderStatsIn(details:FindFirstChild("UnitStats"), unit, baseDisplays and baseDisplays.unitStats)
    end
    renderCost(unit, baseDisplays)
    updateTraitTooltip(trait)
end

local function playTraitResultEffect(trait)
    pcall(function()
        local sound = SoundService:FindFirstChild((tierByTrait[trait] == "Mythic" or tierByTrait[trait] == "Secret") and "trait_rare" or "trait")
        if sound then sound:Play() end
    end)

    if not TraitsUI then return end

    local tier = tierByTrait[trait]
    local special = TraitsUI:FindFirstChild("SpecialAnim")
    if special and (tier == "Mythic" or tier == "Secret") then
        local image = special:FindFirstChild("ImageLabel")
        local rarity = special:FindFirstChild("Rarity")
        special.Visible = true
        special.ImageTransparency = 1
        if image then
            image.Image = getTraitImage(trait)
            image.ImageColor3 = Color3.new(1, 1, 1)
            image.ImageTransparency = 0
            local gradient = image:FindFirstChildOfClass("UIGradient")
            if gradient then gradient.Color = findTraitGradient(trait) end
            popScale(image, 1)
        end
        if rarity then
            rarity.ImageColor3 = Color3.new(1, 1, 1)
            local gradient = rarity:FindFirstChildOfClass("UIGradient")
            if gradient then gradient.Color = findTraitGradient(trait) end
        end

        task.delay(0.9, function()
            if special and special.Parent then
                if image then
                    local tween = TweenService:Create(image, TweenInfo.new(0.25), { ImageTransparency = 1 })
                    tween:Play()
                    tween.Completed:Wait()
                    image.ImageTransparency = 0
                end
                special.Visible = false
            end
        end)
    end
end

local function hideTraitBuffText()
    if not TraitsUI then return end
    local buff = TraitsUI:FindFirstChild("TraitBuff")
    if buff then
        buff.Text = ""
        buff.Visible = false
    end
end

local function renderFakeTraitShards()
    if not TraitsUI then return end
    local item = TraitsUI:FindFirstChild("item")
    local quantity = item and item:FindFirstChild("Quantity")
    if quantity and quantity:IsA("TextLabel") then
        quantity.Text = "x" .. convertNumber(state.fakeTraitShards or 0)
    end
end

local function spendFakeTraitShards(amount)
    amount = tonumber(amount) or 0
    state.fakeTraitShards = math.max(0, (tonumber(state.fakeTraitShards) or 0) - amount)
    saveState()
    renderFakeTraitShards()
end

local function normalizeSubTrait(subTrait)
    subTrait = tostring(subTrait or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if subTrait == "" or subTrait:lower() == "none" or not tierByTrait[subTrait] then
        return nil
    end
    return subTrait
end

local function applyFakeTrait(trait, subTrait)
    local id, unit, util = getCurrentUnit()
    if not id then
        warn("[FakeTrait] Open Traits UI and select a unit first.")
        return false
    end

    subTrait = normalizeSubTrait(subTrait == nil and state.targetSubTrait or subTrait)
    local stats = cloneStats(traitStats[trait])
    local subStats = cloneStats(subTrait and traitStats[subTrait] or nil)
    local baseDisplays = getFakeBaseDisplays(id, unit)
    state.fakeUnits[id] = {
        id = id,
        name = unit.name or currentViewportUnitName(),
        trait = trait,
        trait_2 = subTrait,
        tier = tierByTrait[trait] or "Rare",
        stats = stats,
        subStats = subStats,
        baseDisplays = baseDisplays,
        savedAt = os.time()
    }
    saveState()

    if unit then
        unit.id = unit.id or id
        unit.trait = trait
        unit.trait_2 = subTrait
        unit.fake_trait = trait
        unit.fake_sub_trait = subTrait
        unit.fake_trait_stats = stats
        unit.fake_sub_trait_stats = subStats
    end

    if util and util.data and util.data.characters then
        local realUnit = util.data.characters[id]
        if realUnit then
            realUnit.trait = trait
            realUnit.trait_2 = subTrait
            realUnit.fake_trait = trait
            realUnit.fake_sub_trait = subTrait
            realUnit.fake_trait_stats = stats
            realUnit.fake_sub_trait_stats = subStats
            unit = realUnit
        end
    end

    if TraitsUI then
        applyTraitToFrame(TraitsUI:FindFirstChild("Trait"), trait)
        local sub = TraitsUI:FindFirstChild("Sub-Trait")
        if sub then
            if subTrait then
                applyTraitToFrame(sub, subTrait)
            else
                sub.Visible = false
                if sub:FindFirstChild("Frame") then sub.Frame.Visible = false end
            end
        end
        hideTraitBuffText()
    end
    refreshCharacterPanels(unit, trait, subTrait, baseDisplays)
    playTraitResultEffect(trait)

    print("[FakeTrait] Applied", trait, subTrait and ("+ " .. subTrait) or "", "to", state.fakeUnits[id].name, "local only. Saved:", savePath)
    return true
end

local rolling = false
local function pickRandomTrait(except, except2, except3)
    if #allTraits == 0 then return except end
    for _ = 1, 20 do
        local trait = allTraits[math.random(1, #allTraits)]
        if trait ~= except and trait ~= except2 and trait ~= except3 then return trait end
    end
    for _, trait in ipairs(allTraits) do
        if trait ~= except and trait ~= except2 and trait ~= except3 then return trait end
    end
    return allTraits[1]
end

local function pickRandomSubTrait(mainTrait, finalSubTrait, isFinal, excludedMainTrait, excludedSubTrait)
    if isFinal then
        local wanted = normalizeSubTrait(finalSubTrait)
        if wanted then return wanted end
    end

    local chance = tonumber(state.subTraitRollChance) or 0.35
    if math.random() > chance then
        return nil
    end

    local sub = pickRandomTrait(mainTrait, excludedMainTrait, excludedSubTrait)
    if sub == mainTrait or sub == excludedMainTrait or sub == excludedSubTrait then return nil end
    return sub
end

local function fakeRoll()
    if rolling then return end
    rolling = true

    local target = state.targetTrait
    local targetSubTrait = normalizeSubTrait(state.targetSubTrait)
    local rolls = math.max(1, tonumber(state.rollsToHit) or 1)
    local finalSubTrait = targetSubTrait

    for i = 1, rolls do
        local trait = (i == rolls) and target or pickRandomTrait(target, targetSubTrait)
        local subTrait = pickRandomSubTrait(trait, targetSubTrait, i == rolls, target, targetSubTrait)
        if i == rolls then finalSubTrait = subTrait end
        if TraitsUI then
            applyTraitToFrame(TraitsUI:FindFirstChild("Trait"), trait)
            local sub = TraitsUI:FindFirstChild("Sub-Trait")
            if sub then
                if subTrait then
                    applyTraitToFrame(sub, subTrait)
                else
                    sub.Visible = false
                    if sub:FindFirstChild("Frame") then sub.Frame.Visible = false end
                end
            end
            hideTraitBuffText()
            spendFakeTraitShards(state.shardCostPerRoll or 1)
        end
        task.wait(tonumber(state.rollDelay) or 0.16)
    end

    applyFakeTrait(target, finalSubTrait)
    rolling = false
end

local function enforceSelectedFakeTrait()
    local id, unit, util = getCurrentUnit()
    if not id or not unit then return end

    local saved = state.fakeUnits[id]
    if not saved then
        for savedId, data in pairs(state.fakeUnits) do
            if data.name == unit.name then
                id = savedId
                saved = data
                break
            end
        end
    end
    if not saved or not saved.trait then return end

    unit.trait = saved.trait
    unit.trait_2 = saved.trait_2
    if util and util.data and util.data.characters and util.data.characters[id] then
        util.data.characters[id].trait = saved.trait
        util.data.characters[id].trait_2 = saved.trait_2
        unit = util.data.characters[id]
    end

    refreshCharacterPanels(unit, saved.trait, saved.trait_2, saved.baseDisplays)
    refreshAllSavedHotbarUnits()
    hideTraitBuffText()
    renderFakeTraitShards()
end

local function startEnforcer()
    if _G.ASFakeTraitReroll_Enforcer then
        _G.ASFakeTraitReroll_Enforcer = false
        task.wait()
    end

    _G.ASFakeTraitReroll_Enforcer = true
    task.spawn(function()
        while _G.ASFakeTraitReroll_Enforcer do
            pcall(enforceSelectedFakeTrait)
            task.wait(0.25)
        end
    end)
end

local function splitList(text)
    local out = {}
    for item in tostring(text or ""):gmatch("[^,\n]+") do
        item = item:gsub("^%s+", ""):gsub("%s+$", "")
        if item ~= "" then table.insert(out, item) end
    end
    return out
end

local function renderFakeGems()
    local hotbar = PlayerGui:FindFirstChild("Hotbar")
    hotbar = hotbar and hotbar:FindFirstChild("BottomUI")
    local currencies = hotbar and hotbar:FindFirstChild("Currencies")
    local gems = currencies and currencies:FindFirstChild("Gems")
    if gems and gems:IsA("TextLabel") then
        gems.Text = convertNumber(state.fakeGems or 0)
    end
end

local function spendFakeGems(amount)
    state.fakeGems = math.max(0, (tonumber(state.fakeGems) or 0) - (tonumber(amount) or 0))
    saveState()
    renderFakeGems()
end

local function buildFakeSummonResults(amount)
    local units = splitList(state.fakeSummonUnits)
    local shinySet = {}
    for _, name in ipairs(splitList(state.fakeSummonShiny)) do
        shinySet[name] = true
    end

    local results = {}
    if #units == 0 then units = { "Fastwagon" } end
    amount = math.clamp(tonumber(amount) or 1, 1, 10)

    for i = 1, amount do
        local name = units[((i - 1) % #units) + 1]
        if ReplicatedStorage.Characters:FindFirstChild(name) then
            table.insert(results, {
                id = HttpService:GenerateGUID(false),
                name = name,
                shiny = shinySet[name] or false,
                level = 1,
                sold = false,
                trait = nil,
                trait_2 = nil,
                ranks = {}
            })
        end
    end
    return results
end

local function getFakePlayerData()
    local util = getUtility()
    local data = util and util.data or {}
    local clone = {}
    for k, v in pairs(data) do clone[k] = v end
    clone.stats = {}
    for k, v in pairs(data.stats or {}) do clone.stats[k] = v end
    clone.stats.Gems = state.fakeGems or 0
    clone.settings = clone.settings or {}
    -- Fake summon always uses the compact result UI. Full animation can leave huge/stuck cards when replayed locally.
    clone.settings.skip_summon = true
    clone.pities = clone.pities or data.pities or {}
    clone.discovered = clone.discovered or data.discovered or {}
    return clone
end

local function getAllCharacterNames()
    local names = {}
    local folder = ReplicatedStorage:FindFirstChild("Characters")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") or child:IsA("Folder") then
                table.insert(names, child.Name)
            end
        end
    end
    table.sort(names)
    return names
end

local function normalizeMultiSelection(value)
    if type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            if v == true then
                table.insert(out, tostring(k))
            elseif type(v) == "string" then
                table.insert(out, v)
            end
        end
        table.sort(out)
        return table.concat(out, ",")
    end
    return tostring(value or "")
end

local fakeSummoning = false
local fakeSummonOpenedAt = 0
local fakeSummonCloseConnection

local function hideFakeSummonOverlays(priority)
    priority = priority or PlayerGui:FindFirstChild("Priority")
    if not priority then return end
    for _, name in ipairs({ "ASFakeSummonTitle", "ASFakeSummonCloseHint", "ASFakeSummonDimBand", "ASFakeSummonCloseLayer" }) do
        local gui = priority:FindFirstChild(name)
        if gui and gui:IsA("GuiObject") then
            gui.Visible = false
        end
    end
end

local function closeFakeSummon(skip)
    if skip then skip.Visible = false end
    hideFakeSummonOverlays()
end

local function cloneSummonText(priority, name, template, text, position, size, zIndex)
    local label = priority:FindFirstChild(name)
    if not label then
        label = template and template:Clone() or Instance.new("TextLabel")
        label.Name = name
        label.Parent = priority
    end
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextTransparency = 0
    label.Visible = true
    label.ZIndex = zIndex
    if label:IsA("TextLabel") then
        label.TextScaled = true
    end
    return label
end

local function createCleanSummonCloseHint(priority, template)
    local old = priority:FindFirstChild("ASFakeSummonCloseHint")
    if old then old:Destroy() end

    local label = Instance.new("TextLabel")
    label.Name = "ASFakeSummonCloseHint"
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.fromScale(0.5, 0.9)
    label.Size = UDim2.fromScale(0.42, 0.045)
    label.BackgroundTransparency = 1
    label.Text = "(Click anywhere to close)"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.ZIndex = 100
    label.Visible = true
    if template and template:IsA("TextLabel") then
        label.FontFace = template.FontFace
    else
        label.Font = Enum.Font.FredokaOne
    end
    label.Parent = priority
    return label
end

local function installFakeSummonVisualOverlays(priority, skip)
    local dimBand = priority:FindFirstChild("ASFakeSummonDimBand")
    if dimBand and dimBand:IsA("GuiObject") then
        dimBand.Visible = false
    end

    local template = skip and skip:FindFirstChild("ItemName")
    if template and template:IsA("TextLabel") then
        template.Visible = true
        template.Text = "Units obtained:"
        template.TextTransparency = 0
        template.ZIndex = 100
        local extraTitle = priority:FindFirstChild("ASFakeSummonTitle")
        if extraTitle and extraTitle:IsA("GuiObject") then
            extraTitle.Visible = false
        end
    else
        cloneSummonText(priority, "ASFakeSummonTitle", template, "Units obtained:", UDim2.fromScale(0.5, 0.18), UDim2.fromScale(0.36, 0.04), 100)
    end

    for _, desc in ipairs(priority:GetDescendants()) do
        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text == "(Click anywhere to close)" and desc.Name ~= "ASFakeSummonCloseHint" then
            desc.Visible = false
        end
    end

    createCleanSummonCloseHint(priority, template)
end

local function updateVisualBlockers()
    local traitsButtons = TraitsUI and TraitsUI:FindFirstChild("Buttons")
    local traitReroll = traitsButtons and traitsButtons:FindFirstChild("Reroll")
    local traitBlocker = traitReroll and traitReroll:FindFirstChild("ASFakeBlocker")
    if traitBlocker and traitBlocker:IsA("GuiObject") then
        traitBlocker.Visible = state.visualEnabled == true
    end

    local summonUI = Menus and Menus:FindFirstChild("Summon")
    local summonButtons = summonUI and summonUI:FindFirstChild("Buttons")
    if summonButtons then
        for _, name in ipairs({ "x1", "x10" }) do
            local real = summonButtons:FindFirstChild(name)
            local blocker = real and real:FindFirstChild("ASFakeSummonBlocker")
            if blocker and blocker:IsA("GuiObject") then
                blocker.Visible = state.visualEnabled == true
            end
        end
    end
end

local function setVisualEnabled(enabled)
    state.visualEnabled = enabled == true
    _G.ASFakeTraitReroll_VisualEnabled = state.visualEnabled == true
    saveState()
    updateVisualBlockers()
end

local function clearViewport(viewport)
    for _, child in ipairs(viewport:GetChildren()) do
        if child:IsA("WorldModel") or child:IsA("Camera") then child:Destroy() end
    end
end

local function buildCardViewport(card, unitName)
    local viewport = card and card:FindFirstChild("ViewportFrame")
    if not viewport then return end

    clearViewport(viewport)

    local source = ReplicatedStorage.Characters:FindFirstChild(unitName or "") or ReplicatedStorage:FindFirstChild("black_dummy")
    if not source then return end

    local world = Instance.new("WorldModel")
    world.Name = unitName or "Unit"
    world.Parent = viewport

    local clone = source:Clone()
    clone.Name = unitName or "Unit"
    clone.Parent = world

    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("ModuleScript") then
            desc:Destroy()
        elseif desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
        end
    end

    local _, modelSize = clone:GetBoundingBox()
    local maxSize = math.max(modelSize.X, modelSize.Y, modelSize.Z, 1)
    clone:PivotTo(CFrame.new(0, -0.08, 0) * CFrame.Angles(0, math.pi, 0))

    local camera = Instance.new("Camera")
    camera.FieldOfView = 42
    camera.CFrame = CFrame.new(Vector3.new(0, maxSize * 0.06, maxSize * 1.85), Vector3.new(0, 0, 0))
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    return true
end

local function copyDiscoveryViewport(card, unitName)
    if buildCardViewport(card, unitName) then return end

    local viewport = card and card:FindFirstChild("ViewportFrame")
    if not viewport then return end

    clearViewport(viewport)

    local discovery = Menus and Menus:FindFirstChild("Discovery")
    discovery = discovery and discovery:FindFirstChild("ScrollingFrame")
    local sourceCard = discovery and discovery:FindFirstChild(unitName)
    local sourceViewport = sourceCard and sourceCard:FindFirstChild("ViewportFrame")
    if not sourceViewport then return end

    for _, child in ipairs(sourceViewport:GetChildren()) do
        if child:IsA("WorldModel") then
            local clone = child:Clone()
            clone.Parent = viewport
            return
        end
    end
end

local function addGameViewportToCard(card, result, util)
    local viewport = card and card:FindFirstChild("ViewportFrame")
    if not viewport then return false end

    clearViewport(viewport)

    local source
    local shinys = ReplicatedStorage:FindFirstChild("Shinys")
    if result.shiny == true and shinys then
        source = shinys:FindFirstChild(result.name or "")
    end
    source = source or ReplicatedStorage.Characters:FindFirstChild(result.name or "") or ReplicatedStorage:FindFirstChild("black_dummy")
    if not source then return false end

    local clone = source:Clone()
    local worldModel = Instance.new("WorldModel")
    worldModel.Name = clone.Name
    worldModel.PrimaryPart = clone.PrimaryPart
    worldModel:ScaleTo(0.6)

    local dataModule = clone:FindFirstChild("data")
    local viewportOffset
    if dataModule then
        local okData, data = pcall(require, dataModule)
        if okData and data then
            viewportOffset = data.viewport_offset
        end
    end

    for _, child in ipairs(clone:GetChildren()) do
        child.Parent = worldModel
    end
    clone:Destroy()

    worldModel:PivotTo(CFrame.new(-402, 4.5, 209.5) * CFrame.Angles(0, math.pi, 0))
    if typeof(viewportOffset) == "CFrame" then
        worldModel:PivotTo(worldModel:GetPivot() * viewportOffset)
    end

    worldModel.Parent = viewport
    if util and util.animate then
        pcall(util.animate, worldModel, "Idle")
    end
    return true
end

local function cardHasViewportModel(card)
    local viewport = card and card:FindFirstChild("ViewportFrame")
    if not viewport then return false end
    for _, desc in ipairs(viewport:GetDescendants()) do
        if desc:IsA("BasePart") then return true end
    end
    return false
end

local function applyFakeCardPresentation(card, result)
    if not card then return end

    local shiny = card:FindFirstChild("Shiny")
    if shiny then
        if shiny:IsA("BoolValue") then
            shiny.Value = result.shiny == true
        elseif shiny:IsA("GuiObject") then
            shiny.Visible = result.shiny == true
        end
    end

    local shine = card:FindFirstChild("Shine")
    if shine and shine:IsA("GuiObject") then
        shine.Visible = result.shiny == true
    end

    local viewport = card:FindFirstChild("ViewportFrame")
    if viewport and viewport:IsA("GuiObject") then
        viewport.Size = UDim2.fromScale(0.9, 0.68)
        viewport.Position = UDim2.fromScale(0.5, 0.58)
        viewport.AnchorPoint = Vector2.new(0.5, 0.5)
        viewport.BackgroundTransparency = 1
        viewport.ZIndex = 70
    end

    local unitName = card:FindFirstChild("UnitName")
    if unitName and unitName:IsA("TextLabel") then
        unitName.Visible = true
        unitName.AnchorPoint = Vector2.new(0.5, 0)
        unitName.Position = UDim2.fromScale(0.5, 0.05)
        unitName.Size = UDim2.fromScale(0.86, 0.15)
        unitName.ZIndex = 100
    end

    local unitLevel = card:FindFirstChild("UnitLevel")
    if unitLevel and unitLevel:IsA("TextLabel") then
        unitLevel.Visible = true
        unitLevel.AnchorPoint = Vector2.new(0.5, 0)
        unitLevel.Position = UDim2.fromScale(0.5, 0.18)
        unitLevel.Size = UDim2.fromScale(0.8, 0.12)
        unitLevel.ZIndex = 100
    end

    local button = card:FindFirstChild("Button") or card:FindFirstChild("Clicked")
    if button and button:IsA("GuiButton") then
        button.BackgroundTransparency = 1
        button.ZIndex = 110
    end

    card.ClipsDescendants = false
    local scale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    scale.Parent = card
    scale.Scale = 1

    if button and button:IsA("GuiButton") and not button:GetAttribute("ASFakeHoverHook") then
        button:SetAttribute("ASFakeHoverHook", true)
        button.MouseEnter:Connect(function()
            TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.08 }):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end)
    end
end

local function installSummonClickAnywhere(skip)
    if fakeSummonCloseConnection then
        fakeSummonCloseConnection:Disconnect()
        fakeSummonCloseConnection = nil
    end

    fakeSummonCloseConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not skip or not skip.Parent or not skip.Visible then return end
        if os.clock() - fakeSummonOpenedAt < 0.25 then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            closeFakeSummon(skip)
        end
    end)
end

local function installSummonCloseLayer(priority, skip)
    local layer = priority:FindFirstChild("ASFakeSummonCloseLayer")
    if not layer then
        layer = Instance.new("TextButton")
        layer.Name = "ASFakeSummonCloseLayer"
        layer.BackgroundTransparency = 1
        layer.Text = ""
        layer.AutoButtonColor = false
        layer.Size = UDim2.fromScale(1, 1)
        layer.Position = UDim2.fromScale(0, 0)
        layer.ZIndex = 9000
        layer.Parent = priority
        layer.Activated:Connect(function()
            closeFakeSummon(skip)
        end)
    end
    layer.Visible = true
end

local function showFakeSummonResults(results)
    local priority = PlayerGui:FindFirstChild("Priority")
    local skip = priority and priority:FindFirstChild("Skip_Summon")
    local util = getUtility()
    if not (skip and util and util.add_char) then return false end

    util.clear_frame(skip.Characters.Characters, { "UIListLayout" })
    skip.Visible = true
    fakeSummonOpenedAt = os.clock()
    installSummonClickAnywhere(skip)
    installSummonCloseLayer(priority, skip)
    installFakeSummonVisualOverlays(priority, skip)
    skip.ImageTransparency = 1
    if skip:FindFirstChild("BG") then skip.BG.BackgroundTransparency = 0.25 end
    if skip:FindFirstChild("Characters") then skip.Characters.BackgroundTransparency = 0.35 end

    local oldClose = skip:FindFirstChild("ASFakeClose")
    if oldClose then oldClose:Destroy() end

    for _, child in ipairs({ skip, skip:FindFirstChild("BG"), skip:FindFirstChild("Characters") }) do
        if child then
            local stroke = child:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Enabled = false end
            if child:IsA("GuiObject") then child.BorderSizePixel = 0 end
        end
    end

    for _, desc in ipairs(skip:GetDescendants()) do
        if desc:IsA("UIStroke") then
            desc.Enabled = false
        end
    end

    local clickClose = skip:FindFirstChild("ASFakeClickAnywhere")
    if not clickClose then
        clickClose = Instance.new("TextButton")
        clickClose.Name = "ASFakeClickAnywhere"
        clickClose.BackgroundTransparency = 1
        clickClose.Text = ""
        clickClose.AutoButtonColor = false
        clickClose.Size = UDim2.fromScale(1, 1)
        clickClose.Position = UDim2.fromScale(0, 0)
        clickClose.ZIndex = 5
        clickClose.Parent = skip
        clickClose.Activated:Connect(function()
            closeFakeSummon(skip)
        end)
    end
    clickClose.Visible = true

    for _, result in ipairs(results) do
        local okCard, card = pcall(util.add_char, result, skip.Characters.Characters)
        if not okCard then
            local partial = skip.Characters.Characters:FindFirstChild(result.id or result.name)
            if partial then partial:Destroy() end
            card = ReplicatedStorage.Templates.character:Clone()
            card.Parent = skip.Characters.Characters
            card.Name = result.id or result.name
            card.UnitName.Text = result.name
            card.UnitLevel.Text = "Lvl. <font color='rgb(0,255,0)'>1</font>"
            card.Locked.Visible = false
            card:SetAttribute("shiny", result.shiny == true)
            local shiny = card:FindFirstChild("Shiny")
            if shiny then
                if shiny:IsA("BoolValue") then
                    shiny.Value = result.shiny == true
                elseif shiny:IsA("GuiObject") then
                    shiny.Visible = result.shiny == true
                end
            end
            local shine = card:FindFirstChild("Shine")
            if shine and shine:IsA("GuiObject") then
                shine.Visible = result.shiny == true
            end
            addGameViewportToCard(card, result, util)
        end
        if card then
            card.Size = UDim2.new(0.1, 0, 1, 0)
            if not cardHasViewportModel(card) then
                addGameViewportToCard(card, result, util)
            end
            card:SetAttribute("shiny", result.shiny == true)
            local shiny = card:FindFirstChild("Shiny")
            if shiny then
                if shiny:IsA("BoolValue") then
                    shiny.Value = result.shiny == true
                elseif shiny:IsA("GuiObject") then
                    shiny.Visible = result.shiny == true
                end
            end
            local shine = card:FindFirstChild("Shine")
            if shine and shine:IsA("GuiObject") then
                shine.Visible = result.shiny == true
            end
            local charData = getCharacterData(result.name)
            local rarityGradient = charData and ReplicatedStorage.Rarities:FindFirstChild(charData.rarity)
            if rarityGradient and rarityGradient:IsA("UIGradient") then
                local cardGradient = card:FindFirstChildOfClass("UIGradient")
                if cardGradient then cardGradient.Color = rarityGradient.Color end
            end
            card.UnitLevel.Text = "Lvl. <font color='rgb(0,255,0)'>1</font>"
            card:SetAttribute("no_white_border", true)
            local cardButton = card:FindFirstChild("Button")
            if cardButton and cardButton:IsA("GuiButton") and not cardButton:GetAttribute("ASFakeCloseHook") then
                cardButton:SetAttribute("ASFakeCloseHook", true)
                cardButton.Activated:Connect(function()
                    closeFakeSummon(skip)
                end)
            end
        end
    end

    return true
end

local function fakeSummon(amount)
    if fakeSummoning then return end
    fakeSummoning = true
    local ok, err = pcall(function()
        amount = math.clamp(tonumber(amount) or 1, 1, 10)

        spendFakeGems(amount * 50)

        local priority = PlayerGui:FindFirstChild("Priority")
        local staleSkip = priority and priority:FindFirstChild("Skip_Summon")
        if staleSkip then
            staleSkip.Visible = false
            hideFakeSummonOverlays(priority)
            local util = getUtility()
            if util then util.clear_frame(staleSkip.Characters.Characters, { "UIListLayout" }) end
        end
        local list = Menus and Menus:FindFirstChild("List")
        if list then list.Visible = false end

        local results = buildFakeSummonResults(amount)
        showFakeSummonResults(results)

        renderFakeGems()
    end)
    if not ok then warn("[FakeSummon]", err) end
    fakeSummoning = false
end

local function installSummonBlocker()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local summon = remotes and remotes:FindFirstChild("Summon")
    local startRemote = summon and summon:FindFirstChild("start")

    if startRemote and hookmetamethod and not _G.ASFakeSummon_BlockHooked then
        _G.ASFakeSummon_BlockHooked = true
        local old
        local hookFn = function(self, ...)
            local method = getnamecallmethod()
            if _G.ASFakeTraitReroll_VisualEnabled == true and self == startRemote and method == "InvokeServer" then
                local banner, amount = ...
                if banner == "Basic Banner" or banner == "Selection Banner" then
                    task.spawn(fakeSummon, amount or 1)
                    return false, "Blocked by Fake Summon"
                end
            end
            return old(self, ...)
        end
        old = hookmetamethod(game, "__namecall", newcclosure and newcclosure(hookFn) or hookFn)
    end

    local summonUI = Menus and Menus:FindFirstChild("Summon")
    local buttons = summonUI and summonUI:FindFirstChild("Buttons")
    if not buttons then return end

    for _, name in ipairs({ "x1", "x10" }) do
        local real = buttons:FindFirstChild(name)
        if real then
            local old = real:FindFirstChild("ASFakeSummonBlocker")
            if old then old:Destroy() end
            local blocker = Instance.new("TextButton")
            blocker.Name = "ASFakeSummonBlocker"
            blocker.BackgroundTransparency = 1
            blocker.Text = ""
            blocker.AutoButtonColor = false
            blocker.Visible = state.visualEnabled == true
            blocker.Size = UDim2.fromScale(1, 1)
            blocker.Position = UDim2.fromScale(0, 0)
            blocker.ZIndex = (real.ZIndex or 1) + 20
            blocker.Parent = real
            blocker.Activated:Connect(function()
                if state.visualEnabled == true then
                    fakeSummon(name == "x10" and 10 or 1)
                end
            end)
        end
    end
end

local function makeText(parent, text, size, pos)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.TextSize = 13
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = size
    label.Position = pos
    label.Parent = parent
    return label
end

local function makeBox(parent, text, size, pos)
    local box = Instance.new("TextBox")
    box.Text = text
    box.ClearTextOnFocus = false
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
    box.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
    box.BorderSizePixel = 0
    box.TextSize = 13
    box.Font = Enum.Font.Gotham
    box.Size = size
    box.Position = pos
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    return box
end

local function makeButton(parent, text, size, pos, color)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color or Color3.fromRGB(54, 113, 255)
    btn.BorderSizePixel = 0
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Size = size
    btn.Position = pos
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function createOverlay()
    local okFluent, Fluent = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)

    if okFluent and Fluent then
        pcall(function()
            local old = CoreGui:FindFirstChild("AS_FakeTraitReroll")
            if old then old:Destroy() end
        end)

        local Window = Fluent:CreateWindow({
            Title = "Fake Trait Reroll",
            SubTitle = "Anime Squadron | Local visual only",
            TabWidth = 130,
            Size = UDim2.fromOffset(430, 360),
            Acrylic = true,
            Theme = "Dark",
            MinimizeKey = Enum.KeyCode.RightControl
        })

        local Tab = Window:AddTab({ Title = "Trait", Icon = "dices" })
        local SummonTab = Window:AddTab({ Title = "Summon", Icon = "sparkles" })
        Tab:AddParagraph({
            Title = "Local-only fake reroll",
            Content = "Does not call ReplicatedStorage.Remotes.Traits.reroll. Sub Trait can be blank or None."
        })

        Tab:AddToggle("ASFakeVisual_Enabled", {
            Title = "Enable Visual Blockers",
            Description = "When enabled, real trait reroll and banner summon buttons are replaced with local fake visuals. When disabled, game buttons work normally.",
            Default = state.visualEnabled == true,
            Callback = function(value)
                setVisualEnabled(value == true)
            end
        })

        local subTraitValues = { "None" }
        for _, traitName in ipairs(allTraits) do table.insert(subTraitValues, traitName) end

        Tab:AddDropdown("ASFakeTrait_Main", {
            Title = "Main Trait",
            Description = "Target main trait",
            Values = allTraits,
            Multi = false,
            Default = state.targetTrait,
            Callback = function(value)
                value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if tierByTrait[value] then
                    state.targetTrait = value
                    saveState()
                end
            end
        })

        Tab:AddDropdown("ASFakeTrait_Sub", {
            Title = "Sub Trait",
            Description = "Blank/None to disable",
            Values = subTraitValues,
            Multi = false,
            Default = (state.targetSubTrait ~= "" and state.targetSubTrait) or "None",
            Callback = function(value)
                value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if value == "" or value:lower() == "none" then
                    state.targetSubTrait = ""
                    saveState()
                elseif tierByTrait[value] then
                    state.targetSubTrait = value
                    saveState()
                end
            end
        })

        Tab:AddInput("ASFakeTrait_Rolls", {
            Title = "Rolls To Hit",
            Description = "How many fake rolls before target appears",
            Default = tostring(state.rollsToHit),
            Numeric = true,
            Finished = false,
            Callback = function(value)
                state.rollsToHit = math.clamp(tonumber(value) or state.rollsToHit or 1, 1, 9999)
                saveState()
            end
        })

        Tab:AddInput("ASFakeTrait_RollDelay", {
            Title = "Roll Delay (Seconds)",
            Description = "Delay per fake trait roll. Default 0.16; lower is faster.",
            Default = tostring(state.rollDelay or 0.16),
            Numeric = true,
            Finished = false,
            Callback = function(value)
                state.rollDelay = math.clamp(tonumber(value) or state.rollDelay or 0.16, 0.05, 2)
                saveState()
            end
        })

        Tab:AddInput("ASFakeTrait_Shards", {
            Title = "Fake Trait Shards",
            Description = "Displayed instead of real Trait Shards in reroll UI",
            Default = tostring(state.fakeTraitShards or 0),
            Numeric = true,
            Finished = false,
            Callback = function(value)
                state.fakeTraitShards = math.max(0, tonumber(value) or state.fakeTraitShards or 0)
                saveState()
                renderFakeTraitShards()
            end
        })

        Tab:AddInput("ASFakeTrait_Cost", {
            Title = "Fake Cost Per Roll",
            Description = "How many fake shards to subtract each visual roll",
            Default = tostring(state.shardCostPerRoll or 1),
            Numeric = true,
            Finished = false,
            Callback = function(value)
                state.shardCostPerRoll = math.max(0, tonumber(value) or state.shardCostPerRoll or 1)
                saveState()
            end
        })

        Tab:AddInput("ASFakeTrait_SubChance", {
            Title = "Sub Trait Chance",
            Description = "0-100 chance for random sub trait during roll animation",
            Default = tostring(math.floor((tonumber(state.subTraitRollChance) or 0.35) * 100)),
            Numeric = true,
            Finished = false,
            Callback = function(value)
                state.subTraitRollChance = math.clamp((tonumber(value) or 35) / 100, 0, 1)
                saveState()
            end
        })

        Tab:AddButton({
            Title = "Fake Roll",
            Description = "Animate fake roll then apply main/sub trait locally",
            Callback = fakeRoll
        })

        Tab:AddButton({
            Title = "Apply Now",
            Description = "Apply selected traits without roll animation",
            Callback = function()
                applyFakeTrait(state.targetTrait, state.targetSubTrait)
            end
        })

        Tab:AddButton({
            Title = "Clear Sub Trait",
            Description = "Set sub trait to blank for next apply",
            Callback = function()
                state.targetSubTrait = ""
                saveState()
                applyFakeTrait(state.targetTrait, "")
            end
        })

        renderFakeTraitShards()

        SummonTab:AddParagraph({
            Title = "Fake Summon",
            Content = "Blocks Basic/Selection Banner summon start locally. Results can include any unit in ReplicatedStorage.Characters, including evo/not banner units."
        })

        SummonTab:AddInput("ASFakeSummon_Gems", {
            Title = "Fake Gems",
            Description = "Displayed in hotbar and spent locally: x1=50, x10=500",
            Default = tostring(state.fakeGems or 0),
            Numeric = true,
            Finished = false,
            Callback = function(value)
                state.fakeGems = math.max(0, tonumber(value) or state.fakeGems or 0)
                saveState()
                renderFakeGems()
            end
        })

        SummonTab:AddDropdown("ASFakeSummon_Banner", {
            Title = "Fake Banner",
            Description = "Basic Banner or Selection Banner",
            Values = { "Basic Banner", "Selection Banner" },
            Multi = false,
            Default = state.fakeSummonBanner or "Basic Banner",
            Callback = function(value)
                value = tostring(value or "")
                if value == "Basic Banner" or value == "Selection Banner" then
                    state.fakeSummonBanner = value
                    saveState()
                end
            end
        })

        local characterNames = getAllCharacterNames()
        local function selectedMap(text)
            local map = {}
            for _, name in ipairs(splitList(text)) do map[name] = true end
            return map
        end

        SummonTab:AddDropdown("ASFakeSummon_Units", {
            Title = "Result Units",
            Description = "Choose up to 10. Results cycle if less than amount.",
            Values = characterNames,
            Multi = true,
            Default = selectedMap(state.fakeSummonUnits),
            Callback = function(value)
                state.fakeSummonUnits = normalizeMultiSelection(value)
                saveState()
            end
        })

        SummonTab:AddDropdown("ASFakeSummon_Shiny", {
            Title = "Shiny Units",
            Description = "Selected unit names will appear shiny",
            Values = characterNames,
            Multi = true,
            Default = selectedMap(state.fakeSummonShiny),
            Callback = function(value)
                state.fakeSummonShiny = normalizeMultiSelection(value)
                saveState()
            end
        })

        SummonTab:AddButton({ Title = "Fake Summon x1", Description = "Spend 50 fake gems", Callback = function() fakeSummon(1) end })
        SummonTab:AddButton({ Title = "Fake Summon x10", Description = "Spend 500 fake gems", Callback = function() fakeSummon(10) end })

        renderFakeGems()

        return Window
    end

    local old = CoreGui:FindFirstChild("AS_FakeTraitReroll")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AS_FakeTraitReroll"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    gui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Size = UDim2.fromOffset(270, 285)
    frame.Position = UDim2.new(1, -285, 0.5, -142)
    frame.BackgroundColor3 = Color3.fromRGB(17, 18, 24)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    makeText(frame, "Fake Trait Reroll (local only)", UDim2.fromOffset(240, 22), UDim2.fromOffset(14, 10))
    makeText(frame, "Trait", UDim2.fromOffset(80, 20), UDim2.fromOffset(14, 42))
    makeText(frame, "Sub Trait", UDim2.fromOffset(90, 20), UDim2.fromOffset(150, 42))

    local traitBox = makeBox(frame, tostring(state.targetTrait), UDim2.fromOffset(120, 28), UDim2.fromOffset(14, 64))
    local subTraitBox = makeBox(frame, tostring(state.targetSubTrait or ""), UDim2.fromOffset(90, 28), UDim2.fromOffset(150, 64))

    makeText(frame, "Rolls", UDim2.fromOffset(80, 20), UDim2.fromOffset(14, 98))
    local rollsBox = makeBox(frame, tostring(state.rollsToHit), UDim2.fromOffset(90, 28), UDim2.fromOffset(14, 120))

    makeText(frame, "Delay", UDim2.fromOffset(80, 20), UDim2.fromOffset(14, 153))
    local delayBox = makeBox(frame, tostring(state.rollDelay or 0.16), UDim2.fromOffset(90, 28), UDim2.fromOffset(14, 175))

    makeText(frame, "Sub Trait can be blank/None. Traits: Endure, Sight, Powerful, Ranger, Tank, Knight, Wealthy, Lethal, Sniper, Juggernaut, Rebirth, Entrepreneur, Cloner, Superior", UDim2.fromOffset(240, 54), UDim2.fromOffset(14, 215))

    local rollBtn = makeButton(frame, "FAKE ROLL", UDim2.fromOffset(110, 32), UDim2.fromOffset(132, 112), Color3.fromRGB(73, 126, 255))
    local applyBtn = makeButton(frame, "APPLY NOW", UDim2.fromOffset(110, 32), UDim2.fromOffset(132, 153), Color3.fromRGB(95, 190, 100))

    traitBox.FocusLost:Connect(function()
        local wanted = traitBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if tierByTrait[wanted] then
            state.targetTrait = wanted
            saveState()
        else
            traitBox.Text = state.targetTrait
        end
    end)

    subTraitBox.FocusLost:Connect(function()
        local wanted = subTraitBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if wanted == "" or wanted:lower() == "none" then
            state.targetSubTrait = ""
            subTraitBox.Text = ""
            saveState()
        elseif tierByTrait[wanted] then
            state.targetSubTrait = wanted
            saveState()
        else
            subTraitBox.Text = state.targetSubTrait or ""
        end
    end)

    rollsBox.FocusLost:Connect(function()
        state.rollsToHit = math.clamp(tonumber(rollsBox.Text) or state.rollsToHit or 1, 1, 9999)
        rollsBox.Text = tostring(state.rollsToHit)
        saveState()
    end)

    delayBox.FocusLost:Connect(function()
        state.rollDelay = math.clamp(tonumber(delayBox.Text) or state.rollDelay or 0.16, 0.05, 2)
        delayBox.Text = tostring(state.rollDelay)
        saveState()
    end)

    rollBtn.Activated:Connect(function()
        traitBox:ReleaseFocus()
        subTraitBox:ReleaseFocus()
        rollsBox:ReleaseFocus()
        delayBox:ReleaseFocus()
        fakeRoll()
    end)

    applyBtn.Activated:Connect(function()
        traitBox:ReleaseFocus()
        subTraitBox:ReleaseFocus()
        delayBox:ReleaseFocus()
        applyFakeTrait(state.targetTrait, state.targetSubTrait)
    end)

    return gui
end

local function installRerollBlocker()
    if not TraitsUI then return end
    local buttons = TraitsUI:FindFirstChild("Buttons")
    local real = buttons and buttons:FindFirstChild("Reroll")
    if not real then return end

    local old = real:FindFirstChild("ASFakeBlocker")
    if old then old:Destroy() end

    local blocker = Instance.new("TextButton")
    blocker.Name = "ASFakeBlocker"
    blocker.AutoButtonColor = false
    blocker.BackgroundTransparency = 1
    blocker.Text = ""
    blocker.TextColor3 = Color3.fromRGB(255, 255, 255)
    blocker.Font = Enum.Font.GothamBold
    blocker.TextSize = 12
    blocker.Visible = state.visualEnabled == true
    blocker.Size = UDim2.fromScale(1, 1)
    blocker.Position = UDim2.fromScale(0, 0)
    blocker.ZIndex = (real.ZIndex or 1) + 10
    blocker.Parent = real
    blocker.Activated:Connect(function()
        if state.visualEnabled == true then
            fakeRoll()
        end
    end)
end

if not _G.ASFakeTraitReroll_NoOverlay then
    createOverlay()
end
installRerollBlocker()
installSummonBlocker()
updateVisualBlockers()
startEnforcer()

_G.ASFakeTraitReroll = {
    State = state,
    SetEnabled = function(enabled)
        setVisualEnabled(enabled)
    end,
    SetTrait = function(trait)
        if tierByTrait[trait] then
            state.targetTrait = trait
            saveState()
            return true
        end
        return false
    end,
    SetSubTrait = function(trait)
        trait = normalizeSubTrait(trait)
        state.targetSubTrait = trait or ""
        saveState()
        return true
    end,
    SetRolls = function(amount)
        state.rollsToHit = math.max(1, tonumber(amount) or state.rollsToHit or 1)
        saveState()
    end,
    SetRollDelay = function(seconds)
        state.rollDelay = math.clamp(tonumber(seconds) or state.rollDelay or 0.16, 0.05, 2)
        saveState()
    end,
    SetFakeShards = function(amount)
        state.fakeTraitShards = math.max(0, tonumber(amount) or state.fakeTraitShards or 0)
        saveState()
        renderFakeTraitShards()
    end,
    SetRollCost = function(amount)
        state.shardCostPerRoll = math.max(0, tonumber(amount) or state.shardCostPerRoll or 1)
        saveState()
    end,
    SetSubChance = function(percent)
        state.subTraitRollChance = math.clamp((tonumber(percent) or 35) / 100, 0, 1)
        saveState()
    end,
    SetFakeGems = function(amount)
        state.fakeGems = math.max(0, tonumber(amount) or state.fakeGems or 0)
        saveState()
        renderFakeGems()
    end,
    SetBanner = function(banner)
        banner = tostring(banner or "")
        if banner == "Basic Banner" or banner == "Selection Banner" then
            state.fakeSummonBanner = banner
            saveState()
            return true
        end
        return false
    end,
    SetSummonUnits = function(text)
        state.fakeSummonUnits = tostring(text or "")
        saveState()
    end,
    SetSummonShiny = function(text)
        state.fakeSummonShiny = tostring(text or "")
        saveState()
    end,
    FakeSummon = fakeSummon,
    Roll = fakeRoll,
    Apply = applyFakeTrait,
    Open = createOverlay,
    GetTraits = function()
        local copy = {}
        for _, trait in ipairs(allTraits) do table.insert(copy, trait) end
        return copy
    end,
    GetCharacters = getAllCharacterNames,
    SavePath = savePath
}

print("[FakeTrait] Loaded. Use _G.ASFakeTraitReroll.SetTrait('Superior'), SetRolls(10), Roll().")
