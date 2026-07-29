local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("MisteryHubGAG2") then
    PlayerGui.MisteryHubGAG2:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MisteryHubGAG2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 290)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 12)
UICornerMain.Parent = MainFrame

local UIStrokeMain = Instance.new("UIStroke")
UIStrokeMain.Color = Color3.fromRGB(147, 51, 234)
UIStrokeMain.Thickness = 2
UIStrokeMain.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local UICornerTop = Instance.new("UICorner")
UICornerTop.CornerRadius = UDim.new(0, 12)
UICornerTop.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -15, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌸 Mistery Hub | Grow a Garden 2"
Title.TextColor3 = Color3.fromRGB(216, 180, 254)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -55)
Content.Position = UDim2.new(0, 8, 0, 50)
Content.BackgroundTransparency = 1
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollBarThickness = 3
Content.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.Parent = Content

local Configs = {
    AutoFarm = false,
    AutoWater = false,
    AutoSell = false,
    AutoPet = false,
    AutoAfk = false,
    Delay = 0.15
}

local function CriarBotao(texto, estadoKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.98, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local function Atualizar()
        if Configs[estadoKey] then
            btn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            btn.Text = texto .. " [LIGADO]"
        else
            btn.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
            btn.Text = texto .. " [DESLIGADO]"
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        Configs[estadoKey] = not Configs[estadoKey]
        Atualizar()
    end)
    
    Atualizar()
    btn.Parent = Content
    return btn
end

CriarBotao("Auto Colheita [Harvest]", "AutoFarm")
CriarBotao("Auto Regador [Water]", "AutoWater")
CriarBotao("Auto Vender [Sell Crops]", "AutoSell")
CriarBotao("Auto Pets & Ovos", "AutoPet")
CriarBotao("Anti-AFK Global", "AutoAfk")

-- Loop Avançado de Auto Colheita e Plantação para GAG2
task.spawn(function()
    while true do
        if Configs.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if not Configs.AutoFarm then break end
                        if obj:IsA("ClickDetector") then
                            local modelo = obj.Parent
                            if modelo then
                                local nome = modelo.Name:lower()
                                if nome:find("plant") or nome:find("crop") or nome:find("harvest") or nome:find("flower") or nome:find("fruit") then
                                    local part = modelo:FindFirstChildWhichIsA("BasePart")
                                    if part then
                                        root.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                                        task.wait(0.05)
                                        if fireclickdetector then
                                            fireclickdetector(obj)
                                        end
                                        task.wait(Configs.Delay)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- Loop para Regar, Vender e Pets/Ovos
task.spawn(function()
    while true do
        if Configs.AutoWater or Configs.AutoSell or Configs.AutoPet then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ClickDetector") then
                        local nome = obj.Parent and obj.Parent.Name:lower() or ""
                        if Configs.AutoWater and (nome:find("water") or nome:find("regar") or nome:find("sprinkler")) then
                            if fireclickdetector then fireclickdetector(obj) end
                            task.wait(0.15)
                        end
                        if Configs.AutoSell and (nome:find("sell") or nome:find("shop") or nome:find("coin")) then
                            if fireclickdetector then fireclickdetector(obj) end
                            task.wait(0.2)
                        end
                        if Configs.AutoPet and (nome:find("pet") or nome:find("egg")) then
                            obj.MaxActivationDistance = math.huge
                            if fireclickdetector then fireclickdetector(obj) end
                            task.wait(0.15)
                        end
                    end
                end
            end)
        end
        task.wait(0.4)
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Configs.AutoAfk then
        VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end
end)

print("🚀 Mistery Hub (Grow a Garden 2) Carregado com Sucesso!")
