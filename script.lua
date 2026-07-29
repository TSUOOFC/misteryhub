local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("MisteryHubGui") then
    playerGui.MisteryHubGui:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "MisteryHubGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 250)
main.Position = UDim2.new(0.5, -160, 0.5, -125)
main.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
main.BorderSizePixel = 1
main.BorderColor3 = Color3.fromRGB(34, 197, 94)
main.Active = true
main.Draggable = true
main.Parent = sg

local uicMain = Instance.new("UICorner")
uicMain.CornerRadius = UDim.new(0, 8)
uicMain.Parent = main

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 65, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local uicSide = Instance.new("UICorner")
uicSide.CornerRadius = UDim.new(0, 8)
uicSide.Parent = sidebar

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(1, 0, 0, 40)
logo.Text = "MH"
logo.TextColor3 = Color3.fromRGB(34, 197, 94)
logo.Font = Enum.Font.SourceSansBold
logo.TextSize = 20
logo.BackgroundTransparency = 1
logo.Parent = sidebar

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 1, -40)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = sidebar

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Parent = tabContainer

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -75, 1, -10)
contentFrame.Position = UDim2.new(0, 70, 0, 5)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = main

local Estado = {
    FarmAtivo = false,
    TeleportAtivo = true,
    RegarAtivo = false,
    SprinklerAtivo = false,
    PetAtivo = false,
    AfkAtivo = false,
    SegundosIntervalo = 1.0,
    PlantaAlvo = "",
    TempoRestanteSprinkler = 0.0,
    AbaAberta = "Inicio"
}

local Paginas = {}

local function criarPagina(nome)
    local pf = Instance.new("ScrollingFrame")
    pf.Size = UDim2.new(1, 0, 1, 0)
    pf.BackgroundTransparency = 1
    pf.CanvasSize = UDim2.new(0, 0, 0, 0)
    pf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pf.ScrollBarThickness = 3
    pf.ScrollBarImageColor3 = Color3.fromRGB(63, 63, 70)
    pf.Visible = (nome == Estado.AbaAberta)
    pf.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = pf
    
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 5)
    pad.Parent = pf
    
    Paginas[nome] = pf
    return pf
end

local pInicio = criarPagina("Inicio")
local pFarm = criarPagina("Farm")
local pUtils = criarPagina("Utils")

local function alternarAba(nomeAba)
    Estado.AbaAberta = nomeAba
    for nome, pag in pairs(Paginas) do
        pag.Visible = (nome == nomeAba)
    end
end

local function criarBotaoAba(texto, nomeAba)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 4)
    uic.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        alternarAba(nomeAba)
    end)
    btn.Parent = tabContainer
end

criarBotaoAba("Início", "Inicio")
criarBotaoAba("Farm", "Farm")
criarBotaoAba("Utils", "Utils")

local function criarAlternadorMobile(pagina, texto, estadoKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 35)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 6)
    uic.Parent = btn

    local function atualizarVisual()
        if Estado[estadoKey] then
            btn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            btn.Text = texto .. ": LIGADO"
        else
            btn.BackgroundColor3 = Color3.fromRGB(162, 62, 62)
            btn.Text = texto .. ": DESLIGADO"
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        Estado[estadoKey] = not Estado[estadoKey]
        atualizarVisual()
    end)
    
    atualizarVisual()
    btn.Parent = pagina
    return btn
end

local function criarCampoTextoMobile(pagina, legenda, padrao, placeholder, callback)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.95, 0, 0, 18)
    lbl.Text = legenda
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 13
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = pagina

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.95, 0, 0, 30)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.Text = padrao
    box.PlaceholderText = placeholder
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 13
    
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 6)
    uic.Parent = box
    
    box.FocusLost:Connect(function() callback(box) end)
    box.Parent = pagina
    return box
end

local infoTxt = Instance.new("TextLabel")
infoTxt.Size = UDim2.new(0.95, 0, 0, 45)
infoTxt.Text = "Mistery Hub carregado!\nEstilo Axon Hub Mobile Ativo."
infoTxt.TextColor3 = Color3.fromRGB(150, 150, 150)
infoTxt.Font = Enum.Font.SourceSansItalic
infoTxt.TextSize = 13
infoTxt.BackgroundTransparency = 1
infoTxt.Parent = pInicio

criarAlternadorMobile(pInicio, "Anti-AFK", "AfkAtivo")

criarAlternadorMobile(pFarm, "Colheita Auto", "FarmAtivo")
criarAlternadorMobile(pFarm, "Teleporte", "TeleportAtivo")

criarCampoTextoMobile(pFarm, "Tempo de Intervalo (Segundos):", "1.0", "", function(b)
    local num = tonumber(b.Text)
    if num and num > 0 then Estado.SegundosIntervalo = num else b.Text = tostring(Estado.SegundosIntervalo) end
end)

criarCampoTextoMobile(pFarm, "Nome da Planta (Vazio = Todas):", "", "Ex: Tomato", function(b)
    Estado.PlantaAlvo = b.Text:lower()
end)

criarAlternadorMobile(pUtils, "Regar Auto", "RegarAtivo")
criarAlternadorMobile(pUtils, "Sprinkler Auto", "SprinklerAtivo")
criarAlternadorMobile(pUtils, "Comprar Pets", "PetAtivo")

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0.95, 0, 0, 32)
timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
timerLabel.Text = "⏱️ Próximo Sprinkler: --"
timerLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
timerLabel.Font = Enum.Font.SourceSansBold
timerLabel.TextSize = 13
timerLabel.Parent = pUtils

local uicTimer = Instance.new("UICorner")
uicTimer.CornerRadius = UDim.new(0, 6)
uicTimer.Parent = timerLabel

local function verificarPlantaValida(nomeModelo)
    if Estado.PlantaAlvo == "" then return true end
    return nomeModelo:lower():find(Estado.PlantaAlvo) ~= nil
end

task.spawn(function()
    while true do
        if Estado.FarmAtivo then
            pcall(function()
                local char = player.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    for _, objeto in pairs(workspace:GetDescendants()) do
                        if not Estado.FarmAtivo then break end
                        if objeto:IsA("ClickDetector") then
                            local parentModel = objeto.Parent
                            if parentModel and verificarPlantaValida(parentModel.Name) and (parentModel.Name:lower():find("garden") or parentModel.Name:lower():find("plant") or parentModel.Name:lower():find("flower")) then
                                local part = parentModel:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    if Estado.TeleportAtivo then
                                        rootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.12)
                                    end
                                    if fireclickdetector then fireclickdetector(objeto) end
                                    task.wait(Estado.SegundosIntervalo)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if Estado.RegarAtivo or Estado.SprinklerAtivo then
            pcall(function()
                for _, objeto in pairs(workspace:GetDescendants()) do
                    if objeto:IsA("ClickDetector") then
                        local parentModel = objeto.Parent
                        if parentModel and verificarPlantaValida(parentModel.Name) then
                            if Estado.RegarAtivo and (parentModel.Name:lower():find("water") or parentModel.Name:lower():find("regar") or parentModel.Name:lower():find("can")) then
                                if fireclickdetector then fireclickdetector(objeto) end
                                task.wait(Estado.SegundosIntervalo)
                            end
                            if Estado.SprinklerAtivo and (parentModel.Name:lower():find("sprinkler") or parentModel.Name:lower():find("spliker")) then
                                if fireclickdetector then fireclickdetector(objeto) end
                                Estado.TempoRestanteSprinkler = Estado.SegundosIntervalo
                                while Estado.TempoRestanteSprinkler > 0 and Estado.SprinklerAtivo do
                                    timerLabel.Text = string.format("⏱️ Próximo Sprinkler: %.1fs", Estado.TempoRestanteSprinkler)
                                    task.wait(0.1)
                                    Estado.TempoRestanteSprinkler = Estado.TempoRestanteSprinkler - 0.1
                                end
                            end
                        end
                    end
                end
            end)
        else
            timerLabel.Text = "⏱️ Próximo Sprinkler: --"
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if Estado.PetAtivo then
            pcall(function()
                for _, objeto in pairs(workspace:GetDescendants()) do
                    if not Estado.PetAtivo then break end
                    if objeto:IsA("ClickDetector") then
                        local parentModel = objeto.Parent
                        if parentModel and (parentModel.Name:lower():find("pet") or parentModel.Name:lower():find("egg")) then
                            objeto.MaxActivationDistance = math.huge
                            if fireclickdetector then fireclickdetector(objeto) end
                            task.wait(0.15)
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    if Estado.AfkAtivo then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

print("🚀 Mistery Hub executado via GitHub com sucesso!")
