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

local localPlayerId = tostring(Players.LocalPlayer.UserId)
_G.AnimeSquadron_BasePath = "as_free/as_" .. localPlayerId
local basePath = _G.AnimeSquadron_BasePath

local function ensureFolder(path)
    if not isfolder then return end
    local current = ""
    for part in string.gmatch(path, "[^/]+") do
        current = current == "" and part or current .. "/" .. part
        if not isfolder(current) then
            pcall(function() makefolder(current) end)
        end
    end
end
pcall(function() ensureFolder(basePath) end)

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
        table.sort(traitMaps, function(a, b)
            if a.mode == b.mode then return a.world < b.world end
            return a.mode < b.mode
        end)
        
        if isfile and writefile then
            pcall(function()
                writefile(basePath .. "/MapsCache.json", HttpService:JSONEncode(traitMaps))
            end)
        end
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
            pcall(function() writefile(basePath .. "/MatCache.json", HttpService:JSONEncode(_G.MATERIAL_DROPS)) end)
        end
    else
        local function loadCache()
            if isfile and readfile and isfile(basePath .. "/MatCache.json") then
                pcall(function() _G.MATERIAL_DROPS = HttpService:JSONDecode(readfile(basePath .. "/MatCache.json")) end)
            end
            if isfile and readfile and isfile(basePath .. "/MapsCache.json") then
                local succ2, data2 = pcall(function() return HttpService:JSONDecode(readfile(basePath .. "/MapsCache.json")) end)
                if succ2 and type(data2) == "table" then
                    traitMaps = data2
                end
            end
        end
        loadCache()
    end
else
    local function loadCache()
        if isfile and readfile and isfile(basePath .. "/MatCache.json") then
            pcall(function() _G.MATERIAL_DROPS = HttpService:JSONDecode(readfile(basePath .. "/MatCache.json")) end)
        end
        if isfile and readfile and isfile(basePath .. "/MapsCache.json") then
            local succ, data = pcall(function() return HttpService:JSONDecode(readfile(basePath .. "/MapsCache.json")) end)
            if succ and type(data) == "table" then
                traitMaps = data
            end
        end
    end
    loadCache()
end

local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end
local makefolder = makefolder or function() end
local isfolder = isfolder or function() return false end

if not isfolder("as_free") then pcall(function() makefolder("as_free") end) end

if not isfile("as_free/Language.txt") then
    local CoreGui = game:GetService("CoreGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "LanguageSetupGUI"
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local protect = syn and syn.protect_gui or protectgui
    if protect then pcall(function() protect(sg) end) end
    pcall(function() sg.Parent = CoreGui end)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(350, 200)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BorderSizePixel = 0
    frame.Parent = sg
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Select Language / Chọn Ngôn Ngữ"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 60)
    desc.Position = UDim2.new(0, 20, 0, 45)
    desc.BackgroundTransparency = 1
    desc.Text = "Please select your preferred language.\nVui lòng chọn ngôn ngữ của bạn."
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextWrapped = true
    desc.Parent = frame
    
    local btnEn = Instance.new("TextButton")
    btnEn.Size = UDim2.new(0, 120, 0, 40)
    btnEn.Position = UDim2.new(0, 40, 1, -60)
    btnEn.BackgroundColor3 = Color3.fromRGB(50, 100, 255)
    btnEn.Text = "English"
    btnEn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnEn.Font = Enum.Font.GothamBold
    btnEn.TextSize = 14
    btnEn.Parent = frame
    
    local uc1 = Instance.new("UICorner")
    uc1.CornerRadius = UDim.new(0, 6)
    uc1.Parent = btnEn
    
    local btnVn = Instance.new("TextButton")
    btnVn.Size = UDim2.new(0, 120, 0, 40)
    btnVn.Position = UDim2.new(1, -160, 1, -60)
    btnVn.BackgroundColor3 = Color3.fromRGB(50, 100, 255)
    btnVn.Text = "Tiếng Việt"
    btnVn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnVn.Font = Enum.Font.GothamBold
    btnVn.TextSize = 14
    btnVn.Parent = frame
    
    local uc2 = Instance.new("UICorner")
    uc2.CornerRadius = UDim.new(0, 6)
    uc2.Parent = btnVn
    
    local languageSelected = false
    
    btnEn.MouseButton1Click:Connect(function()
        pcall(function() if not isfolder("as_free") then makefolder("as_free") end end)
        pcall(function() writefile("as_free/Language.txt", "EN") end)
        languageSelected = true
    end)
    
    btnVn.MouseButton1Click:Connect(function()
        pcall(function() if not isfolder("as_free") then makefolder("as_free") end end)
        pcall(function() writefile("as_free/Language.txt", "VN") end)
        languageSelected = true
    end)
    
    while not languageSelected do
        task.wait(0.1)
    end
    
    sg:Destroy()
    task.wait(0.5)
end

local currentLang = "EN"
pcall(function()
    if isfile("as_free/Language.txt") then
        local l = readfile("as_free/Language.txt")
        if l == "VN" or l == "EN" then currentLang = l end
    end
end)

local Locales = {
    EN = {
        WinTitle = "🇻🇳 Free HUB", WinSub = "Anime Squadron",
        TabAutoFarm = "Auto Farm", TabPriority = "Priority Settings", TabMaps = "Trait Maps", TabEvo = "Evo & Craft", TabReroll = "Auto Reroll", TabShop = "Shop & Upgrades", TabClaims = "Claims & Misc", TabSniper = "Challenge Sniper", TabIngame = "Ingame Helper", TabParty = "Party & Multi", TabWebhook = "Webhook", TabSettings = "Settings",
        
        StuckAutoHop = "Auto Server Hop (Stuck Failsafe)", StuckAutoHopD = "Automatically hops to another server if stuck in the Lobby for too long.",
        StuckTimeout = "Stuck Timeout (Seconds)", StuckTimeoutD = "Time in seconds before hopping.",
        SniperCfg = "Sniper Configuration", SniperCfgD = "Used in Lobby. Checked with highest priority.",
        Snip1d = "Enable Daily Challenge (1d)", Snip1dD = "Auto joins the daily challenge.",
        Snip30m = "Enable Regular Challenge (30m)", Snip30mD = "Auto joins the regular 30m challenge.",
        SnipTarget = "Target Items (Regular 30m)", SnipTargetD = "Select which items you want to snipe.",
        
        MapCfg = "Configuration Guide", MapCfgD = "Enter 'Priority' (lower number = higher priority). Enter 0 to skip.",
        MapNoData = "No Data Found", MapNoDataD = "Execute this script in the Lobby at least once to cache Map data!",
        MapTrack = "Tracking current limit.", MapPriority = "Priority (0 = Skip)", MapPriorityD = "Set priority for this map.", MapDiff = "Difficulty", MapDiffD = "Select Normal or Hard.",
        
        IgUtil = "Ingame Utilities", IgUtilD = "Only active during a match.",
        IgAutoPlay = "ENABLE Official Auto Play", IgAutoPlayD = "Turns on the game's official Auto Play feature.",
        IgAutoLeave = "ENABLE Auto Leave (On Max Limit/Cant Replay)", IgAutoLeaveD = "Leaves match if you hit cap limit.",
        IgAutoLeaveBase = "ENABLE Auto Leave (Base 0 HP Failsafe)", IgAutoLeaveBaseD = "Leaves match instantly if base HP hits 0 to save time.",
        IgAutoReplay = "ENABLE Auto Replay", IgAutoReplayD = "Auto replays the match when it ends.",
        IgReplayInf = "ENABLE Auto Replay at Wave (Inf Mode)", IgReplayInfD = "Auto replays when hitting a specific wave in Infinite Mode.",
        IgWaveTarget = "Target Wave to Replay", IgWaveTargetD = "Wave number to trigger replay.",
        IgSpeed = "ENABLE Auto Speed (Max 2x/3x)", IgSpeedD = "Automatically clicks the 2x/3x speed button.",
        IgUlt = "ENABLE Auto Ultimate", IgUltD = "Only uses ultimate when enemies are present.",
        IgSniper = "Challenge Sniper Sync", IgSniperD = "Automatically return to lobby around XX:00 and XX:30 to check new challenges.",
        IgSniperTog = "ENABLE Sniper Sync", IgSniperTogD = "Leaves match early to catch challenges.",
        IgSniperMode = "Sync Mode", IgSniperModeD = "Safe = waits for match end. Instant = leaves immediately.",
        
        EvoPri = "Evo & Craft Priority", EvoPriD = "Runs in the Lobby. Lower priority than Auto Quest. Evo and Craft will NOT run simultaneously.",
        EvoTarget = "Evo Target", EvoTargetD = "Select the unit to evolve.",
        EvoToggle = "ENABLE Auto Evo", EvoToggleD = "Auto evolves the selected unit.",
        CraftTarget = "Craft Target", CraftTargetD = "Select item to craft.",
        CraftQty = "Quantity to Craft", CraftQtyD = "How many to craft.",
        CraftQueue = "Crafting Queue", CraftQueueD = "Current tasks.",
        CraftAdd = "Add to Queue", CraftAddD = "Add currently selected item and quantity to queue.",
        CraftClear = "Clear Queue", CraftClearD = "Remove all items from queue.",
        CraftToggle = "ENABLE Auto Craft", CraftToggleD = "Auto crafts items in the queue.",
        
        RerollCfg = "Auto Stat Reroll", RerollCfgD = "Select a unit. It will automatically lock the specified stats and reroll when Potential reaches 100%.",
        RerollUnit = "Select Unit", RerollUnitD = "Target unit for rerolling.",
        RerollLock = "Stats to Lock", RerollLockD = "Keep these stats, don't reroll them.",
        RerollTog = "ENABLE Auto Reroll (100% Potential)", RerollTogD = "Auto rerolls when max potential is reached.",
        
        ShopDyn = "Dynamic Shops", ShopDynD = "Merchant lists all possible items. Raid/Event refresh automatically.",
        MerchItem = "[Merchant] Target Item", MerchItemD = "Items to buy from regular merchant.",
        MerchTog = "ENABLE Auto Buy [Merchant]", MerchTogD = "Buys targeted items automatically.",
        RaidItem = "[Raid] Target Item", RaidItemD = "Items to buy from Raid shop.",
        RaidTog = "ENABLE Auto Buy [Raid Shop]", RaidTogD = "Buys targeted items automatically.",
        EventItem = "[Event] Target Item", EventItemD = "Items to buy from Event shop.",
        EventTog = "ENABLE Auto Buy [Event Shop]", EventTogD = "Buys targeted items automatically.",
        PerkCfg = "Perks Upgrades", PerkCfgD = "Auto upgrade your base stats.",
        PerkTarget = "Perk Target", PerkTargetD = "Stat to upgrade.",
        PerkTog = "ENABLE Auto Perk Upgrade", PerkTogD = "Auto buys perk upgrades.",
        
        ClaimCfg = "Auto Claims", ClaimCfgD = "Automatically claims passive rewards.",
        ClaimPass = "ENABLE Auto Battlepass", ClaimPassD = "Claims free pass rewards.",
        ClaimMile = "ENABLE Auto Level Milestones", ClaimMileD = "Claims level rewards.",
        ClaimIdx = "ENABLE Auto Discovery Index", ClaimIdxD = "Claims index rewards.",
        CodeCfg = "Code Redeemer", CodeCfgD = "Auto redeem predefined codes and dynamically scan Update Log.",
        CodeBtn = "Redeem All Codes", CodeBtnD = "Sends all known codes to the server.",
        CodeMsgT = "Redeeming Codes", CodeMsg = "Sending codes to server. Check game UI for rewards!",
        
        AF_StatL = "Status: LOBBY", AF_StatLD = "Master Auto Farm system is ready.",
        AF_StatI = "Status: INGAME", AF_StatID = "NOTE: Auto Farm functions will NOT operate while in-game. It will resume automatically in the Lobby.",
        AF_Sess = "Session Stats (Farmed Today)", AF_SessD = "Matches Played: 0",
        AF_Friend = "Friends Only", AF_FriendD = "Creates rooms as Friends Only.",
        AF_Daily = "Auto Claim Daily Rewards", AF_DailyD = "Claims daily login rewards.",
        AF_Bun = "Auto Claim Free Bundle", AF_BunD = "Claims the free bundle in shop.",
        AF_Quest = "Auto Quest", AF_QuestD = "Auto accepts and claims quests.",
        AF_Master = "ENABLE MASTER AUTO FARM", AF_MasterD = "Turns on the entire Auto Farm logic.",
        
        PriCfg = "Task Priority", PriCfgD = "Configure which auto farm tasks have priority over others. If a task has no work to do, it will fallback to the next priority. If all tasks are done, it defaults to Auto Farm Map.",
        Pri1 = "Priority 1 (Highest)", Pri1D = "Runs first.",
        Pri2 = "Priority 2", Pri2D = "Runs second.",
        Pri3 = "Priority 3", Pri3D = "Runs third.",
        Pri4 = "Priority 4", Pri4D = "Runs last.",
        
        PtCfg = "Auto Party System", PtCfgD = "Play with your alt accounts automatically.",
        PtTog = "ENABLE Party Mode", PtTogD = "Turns on the party system.",
        PtRole = "Party Role", PtRoleD = "Host creates room, Member joins.",
        PtSync = "Sync Leave", PtSyncD = "Return to Lobby if ANY player leaves.",
        PtHostCfg = "Host Settings", PtHostCfgD = "If you are Host, specify EXACT usernames of members to wait for.",
        PtM1 = "Wait for Member 1", PtM1D = "Username of Clone 1.",
        PtM2 = "Wait for Member 2", PtM2D = "Username of Clone 2.",
        PtM3 = "Wait for Member 3", PtM3D = "Username of Clone 3.",
        PtTime = "Host Wait Timeout (Minutes)", PtTimeD = "Start without them if they take too long.",
        PtMemCfg = "Member Settings", PtMemCfgD = "If you are a Member, specify the EXACT username of the Host you want to follow.",
        PtHostName = "Host Username", PtHostNameD = "Username of your Main account.",
        
        WbCfg = "Discord Webhook", WbCfgD = "Automatic status reporter.",
        WbUrl = "Webhook URL", WbUrlD = "Link to your discord webhook.",
        WbDrop = "Send on Item Drop (Traits/Cubes)", WbDropD = "Alerts you when rare items drop.",
        WbMatch = "Send on Match End (Win/Loss)", WbMatchD = "Sends match results.",
        WbInt = "Send on Interval", WbIntD = "Sends periodic summary.",
        WbEvo = "Send on Evo/Craft (Success/Fail)", WbEvoD = "Alerts on craft results.",
        WbTime = "Interval (Minutes)", WbTimeD = "How often to send summary.",
        
        SetLang = "Language / Ngôn ngữ", SetLangD = "Select UI language. Tắt Script đi mở lại để áp dụng!"
    },
    VN = {
        WinTitle = "🇻🇳 Free HUB", WinSub = "Anime Squadron",
        TabAutoFarm = "Auto Farm", TabPriority = "Cài đặt Ưu tiên", TabMaps = "Bản đồ Trait", TabEvo = "Tiến hoá & Ghép", TabReroll = "Auto Đập Chỉ số", TabShop = "Cửa hàng & Nâng cấp", TabClaims = "Nhận thưởng & Code", TabSniper = "Săn Challenge", TabIngame = "Hỗ trợ Trong Game", TabParty = "Tổ đội (Nhiều Acc)", TabWebhook = "Thông báo Webhook", TabSettings = "Cài đặt (Settings)",
        
        StuckAutoHop = "BẬT Tự động Đổi Server (Chống Kẹt)", StuckAutoHopD = "Tự động tìm server khác nếu kẹt ở Sảnh quá lâu.",
        StuckTimeout = "Thời gian chờ Kẹt (Giây)", StuckTimeoutD = "Số giây kẹt trước khi đổi server.",
        SniperCfg = "Cấu hình Săn Challenge", SniperCfgD = "Chỉ chạy ở sảnh (Lobby). Độ ưu tiên cao nhất, luôn được check đầu tiên.",
        Snip1d = "Bật Săn Thử thách Hàng ngày (1d)", Snip1dD = "Tự động vào map Thử thách Hàng ngày.",
        Snip30m = "Bật Săn Thử thách Thường (30m)", Snip30mD = "Tự động vào map 30 phút mỗi khi làm mới.",
        SnipTarget = "Mục tiêu Săn (30m)", SnipTargetD = "Chọn các vật phẩm bạn muốn săn.",
        
        MapCfg = "Hướng dẫn Cài đặt Map", MapCfgD = "Nhập 'Priority' (độ ưu tiên: số càng nhỏ càng ưu tiên). Nhập 0 để bỏ qua map đó.",
        MapNoData = "Chưa có dữ liệu", MapNoDataD = "Hãy chạy Script ở sảnh (Lobby) ít nhất 1 lần để tải dữ liệu Map!",
        MapTrack = "Đang theo dõi giới hạn.", MapPriority = "Độ Ưu Tiên (0 = Bỏ qua)", MapPriorityD = "Thiết lập mức độ ưu tiên cho map này.", MapDiff = "Độ Khó", MapDiffD = "Chọn Normal (Thường) hoặc Hard (Khó).",
        
        IgUtil = "Tiện ích Trong Game", IgUtilD = "Chỉ hoạt động khi đang ở trong trận đấu.",
        IgAutoPlay = "BẬT Auto Play của Game", IgAutoPlayD = "Tự động kích hoạt nút Auto Play có sẵn của game.",
        IgAutoLeave = "BẬT Tự động Rời Trận (Mắc giới hạn)", IgAutoLeaveD = "Tự rời ván nếu bạn đã cày đủ max giới hạn (Nguyên liệu evo, trait limit).",
        IgAutoLeaveBase = "BẬT Tự động Rời Trận (Bảo vệ Base)", IgAutoLeaveBaseD = "Tự rời ván ngay lập tức nếu nhà chính (Base) còn 0 máu để tiết kiệm thời gian.",
        IgAutoReplay = "BẬT Tự động Chơi lại", IgAutoReplayD = "Tự động bấm chơi lại khi hết ván.",
        IgReplayInf = "BẬT Chơi lại ở Wave (Chế độ Vô tận)", IgReplayInfD = "Tự động chơi lại khi đạt đến số Wave chỉ định ở chế độ Vô tận.",
        IgWaveTarget = "Mục tiêu Wave để Chơi lại", IgWaveTargetD = "Số wave để kích hoạt chơi lại.",
        IgSpeed = "BẬT Tự động Tua Nhanh (Max 2x/3x)", IgSpeedD = "Tự động bấm nút tua nhanh 2x hoặc 3x.",
        IgUlt = "BẬT Tự động dùng Chiêu cuối (Ultimate)", IgUltD = "Chỉ sử dụng chiêu cuối khi có quái trên bản đồ.",
        IgSniper = "Đồng bộ Săn Challenge", IgSniperD = "Tự động quay về sảnh lúc XX:00 và XX:30 để canh Challenge mới.",
        IgSniperTog = "BẬT Đồng bộ Săn Challenge", IgSniperTogD = "Rời trận sớm để kịp giờ săn.",
        IgSniperMode = "Chế độ Đồng bộ", IgSniperModeD = "Safe = Đợi hết ván mới out. Instant = Thoát ngay lập tức bất chấp.",
        
        EvoPri = "Cài đặt Tiến hoá & Ghép", EvoPriD = "Chỉ chạy ở sảnh. Độ ưu tiên thấp hơn Nhiệm vụ. Evo và Craft sẽ KHÔNG chạy cùng lúc để tránh kẹt.",
        EvoTarget = "Mục tiêu Tiến hoá", EvoTargetD = "Chọn nhân vật bạn muốn tiến hoá.",
        EvoToggle = "BẬT Tự động Tiến hoá (Auto Evo)", EvoToggleD = "Tự động tiến hoá nhân vật đã chọn khi đủ nguyên liệu.",
        CraftTarget = "Mục tiêu Ghép (Craft)", CraftTargetD = "Chọn vật phẩm bạn muốn ghép.",
        CraftQty = "Số lượng cần Ghép", CraftQtyD = "Số lượng vật phẩm cần tạo ra.",
        CraftQueue = "Hàng đợi Ghép", CraftQueueD = "Danh sách các vật phẩm đang chờ ghép.",
        CraftAdd = "Thêm vào Hàng đợi", CraftAddD = "Thêm vật phẩm và số lượng hiện tại vào hàng đợi.",
        CraftClear = "Xoá Hàng đợi", CraftClearD = "Xoá toàn bộ vật phẩm khỏi hàng đợi.",
        CraftToggle = "BẬT Tự động Ghép (Auto Craft)", CraftToggleD = "Tự động ghép các vật phẩm trong hàng đợi.",
        
        RerollCfg = "Tự động Đập Chỉ số (Trait)", RerollCfgD = "Chọn nhân vật và các dòng chỉ số cần giữ lại. Nó sẽ tự động khoá dòng và đập khi Thanh Tiềm Năng (Potential) đạt 100%.",
        RerollUnit = "Chọn Nhân Vật", RerollUnitD = "Nhân vật mục tiêu để đập chỉ số.",
        RerollLock = "Các Chỉ số cần Giữ (Khoá)", RerollLockD = "Giữ lại những dòng này, không đập mất.",
        RerollTog = "BẬT Tự động Đập Chỉ số", RerollTogD = "Chỉ đập khi Tiềm năng max 100%.",
        
        ShopDyn = "Cửa hàng Thông minh", ShopDynD = "Thương gia (Merchant) hiển thị toàn bộ đồ. Raid/Event tự động làm mới.",
        MerchItem = "[Thương Gia] Mục tiêu Mua", MerchItemD = "Chọn đồ muốn mua từ Thương gia.",
        MerchTog = "BẬT Tự động Mua [Thương Gia]", MerchTogD = "Tự động mua đồ đã chọn khi thương gia xuất hiện.",
        RaidItem = "[Raid Shop] Mục tiêu Mua", RaidItemD = "Chọn đồ muốn mua từ Raid Shop.",
        RaidTog = "BẬT Tự động Mua [Raid Shop]", RaidTogD = "Tự động gom đồ Raid Shop đã chọn.",
        EventItem = "[Event Shop] Mục tiêu Mua", EventItemD = "Chọn đồ muốn mua từ Event Shop.",
        EventTog = "BẬT Tự động Mua [Event Shop]", EventTogD = "Tự động gom đồ Event Shop đã chọn.",
        PerkCfg = "Nâng cấp Bổ trợ (Perks)", PerkCfgD = "Tự động nâng cấp các chỉ số cơ bản của bạn.",
        PerkTarget = "Mục tiêu Nâng cấp", PerkTargetD = "Chỉ số muốn nâng (Máu, Tiền...).",
        PerkTog = "BẬT Tự động Nâng Bổ trợ", PerkTogD = "Tự động mua khi đủ vàng.",
        
        ClaimCfg = "Tự động Nhận thưởng", ClaimCfgD = "Tự động nhận các phần thưởng treo.",
        ClaimPass = "BẬT Tự động Nhận Battlepass", ClaimPassD = "Nhận thẻ ưu đãi miễn phí.",
        ClaimMile = "BẬT Tự động Nhận Quà Cấp độ", ClaimMileD = "Nhận quà khi lên cấp.",
        ClaimIdx = "BẬT Tự động Nhận Quà Bộ Sưu Tập", ClaimIdxD = "Nhận quà từ Index.",
        CodeCfg = "Tự động Nhập Code", CodeCfgD = "Tự động nhập code cũ và tự động quét update log để tìm code mới.",
        CodeBtn = "Nhập Tất cả Code", CodeBtnD = "Gửi toàn bộ code vào game.",
        CodeMsgT = "Đang Nhập Code", CodeMsg = "Đang gửi code tới máy chủ. Vui lòng kiểm tra màn hình game!",
        
        AF_StatL = "Trạng thái: ĐANG Ở SẢNH", AF_StatLD = "Hệ thống Master Auto Farm đã sẵn sàng chạy.",
        AF_StatI = "Trạng thái: ĐANG TRONG TRẬN", AF_StatID = "LƯU Ý: Các chức năng Auto Farm Lobbby sẽ KHÔNG hoạt động khi ở trong trận. Nó sẽ tự tiếp tục khi về Sảnh.",
        AF_Sess = "Thống kê Cày cuốc (Hôm nay)", AF_SessD = "Số trận đã chơi: 0",
        AF_Friend = "Chế độ Chỉ Bạn Bè (Friends Only)", AF_FriendD = "Tạo phòng không cho người lạ vào.",
        AF_Daily = "Tự động Nhận Quà Đăng nhập", AF_DailyD = "Nhận quà điểm danh hàng ngày.",
        AF_Bun = "Tự động Nhận Quà Miễn phí", AF_BunD = "Nhận gói quà Free trong Shop.",
        AF_Quest = "Tự động Làm Nhiệm vụ", AF_QuestD = "Tự động nhận và trả nhiệm vụ.",
        AF_Master = "BẬT MASTER AUTO FARM (TRẠNG THÁI CHÍNH)", AF_MasterD = "Công tắc tổng. Bật cái này thì mọi chuỗi Auto mới bắt đầu chạy.",
        
        PriCfg = "Cài đặt Mức độ Ưu tiên", PriCfgD = "Tuỳ chỉnh xem cái nào chạy trước, cái nào chạy sau. Nếu cái số 1 không có gì để làm, nó sẽ làm cái số 2. Nếu xong hết, nó sẽ tự động tạo map đi farm.",
        Pri1 = "Ưu tiên 1 (Cao nhất)", Pri1D = "Chạy đầu tiên.",
        Pri2 = "Ưu tiên 2", Pri2D = "Chạy thứ hai.",
        Pri3 = "Ưu tiên 3", Pri3D = "Chạy thứ ba.",
        Pri4 = "Ưu tiên 4", Pri4D = "Chạy cuối cùng.",
        
        PtCfg = "Hệ thống Tổ đội Tự động", PtCfgD = "Chơi chung với các acc Clone của bạn một cách hoàn toàn tự động.",
        PtTog = "BẬT Chế độ Tổ đội (Party Mode)", PtTogD = "Kích hoạt hệ thống kéo acc.",
        PtRole = "Vai trò Tổ đội", PtRoleD = "Host (Chủ phòng): Tạo phòng và kéo đệ. Member (Đệ tử): Tắt mọi Auto, chỉ ngoan ngoãn đi theo Host.",
        PtSync = "Đồng bộ Rời Trận", PtSyncD = "Nếu 1 acc bị văng hoặc thoát, cả team sẽ tự động thoát theo về sảnh.",
        PtHostCfg = "Cài đặt Chủ Phòng (Host)", PtHostCfgD = "Nếu bạn là Chủ phòng, ghi chính xác Tên nhân vật (Username) của các đệ tử vào đây để đợi.",
        PtM1 = "Đợi Đệ tử 1", PtM1D = "Tên nhân vật của Clone 1.",
        PtM2 = "Đợi Đệ tử 2", PtM2D = "Tên nhân vật của Clone 2.",
        PtM3 = "Đợi Đệ tử 3", PtM3D = "Tên nhân vật của Clone 3.",
        PtTime = "Thời gian Đợi (Phút)", PtTimeD = "Nếu quá thời gian này mà đệ tử bị crash chưa vào kịp, Host sẽ tự động kích đệ và vào trận luôn.",
        PtMemCfg = "Cài đặt Đệ Tử (Member)", PtMemCfgD = "Nếu bạn là Đệ tử, ghi chính xác Tên nhân vật Chủ phòng mà bạn muốn đi theo.",
        PtHostName = "Tên Chủ Phòng", PtHostNameD = "Tên nhân vật của Acc Chính.",
        
        WbCfg = "Thông báo Discord (Webhook)", WbCfgD = "Bot tự động gửi báo cáo cày cuốc.",
        WbUrl = "Link Webhook", WbUrlD = "Dán link Discord Webhook của bạn vào đây.",
        WbDrop = "Báo cáo Rớt đồ (Traits/Cubes)", WbDropD = "Gửi thông báo khi bạn nhặt được đồ hiếm.",
        WbMatch = "Báo cáo Hết Trận (Thắng/Thua)", WbMatchD = "Gửi thống kê sau mỗi ván chơi.",
        WbInt = "Báo cáo Định kỳ", WbIntD = "Gửi tóm tắt tình trạng cày cuốc theo chu kỳ.",
        WbEvo = "Báo cáo Tiến hoá/Ghép", WbEvoD = "Gửi thông báo khi Ghép đồ Thành công hay Thất bại.",
        WbTime = "Chu kỳ Báo cáo (Phút)", WbTimeD = "Cứ sau bao nhiêu phút thì gửi 1 báo cáo tổng hợp.",
        
        SetLang = "Language / Ngôn ngữ", SetLangD = "Choose language. Tắt Script đi mở lại để áp dụng / Restart Script to apply!"
    }
}

local L = Locales[currentLang]

local Window = Fluent:CreateWindow({
    Title = L.WinTitle,
    SubTitle = L.WinSub,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    AutoFarm = Window:AddTab({ Title = L.TabAutoFarm, Icon = "play" }),
    Priority = Window:AddTab({ Title = L.TabPriority, Icon = "list-ordered" }),
    Maps = Window:AddTab({ Title = L.TabMaps, Icon = "map" }),
    EvoCraft = Window:AddTab({ Title = L.TabEvo, Icon = "hammer" }),
    AutoReroll = Window:AddTab({ Title = L.TabReroll, Icon = "dices" }),
    ShopUpgrade = Window:AddTab({ Title = L.TabShop, Icon = "shopping-cart" }),
    Claims = Window:AddTab({ Title = L.TabClaims, Icon = "gift" }),
    Sniper = Window:AddTab({ Title = L.TabSniper, Icon = "target" }),
    Ingame = Window:AddTab({ Title = L.TabIngame, Icon = "swords" }),
    PartyMulti = Window:AddTab({ Title = L.TabParty, Icon = "users" }),
    Webhook = Window:AddTab({ Title = L.TabWebhook, Icon = "link" }),
    Settings = Window:AddTab({ Title = L.TabSettings, Icon = "settings" })
}

local Options = Fluent.Options

local itemsList = {"Trait Shards", "Reroll Cubes", "Perfect Cubes", "Gems", "Gold"}

Tabs.Sniper:AddParagraph({ Title = L.SniperCfg, Content = L.SniperCfgD })

local Toggle1d = Tabs.Sniper:AddToggle("AutoJoin1d", { Title = L.Snip1d, Description = L.Snip1dD, Default = false })
local Toggle30m = Tabs.Sniper:AddToggle("AutoJoin30m", { Title = L.Snip30m, Description = L.Snip30mD, Default = false })

local itemDropdown = Tabs.Sniper:AddDropdown("TargetItem30m", {
    Title = L.SnipTarget,
    Description = L.SnipTargetD,
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
Tabs.Maps:AddParagraph({ Title = L.MapCfg, Content = L.MapCfgD })

if #traitMaps == 0 then
    Tabs.Maps:AddParagraph({ Title = L.MapNoData, Content = L.MapNoDataD })
else
    for i, map in ipairs(traitMaps) do
        local capStr = get_cap_string(map.mode, map.world, map.act, "Trait Shards")
        local titleStr = string.format("[%s] %s (Act %d)", map.mode, map.world, map.act)
        
        local paragraph = Tabs.Maps:AddParagraph({ Title = titleStr, Content = L.MapTrack })
        
        local input = Tabs.Maps:AddInput("Priority_"..i, {
            Title = L.MapPriority,
            Description = L.MapPriorityD,
            Default = tostring(i),
            Numeric = true,
            Finished = false,
        })
        
        local diff = Tabs.Maps:AddDropdown("Diff_"..i, {
            Title = L.MapDiff,
            Description = L.MapDiffD,
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

Tabs.Ingame:AddParagraph({ Title = L.IgUtil, Content = L.IgUtilD })
local ToggleAutoPlay = Tabs.Ingame:AddToggle("AutoPlayToggle", { Title = L.IgAutoPlay, Description = L.IgAutoPlayD, Default = false })
local ToggleLeave = Tabs.Ingame:AddToggle("AutoLeaveToggle", { Title = L.IgAutoLeave, Description = L.IgAutoLeaveD, Default = false })
local ToggleLeaveBase = Tabs.Ingame:AddToggle("AutoLeaveBaseFailsafe", { Title = L.IgAutoLeaveBase, Description = L.IgAutoLeaveBaseD, Default = false })
local ToggleReplay = Tabs.Ingame:AddToggle("AutoReplayToggle", { Title = L.IgAutoReplay, Description = L.IgAutoReplayD, Default = false })
local ToggleReplayAtWave = Tabs.Ingame:AddToggle("AutoReplayAtWave", { Title = L.IgReplayInf, Description = L.IgReplayInfD, Default = false })
local InputReplayWave = Tabs.Ingame:AddInput("ReplayWaveTarget", { Title = L.IgWaveTarget, Description = L.IgWaveTargetD, Default = "30", Numeric = true, Finished = false })
local ToggleSpeed = Tabs.Ingame:AddToggle("AutoSpeedToggle", { Title = L.IgSpeed, Description = L.IgSpeedD, Default = false })
local ToggleUltimate = Tabs.Ingame:AddToggle("AutoUltimateToggle", { Title = L.IgUlt, Description = L.IgUltD, Default = false })

Tabs.Ingame:AddParagraph({ Title = L.IgSniper, Content = L.IgSniperD })
local ToggleSniperSync = Tabs.Ingame:AddToggle("AutoSniperSync", { Title = L.IgSniperTog, Description = L.IgSniperTogD, Default = false })
local DropdownSniperSyncMode = Tabs.Ingame:AddDropdown("SniperSyncMode", {
    Title = L.IgSniperMode,
    Description = L.IgSniperModeD,
    Values = {"Safe (At EndScreen)", "Instant (Abort Match)"},
    Multi = false,
    Default = 1,
})
Tabs.EvoCraft:AddParagraph({ Title = L.EvoPri, Content = L.EvoPriD })

local function getSavedTarget(key, defaultVal)
    local saved = defaultVal
    if isfile and readfile and isfile(basePath .. "/AutoFarm/settings/AutoSave.json") then
        local succ, content = pcall(function() return readfile(basePath .. "/AutoFarm/settings/AutoSave.json") end)
        if succ and type(content) == "string" then
            local match = string.match(content, '"idx"%s*:%s*"' .. key .. '".-"value"%s*:%s*"([^"]+)"')
            if match then saved = match end
        end
    end
    return saved
end

local initEvo = getSavedTarget("EvoTarget", "(Waiting for Inventory...)")
local DropdownEvoTarget = Tabs.EvoCraft:AddDropdown("EvoTarget", { Title = L.EvoTarget, Description = L.EvoTargetD, Values = {initEvo}, Multi = false, Default = 1 })

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
local ToggleAutoEvo = Tabs.EvoCraft:AddToggle("AutoEvo", { Title = L.EvoToggle, Description = L.EvoToggleD, Default = false })

Tabs.EvoCraft:AddParagraph({ Title = "---", Content = "" })

local initCraft = getSavedTarget("CraftTarget", "(Loading Craftables...)")
local DropdownCraftTarget = Tabs.EvoCraft:AddDropdown("CraftTarget", { Title = L.CraftTarget, Description = L.CraftTargetD, Values = {initCraft}, Multi = false, Default = 1 })

task.spawn(function()
    local craftTargets = {}
    local craftingFolder = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Crafting")
    if craftingFolder then
        local get = craftingFolder:WaitForChild("get", 5)
        if get then
        local succ, recipes = pcall(function() return get:InvokeServer() end)
        if succ and type(recipes) == "table" then
            _G.AnimeSquadron_Recipes = recipes
            for name, _ in pairs(recipes) do
                table.insert(craftTargets, name)
            end
            if _G.AnimeSquadron_UpdateCraftQueueUI then
                _G.AnimeSquadron_UpdateCraftQueueUI()
            end
        end
        end
    end
    table.sort(craftTargets)
    if #craftTargets == 0 then table.insert(craftTargets, "(None)") end
    local currentCraft = Options.CraftTarget and Options.CraftTarget.Value
    DropdownCraftTarget:SetValues(craftTargets)
    if currentCraft then DropdownCraftTarget:SetValue(currentCraft) end
end)
local InputCraftQty = Tabs.EvoCraft:AddInput("CraftQty", { Title = L.CraftQty, Description = L.CraftQtyD, Default = "1", Numeric = true, Finished = false })

_G.AnimeSquadron_CraftQueue = {}
if isfile and readfile and isfile(basePath .. "/CraftQueue.json") then
    pcall(function()
        local data = game:GetService("HttpService"):JSONDecode(readfile(basePath .. "/CraftQueue.json"))
        if type(data) == "table" then
            _G.AnimeSquadron_CraftQueue = data
        end
    end)
end

_G.AnimeSquadron_UpdateCraftQueueUI = function() end

local CraftQueuePara = Tabs.EvoCraft:AddParagraph({ Title = L.CraftQueue, Content = L.CraftQueueD })
local CraftReqPara = Tabs.EvoCraft:AddParagraph({ Title = currentLang == "VN" and "Tổng Nguyên Liệu Cần" or "Total Materials Required", Content = "0" })

_G.AnimeSquadron_UpdateCraftQueueUI = function()
    if #_G.AnimeSquadron_CraftQueue == 0 then
        CraftQueuePara:SetDesc(L.CraftQueueD)
        CraftReqPara:SetDesc(currentLang == "VN" and "Trống" or "Empty")
    else
        local lines = {}
        local totalMats = {}
        for i, task in ipairs(_G.AnimeSquadron_CraftQueue) do
            table.insert(lines, tostring(i) .. ". " .. task.name .. " x" .. task.qty)
            if _G.AnimeSquadron_Recipes and _G.AnimeSquadron_Recipes[task.name] then
                for matName, amt in pairs(_G.AnimeSquadron_Recipes[task.name]) do
                    totalMats[matName] = (totalMats[matName] or 0) + (amt * task.qty)
                end
            end
        end
        CraftQueuePara:SetDesc(table.concat(lines, "\n"))
        
        local matLines = {}
        for matName, amt in pairs(totalMats) do
            table.insert(matLines, "- " .. matName .. ": " .. tostring(amt))
        end
        table.sort(matLines)
        if #matLines == 0 then
            CraftReqPara:SetDesc(currentLang == "VN" and "Đang tải dữ liệu..." or "Loading data...")
        else
            CraftReqPara:SetDesc(table.concat(matLines, "\n"))
        end
    end
    if isfile and writefile then
        pcall(function() writefile(basePath .. "/CraftQueue.json", game:GetService("HttpService"):JSONEncode(_G.AnimeSquadron_CraftQueue)) end)
    end
end
_G.AnimeSquadron_UpdateCraftQueueUI()

Tabs.EvoCraft:AddButton({
    Title = L.CraftAdd,
    Description = L.CraftAddD,
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
    Title = L.CraftClear,
    Description = L.CraftClearD,
    Callback = function()
        _G.AnimeSquadron_CraftQueue = {}
        _G.AnimeSquadron_UpdateCraftQueueUI()
        Fluent:Notify({ Title = "Craft Queue", Content = "Queue cleared.", Duration = 2 })
    end
})

local ToggleAutoCraft = Tabs.EvoCraft:AddToggle("AutoCraft", { Title = L.CraftToggle, Description = L.CraftToggleD, Default = false })
Tabs.AutoReroll:AddParagraph({ Title = L.RerollCfg, Content = L.RerollCfgD })

local DropdownRerollUnit = Tabs.AutoReroll:AddDropdown("RerollUnit", { Title = L.RerollUnit, Description = L.RerollUnitD, Values = {"(Loading...)"}, Multi = false, Default = 1 })

Tabs.AutoReroll:AddButton({
    Title = "Refresh Unit List",
    Description = "Manually refresh the list of equipped units.",
    Callback = function()
        local util
        pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end)
        if util and util.data and util.data.characters then
            local unitList = {}
            for k, v in pairs(util.data.characters) do
                if v.equipped == true then
                    table.insert(unitList, v.name .. " [" .. tostring(k) .. "]")
                end
            end
            if #unitList == 0 then table.insert(unitList, "(No Equipped Units)") end
            
            local currentVal = Options.RerollUnit and Options.RerollUnit.Value
            local found = false
            if currentVal then
                for _, u in ipairs(unitList) do
                    if u == currentVal then found = true break end
                end
            end
            
            DropdownRerollUnit:SetValues(unitList)
            if currentVal and not found then
                DropdownRerollUnit:SetValue(unitList[1])
            elseif currentVal and found then
                DropdownRerollUnit:SetValue(currentVal)
            end
        end
    end
})

task.spawn(function()
    local util
    while task.wait(3) do
        pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end)
        if util and util.data and util.data.characters then
            local unitList = {}
            for k, v in pairs(util.data.characters) do
                if v.equipped == true then
                    table.insert(unitList, v.name .. " [" .. tostring(k) .. "]")
                end
            end
            if #unitList == 0 then table.insert(unitList, "(No Equipped Units)") end
            
            local currentVals = DropdownRerollUnit.Values or {}
            local isDiff = false
            if #unitList ~= #currentVals then
                isDiff = true
            else
                for i = 1, #unitList do
                    if unitList[i] ~= currentVals[i] then isDiff = true break end
                end
            end
            
            if isDiff then
                local currentVal = Options.RerollUnit and Options.RerollUnit.Value
                local found = false
                if currentVal then
                    for _, u in ipairs(unitList) do
                        if u == currentVal then found = true break end
                    end
                end
                
                DropdownRerollUnit:SetValues(unitList)
                if currentVal and not found then
                    DropdownRerollUnit:SetValue(unitList[1])
                elseif currentVal and found then
                    DropdownRerollUnit:SetValue(currentVal)
                end
            end
        end
    end
end)

local DropdownLockedStats = Tabs.AutoReroll:AddDropdown("LockedStats", { Title = L.RerollLock, Description = L.RerollLockD, Values = {"SSS", "SS", "S+", "S", "A+", "A", "B+", "B", "C+", "C", "C-"}, Multi = true, Default = {["SSS"] = true} })

local ToggleAutoReroll = Tabs.AutoReroll:AddToggle("AutoReroll", { Title = L.RerollTog, Description = L.RerollTogD, Default = false })
Tabs.ShopUpgrade:AddParagraph({ Title = L.ShopDyn, Content = L.ShopDynD })

local function loadShopItems(shopName)
    local items = {}
    pcall(function()
        if isfile and readfile and isfile("as_free/ShopItems.json") then
            local data = game:GetService("HttpService"):JSONDecode(readfile("as_free/ShopItems.json"))
            if data and type(data) == "table" and data[shopName] then
                items = data[shopName]
            end
        end
    end)
    return items
end

local function saveShopItems(shopName, itemsList)
    pcall(function()
        local data = {}
        if isfile and readfile and isfile("as_free/ShopItems.json") then
            data = game:GetService("HttpService"):JSONDecode(readfile("as_free/ShopItems.json")) or {}
        end
        data[shopName] = itemsList
        if writefile then
            writefile("as_free/ShopItems.json", game:GetService("HttpService"):JSONEncode(data))
        end
    end)
end

local DropdownMerchantItem = Tabs.ShopUpgrade:AddDropdown("MerchantItem", { Title = L.MerchItem, Description = L.MerchItemD, Values = {"(Loading Items...)"}, Multi = true, Default = {} })

task.spawn(function()
    local allMerchantItems = loadShopItems("Merchant")
    if type(allMerchantItems) ~= "table" then allMerchantItems = {} end
    
    if isLobby then
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local get = rep.Remotes.Shops:WaitForChild("get", 30)
            
            local blacklist = {}
            if get then
                local succ1, raid = pcall(function() return get:InvokeServer("gt_city_raid") end)
                if succ1 and type(raid) == "table" then for k,_ in pairs(raid) do blacklist[k] = true end end
                
                local succ2, event = pcall(function() return get:InvokeServer("baras_event") end)
                if succ2 and type(event) == "table" then for k,_ in pairs(event) do blacklist[k] = true end end
            end
            
            local whitelist = {
                ["Trait Shards"] = true, ["Reroll Cubes"] = true, ["Perfect Cubes"] = true
            }
            
            local tempItems = {}
            for _, folderName in ipairs({"Items", "Materials"}) do
                local folder = rep:WaitForChild(folderName, 30)
                if folder then
                    for _, v in ipairs(folder:GetChildren()) do
                        local name = v.Name
                        if whitelist[name] then
                            if not table.find(tempItems, name) then table.insert(tempItems, name) end
                        else
                            if not blacklist[name] and not string.find(name, "XP") and not string.find(name, "Coin") then
                                if not table.find(tempItems, name) then table.insert(tempItems, name) end
                            end
                        end
                    end
                end
            end
            
            if #tempItems > 0 then
                table.sort(tempItems)
                allMerchantItems = tempItems
                saveShopItems("Merchant", allMerchantItems)
            end
        end)
    end
    if #allMerchantItems == 0 then table.insert(allMerchantItems, "(Empty)") end
    local currentMerchant = Options.MerchantItem and Options.MerchantItem.Value
    DropdownMerchantItem:SetValues(allMerchantItems)
    if type(currentMerchant) == "table" then DropdownMerchantItem:SetValue(currentMerchant) end
end)
local ToggleAutoBuyMerchant = Tabs.ShopUpgrade:AddToggle("AutoBuyMerchant", { Title = L.MerchTog, Description = L.MerchTogD, Default = false })

local DropdownRaidShopItem = Tabs.ShopUpgrade:AddDropdown("RaidShopItems", { Title = L.RaidItem, Description = L.RaidItemD, Values = {"(Waiting...)"}, Multi = true, Default = {} })
local ToggleAutoBuyRaid = Tabs.ShopUpgrade:AddToggle("AutoBuyRaid", { Title = L.RaidTog, Description = L.RaidTogD, Default = false })

local DropdownEventShopItem = Tabs.ShopUpgrade:AddDropdown("EventShopItems", { Title = L.EventItem, Description = L.EventItemD, Values = {"(Waiting...)"}, Multi = true, Default = {} })
local ToggleAutoBuyEvent = Tabs.ShopUpgrade:AddToggle("AutoBuyEvent", { Title = L.EventTog, Description = L.EventTogD, Default = false })

task.spawn(function()
    pcall(function()
        local raidItems = loadShopItems("Raid")
        if #raidItems > 0 then DropdownRaidShopItem:SetValues(raidItems) end
        local rCurrent = Options.RaidShopItems and Options.RaidShopItems.Value
        if type(rCurrent) == "table" then DropdownRaidShopItem:SetValue(rCurrent) end
        
        local eventItems = loadShopItems("Event")
        if #eventItems > 0 then DropdownEventShopItem:SetValues(eventItems) end
        local eCurrent = Options.EventShopItems and Options.EventShopItems.Value
        if type(eCurrent) == "table" then DropdownEventShopItem:SetValue(eCurrent) end
    end)
end)

if isLobby then
    _G.AnimeSquadronShopLoop = (_G.AnimeSquadronShopLoop or 0) + 1
    local currentLoopId = _G.AnimeSquadronShopLoop
    task.spawn(function()
        local get = game:GetService("ReplicatedStorage").Remotes.Shops:WaitForChild("get", 30)
        if not get then return end
        local HttpService = game:GetService("HttpService")
        
        while task.wait(10) do
            if _G.AnimeSquadronShopLoop ~= currentLoopId then return end
            local function updateShop(shopId, dropdown, saveKey)
                local succ, data = pcall(function() return get:InvokeServer(shopId) end)
                if succ and type(data) == "table" then
                    local items = {}
                    for k,v in pairs(data) do
                        table.insert(items, tostring(k))
                    end
                    local currentShopItem = dropdown.Value
                    if #items == 0 then table.insert(items, "(Empty)") else
                        saveShopItems(saveKey, items)
                    end
                    dropdown:SetValues(items)
                    if currentShopItem then dropdown:SetValue(currentShopItem) end
                end
            end
            
            updateShop("gt_city_raid", DropdownRaidShopItem, "Raid")
            updateShop("baras_event", DropdownEventShopItem, "Event")
        end
    end)
end

Tabs.ShopUpgrade:AddParagraph({ Title = L.PerkCfg, Content = L.PerkCfgD })
local DropdownPerkTarget = Tabs.ShopUpgrade:AddDropdown("PerkTarget", { Title = L.PerkTarget, Description = L.PerkTargetD, Values = {"health", "yen_generation", "yen_max"}, Multi = false, Default = 1 })
local ToggleAutoPerk = Tabs.ShopUpgrade:AddToggle("AutoPerk", { Title = L.PerkTog, Description = L.PerkTogD, Default = false })
Tabs.Claims:AddParagraph({ Title = L.ClaimCfg, Content = L.ClaimCfgD })
local ToggleAutoPass = Tabs.Claims:AddToggle("AutoPass", { Title = L.ClaimPass, Description = L.ClaimPassD, Default = false })
local ToggleAutoMilestones = Tabs.Claims:AddToggle("AutoMilestones", { Title = L.ClaimMile, Description = L.ClaimMileD, Default = false })
local ToggleAutoDiscovery = Tabs.Claims:AddToggle("AutoDiscovery", { Title = L.ClaimIdx, Description = L.ClaimIdxD, Default = false })

Tabs.Claims:AddParagraph({ Title = L.CodeCfg, Content = L.CodeCfgD })
Tabs.Claims:AddButton({
    Title = L.CodeBtn,
    Description = L.CodeBtnD,
    Callback = function()
        Window:Dialog({
            Title = L.CodeMsgT,
            Content = L.CodeMsg,
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
    StatusParagraph = Tabs.AutoFarm:AddParagraph({ Title = L.AF_StatL, Content = L.AF_StatLD })
else
    StatusParagraph = Tabs.AutoFarm:AddParagraph({ Title = L.AF_StatI, Content = L.AF_StatID })
end

local userId = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.UserId or 0
local statsFileName = basePath .. "/DailyStats_" .. tostring(userId) .. ".json"

local SessionStats = {
    Date = os.date("%Y-%m-%d"),
    Matches = 0,
    Gained = {}
}

local StatsParagraph = Tabs.AutoFarm:AddParagraph({
    Title = L.AF_Sess,
    Content = L.AF_SessD
})

local function saveSessionStats()
    if writefile then
        pcall(function() writefile(statsFileName, game:GetService("HttpService"):JSONEncode(SessionStats)) end)
    end
end

local function updateStatsUI()
    if StatsParagraph then
        local matchesStr = currentLang == "VN" and "Số trận đã chơi: " or "Matches Played: "
        local lines = { matchesStr .. tostring(SessionStats.Matches) }
        
        local util
        pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end)
        
        local function getCurrentAmount(name)
            if not (util and util.data) then return 0 end
            if name == "Gold" then return util.data.stats and util.data.stats.Gold or 0 end
            if name == "Gems" then return util.data.stats and util.data.stats.Gems or 0 end
            if name == "Trait Shards" then return util.data.stats and util.data.stats["Trait Shards"] or 0 end
            if name == "Perfect Cubes" then return util.data.stats and util.data.stats["Perfect Cubes"] or 0 end
            if name == "Reroll Cubes" then return util.data.stats and util.data.stats["Reroll Cubes"] or 0 end
            return 0
        end
        
        local displayOrder = {"Gold", "Gems", "Trait Shards", "Perfect Cubes", "Reroll Cubes"}
        
        for _, name in ipairs(displayOrder) do
            local gained = SessionStats.Gained[name] or 0
            local current = getCurrentAmount(name)
            table.insert(lines, string.format("%s: +%d (Current: %d)", name, gained, current))
        end
        
        StatsParagraph:SetDesc(table.concat(lines, "\n"))
    end
end

local function resetSessionStats()
    SessionStats.Matches = 0
    SessionStats.Gained = {}
    SessionStats.Date = os.date("%Y-%m-%d")
    saveSessionStats()
    updateStatsUI()
end

local function loadSessionStats()
    if isfile and readfile and isfile(statsFileName) then
        local s, res = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(statsFileName)) end)
        if s and type(res) == "table" then
            if res.Date == os.date("%Y-%m-%d") then
                SessionStats.Matches = res.Matches or 0
                SessionStats.Gained = type(res.Gained) == "table" and res.Gained or {}
                updateStatsUI()
            else
                resetSessionStats()
            end
        end
    end
end
loadSessionStats()
local friendToggle = Tabs.AutoFarm:AddToggle("FriendsOnly", { Title = L.AF_Friend, Description = L.AF_FriendD, Default = true })
local AutoClaimDaily = Tabs.AutoFarm:AddToggle("AutoClaimDaily", { Title = L.AF_Daily, Description = L.AF_DailyD, Default = false })
local AutoClaimBundle = Tabs.AutoFarm:AddToggle("AutoClaimBundle", { Title = L.AF_Bun, Description = L.AF_BunD, Default = false })
local AutoQuest = Tabs.AutoFarm:AddToggle("AutoQuest", { Title = L.AF_Quest, Description = L.AF_QuestD, Default = false })
local AutoToggle = Tabs.AutoFarm:AddToggle("MasterAutoRun", { Title = L.AF_Master, Description = L.AF_MasterD, Default = false })
game:GetService("GuiService").ErrorMessageChanged:Connect(function(errMessage)
    if errMessage and errMessage ~= "" then
        Fluent:Notify({ Title = "Connection Lost", Content = "Auto reconnecting in 5 seconds...", Duration = 5 })
        task.wait(5)
        game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end
end)

Tabs.Priority:AddParagraph({ Title = L.PriCfg, Content = L.PriCfgD })
local PriorityList = {"Auto Quest", "Auto Craft", "Auto Evo", "Auto Reroll", "None"}
Tabs.Priority:AddDropdown("Priority1", { Title = L.Pri1, Description = L.Pri1D, Values = PriorityList, Multi = false, Default = "Auto Quest" })
Tabs.Priority:AddDropdown("Priority2", { Title = L.Pri2, Description = L.Pri2D, Values = PriorityList, Multi = false, Default = "Auto Craft" })
Tabs.Priority:AddDropdown("Priority3", { Title = L.Pri3, Description = L.Pri3D, Values = PriorityList, Multi = false, Default = "Auto Evo" })
Tabs.Priority:AddDropdown("Priority4", { Title = L.Pri4, Description = L.Pri4D, Values = PriorityList, Multi = false, Default = "Auto Reroll" })

Tabs.PartyMulti:AddParagraph({ Title = L.PtCfg, Content = L.PtCfgD })
local TogglePartyMode = Tabs.PartyMulti:AddToggle("PartyMode", { Title = L.PtTog, Description = L.PtTogD, Default = false })
local DropdownPartyRole = Tabs.PartyMulti:AddDropdown("PartyRole", { Title = L.PtRole, Description = L.PtRoleD, Values = {"Host", "Member"}, Multi = false, Default = "Host" })
local TogglePartyLeaveSync = Tabs.PartyMulti:AddToggle("PartyLeaveSync", { Title = L.PtSync, Description = L.PtSyncD, Default = true })

Tabs.PartyMulti:AddParagraph({ Title = L.PtHostCfg, Content = L.PtHostCfgD })
local InputMember1 = Tabs.PartyMulti:AddInput("PartyMember1", { Title = L.PtM1, Description = L.PtM1D, Default = "", Numeric = false, Finished = false })
local InputMember2 = Tabs.PartyMulti:AddInput("PartyMember2", { Title = L.PtM2, Description = L.PtM2D, Default = "", Numeric = false, Finished = false })
local InputMember3 = Tabs.PartyMulti:AddInput("PartyMember3", { Title = L.PtM3, Description = L.PtM3D, Default = "", Numeric = false, Finished = false })
local SliderHostTimeout = Tabs.PartyMulti:AddSlider("HostWaitTimeout", { Title = L.PtTime, Description = L.PtTimeD, Default = 5, Min = 1, Max = 10, Rounding = 0 })

Tabs.PartyMulti:AddParagraph({ Title = L.PtMemCfg, Content = L.PtMemCfgD })
local InputHostName = Tabs.PartyMulti:AddInput("PartyHostName", { Title = L.PtHostName, Description = L.PtHostNameD, Default = "", Numeric = false, Finished = false })
_G.AnimeSquadron_UserCache = _G.AnimeSquadron_UserCache or {}
local function resolveUsernameToID(username)
    if not username or username == "" then return nil end
    local lower = string.lower(username)
    if _G.AnimeSquadron_UserCache[lower] then return _G.AnimeSquadron_UserCache[lower] end
    
    local succ, res = pcall(function()
        local req
        if request then req = request
        elseif http_request then req = http_request
        elseif HttpService and HttpService.RequestInternal then
        end
        if req then
            local reqData = HttpService:JSONEncode({ usernames = {username}, excludeBannedUsers = true })
            local resp = req({
                Url = "https://users.roblox.com/v1/usernames/users",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = reqData
            })
            if not resp or not resp.Body or string.find(resp.Body, "Too many requests") then
                resp = req({
                    Url = "https://users.roproxy.com/v1/usernames/users",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = reqData
                })
            end
            
            if resp and resp.Body then
                local data = HttpService:JSONDecode(resp.Body)
                if data and data.data and data.data[1] and data.data[1].id then
                    return data.data[1].id
                end
            end
        end
        return nil
    end)
    if succ and res then
        _G.AnimeSquadron_UserCache[lower] = res
        return res
    end
    return nil
end

Tabs.Webhook:AddParagraph({ Title = L.WbCfg, Content = L.WbCfgD })
local WebhookURL = Tabs.Webhook:AddInput("WebhookURL", { Title = L.WbUrl, Description = L.WbUrlD, Default = "", Numeric = false, Finished = false, Placeholder = "https://discord.com/api/webhooks/..." })
local WebhookOnDrop = Tabs.Webhook:AddToggle("WebhookOnDrop", { Title = L.WbDrop, Description = L.WbDropD, Default = false })
local WebhookOnMatchEnd = Tabs.Webhook:AddToggle("WebhookOnMatchEnd", { Title = L.WbMatch, Description = L.WbMatchD, Default = false })
local WebhookOnInterval = Tabs.Webhook:AddToggle("WebhookOnInterval", { Title = L.WbInt, Description = L.WbIntD, Default = false })
local WebhookOnEvoCraft = Tabs.Webhook:AddToggle("WebhookOnEvoCraft", { Title = L.WbEvo, Description = L.WbEvoD, Default = false })
local WebhookInterval = Tabs.Webhook:AddSlider("WebhookInterval", { Title = L.WbTime, Description = L.WbTimeD, Default = 10, Min = 1, Max = 60, Rounding = 0 })
Tabs.Settings:AddToggle("StuckAutoHop", { Title = L.StuckAutoHop, Description = L.StuckAutoHopD, Default = true })
Tabs.Settings:AddSlider("StuckTimeout", { Title = L.StuckTimeout, Description = L.StuckTimeoutD, Default = 60, Min = 30, Max = 300, Rounding = 0 })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"ScriptLanguage"})
InterfaceManager:SetFolder(basePath)
SaveManager:SetFolder(basePath .. "/AutoFarm")

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
    local update_lobby = ReplicatedStorage.Remotes.Play:WaitForChild("update_lobby", 10)
    local join_remote = ReplicatedStorage.Remotes.Play:WaitForChild("join", 10)
    
    local activeRooms = {}
    if update_lobby then
        update_lobby.OnClientEvent:Connect(function(data)
            if type(data) == "table" then
                activeRooms = data
            end
        end)
    end
    
    local dailyCompleted = false
    local lastDailyWorld = ""
    local lastDailyAct = -1
    
    local util
    pcall(function() util = require(Players.LocalPlayer.PlayerScripts.Client.Utility) end)
    
    local function joinRoom(act, diff, mode, world, rewards, capStr, maxCap, capType)
        if Options.PartyMode and Options.PartyMode.Value then
            if Options.PartyRole.Value == "Member" then
                local hostUsername = Options.PartyHostName and Options.PartyHostName.Value
                local hostId = nil
                
                if not hostUsername or hostUsername == "" then
                    Fluent:Notify({ Title = "Party Error", Content = "Please enter Host Username", Duration = 3 })
                    return false
                end
                
                hostId = resolveUsernameToID(hostUsername)
                if not hostId then
                    Fluent:Notify({ Title = "Party Error", Content = "Invalid Host Username (Cannot resolve to ID)", Duration = 3 })
                    return false
                end
                
                local currentRoom = activeRooms[hostId] or activeRooms[tonumber(hostId)] or activeRooms[tostring(hostId)]
                if currentRoom then
                    Fluent:Notify({ Title = "Party System", Content = "Joining Host's Room!", Duration = 3 })
                    if join_remote then pcall(function() join_remote:InvokeServer(hostId) end) end
                    task.wait(10)
                    return true
                else
                    Fluent:Notify({ Title = "Party System", Content = "Waiting for Host to create a room...", Duration = 3 })
                    return false
                end
            end
        end

        if isfile and writefile then
            if capStr and maxCap then
                pcall(function()
                    local dataToSave = {
                        capStr = capStr,
                        maxCap = maxCap,
                        worldName = world,
                        capType = capType
                    }
                    writefile(basePath .. "/CurrentTarget.json", HttpService:JSONEncode(dataToSave))
                end)
            else
                if isfile(basePath .. "/CurrentTarget.json") and delfile then
                    pcall(function() delfile(basePath .. "/CurrentTarget.json") end)
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
            if Options.PartyMode and Options.PartyMode.Value and Options.PartyRole.Value == "Host" then
                local membersToWait = {}
                local m1 = Options.PartyMember1 and Options.PartyMember1.Value; if m1 and m1 ~= "" then table.insert(membersToWait, {name = m1, key = "PartyMember1"}) end
                local m2 = Options.PartyMember2 and Options.PartyMember2.Value; if m2 and m2 ~= "" then table.insert(membersToWait, {name = m2, key = "PartyMember2"}) end
                local m3 = Options.PartyMember3 and Options.PartyMember3.Value; if m3 and m3 ~= "" then table.insert(membersToWait, {name = m3, key = "PartyMember3"}) end
                
                local memberData = {}
                for _, m in ipairs(membersToWait) do
                    local id = resolveUsernameToID(m.name)
                    if id then 
                        memberData[tostring(id)] = {name = m.name, key = m.key}
                    end
                end
                
                if next(memberData) then
                    local waitingNames = {}
                    for _, data in pairs(memberData) do table.insert(waitingNames, data.name) end
                    Fluent:Notify({ Title = "Party System", Content = "Waiting for members: " .. table.concat(waitingNames, ", "), Duration = 5 })
                    
                    local timeoutMins = (Options.HostWaitTimeout and Options.HostWaitTimeout.Value) or 5
                    local endTime = os.time() + (timeoutMins * 60)
                    local hostIdStr = tostring(game.Players.LocalPlayer.UserId)
                    
                    while os.time() < endTime do
                        local allJoined = true
                        local currentRoom = activeRooms[hostIdStr] or activeRooms[tonumber(hostIdStr)]
                        
                        if currentRoom and currentRoom.players then
                            local joinedIds = {}
                            for _, p in pairs(currentRoom.players) do
                                joinedIds[tostring(p)] = true
                            end
                            for id, _ in pairs(memberData) do
                                if not joinedIds[id] then
                                    allJoined = false
                                    break
                                end
                            end
                        else
                            allJoined = false
                        end
                        
                        if allJoined then break end
                        task.wait(1)
                    end
                    
                    -- Check who failed to join
                    local currentRoom = activeRooms[hostIdStr] or activeRooms[tonumber(hostIdStr)]
                    local joinedIds = {}
                    if currentRoom and currentRoom.players then
                        for _, p in pairs(currentRoom.players) do joinedIds[tostring(p)] = true end
                    end
                    
                    local missingMembers = {}
                    for id, data in pairs(memberData) do
                        if not joinedIds[id] then
                            table.insert(missingMembers, data.name)
                            if Options[data.key] then
                                Options[data.key]:SetValue("")
                            end
                        end
                    end
                    
                    if #missingMembers > 0 then
                        local msg = "Members failed to join (Crashed): " .. table.concat(missingMembers, ", ") .. ". They have been REMOVED from the Wait List."
                        Fluent:Notify({ Title = "Party Timeout", Content = msg, Duration = 10 })
                        if sendWebhookData then
                            task.spawn(function()
                                sendWebhookData("🔴 **PARTY TIMEOUT**\n" .. msg, 0xFF0000)
                            end)
                        end
                    end
                end
            end
        
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
        task.wait(10) -- Initial delay to allow Evo/Craft to load their data fully before skipping to Trait Maps
        local lastClaimTime = 0
        local lobbyEnterTime = os.time()
        local buyingDebounce = {}
        while true do
            task.wait(3)
            if _G.AnimeSquadronMainLoop ~= currentLoopId then return end
            
            if Options.MasterAutoRun.Value then
                if Options.StuckAutoHop and Options.StuckAutoHop.Value then
                    local timeout = Options.StuckTimeout and Options.StuckTimeout.Value or 60
                    if os.time() - lobbyEnterTime > timeout then
                        -- Handle Hopping
                        local req = request or http_request or (syn and syn.request)
                        local HttpService = game:GetService("HttpService")
                        local TeleportService = game:GetService("TeleportService")
                        if req then
                            pcall(function()
                                local res = req({
                                    Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100",
                                    Method = "GET"
                                })
                                if res and res.Body then
                                    local data = HttpService:JSONDecode(res.Body)
                                    if data and data.data then
                                        for _, v in pairs(data.data) do
                                            if type(v) == "table" and v.playing and v.maxPlayers and v.playing < v.maxPlayers and v.id ~= game.JobId then
                                                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, game:GetService("Players").LocalPlayer)
                                                task.wait(2)
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                        TeleportService:Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
                        task.wait(10)
                    end
                end
            else
                lobbyEnterTime = os.time()
            end
            
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
            if Options.AutoPass and Options.AutoPass.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Battlepass.claim_all:InvokeServer() end)
            end
            if Options.AutoMilestones and Options.AutoMilestones.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Level_Milestones.claim:InvokeServer() end)
            end
            if Options.AutoDiscovery and Options.AutoDiscovery.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Characters.claim_all_index:InvokeServer() end)
            end
            if Options.AutoPerk and Options.AutoPerk.Value then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.Perks.upgrade:InvokeServer(Options.PerkTarget.Value) end)
            end
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
            tryBuyShop(Options.AutoBuyRaid, Options.RaidShopItems, "gt_city_raid")
            tryBuyShop(Options.AutoBuyEvent, Options.EventShopItems, "baras_event")
            
            local function runAutoCraft()
                if not (Options.AutoCraft and Options.AutoCraft.Value) then return false end
                if not (util and util.data and util.data.stats and util.data.stats.Gold) then 
                    table.insert(activeQuestTexts, "Waiting for Player Data...")
                    return true 
                end
                local currentTask = _G.AnimeSquadron_CraftQueue[1]
                if not currentTask then
                    table.insert(activeQuestTexts, "Auto Craft is ON but Queue is Empty. Idling...")
                    return true
                end
                
                local targetName = currentTask.name
                local targetQty = currentTask.qty
                local get = game:GetService("ReplicatedStorage").Remotes.Crafting:WaitForChild("get", 5)
                if not get then return true end
                
                local succ, recipes = pcall(function() return get:InvokeServer() end)
                if not succ or type(recipes) ~= "table" or not recipes[targetName] then 
                    table.insert(activeQuestTexts, "Waiting for Recipe Data...")
                    return true 
                end
                
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
                if not (util and util.data and util.data.stats and util.data.stats.Gold) then 
                    table.insert(activeQuestTexts, "Waiting for Player Data...")
                    return true 
                end
                local targetName = Options.EvoTarget and Options.EvoTarget.Value
                if not targetName or targetName == "(None)" or string.find(targetName, "Waiting") then 
                    table.insert(activeQuestTexts, "Auto Evo is ON but no unit selected. Idling...")
                    return true 
                end
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
            local function runAutoReroll()
                if not (Options.AutoReroll and Options.AutoReroll.Value) then return false end
                if not util or not util.data or not util.data.characters then return false end
                
                local targetString = Options.RerollUnit and Options.RerollUnit.Value
                if not targetString or targetString == "(Loading...)" or targetString == "(No Equipped Units)" then return false end
                
                local targetId = string.match(targetString, "%[(.-)%]")
                if not targetId then return false end
                
                local unit = util.data.characters[targetId]
                if not unit then return false end
                
                if _G.DEBUG_REROLL then print("[AutoReroll] Checking unit:", unit.name, "Potential:", unit.potential) end
                
                if unit.potential and tonumber(unit.potential) >= 1000 then
                    local locksToApply = {}
                    local lockToggles = {}
                    if Options.LockedStats and type(Options.LockedStats.Value) == "table" then
                        for k, v in pairs(Options.LockedStats.Value) do
                            if v then lockToggles[k] = true end
                        end
                    end
                    
                    local hasUnlock = false
                    if unit.ranks then
                        for statName, rank in pairs(unit.ranks) do
                            if _G.DEBUG_REROLL then print("[AutoReroll] Stat:", statName, "Rank:", rank) end
                            if lockToggles[rank] then
                                locksToApply[statName] = true
                                if _G.DEBUG_REROLL then print("[AutoReroll] Locking:", statName) end
                            else
                                hasUnlock = true
                            end
                        end
                    else
                        hasUnlock = true
                    end
                    
                    if _G.DEBUG_REROLL then print("[AutoReroll] hasUnlock:", hasUnlock) end
                    
                    if hasUnlock then
                        local rerollRemote = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Stat_Reroll")
                        if rerollRemote and rerollRemote:FindFirstChild("reroll") then
                            pcall(function()
                                rerollRemote.reroll:InvokeServer(targetId, locksToApply)
                            end)
                            table.insert(activeQuestTexts, "Rerolling Stats for " .. unit.name .. "...")
                            return true
                        end
                    else
                        ToggleAutoReroll:SetValue(false)
                        Fluent:Notify({ Title = "Auto Reroll", Content = "All stats are locked or matched! Auto Reroll disabled.", Duration = 3 })
                    end
                end
                return false
            end
            
            local priorities = {
                Options.Priority1 and Options.Priority1.Value or "Auto Quest",
                Options.Priority2 and Options.Priority2.Value or "Auto Craft",
                Options.Priority3 and Options.Priority3.Value or "Auto Evo",
                Options.Priority4 and Options.Priority4.Value or "Auto Reroll"
            }
            
            local handled = false
            for _, p in ipairs(priorities) do
                if not handled then
                    if p == "Auto Quest" then handled = runAutoQuest()
                    elseif p == "Auto Craft" then handled = runAutoCraft()
                    elseif p == "Auto Evo" then handled = runAutoEvo()
                    elseif p == "Auto Reroll" then handled = runAutoReroll()
                    end
                end
            end
            
            if handled then lobbyEnterTime = os.time() end
            
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
            
            if Options.MasterAutoRun.Value and get_challenges and create_room and not (Options.PartyMode and Options.PartyMode.Value and Options.PartyRole.Value == "Member") then
                local succ, challengeData = pcall(function() return get_challenges:InvokeServer() end)
                local joinedSomething = false
                
                if succ and type(challengeData) == "table" then
                    if isfile and writefile then
                        pcall(function() writefile(basePath .. "/LastSnipeCheck.txt", tostring(math.floor(os.time() / 1800))) end)
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
                elseif handled then
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
    
    if isfile and readfile and isfile(basePath .. "/CurrentTarget.json") then
        local succ, parsed = pcall(function() return HttpService:JSONDecode(readfile(basePath .. "/CurrentTarget.json")) end)
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
    
    game.Players.PlayerRemoving:Connect(function(player)
        if Options.PartyMode and Options.PartyMode.Value and Options.PartyLeaveSync and Options.PartyLeaveSync.Value then
            forceTeleportToLobby("Party Sync", "Player " .. player.Name .. " left the match! Returning to lobby...")
        end
    end)

    
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
                if isfile and readfile and isfile(basePath .. "/LastSnipeCheck.txt") then
                    pcall(function() lastCheck = tonumber(readfile(basePath .. "/LastSnipeCheck.txt")) or 0 end)
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
                        if isfile and readfile and isfile(basePath .. "/LastSnipeCheck.txt") then
                            pcall(function() lastCheck = tonumber(readfile(basePath .. "/LastSnipeCheck.txt")) or 0 end)
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
                    
                    if not isTeleporting and Options.AutoLeaveToggle.Value and targetCapStr and targetMaxCap and util and util.data then
                        local currentVal = 0
                        if targetCapType == "Item" then
                            currentVal = (util.data.items and util.data.items[targetCapStr] or 0) + (util.data.stats and util.data.stats[targetCapStr] or 0)
                        else
                            currentVal = util.data.caps and util.data.caps[targetCapStr] or 0
                        end
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
    local strGems = tostring(gems)
    local strGold = tostring(gold)
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
        if diffs.items and type(diffs.items) == "table" then
            if diffs.items["Gems"] and diffs.items["Gems"] > 0 then
                strGems = tostring(gems - diffs.items["Gems"]) .. " + " .. diffs.items["Gems"]
            end
            if diffs.items["Gold"] and diffs.items["Gold"] > 0 then
                strGold = tostring(gold - diffs.items["Gold"]) .. " + " .. diffs.items["Gold"]
            end
            for itemName, qty in pairs(diffs.items) do
                if itemName ~= "Trait Shards" and itemName ~= "Perfect Cubes" and itemName ~= "Reroll Cubes" and itemName ~= "Gold" and itemName ~= "Gems" then
                    table.insert(droppedItems, itemName .. " +" .. tostring(qty))
                end
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
            { name = "<:Gems:1521405276127760434> Gems", value = strGems, inline = true },
            { name = "<:Gold:1521405249988989008> Gold", value = strGold, inline = true },
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
            if isfile and readfile and isfile(basePath .. "/LastWebhook.txt") then
                pcall(function() lastSend = tonumber(readfile(basePath .. "/LastWebhook.txt")) or 0 end)
            end
            
            if os.time() - lastSend >= (interval * 60) then
                local success = sendWebhookData("INTERVAL")
                if success and writefile then
                    pcall(function() writefile(basePath .. "/LastWebhook.txt", tostring(os.time())) end)
                end
            end
        end
    end
end)

_G.AnimeSquadronStatsLoop = (_G.AnimeSquadronStatsLoop or 0) + 1
local currentStatsLoop = _G.AnimeSquadronStatsLoop
task.spawn(function()
    local util
    local knownChars = nil
    local lastItems = nil
    local sessionStarted = false
    while true do
        if _G.AnimeSquadronStatsLoop ~= currentStatsLoop then return end
        task.wait(5)
        pcall(function() util = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Utility) end)
        if util and util.data and util.data.stats then
            local currentItems = {}
            local statKeys = {"Gold", "Gems", "Trait Shards", "Perfect Cubes", "Reroll Cubes"}
            for _, k in ipairs(statKeys) do
                if util.data.stats[k] then currentItems[k] = util.data.stats[k] end
            end
            
            local currentChars = {}
            if util.data.characters then
                for k, v in pairs(util.data.characters) do
                    currentChars[k] = v.name
                end
            end
            
            if lastItems ~= nil and knownChars ~= nil then
                if not sessionStarted then
                    sessionStarted = true
                    updateStatsUI()
                end
                
                local droppedUnits = {}
                for k, v in pairs(currentChars) do
                    if not knownChars[k] then
                        table.insert(droppedUnits, v)
                    end
                end
                
                local diffItems = {}
                local hasItemDiff = false
                for k, v in pairs(currentItems) do
                    local old = lastItems[k] or 0
                    if v > old then
                        diffItems[k] = v - old
                        hasItemDiff = true
                    end
                end
                
                if #droppedUnits > 0 or hasItemDiff then
                    for k, diff in pairs(diffItems) do
                        SessionStats.Gained[k] = (SessionStats.Gained[k] or 0) + diff
                    end
                    
                    saveSessionStats()
                    updateStatsUI()
                    
                    if Options.WebhookOnDrop and Options.WebhookOnDrop.Value and Options.WebhookURL and Options.WebhookURL.Value ~= "" then
                        sendWebhookData("DROP", {
                            trait = diffItems["Trait Shards"] or 0,
                            perfect = diffItems["Perfect Cubes"] or 0,
                            reroll = diffItems["Reroll Cubes"] or 0,
                            units = droppedUnits,
                            items = diffItems
                        })
                        task.wait(10)
                    end
                end
            end
            knownChars = currentChars
            lastItems = currentItems
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


