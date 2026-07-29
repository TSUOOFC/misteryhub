-- ===============================================================
-- GAG HUB - SCRIPT COMPLETO (VERSÃO PT-BR)
-- Feito para Grow a Garden (Roblox)
-- ===============================================================

if _G.GAGHubLoaded then
    warn("[GAG Hub] O Hub já está em execução!")
    return
end
_G.GAGHubLoaded = true

local VERSION = "1.0.0"

---------------------------------------------------------------
-- CONFIGURAÇÕES GLOBAIS
---------------------------------------------------------------

local Config = {
    UI = {
        Title = "GAG Hub | Grow a Garden",
    },
    Timings = {
        HarvestInterval = 2,
        SellInterval = 5,
        WaterInterval = 3,
        PlantInterval = 2,
        RestockPollInterval = 1,
        GearPollInterval = 5,
        PetHatchInterval = 2,
        MutationScanInterval = 3,
        WeatherPollInterval = 5,
        StealInterval = 1.5,
        SeedPackPollInterval = 1,
        PetCatchInterval = 3,
        InventoryCheckInterval = 10,
    },
    Water = {
        WaterFullyGrown = false,
        RequiredCan = "",
    },
    Plant = {
        PlantOrder = "Top",
        GridSpacing = 4,
        PreferSeed = nil,
        BlacklistMutated = false,
    },
    Restock = {
        TargetSeeds = {},
        BlacklistedSeeds = {},
    },
    Gear = {
        TargetGears = {},
    },
    Sell = {
        AutoSell = false,
    },
    Pet = {
        MinRarity = "Rare",
        AutoSellUnwanted = false,
    },
    PetCatch = {
        MinRarity = "Rare",
        AutoReturn = true,
    },
    Mutation = {
        MinRarity = "Common",
        TrackAll = true,
        AlertMutations = {"Gold", "Rainbow", "Starstruck", "Bloodlit"},
        LogToConsole = true,
        PriceMultipliers = {
            Gold = 20,
            Rainbow = 50,
            Electric = 12,
            Frozen = 10,
            Bloodlit = 5,
            Chained = 8,
            Starstruck = 100,
        },
    },
    Weather = {
        AlertEvents = {"Bloodmoon", "Rainbow", "GoldMoon"},
        PlaySound = true,
    },
    Steal = {
        Enabled = false,
        MaxAttemptsPerNight = 20,
        MinFruitValue = 100,
    },
    Inventory = {
        AutoFavorite = true,
        FavoriteThreshold = 500,
        AutoPromote = true,
        DropThreshold = 0,
    },
    Server = {
        TargetJobId = "",
        AutoRejoin = true,
        RejoinDelay = 5,
        MaxRetries = 10,
    },
}

function Config.Notify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 5,
        })
    end)
end

---------------------------------------------------------------
-- RECURSOS (PREÇOS, SEMENTES E ITENS)
---------------------------------------------------------------

local Resources = {
    AllSeeds = {
        "Strawberry","Carrot","Blueberry","Tomato","Green Bean",
        "Apple","Pineapple","Corn","Banana","Cactus","Grape",
        "Coconut","Tulip","Baby Cactus","Mango","Pinetree",
        "Thorn Rose","Dragon Fruit","Acorn","Horned Melon",
        "Pumpkin","Cherry","Glow Mushroom","Bamboo",
        "Pomegranate","Poison Apple","Romanesco","Poison Ivy",
        "Sunflower","Beanstalk","Ghost Pepper","Venus Fly Trap",
        "Dragon's Breath","Lotus","Moon Bloom","Mushroom",
    },
    AllGears = {
        "Trowel","Speed Mushroom","Jump Mushroom","Common Watering Can",
        "Common Sprinkler","Sign","Shrink Mushroom","Supersize Mushroom",
        "Flashbang","Uncommon Sprinkler","Lantern","Teleporter",
        "Rare Sprinkler","Gnome","Basic Pot","Legendary Sprinkler",
        "Super Watering Can","Super Sprinkler","Wheelbarrow",
    },
    GearPrices = {
        ["Trowel"] = 100,
        ["Speed Mushroom"] = 150,
        ["Common Watering Can"] = 50,
        ["Common Sprinkler"] = 500,
        ["Sign"] = 75,
        ["Lantern"] = 250,
        ["Basic Pot"] = 200,
        ["Super Watering Can"] = 1500,
        ["Super Sprinkler"] = 5000,
        ["Wheelbarrow"] = 2500,
    }
}

---------------------------------------------------------------
-- SISTEMA DE REDE (NETWORKING)
---------------------------------------------------------------

local Networking = {}
do
    local RS = game:GetService("ReplicatedStorage")
    local Remotes = RS:FindFirstChild("Remotes") or RS

    function Networking.getRemote(name)
        local current = Remotes
        for part in string.gmatch(name, "[^.]+") do
            if current then
                current = current:FindFirstChild(part)
            end
        end
        return current
    end

    function Networking.fire(name, ...)
        local remote = Networking.getRemote(name)
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(...)
            return true
        end
        return false
    end

    function Networking.invoke(name, ...)
        local remote = Networking.getRemote(name)
        if remote and remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
        return nil
    end

    function Networking.on(name, callback)
        local remote = Networking.getRemote(name)
        if remote and remote:IsA("RemoteEvent") then
            return remote.OnClientEvent:Connect(callback)
        end
        return nil
    end
end

---------------------------------------------------------------
-- UTILITÁRIOS
---------------------------------------------------------------

local Utils = {}
do
    local Players = game:GetService("Players")

    function Utils.getLocalPlayer()
        return Players.LocalPlayer
    end

    function Utils.getHumanoidRootPart()
        local lp = Players.LocalPlayer
        if lp and lp.Character then
            return lp.Character:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end

    function Utils.getMyGarden()
        local lp = Players.LocalPlayer
        local plotId = lp and lp:GetAttribute("PlotId")
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return nil end
        
        if plotId then
            local plot = gardens:FindFirstChild("Plot" .. plotId)
            if plot then return plot end
        end

        for _, garden in ipairs(gardens:GetChildren()) do
            local owner = garden:GetAttribute("OwnerUserId") or garden:GetAttribute("Owner")
            if owner and tonumber(owner) == lp.UserId then
                return garden
            end
        end
        return nil
    end

    function Utils.getPlantsInGarden(garden)
        if not garden then return {} end
        local plantsFolder = garden:FindFirstChild("Plants")
        if not plantsFolder then return {} end
        return plantsFolder:GetChildren()
    end

    function Utils.getPlantInfo(plantModel)
        return {
            Model = plantModel,
            SeedName = plantModel:GetAttribute("SeedName"),
            Stage = plantModel:GetAttribute("Stage"),
            Watered = plantModel:GetAttribute("Watered"),
            Mutation = plantModel:GetAttribute("Mutation"),
            PlantedTime = plantModel:GetAttribute("PlantedTime"),
        }
    end

    function Utils.getSheckles()
        local lp = Players.LocalPlayer
        if not lp then return 0 end
        local leaderstats = lp:FindFirstChild("leaderstats")
        if leaderstats then
            local sheckles = leaderstats:FindFirstChild("Sheckles") or leaderstats:FindFirstChild("Money")
            if sheckles then return sheckles.Value end
        end
        return lp:GetAttribute("Sheckles") or 0
    end

    function Utils.formatNumber(n)
        if not n then return "0" end
        if n >= 1e9 then
            return string.format("%.2fB", n / 1e9)
        elseif n >= 1e6 then
            return string.format("%.2fM", n / 1e6)
        elseif n >= 1e3 then
            return string.format("%.2fK", n / 1e3)
        end
        return tostring(math.floor(n))
    end

    function Utils.formatTime(seconds)
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        local hours = math.floor(mins / 60)
        mins = mins % 60
        if hours > 0 then
            return string.format("%d:%02d:%02d", hours, mins, secs)
        end
        return string.format("%02d:%02d", mins, secs)
    end

    function Utils.isNight()
        local lighting = game:GetService("Lighting")
        local rs = game:GetService("ReplicatedStorage")
        local nightVal = rs:FindFirstChild("Night")
        if nightVal and nightVal:IsA("BoolValue") then
            return nightVal.Value
        end
        return lighting.ClockTime < 6 or lighting.ClockTime > 18
    end
end

---------------------------------------------------------------
-- MÓDULOS DO HUB
---------------------------------------------------------------

local Modules = {}
local Running = {}

local function startModule(name)
    if Running[name] then return end
    if Modules[name] and Modules[name].start then
        Running[name] = true
        pcall(function()
            Modules[name].start(Config, Networking, Utils)
        end)
    end
end

local function stopModule(name)
    if not Running[name] then return end
    Running[name] = false
    if Modules[name] and Modules[name].stop then
        pcall(function()
            Modules[name].stop()
        end)
    end
end

local function toggleModule(name)
    if Running[name] then
        stopModule(name)
    else
        startModule(name)
    end
end

---------------------------------------------------------------
-- MÓDULO: AUTO HARVEST (Colheita Automática)
---------------------------------------------------------------
Modules.AutoHarvest = {}
do
    local M = Modules.AutoHarvest
    M._running = false
    M._thread = nil
    M._stats = { harvested = 0, errors = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        local interval = config.Timings.HarvestInterval or 2

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    local garden = Utils.getMyGarden()
                    if garden then
                        local plants = Utils.getPlantsInGarden(garden)
                        for _, plant in ipairs(plants) do
                            local fruits = plant:FindFirstChild("Fruits")
                            if fruits then
                                for _, fruit in ipairs(fruits:GetChildren()) do
                                    local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt then
                                        fireproximityprompt(prompt)
                                        M._stats.harvested = M._stats.harvested + 1
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(interval)
            end
        end)
    end

    function M.stop()
        M._running = false
    end

    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: AUTO SELL (Venda Automática)
---------------------------------------------------------------
Modules.AutoSell = {}
do
    local M = Modules.AutoSell
    M._running = false
    M._thread = nil
    M._stats = { sold = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        local interval = config.Timings.SellInterval or 5

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    local lp = Utils.getLocalPlayer()
                    local backpack = lp and lp:FindFirstChild("Backpack")
                    if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") and (tool:GetAttribute("FruitName") or tool:GetAttribute("IsFruit")) then
                                Net.fire("NPCS.SellItem", tool)
                                M._stats.sold = M._stats.sold + 1
                            end
                        end
                    end
                end)
                task.wait(interval)
            end
        end)
    end

    function M.stop() M._running = false end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: AUTO WATER (Rega Automática)
---------------------------------------------------------------
Modules.AutoWater = {}
do
    local M = Modules.AutoWater
    M._running = false
    M._stats = { watered = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        local interval = config.Timings.WaterInterval or 3

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    local garden = Utils.getMyGarden()
                    if garden then
                        for _, plant in ipairs(Utils.getPlantsInGarden(garden)) do
                            local info = Utils.getPlantInfo(plant)
                            if info and not info.Watered then
                                Net.fire("Plants.WaterPlant", plant)
                                M._stats.watered = M._stats.watered + 1
                            end
                        end
                    end
                end)
                task.wait(interval)
            end
        end)
    end

    function M.stop() M._running = false end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: AUTO PLANT (Plantio Automático)
---------------------------------------------------------------
Modules.AutoPlant = {}
do
    local M = Modules.AutoPlant
    M._running = false
    M._stats = { planted = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        local interval = config.Timings.PlantInterval or 2

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    local garden = Utils.getMyGarden()
                    if garden then
                        local area = garden:FindFirstChild("PlantArea")
                        if area then
                            Net.fire("Plants.PlantSeed", "Carrot", area.Position)
                            M._stats.planted = M._stats.planted + 1
                        end
                    end
                end)
                task.wait(interval)
            end
        end)
    end

    function M.stop() M._running = false end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: RESTOCK SNIPER
---------------------------------------------------------------
Modules.RestockSniper = {}
do
    local M = Modules.RestockSniper
    M._running = false
    M._stats = { bought = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        local interval = config.Timings.RestockPollInterval or 1

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    for _, seedName in ipairs(config.Restock.TargetSeeds or {}) do
                        Net.fire("SeedShop.BuySeed", seedName, 1)
                        M._stats.bought = M._stats.bought + 1
                    end
                end)
                task.wait(interval)
            end
        end)
    end

    function M.stop() M._running = false end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: MUTATION TRACKER
---------------------------------------------------------------
Modules.MutationTracker = {}
do
    local M = Modules.MutationTracker
    M._running = false
    M._stats = { tracked = 0, alerts = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        
        local conn = Net.on("Mutation.Detected", function(mutationName)
            M._stats.tracked = M._stats.tracked + 1
            M._stats.alerts = M._stats.alerts + 1
            Config.Notify("🧬 Mutação Detectada!", "Mutação encontrada: " .. tostring(mutationName), 8)
        end)
        
        M._conn = conn
    end

    function M.stop()
        M._running = false
        if M._conn then M._conn:Disconnect() end
    end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: WEATHER BOT
---------------------------------------------------------------
Modules.WeatherBot = {}
do
    local M = Modules.WeatherBot
    M._running = false
    M._stats = { events = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        
        M._conn = Net.on("Weather.Changed", function(weatherName)
            M._stats.events = M._stats.events + 1
            Config.Notify("🌦️ Mudança de Clima", "Clima atual: " .. tostring(weatherName), 10)
        end)
    end

    function M.stop()
        M._running = false
        if M._conn then M._conn:Disconnect() end
    end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: STEAL BOT (Modo Roubo)
---------------------------------------------------------------
Modules.StealBot = {}
do
    local M = Modules.StealBot
    M._running = false
    M._stats = { stolen = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    if Utils.isNight() then
                        M._stats.stolen = M._stats.stolen + 1
                    end
                end)
                task.wait(config.Timings.StealInterval or 1.5)
            end
        end)
    end

    function M.stop() M._running = false end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: AUTO BUY PET
---------------------------------------------------------------
Modules.AutoBuyPet = {}
do
    local M = Modules.AutoBuyPet
    M._running = false
    M._stats = { hatched = 0 }

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true

        M._thread = task.spawn(function()
            while M._running do
                pcall(function()
                    Net.fire("Egg.OpenEgg", "Basic Egg")
                    M._stats.hatched = M._stats.hatched + 1
                end)
                task.wait(config.Timings.PetHatchInterval or 2)
            end
        end)
    end

    function M.stop() M._running = false end
    function M.getStats() return M._stats end
end

---------------------------------------------------------------
-- MÓDULO: INVENTORY OPTIMIZER
---------------------------------------------------------------
Modules.InventoryOptimizer = {}
do
    local M = Modules.InventoryOptimizer
    M._running = false

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
    end

    function M.stop() M._running = false end
    function M.getStats() return { optimized = 0 } end
end

---------------------------------------------------------------
-- MÓDULO: GEAR BUYER
---------------------------------------------------------------
Modules.GearBuyer = {}
do
    local M = Modules.GearBuyer
    M._running = false

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
    end

    function M.stop() M._running = false end
    function M.getStats() return { bought = 0 } end
end

---------------------------------------------------------------
-- MÓDULO: SEED PACK CLAIMER
---------------------------------------------------------------
Modules.SeedPackClaimer = {}
do
    local M = Modules.SeedPackClaimer
    M._running = false

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
    end

    function M.stop() M._running = false end
    function M.getStats() return { claimed = 0 } end
end

---------------------------------------------------------------
-- MÓDULO: AUTO JOIN SERVER
---------------------------------------------------------------
Modules.AutoJoinServer = {}
do
    local M = Modules.AutoJoinServer
    M._running = false

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        if config.Server.TargetJobId ~= "" then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, config.Server.TargetJobId, Utils.getLocalPlayer())
        end
    end

    function M.stop() M._running = false end
    function M.getStats() return { teleports = 0 } end
end

---------------------------------------------------------------
-- MÓDULO: AUTO PET CATCH
---------------------------------------------------------------
Modules.AutoPetCatch = {}
do
    local M = Modules.AutoPetCatch
    M._running = false

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
    end

    function M.stop() M._running = false end
    function M.getStats() return { caught = 0 } end
end

---------------------------------------------------------------
-- MÓDULO: AUTO CENTER PLOT
---------------------------------------------------------------
Modules.AutoCenterPlot = {}
do
    local M = Modules.AutoCenterPlot
    M._running = false

    function M.start(config, Net, Utils)
        if M._running then return end
        M._running = true
        task.spawn(function()
            local hrp = Utils.getHumanoidRootPart()
            local garden = Utils.getMyGarden()
            if hrp and garden then
                hrp.CFrame = garden:GetPivot() + Vector3.new(0, 5, 0)
            end
            M._running = false
        end)
    end

    function M.stop() M._running = false end
end

---------------------------------------------------------------
-- RASTREADOR DE ESTATÍSTICAS DA SESSÃO
---------------------------------------------------------------

local Stats = {
    startSheckles = 0,
    startTime = os.clock(),
}

function Stats.init()
    Stats.startSheckles = Utils.getSheckles()
    Stats.startTime = os.clock()
end

function Stats.getProfit()
    return Utils.getSheckles() - Stats.startSheckles
end

function Stats.buildText()
    local sheckles = Utils.getSheckles()
    local profit = Stats.getProfit()
    local elapsed = os.clock() - Stats.startTime

    local profitSign = profit >= 0 and "+" or ""
    local profitColor = profit >= 0 and "🟢" or "🔴"

    local lines = {}
    table.insert(lines, "💰 **Dinheiro & Economia**")
    table.insert(lines, string.format("  Atual: %s", Utils.formatNumber(sheckles)))
    table.insert(lines, string.format("  Lucro: %s%s%s", profitColor, profitSign, Utils.formatNumber(profit)))
    table.insert(lines, "")
    table.insert(lines, "⏱ **Sessão**")
    table.insert(lines, string.format("  Tempo Ativo: %s", Utils.formatTime(elapsed)))

    return table.concat(lines, "\n")
end

---------------------------------------------------------------
-- INTERFACE GRÁFICA (RAYFIELD UI EM PT-BR)
---------------------------------------------------------------

local function createUI()
    local Rayfield = nil
    local ok = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if not ok or not Rayfield then
        warn("[GAG Hub] Falha ao carregar o Rayfield UI!")
        return false
    end

    Stats.init()

    local Window = Rayfield:CreateWindow({
        Name = "🌿 " .. Config.UI.Title .. " v" .. VERSION,
        LoadingTitle = "Carregando GAG Hub...",
        LoadingSubtitle = "por Brave (Tradução PT-BR)",
        ConfigurationSaving = { Enabled = true, FolderName = "GAGHub", FileName = "config_pt" },
        Discord = { Enabled = false },
        KeySystem = false,
    })

    -------------------------------------------------------
    -- ABA 1: AGRICULTURA (Farming)
    -------------------------------------------------------
    local FarmTab = Window:CreateTab("Agricultura", 6034510)

    FarmTab:CreateSection("⚡ Módulos Automáticos")
    FarmTab:CreateToggle({Name = "Auto Colheita", CurrentValue = false, Flag = "AutoHarvest", Callback = function(v) if v then startModule("AutoHarvest") else stopModule("AutoHarvest") end end})
    FarmTab:CreateToggle({Name = "Auto Venda", CurrentValue = false, Flag = "AutoSell", Callback = function(v) if v then startModule("AutoSell") else stopModule("AutoSell") end end})
    FarmTab:CreateToggle({Name = "Auto Rega", CurrentValue = false, Flag = "AutoWater", Callback = function(v) if v then startModule("AutoWater") else stopModule("AutoWater") end end})
    FarmTab:CreateToggle({Name = "Auto Plantio", CurrentValue = false, Flag = "AutoPlant", Callback = function(v) if v then startModule("AutoPlant") else stopModule("AutoPlant") end end})

    FarmTab:CreateSection("⏱ Intervalos (Segundos)")
    FarmTab:CreateSlider({Name = "Colheita", Range = {0.5, 10}, Increment = 0.5, Suffix = "s", CurrentValue = Config.Timings.HarvestInterval, Callback = function(v) Config.Timings.HarvestInterval = v end})
    FarmTab:CreateSlider({Name = "Venda", Range = {1, 30}, Increment = 1, Suffix = "s", CurrentValue = Config.Timings.SellInterval, Callback = function(v) Config.Timings.SellInterval = v end})
    FarmTab:CreateSlider({Name = "Rega", Range = {1, 15}, Increment = 1, Suffix = "s", CurrentValue = Config.Timings.WaterInterval, Callback = function(v) Config.Timings.WaterInterval = v end})
    FarmTab:CreateSlider({Name = "Plantio", Range = {1, 15}, Increment = 1, Suffix = "s", CurrentValue = Config.Timings.PlantInterval, Callback = function(v) Config.Timings.PlantInterval = v end})

    -------------------------------------------------------
    -- ABA 2: LOJA E PETS (Shop & Pets)
    -------------------------------------------------------
    local ShopTab = Window:CreateTab("Loja & Pets", 6031790)

    ShopTab:CreateSection("🎯 Sniper de Restoque")
    ShopTab:CreateToggle({Name = "Ativar Sniper", CurrentValue = false, Flag = "RestockSniper", Callback = function(v) if v then startModule("RestockSniper") else stopModule("RestockSniper") end end})
    ShopTab:CreateDropdown({Name = "Sementes Alvo", Options = Resources.AllSeeds, CurrentOption = Config.Restock.TargetSeeds, MultipleOptions = true, Callback = function(opts) Config.Restock.TargetSeeds = opts end})

    ShopTab:CreateSection("🐾 Ovos e Pets")
    ShopTab:CreateToggle({Name = "Auto Abrir Ovos", CurrentValue = false, Flag = "AutoBuyPet", Callback = function(v) if v then startModule("AutoBuyPet") else stopModule("AutoBuyPet") end end})
    ShopTab:CreateDropdown({Name = "Raridade Mínima", Options = {"Common", "Uncommon", "Rare", "Legendary", "Mythic", "Super"}, CurrentOption = {Config.Pet.MinRarity}, MultipleOptions = false, Callback = function(opt) Config.Pet.MinRarity = type(opt) == "table" and opt[1] or opt end})

    -------------------------------------------------------
    -- ABA 3: EVENTOS (Events)
    -------------------------------------------------------
    local EventTab = Window:CreateTab("Eventos", 6035974)

    EventTab:CreateSection("🧬 Mutações & Clima")
    EventTab:CreateToggle({Name = "Rastreador de Mutações", CurrentValue = false, Flag = "MutationTracker", Callback = function(v) if v then startModule("MutationTracker") else stopModule("MutationTracker") end end})
    EventTab:CreateToggle({Name = "Bot do Clima", CurrentValue = false, Flag = "WeatherBot", Callback = function(v) if v then startModule("WeatherBot") else stopModule("WeatherBot") end end})

    EventTab:CreateSection("🌙 Roubo Automático (Steal Bot)")
    EventTab:CreateToggle({Name = "Ativar Roubo à Noite", CurrentValue = false, Flag = "StealBot", Callback = function(v) if v then startModule("StealBot") else stopModule("StealBot") end end})

    -------------------------------------------------------
    -- ABA 4: SERVIDOR (Server)
    -------------------------------------------------------
    local ServerTab = Window:CreateTab("Servidor", 6035172)

    ServerTab:CreateSection("🚀 Conexão Direta")
    ServerTab:CreateInput({
        Name = "JobId do Servidor Alvo",
        PlaceholderText = "Cole o JobId aqui...",
        RemoveTextAfterFocusLost = false,
        Callback = function(v) Config.Server.TargetJobId = v end
    })
    ServerTab:CreateToggle({
        Name = "Auto Entrar no Servidor Alvo",
        CurrentValue = false,
        Callback = function(v)
            if v then startModule("AutoJoinServer") else stopModule("AutoJoinServer") end
        end
    })

    -------------------------------------------------------
    -- ABA 5: STATUS E CONTROLE (Status)
    -------------------------------------------------------
    local StatusTab = Window:CreateTab("Status", 6030690)

    StatusTab:CreateSection("📊 Estatísticas ao Vivo")
    local StatsParagraph = StatusTab:CreateParagraph({
        Title = "Resumo da Sessão",
        Content = "Carregando dados..."
    })

    StatusTab:CreateSection("🎮 Painel de Controle Global")
    StatusTab:CreateButton({Name = "✅ Ativar Tudo", Callback = function()
        for n in pairs(Modules) do startModule(n) end
        Rayfield:Notify({Title = "GAG Hub", Content = "Todos os módulos foram ativados!", Duration = 3})
    end})
    StatusTab:CreateButton({Name = "❌ Desativar Tudo", Callback = function()
        for n in pairs(Modules) do stopModule(n) end
        Rayfield:Notify({Title = "GAG Hub", Content = "Todos os módulos foram desativados!", Duration = 3})
    end})

    task.spawn(function()
        while true do
            pcall(function()
                StatsParagraph:Set({Title = "Resumo da Sessão", Content = Stats.buildText()})
            end)
            task.wait(2)
        end
    end)

    pcall(function() Rayfield:LoadConfiguration() end)
    return true
end

---------------------------------------------------------------
-- API DO CONSOLE E INICIALIZAÇÃO
---------------------------------------------------------------

_G.GAGHub = {
    Config = Config,
    Modules = Modules,
    Net = Networking,
    Utils = Utils,
    toggle = toggleModule,
    start = startModule,
    stop = stopModule,
    enableAll = function() for n in pairs(Modules) do startModule(n) end end,
    disableAll = function() for n in pairs(Modules) do stopModule(n) end end,
}

local LP = Utils.getLocalPlayer()

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

task.spawn(createUI)
Config.Notify("GAG Hub Carregado!", "Painel totalmente traduzido para PT-BR.", 5)
print("[GAG Hub] Carregado com sucesso! Use _G.GAGHub no console se necessário.")
