```lua
-- ===============================================================
-- GAG HUB - SCRIPT COMPLETO (ULTRA CORRIGIDO)
-- ===============================================================

if _G.GAGHubLoaded then
    warn("[GAG Hub] O Hub já está em execução!")
    return
end
_G.GAGHubLoaded = true

local VERSION = "1.0.5"
local Rayfield = nil

---------------------------------------------------------------
-- CONFIGURAÇÕES GLOBAIS
---------------------------------------------------------------

local Config = {
    UI = {
        Title = "GAG Hub | Grow a Garden",
    },
    Timings = {
        HarvestInterval = 2,
        SellInterval = 3,
        WaterInterval = 3,
        PlantInterval = 2,
    },
}

function Config.Notify(title, content, duration)
    pcall(function()
        if Rayfield then
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration or 5,
            })
        end
    end)
end

---------------------------------------------------------------
-- SISTEMA DE REDE (NETWORKING)
---------------------------------------------------------------

local Networking = {}
do
    local RS = game:GetService("ReplicatedStorage")
    
    function Networking.fire(remoteName, ...)
        pcall(function()
            local remote = RS:FindFirstChild(remoteName, true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            end
        end)
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
end

---------------------------------------------------------------
-- GERENCIAMENTO DE MÓDULOS
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
        pcall(function() Modules[name].stop() end)
    end
end

---------------------------------------------------------------
-- MÓDULO: AUTO HARVEST
---------------------------------------------------------------
Modules.AutoHarvest = {}
do
    local M = Modules.AutoHarvest
    M._running = false
    function M.start(config, Net, Utils)
        M._running = true
        task.spawn(function()
            while M._running do
                pcall(function()
                    local garden = Utils.getMyGarden()
                    if garden then
                        for _, plant in ipairs(Utils.getPlantsInGarden(garden)) do
                            local fruits = plant:FindFirstChild("Fruits")
                            if fruits then
                                for _, fruit in ipairs(fruits:GetChildren()) do
                                    local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt then fireproximityprompt(prompt) end
                                end
                            end
                        end
                    end
                end)
                task.wait(config.Timings.HarvestInterval)
            end
        end)
    end
    function M.stop() M._running = false end
end

---------------------------------------------------------------
-- MÓDULO: AUTO SELL (Busca Dinâmica por Remotos de Venda)
---------------------------------------------------------------
Modules.AutoSell = {}
do
    local M = Modules.AutoSell
    M._running = false
    function M.start(config, Net, Utils)
        M._running = true
        task.spawn(function()
            while M._running do
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    
                    -- Vreifica recursivamente na árvore do ReplicatedStorage por qualquer remote com "Sell"
                    for _, desc in ipairs(RS:GetDescendants()) do
                        if desc:IsA("RemoteEvent") then
                            local nameLower = desc.Name:lower()
                            if nameLower:find("sell") or nameLower:find("venda") then
                                desc:FireServer()
                            end
                        end
                    end
                end)
                task.wait(config.Timings.SellInterval)
            end
        end)
    end
    function M.stop() M._running = false end
end

---------------------------------------------------------------
-- MÓDULO: AUTO WATER
---------------------------------------------------------------
Modules.AutoWater = {}
do
    local M = Modules.AutoWater
    M._running = false
    function M.start(config, Net, Utils)
        M._running = true
        task.spawn(function()
            while M._running do
                pcall(function()
                    local garden = Utils.getMyGarden()
                    if garden then
                        for _, plant in ipairs(Utils.getPlantsInGarden(garden)) do
                            if plant:GetAttribute("Watered") == false then
                                Networking.fire("Plants.WaterPlant", plant)
                            end
                        end
                    end
                end)
                task.wait(config.Timings.WaterInterval)
            end
        end)
    end
    function M.stop() M._running = false end
end

---------------------------------------------------------------
-- INTERFACE GRÁFICA (RAYFIELD UI)
---------------------------------------------------------------

local function createUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if not success or not result then
        warn("[GAG Hub] Falha ao carregar Rayfield UI.")
        return false
    end
    
    Rayfield = result

    local Window = Rayfield:CreateWindow({
        Name = Config.UI.Title .. " v" .. VERSION,
        LoadingTitle = "Carregando GAG Hub...",
        LoadingSubtitle = "por Brave",
        ConfigurationSaving = { Enabled = true, FolderName = "GAGHub", FileName = "config_pt" },
        Discord = { Enabled = false },
        KeySystem = false,
    })

    local FarmTab = Window:CreateTab("Agricultura", 6034510)

    FarmTab:CreateSection("⚡ Automação")
    FarmTab:CreateToggle({Name = "Auto Colheita", CurrentValue = false, Callback = function(v) if v then startModule("AutoHarvest") else stopModule("AutoHarvest") end end})
    FarmTab:CreateToggle({Name = "Auto Venda", CurrentValue = false, Callback = function(v) if v then startModule("AutoSell") else stopModule("AutoSell") end end})
    FarmTab:CreateToggle({Name = "Auto Rega", CurrentValue = false, Callback = function(v) if v then startModule("AutoWater") else stopModule("AutoWater") end end})

    FarmTab:CreateSection("⏱ Intervalos")
    FarmTab:CreateSlider({Name = "Colheita", Range = {0.5, 10}, Increment = 0.5, Suffix = "s", CurrentValue = Config.Timings.HarvestInterval, Callback = function(v) Config.Timings.HarvestInterval = v end})
    FarmTab:CreateSlider({Name = "Venda", Range = {1, 30}, Increment = 1, Suffix = "s", CurrentValue = Config.Timings.SellInterval, Callback = function(v) Config.Timings.SellInterval = v end})

    pcall(function() Rayfield:LoadConfiguration() end)
    return true
end

---------------------------------------------------------------
-- INICIALIZAÇÃO
---------------------------------------------------------------

task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    if lp then
        lp.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end)

task.spawn(createUI)
print("[GAG Hub] Carregado com sucesso!")

```
