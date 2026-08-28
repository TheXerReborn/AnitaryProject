--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║                         IDEKHERE HUB                           ║
    ║                Complete Blox Fruits Script Hub                 ║
    ╚════════════════════════════════════════════════════════════════╝
]]

-- ================================================================
-- [PART 1] INITIALIZATION & SERVICES
-- ================================================================
repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

-- รอโหลดตัวเกมสมบูรณ์
if not game:IsLoaded() then
    local loadingMsg = Instance.new("Message", workspace)
    loadingMsg.Text = "[IDekhere Hub] รอตัวเกมกำลังโหลด..."
    game.Loaded:Wait()
    loadingMsg:Destroy()
    task.wait(1)
end

-- ดึง Services ที่จำเป็นทั้งหมด
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

-- ตรวจสอบโลกปัจจุบัน (Sea 1, 2, 3)
local World1, World2, World3 = false, false, false
if game.PlaceId == 2753915549 then
    World1 = true
elseif game.PlaceId == 4442272183 then
    World2 = true
elseif game.PlaceId == 7449423635 then
    World3 = true
end


-- ================================================================
-- [PART 2] CONFIGURATION & SAVE/LOAD SYSTEM
-- ================================================================
local folderName = "IDekHere Hub Data"
local playerName = LocalPlayer.Name:gsub("[^%w_ ]", "")
local fileName   = folderName .. "/Blox Fruit [ " .. playerName .. " ].json"

local defaultSettings = {
    Select_Team                 = "Pirate",
    Auto_Farm_Level             = false,
    Auto_Second_Sea             = false,
    Auto_Third_Sea              = false,
    Select_Materials            = "",
    Auto_Farm_Material          = false,
    Select_Boss                 = "",
    Auto_Farm_Boss              = false,
    Auto_Farm_All_Boss          = false,
    Auto_Farm_All_Boss_Hop      = false,
    Select_Item_Type            = "Melee",
    Select_Mode_Attack          = "Fast",
    Auto_Attack                 = false,
    Select_Bring_Distance       = 250,
    Select_Mode_Bring           = "Normal",
    Bring_Mob                   = false,
    Tween_Speed                 = 250,
    Distance_For_Tp             = 150,
    Pos_X                       = 0,
    Pos_Y                       = 25,
    Pos_Z                       = 0,
    Disible_Notifications       = false,
    Auto_Activate_Race_Ability  = false,
    Auto_Activate_RaceV4_Ability= false,
    Select_Stats                = {},
    Select_Point_Stats          = 1,
    Auto_Stats                  = false,
    Auto_Super_Human            = false,
    Auto_Death_Step             = false,
    Auto_Shark_Man              = false,
    Auto_Electric_Claw          = false,
    Auto_Dragon_Talon           = false,
    Auto_God_Human              = false,
    Select_Sword                = "Katana",
    Auto_Find_Sword             = false,
    Auto_Chest                  = false,
    Auto_Random_Fruit           = false,
    Auto_Store_Fruit            = false,
    Auto_Buso                   = true,
    Auto_Ken                    = false,
}

_G.SST = defaultSettings

if not isfolder(folderName) then
    makefolder(folderName)
end

function loadcheck()
    if not isfile(fileName) then
        _G.SST = defaultSettings
        writefile(fileName, HttpService:JSONEncode(_G.SST))
    end
end

function SS()
    if _G.SST then
        writefile(fileName, HttpService:JSONEncode(_G.SST))
    else
        loadcheck()
    end
end

function LoadSetting()
    if isfile(fileName) then
        local content = readfile(fileName)
        local success, result = pcall(function()
            return HttpService:JSONDecode(content)
        end)

        if success and result then
            for k, v in pairs(defaultSettings) do
                if result[k] == nil then
                    result[k] = v
                end
            end
            _G.SST = result
        else
            _G.SST = defaultSettings
            SS()
        end
    else
        loadcheck()
    end
end

loadcheck()
LoadSetting()


-- ================================================================
-- [PART 3] AUTO SELECT TEAM
-- ================================================================
task.spawn(function()
    local gui = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not gui then return end
    local mainMinimal = gui:WaitForChild("Main (minimal)", 10) or gui:WaitForChild("Main", 10)
    if not mainMinimal then return end
    local chooseTeam = mainMinimal:FindFirstChild("ChooseTeam")

    local vim = game:GetService("VirtualInputManager")
    local function ForceClick(btn)
        if not btn then return end
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end

    local Team = _G.SST.Select_Team or "Pirate"
    if chooseTeam then
        repeat
            task.wait(0.5)
            if chooseTeam.Visible then
                if Team == "Pirate" and chooseTeam:FindFirstChild("Container") and chooseTeam.Container:FindFirstChild("Pirates") then
                    ForceClick(chooseTeam.Container.Pirates.Frame.TextButton)
                elseif Team == "Marine" and chooseTeam:FindFirstChild("Container") and chooseTeam.Container:FindFirstChild("Marines") then
                    ForceClick(chooseTeam.Container.Marines.Frame.TextButton)
                elseif chooseTeam:FindFirstChild("Container") and chooseTeam.Container:FindFirstChild("Pirates") then
                    ForceClick(chooseTeam.Container.Pirates.Frame.TextButton)
                end
            end
        until LocalPlayer.Team ~= nil or not chooseTeam.Visible
    end
end)


-- ================================================================
-- [PART 4] CORE UTILITIES & MOVEMENT
-- ================================================================
local currentTween   = nil
local StopTweenFlag  = false
local NotAutoEquip   = false

-- ฟังก์ชันสลับเซิร์ฟเวอร์ (Server Hop)
function Hop()
    local PlaceID = game.PlaceId
    local AllIDs = {}
    local foundAnything = ""
    local actualHour = os.date("!*t").hour

    pcall(function()
        AllIDs = HttpService:JSONDecode(readfile("NotSameServers.json"))
    end)
    if #AllIDs == 0 then
        table.insert(AllIDs, actualHour)
        pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs)) end)
    end

    local function TPReturner()
        local Site
        if foundAnything == "" then
            Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/0?sortOrder=2&excludeFullGames=true&limit=100'))
        else
            Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/0?sortOrder=2&excludeFullGames=true&limit=100&cursor=' .. foundAnything))
        end
        if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
            foundAnything = Site.nextPageCursor
        end
        for _, server in pairs(Site.data) do
            local Possible = true
            if server.maxPlayers > server.playing and server.id ~= game.JobId then
                for _, Existing in pairs(AllIDs) do
                    if tostring(server.id) == tostring(Existing) then
                        Possible = false
                    end
                end
                if Possible then
                    table.insert(AllIDs, server.id)
                    pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs)) end)
                    TeleportService:TeleportToPlaceInstance(PlaceID, server.id, LocalPlayer)
                    task.wait(4)
                end
            end
        end
    end
    while task.wait() do
        pcall(TPReturner)
    end
end

-- ฟังก์ชัน Rejoin เซิร์ฟเวอร์เดิม
function Rejoin()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- ฟังก์ชันหยุด Tween
function StopTween()
    StopTweenFlag = true
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("BodyClip") then
        hrp.BodyClip:Destroy()
    end
    StopTweenFlag = false
end

-- ฟังก์ชันเดินทางแบบ Tween & Instant TP
function Tween(Pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end

    local distance = (Pos.Position - hrp.Position).Magnitude

    if humanoid.Sit then
        humanoid.Sit = false
    end

    local speed = _G.SST.Tween_Speed or 250
    local tpDist = _G.SST.Distance_For_Tp or 150
    local tweenTime = math.max(distance / speed, 0.05)

    if distance <= tpDist then
        if currentTween then currentTween:Cancel() end
        hrp.CFrame = Pos
        return
    end

    if StopTweenFlag then
        if currentTween then currentTween:Cancel() end
        return
    end

    if not currentTween or (currentTween.PlaybackState ~= Enum.PlaybackState.Playing) then
        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = Pos})
        currentTween:Play()
    end
end

-- ฟังก์ชันสวมใส่อาวุธ
function Equip(ToolSe)
    if not NotAutoEquip and ToolSe and ToolSe ~= "" then
        if LocalPlayer.Backpack:FindFirstChild(ToolSe) then
            local Tool = LocalPlayer.Backpack:FindFirstChild(ToolSe)
            task.wait(0.05)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:EquipTool(Tool)
            end
        end
    end
end

function UnEquip(Weapon)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(Weapon) then
        NotAutoEquip = true
        task.wait(0.2)
        LocalPlayer.Character:FindFirstChild(Weapon).Parent = LocalPlayer.Backpack
        task.wait(0.1)
        NotAutoEquip = false
    end
end

-- Noclip & Anti-Fall ลอยตัวกันตกโลก
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local active = _G.SST.Auto_Farm_Level or _G.SST.Auto_Farm_Boss or _G.SST.Auto_Farm_All_Boss or _G.SST.Auto_Second_Sea or _G.SST.Auto_Third_Sea or _G.SST.Auto_Farm_Material or _G.SST.Auto_Find_Sword
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if active then
                    if not hrp:FindFirstChild("BodyClip") then
                        local Noclip = Instance.new("BodyVelocity")
                        Noclip.Name = "BodyClip"
                        Noclip.Parent = hrp
                        Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
                        Noclip.Velocity = Vector3.new(0, 0, 0)
                    end
                else
                    local bodyClip = hrp:FindFirstChild("BodyClip")
                    if bodyClip then bodyClip:Destroy() end
                end
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    pcall(function()
        local active = _G.SST.Auto_Farm_Level or _G.SST.Auto_Farm_Boss or _G.SST.Auto_Farm_All_Boss or _G.SST.Auto_Second_Sea or _G.SST.Auto_Third_Sea or _G.SST.Auto_Farm_Material or _G.SST.Auto_Find_Sword
        if active and LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)
end)


-- ================================================================
-- [PART 5] COMBAT ENGINE
-- ================================================================
_G.SpeedAttack = 0.05

-- ฟังก์ชันเปิดใช้งานฮาคิเกราะ (Buso)
function AutoHaki()
    pcall(function()
        if _G.SST.Auto_Buso and not LocalPlayer.Character:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

-- Fast Attack ระบบโจมตีความเร็วสูง
function Click()
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return end
        local args = { [1] = nil, [2] = {} }
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                table.insert(args[2], { [1] = enemy, [2] = enemy.HumanoidRootPart })
                if not args[1] then args[1] = enemy.HumanoidRootPart end
            end
        end
        if args[1] then
            local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
            if net then
                if net:FindFirstChild("RE/RegisterAttack") then net["RE/RegisterAttack"]:FireServer(1) end
                if net:FindFirstChild("RE/RegisterHit") then net["RE/RegisterHit"]:FireServer(unpack(args)) end
            end
        end
    end)
end


-- ================================================================
-- [PART 6] QUEST & FARMING DATABASE
-- ================================================================
local Mon, LevelQuest, NameQuest, NameMon, CFrameQuest, PUK
local PosMon = nil

-- ข้อมูลเควสและการฟาร์ม (โลก 1, 2, 3)
function QuestFunction()
    local MyLevel = LocalPlayer.Data.Level.Value
    if World1 then
        if MyLevel <= 9 then
            Mon, LevelQuest, NameQuest, NameMon = "Bandit", 1, "BanditQuest1", "Bandit"
            PUK = CFrame.new(1216, 56, 1606)
            CFrameQuest = CFrame.new(1059, 15, 1550)
        elseif MyLevel <= 14 then
            Mon, LevelQuest, NameQuest, NameMon = "Monkey", 1, "JungleQuest", "Monkey"
            PUK = CFrame.new(-1496, 63, 35)
            CFrameQuest = CFrame.new(-1598, 35, 153)
        elseif MyLevel <= 29 then
            Mon, LevelQuest, NameQuest, NameMon = "Gorilla", 2, "JungleQuest", "Gorilla"
            PUK = CFrame.new(-1257, 65, -499)
            CFrameQuest = CFrame.new(-1598, 35, 153)
        elseif MyLevel <= 39 then
            Mon, LevelQuest, NameQuest, NameMon = "Pirate", 1, "BuggyQuest1", "Pirate"
            PUK = CFrame.new(-1178, 65, 3889)
            CFrameQuest = CFrame.new(-1141, 4, 3831)
        elseif MyLevel <= 59 then
            Mon, LevelQuest, NameQuest, NameMon = "Brute", 2, "BuggyQuest1", "Brute"
            PUK = CFrame.new(-1144, 90, 4307)
            CFrameQuest = CFrame.new(-1141, 4, 3831)
        elseif MyLevel <= 74 then
            Mon, LevelQuest, NameQuest, NameMon = "Desert Bandit", 1, "DesertQuest", "Desert Bandit"
            PUK = CFrame.new(919, 69, 4487)
            CFrameQuest = CFrame.new(894, 5, 4392)
        elseif MyLevel <= 89 then
            Mon, LevelQuest, NameQuest, NameMon = "Desert Officer", 2, "DesertQuest", "Desert Officer"
            PUK = CFrame.new(1580, 4, 4366)
            CFrameQuest = CFrame.new(894, 5, 4392)
        elseif MyLevel <= 99 then
            Mon, LevelQuest, NameQuest, NameMon = "Snow Bandit", 1, "SnowQuest", "Snow Bandit"
            PUK = CFrame.new(1365, 124, -1364)
            CFrameQuest = CFrame.new(1389, 88, -1298)
        elseif MyLevel <= 119 then
            Mon, LevelQuest, NameQuest, NameMon = "Snowman", 2, "SnowQuest", "Snowman"
            PUK = CFrame.new(1122, 143, -1539)
            CFrameQuest = CFrame.new(1389, 88, -1298)
        elseif MyLevel <= 149 then
            Mon, LevelQuest, NameQuest, NameMon = "Chief Petty Officer", 1, "MarineQuest2", "Chief Petty Officer"
            PUK = CFrame.new(-4882, 22, 4255)
            CFrameQuest = CFrame.new(-5039, 27, 4324)
        elseif MyLevel <= 174 then
            Mon, LevelQuest, NameQuest, NameMon = "Sky Bandit", 1, "SkyQuest", "Sky Bandit"
            PUK = CFrame.new(-4970, 294, -2890)
            CFrameQuest = CFrame.new(-4839, 716, -2619)
        elseif MyLevel <= 189 then
            Mon, LevelQuest, NameQuest, NameMon = "Dark Master", 2, "SkyQuest", "Dark Master"
            PUK = CFrame.new(-5220, 430, -2278)
            CFrameQuest = CFrame.new(-4839, 716, -2619)
        elseif MyLevel <= 209 then
            Mon, LevelQuest, NameQuest, NameMon = "Prisoner", 1, "PrisonerQuest", "Prisoner"
            PUK = CFrame.new(5308, 1, 475)
            CFrameQuest = CFrame.new(5308, 1, 475)
        elseif MyLevel <= 249 then
            Mon, LevelQuest, NameQuest, NameMon = "Dangerous Prisoner", 2, "PrisonerQuest", "Dangerous Prisoner"
            PUK = CFrame.new(5563, 67, 832)
            CFrameQuest = CFrame.new(5308, 1, 475)
        elseif MyLevel <= 299 then
            Mon, LevelQuest, NameQuest, NameMon = "Toga Warrior", 1, "ColosseumQuest", "Toga Warrior"
            PUK = CFrame.new(-1848, 42, -2794)
            CFrameQuest = CFrame.new(-1580, 6, -2986)
        elseif MyLevel <= 324 then
            Mon, LevelQuest, NameQuest, NameMon = "Military Soldier", 1, "MagmaQuest", "Military Soldier"
            PUK = CFrame.new(-5461, 44, 8457)
            CFrameQuest = CFrame.new(-5313, 10, 8515)
        elseif MyLevel <= 374 then
            Mon, LevelQuest, NameQuest, NameMon = "Military Spy", 2, "MagmaQuest", "Military Spy"
            PUK = CFrame.new(-5872, 143, 8790)
            CFrameQuest = CFrame.new(-5313, 10, 8515)
        elseif MyLevel <= 399 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Warrior", 1, "FishmanQuest", "Fishman Warrior"
            PUK = CFrame.new(60875, 35, 1434)
            CFrameQuest = CFrame.new(61122, 18, 1569)
        elseif MyLevel <= 449 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Commando", 2, "FishmanQuest", "Fishman Commando"
            PUK = CFrame.new(61914, 82, 1461)
            CFrameQuest = CFrame.new(61122, 18, 1569)
        elseif MyLevel <= 474 then
            Mon, LevelQuest, NameQuest, NameMon = "God's Guard", 1, "SkyExp1Quest", "God's Guard"
            PUK = CFrame.new(-4721, 843, -1949)
            CFrameQuest = CFrame.new(-4721, 843, -1949)
        elseif MyLevel <= 524 then
            Mon, LevelQuest, NameQuest, NameMon = "Shanda", 2, "SkyExp1Quest", "Shanda"
            PUK = CFrame.new(-7658, 5605, -529)
            CFrameQuest = CFrame.new(-7859, 5544, -381)
        elseif MyLevel <= 549 then
            Mon, LevelQuest, NameQuest, NameMon = "Royal Squad", 1, "SkyExp2Quest", "Royal Squad"
            PUK = CFrame.new(-7669, 5638, -1448)
            CFrameQuest = CFrame.new(-7906, 5634, -1411)
        elseif MyLevel <= 624 then
            Mon, LevelQuest, NameQuest, NameMon = "Royal Soldier", 2, "SkyExp2Quest", "Royal Soldier"
            PUK = CFrame.new(-7839, 5681, -1717)
            CFrameQuest = CFrame.new(-7906, 5634, -1411)
        elseif MyLevel <= 649 then
            Mon, LevelQuest, NameQuest, NameMon = "Galley Pirate", 1, "FountainQuest", "Galley Pirate"
            PUK = CFrame.new(5566, 71, 3964)
            CFrameQuest = CFrame.new(5259, 37, 4050)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Galley Captain", 2, "FountainQuest", "Galley Captain"
            PUK = CFrame.new(5344, 104, 4821)
            CFrameQuest = CFrame.new(5259, 37, 4050)
        end
    elseif World2 then
        if MyLevel <= 724 then
            Mon, LevelQuest, NameQuest, NameMon = "Raider", 1, "Area1Quest", "Raider"
            PUK = CFrame.new(-737, 39, 2392)
            CFrameQuest = CFrame.new(-429, 71, 1836)
        elseif MyLevel <= 774 then
            Mon, LevelQuest, NameQuest, NameMon = "Mercenary", 2, "Area1Quest", "Mercenary"
            PUK = CFrame.new(-1016, 133, 1433)
            CFrameQuest = CFrame.new(-429, 71, 1836)
        elseif MyLevel <= 874 then
            Mon, LevelQuest, NameQuest, NameMon = "Swan Pirate", 1, "Area2Quest", "Swan Pirate"
            PUK = CFrame.new(970, 142, 1217)
            CFrameQuest = CFrame.new(638, 71, 918)
        elseif MyLevel <= 899 then
            Mon, LevelQuest, NameQuest, NameMon = "Marine Lieutenant", 1, "MarineQuest3", "Marine Lieutenant"
            PUK = CFrame.new(-2929, 163, -3027)
            CFrameQuest = CFrame.new(-2440, 71, -3216)
        elseif MyLevel <= 949 then
            Mon, LevelQuest, NameQuest, NameMon = "Marine Captain", 2, "MarineQuest3", "Marine Captain"
            PUK = CFrame.new(-1932, 131, -3291)
            CFrameQuest = CFrame.new(-2440, 71, -3216)
        elseif MyLevel <= 999 then
            Mon, LevelQuest, NameQuest, NameMon = "Zombie", 1, "ZombieQuest", "Zombie"
            PUK = CFrame.new(-5695, 124, -775)
            CFrameQuest = CFrame.new(-5497, 47, -795)
        elseif MyLevel <= 1049 then
            Mon, LevelQuest, NameQuest, NameMon = "Snow Trooper", 1, "SnowMountainQuest", "Snow Trooper"
            PUK = CFrame.new(535, 401, -5329)
            CFrameQuest = CFrame.new(609, 400, -5372)
        elseif MyLevel <= 1099 then
            Mon, LevelQuest, NameQuest, NameMon = "Winter Warrior", 2, "SnowMountainQuest", "Winter Warrior"
            PUK = CFrame.new(1223, 454, -5170)
            CFrameQuest = CFrame.new(609, 400, -5372)
        elseif MyLevel <= 1124 then
            Mon, LevelQuest, NameQuest, NameMon = "Lab Subordinate", 1, "IceSideQuest", "Lab Subordinate"
            PUK = CFrame.new(-6060, 15, -4904)
            CFrameQuest = CFrame.new(-6064, 15, -4902)
        elseif MyLevel <= 1174 then
            Mon, LevelQuest, NameQuest, NameMon = "Horned Warrior", 2, "IceSideQuest", "Horned Warrior"
            PUK = CFrame.new(-6400, 24, -5818)
            CFrameQuest = CFrame.new(-6064, 15, -4902)
        elseif MyLevel <= 1199 then
            Mon, LevelQuest, NameQuest, NameMon = "Magma Ninja", 1, "FireSideQuest", "Magma Ninja"
            PUK = CFrame.new(-5496, 58, -5929)
            CFrameQuest = CFrame.new(-5428, 15, -5299)
        elseif MyLevel <= 1249 then
            Mon, LevelQuest, NameQuest, NameMon = "Lava Pirate", 2, "FireSideQuest", "Lava Pirate"
            PUK = CFrame.new(-5169, 34, -4669)
            CFrameQuest = CFrame.new(-5428, 15, -5299)
        elseif MyLevel <= 1274 then
            Mon, LevelQuest, NameQuest, NameMon = "Ship Deckhand", 1, "ShipQuest1", "Ship Deckhand"
            PUK = CFrame.new(1181, 130, 33005)
            CFrameQuest = CFrame.new(1037, 125, 32911)
        elseif MyLevel <= 1299 then
            Mon, LevelQuest, NameQuest, NameMon = "Ship Engineer", 2, "ShipQuest1", "Ship Engineer"
            PUK = CFrame.new(919, 43, 32781)
            CFrameQuest = CFrame.new(1037, 125, 32911)
        elseif MyLevel <= 1324 then
            Mon, LevelQuest, NameQuest, NameMon = "Ship Steward", 1, "ShipQuest2", "Ship Steward"
            PUK = CFrame.new(917, 129, 33441)
            CFrameQuest = CFrame.new(968, 125, 33244)
        elseif MyLevel <= 1349 then
            Mon, LevelQuest, NameQuest, NameMon = "Ship Officer", 2, "ShipQuest2", "Ship Officer"
            PUK = CFrame.new(1201, 181, 33308)
            CFrameQuest = CFrame.new(968, 125, 33244)
        elseif MyLevel <= 1374 then
            Mon, LevelQuest, NameQuest, NameMon = "Arctic Warrior", 1, "FrostQuest", "Arctic Warrior"
            PUK = CFrame.new(5667, 26, -6486)
            CFrameQuest = CFrame.new(5667, 26, -6486)
        elseif MyLevel <= 1424 then
            Mon, LevelQuest, NameQuest, NameMon = "Snow Lurker", 2, "FrostQuest", "Snow Lurker"
            PUK = CFrame.new(5518, 60, -6828)
            CFrameQuest = CFrame.new(5667, 26, -6486)
        elseif MyLevel <= 1449 then
            Mon, LevelQuest, NameQuest, NameMon = "Sea Soldier", 1, "ForgottenQuest", "Sea Soldier"
            PUK = CFrame.new(-3366, 47, -9704)
            CFrameQuest = CFrame.new(-3054, 235, -10142)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Water Fighter", 2, "ForgottenQuest", "Water Fighter"
            PUK = CFrame.new(-3436, 290, -10503)
            CFrameQuest = CFrame.new(-3054, 235, -10142)
        end
    elseif World3 then
        if MyLevel <= 1524 then
            Mon, LevelQuest, NameQuest, NameMon = "Pirate Millionaire", 1, "PiratePortQuest", "Pirate Millionaire"
            PUK = CFrame.new(-290, 34, 5417)
            CFrameQuest = CFrame.new(-290, 42, 5581)
        elseif MyLevel <= 1574 then
            Mon, LevelQuest, NameQuest, NameMon = "Pistol Billionaire", 2, "PiratePortQuest", "Pistol Billionaire"
            PUK = CFrame.new(-387, 74, 5851)
            CFrameQuest = CFrame.new(-290, 42, 5581)
        elseif MyLevel <= 1599 then
            Mon, LevelQuest, NameQuest, NameMon = "Dragon Crew Warrior", 1, "AmazonQuest", "Dragon Crew Warrior"
            PUK = CFrame.new(6241, 51, -1243)
            CFrameQuest = CFrame.new(5832, 51, -1101)
        elseif MyLevel <= 1624 then
            Mon, LevelQuest, NameQuest, NameMon = "Dragon Crew Archer", 2, "AmazonQuest", "Dragon Crew Archer"
            PUK = CFrame.new(6788, 462, 164)
            CFrameQuest = CFrame.new(5833, 51, -1103)
        elseif MyLevel <= 1649 then
            Mon, LevelQuest, NameQuest, NameMon = "Female Islander", 1, "AmazonQuest2", "Female Islander"
            PUK = CFrame.new(5763, 848, 1082)
            CFrameQuest = CFrame.new(5446, 601, 749)
        elseif MyLevel <= 1699 then
            Mon, LevelQuest, NameQuest, NameMon = "Giant Islander", 2, "AmazonQuest2", "Giant Islander"
            PUK = CFrame.new(4784, 708, 466)
            CFrameQuest = CFrame.new(5446, 601, 749)
        elseif MyLevel <= 1724 then
            Mon, LevelQuest, NameQuest, NameMon = "Marine Commodore", 1, "MarineTreeIsland", "Marine Commodore"
            PUK = CFrame.new(2490, 190, -7160)
            CFrameQuest = CFrame.new(2180, 27, -6741)
        elseif MyLevel <= 1774 then
            Mon, LevelQuest, NameQuest, NameMon = "Marine Rear Admiral", 2, "MarineTreeIsland", "Marine Rear Admiral"
            PUK = CFrame.new(3951, 229, -6912)
            CFrameQuest = CFrame.new(2179, 28, -6740)
        elseif MyLevel <= 1799 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Raider", 1, "DeepForestIsland3", "Fishman Raider"
            PUK = CFrame.new(-10322, 390, -8580)
            CFrameQuest = CFrame.new(-10581, 330, -8761)
        elseif MyLevel <= 1824 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Captain", 2, "DeepForestIsland3", "Fishman Captain"
            PUK = CFrame.new(-11194, 442, -8608)
            CFrameQuest = CFrame.new(-10581, 330, -8761)
        elseif MyLevel <= 1849 then
            Mon, LevelQuest, NameQuest, NameMon = "Forest Pirate", 1, "DeepForestIsland", "Forest Pirate"
            PUK = CFrame.new(-13225, 428, -7753)
            CFrameQuest = CFrame.new(-13234, 331, -7625)
        elseif MyLevel <= 1899 then
            Mon, LevelQuest, NameQuest, NameMon = "Mythological Pirate", 2, "DeepForestIsland", "Mythological Pirate"
            PUK = CFrame.new(-13869, 564, -7084)
            CFrameQuest = CFrame.new(-13234, 331, -7625)
        elseif MyLevel <= 1924 then
            Mon, LevelQuest, NameQuest, NameMon = "Jungle Pirate", 1, "DeepForestIsland2", "Jungle Pirate"
            PUK = CFrame.new(-11982, 376, -10451)
            CFrameQuest = CFrame.new(-12680, 389, -9902)
        elseif MyLevel <= 1974 then
            Mon, LevelQuest, NameQuest, NameMon = "Musketeer Pirate", 2, "DeepForestIsland2", "Musketeer Pirate"
            PUK = CFrame.new(-13282, 496, -9565)
            CFrameQuest = CFrame.new(-12680, 389, -9902)
        elseif MyLevel <= 1999 then
            Mon, LevelQuest, NameQuest, NameMon = "Reborn Skeleton", 1, "HauntedQuest1", "Reborn Skeleton"
            PUK = CFrame.new(-8817, 191, 6298)
            CFrameQuest = CFrame.new(-9479, 141, 5566)
        elseif MyLevel <= 2024 then
            Mon, LevelQuest, NameQuest, NameMon = "Living Zombie", 2, "HauntedQuest1", "Living Zombie"
            PUK = CFrame.new(-10125, 183, 6242)
            CFrameQuest = CFrame.new(-9479, 141, 5566)
        elseif MyLevel <= 2049 then
            Mon, LevelQuest, NameQuest, NameMon = "Demonic Soul", 1, "HauntedQuest2", "Demonic Soul"
            PUK = CFrame.new(-9712, 204, 6193)
            CFrameQuest = CFrame.new(-9516, 172, 6078)
        elseif MyLevel <= 2074 then
            Mon, LevelQuest, NameQuest, NameMon = "Posessed Mummy", 2, "HauntedQuest2", "Posessed Mummy"
            PUK = CFrame.new(-9545, 69, 6339)
            CFrameQuest = CFrame.new(-9516, 172, 6078)
        elseif MyLevel <= 2099 then
            Mon, LevelQuest, NameQuest, NameMon = "Peanut Scout", 1, "NutsIslandQuest", "Peanut Scout"
            PUK = CFrame.new(-2265, 89, -10261)
            CFrameQuest = CFrame.new(-2104, 38, -10194)
        elseif MyLevel <= 2124 then
            Mon, LevelQuest, NameQuest, NameMon = "Peanut President", 2, "NutsIslandQuest", "Peanut President"
            PUK = CFrame.new(-2062, 86, -10481)
            CFrameQuest = CFrame.new(-2104, 38, -10194)
        elseif MyLevel <= 2149 then
            Mon, LevelQuest, NameQuest, NameMon = "Ice Cream Chef", 1, "IceCreamIslandQuest", "Ice Cream Chef"
            PUK = CFrame.new(-875, 107, -11253)
            CFrameQuest = CFrame.new(-820, 65, -10965)
        elseif MyLevel <= 2199 then
            Mon, LevelQuest, NameQuest, NameMon = "Ice Cream Commander", 2, "IceCreamIslandQuest", "Ice Cream Commander"
            PUK = CFrame.new(-643, 140, -11334)
            CFrameQuest = CFrame.new(-820, 65, -10965)
        elseif MyLevel <= 2224 then
            Mon, LevelQuest, NameQuest, NameMon = "Cookie Crafter", 1, "CakeQuest1", "Cookie Crafter"
            PUK = CFrame.new(-2437, 133, -12122)
            CFrameQuest = CFrame.new(-2021, 37, -12028)
        elseif MyLevel <= 2249 then
            Mon, LevelQuest, NameQuest, NameMon = "Cake Guard", 2, "CakeQuest1", "Cake Guard"
            PUK = CFrame.new(-1595, 44, -12252)
            CFrameQuest = CFrame.new(-2021, 37, -12028)
        elseif MyLevel <= 2274 then
            Mon, LevelQuest, NameQuest, NameMon = "Baking Staff", 1, "CakeQuest2", "Baking Staff"
            PUK = CFrame.new(-1817, 93, -12885)
            CFrameQuest = CFrame.new(-1927, 37, -12842)
        elseif MyLevel <= 2299 then
            Mon, LevelQuest, NameQuest, NameMon = "Head Baker", 2, "CakeQuest2", "Head Baker"
            PUK = CFrame.new(-2263, 156, -12776)
            CFrameQuest = CFrame.new(-1927, 37, -12842)
        elseif MyLevel <= 2324 then
            Mon, LevelQuest, NameQuest, NameMon = "Cocoa Warrior", 1, "ChocQuest1", "Cocoa Warrior"
            PUK = CFrame.new(-103, 141, -12260)
            CFrameQuest = CFrame.new(231, 25, -12199)
        elseif MyLevel <= 2349 then
            Mon, LevelQuest, NameQuest, NameMon = "Chocolate Bar Battler", 2, "ChocQuest1", "Chocolate Bar Battler"
            PUK = CFrame.new(617, 80, -12580)
            CFrameQuest = CFrame.new(231, 25, -12199)
        elseif MyLevel <= 2374 then
            Mon, LevelQuest, NameQuest, NameMon = "Sweet Thief", 1, "ChocQuest2", "Sweet Thief"
            PUK = CFrame.new(72, 77, -12640)
            CFrameQuest = CFrame.new(149, 24, -12775)
        elseif MyLevel <= 2399 then
            Mon, LevelQuest, NameQuest, NameMon = "Candy Rebel", 2, "ChocQuest2", "Candy Rebel"
            PUK = CFrame.new(420, 109, -12989)
            CFrameQuest = CFrame.new(149, 24, -12775)
        elseif MyLevel <= 2424 then
            Mon, LevelQuest, NameQuest, NameMon = "Candy Pirate", 1, "CandyQuest1", "Candy Pirate"
            PUK = CFrame.new(-1218, 174, -14536)
            CFrameQuest = CFrame.new(-1147, 16, -14445)
        elseif MyLevel <= 2449 then
            Mon, LevelQuest, NameQuest, NameMon = "Snow Demon", 2, "CandyQuest1", "Snow Demon"
            PUK = CFrame.new(-989, 142, -14594)
            CFrameQuest = CFrame.new(-1147, 16, -14445)
        elseif MyLevel <= 2474 then
            Mon, LevelQuest, NameQuest, NameMon = "Isle Outlaw", 1, "TikiQuest1", "Isle Outlaw"
            PUK = CFrame.new(-16548, 55, -172)
            CFrameQuest = CFrame.new(-16548, 55, -172)
        elseif MyLevel <= 2524 then
            Mon, LevelQuest, NameQuest, NameMon = "Island Boy", 2, "TikiQuest1", "Island Boy"
            PUK = CFrame.new(-16548, 55, -172)
            CFrameQuest = CFrame.new(-16548, 55, -172)
        elseif MyLevel <= 2549 then
            Mon, LevelQuest, NameQuest, NameMon = "Isle Champion", 2, "TikiQuest2", "Isle Champion"
            PUK = CFrame.new(-16541, 54, 1051)
            CFrameQuest = CFrame.new(-16541, 54, 1051)
        elseif MyLevel <= 2574 then
            Mon, LevelQuest, NameQuest, NameMon = "Serpent Hunter", 1, "TikiQuest3", "Serpent Hunter"
            PUK = CFrame.new(-16665, 104, 1579)
            CFrameQuest = CFrame.new(-16665, 104, 1579)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Skull Slayer", 2, "TikiQuest3", "Skull Slayer"
            PUK = CFrame.new(-16665, 104, 1579)
            CFrameQuest = CFrame.new(-16665, 104, 1579)
        end
    end
end


-- ================================================================
-- [PART 7] UI ENGINE (macOS THEME)
-- ================================================================
local oldGui = CoreGui:FindFirstChild("IDekhere Hub")
if oldGui then oldGui:Destroy() end

local Update = {}

function Update:AddWindow(hubName, logo, keybind)
    local keybind = keybind or Enum.KeyCode.RightControl

    local IDekhere_Hub = Instance.new("ScreenGui")
    IDekhere_Hub.Name = "IDekhere Hub"
    IDekhere_Hub.Parent = CoreGui
    IDekhere_Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Main = Instance.new("Frame")
    local WindowStrokemain = Instance.new("UIStroke")
    Main.Name = "Main"
    Main.Parent = IDekhere_Hub
    Main.ClipsDescendants = true
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 600, 0, 400)

    WindowStrokemain.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    WindowStrokemain.Color = Color3.fromRGB(255, 255, 255)
    WindowStrokemain.Thickness = 1
    WindowStrokemain.Parent = Main

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

    local Top = Instance.new("Frame", Main)
    Top.Name = "Top"
    Top.Size = UDim2.new(1, 0, 0, 32)
    Top.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 8)

    -- ฟังก์ชันทำให้หน้าต่างลากได้
    local function MakeDraggable(topbarobject, object)
        local Dragging, DragInput, DragStart, StartPosition
        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartPosition = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then Dragging = false end
                end)
            end
        end)
        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                local Delta = input.Position - DragStart
                object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
            end
        end)
    end
    MakeDraggable(Top, Main)

    -- ปุ่ม macOS 3 สี (Close, Minimize, Maximize)
    local function createMacButton(name, color, posX, onClick)
        local button = Instance.new("TextButton", Top)
        button.Name = name
        button.BackgroundColor3 = color
        button.Size = UDim2.new(0, 14, 0, 14)
        button.Position = UDim2.new(0, posX, 0, 9)
        button.Text = ""
        button.AutoButtonColor = false
        Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
        button.MouseButton1Click:Connect(onClick)
        return button
    end

    -- 🔴 ปุ่มปิด (Close)
    createMacButton("CloseBtn", Color3.fromRGB(255, 59, 48), 10, function()
        if IDekhere_Hub:FindFirstChild("ConfirmFrame") then return end

        local confirmFrame = Instance.new("Frame", IDekhere_Hub)
        confirmFrame.Name = "ConfirmFrame"
        confirmFrame.Size = UDim2.new(0, 300, 0, 140)
        confirmFrame.Position = UDim2.new(0.5, -150, 0.5, -70)
        confirmFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        confirmFrame.ZIndex = 9999
        Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", confirmFrame)
        stroke.Color = Color3.fromRGB(255, 59, 48)

        local label = Instance.new("TextLabel", confirmFrame)
        label.Size = UDim2.new(1, -20, 0, 50)
        label.Position = UDim2.new(0, 10, 0, 15)
        label.Text = "คุณต้องการปิด IDekhere Hub จริงหรือไม่?"
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.Code
        label.TextSize = 14
        label.ZIndex = 10000

        local yesBtn = Instance.new("TextButton", confirmFrame)
        yesBtn.Size = UDim2.new(0.4, 0, 0, 32)
        yesBtn.Position = UDim2.new(0.08, 0, 1, -45)
        yesBtn.Text = "ตกลง"
        yesBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        yesBtn.Font = Enum.Font.Code
        yesBtn.ZIndex = 10000
        Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 6)

        local noBtn = Instance.new("TextButton", confirmFrame)
        noBtn.Size = UDim2.new(0.4, 0, 0, 32)
        noBtn.Position = UDim2.new(0.52, 0, 1, -45)
        noBtn.Text = "ยกเลิก"
        noBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        noBtn.Font = Enum.Font.Code
        noBtn.ZIndex = 10000
        Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 6)

        yesBtn.MouseButton1Click:Connect(function() IDekhere_Hub:Destroy() end)
        noBtn.MouseButton1Click:Connect(function() confirmFrame:Destroy() end)
    end)

    -- 🟡 ปุ่มย่อลง Dock (Minimize)
    local originalSize = UDim2.new(0, 600, 0, 400)
    local originalPos = UDim2.new(0.5, 0, 0.5, 0)
    local isMinimized = false

    local function toggleRestore()
        local restoreBtn = IDekhere_Hub:FindFirstChild("RestoreButton")
        if isMinimized and restoreBtn then
            Main.Visible = true
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = originalSize,
                Position = originalPos,
                BackgroundTransparency = 0
            }):Play()
            restoreBtn:Destroy()
            isMinimized = false
        elseif not isMinimized then
            originalSize = Main.Size
            originalPos = Main.Position
            isMinimized = true

            local shrinkTween = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.05, 0, 0.9, 0),
                BackgroundTransparency = 1
            })
            shrinkTween:Play()
            shrinkTween.Completed:Connect(function()
                Main.Visible = false
                local restoreBtn = Instance.new("ImageButton", IDekhere_Hub)
                restoreBtn.Name = "RestoreButton"
                restoreBtn.Size = UDim2.new(0, 45, 0, 45)
                restoreBtn.Position = UDim2.new(0.02, 0, 0.85, 0)
                restoreBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                restoreBtn.Image = "rbxassetid://108287073891881"
                restoreBtn.ZIndex = 9999
                restoreBtn.Draggable = true

                Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(0, 10)
                local s = Instance.new("UIStroke", restoreBtn)
                s.Color = Color3.fromRGB(255, 204, 0)
                s.Thickness = 1.5

                restoreBtn.MouseButton1Click:Connect(toggleRestore)
            end)
        end
    end

    createMacButton("MinimizeBtn", Color3.fromRGB(255, 204, 0), 28, toggleRestore)

    -- 🟢 ปุ่มขยายเต็มจอ (Maximize)
    local isMaximized = false
    createMacButton("MaximizeBtn", Color3.fromRGB(52, 199, 89), 46, function()
        if not isMaximized then
            originalSize = Main.Size
            originalPos = Main.Position
            Main:TweenSizeAndPosition(UDim2.new(0.95, 0, 0.9, 0), UDim2.new(0.5, 0, 0.5, 0), "Out", "Quad", 0.3, true)
            isMaximized = true
        else
            Main:TweenSizeAndPosition(originalSize, originalPos, "Out", "Quad", 0.3, true)
            isMaximized = false
        end
    end)

    -- ป้ายชื่อ Hub
    local NameLabel = Instance.new("TextLabel", Top)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Position = UDim2.new(0, 70, 0, 0)
    NameLabel.Size = UDim2.new(0, 120, 1, 0)
    NameLabel.Font = Enum.Font.Code
    NameLabel.Text = hubName
    NameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    NameLabel.TextSize = 13
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Hotkey Toggle UI
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == keybind then
            if isMinimized then
                toggleRestore()
            else
                Main.Visible = not Main.Visible
            end
        end
    end)

    -- แถบ Tab และ Container
    local TabBar = Instance.new("ScrollingFrame", Top)
    TabBar.Name = "TabBar"
    TabBar.Position = UDim2.new(0, 190, 0, 2)
    TabBar.Size = UDim2.new(1, -200, 1, -4)
    TabBar.BackgroundTransparency = 1
    TabBar.ScrollBarThickness = 0
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)

    local TabListLayout = Instance.new("UIListLayout", TabBar)
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.Padding = UDim.new(0, 4)

    local PageContainer = Instance.new("Frame", Main)
    PageContainer.Name = "PageContainer"
    PageContainer.Position = UDim2.new(0, 0, 0, 35)
    PageContainer.Size = UDim2.new(1, 0, 1, -35)
    PageContainer.BackgroundTransparency = 1

    local PageLayout = Instance.new("UIPageLayout", PageContainer)
    PageLayout.EasingStyle = Enum.EasingStyle.Quad
    PageLayout.EasingDirection = Enum.EasingDirection.Out
    PageLayout.TweenTime = 0.25

    local uitab = {}
    local firstTab = true

    function uitab:AddTab(title, icon)
        local TabButton = Instance.new("TextButton", TabBar)
        TabButton.Name = title .. "_Btn"
        TabButton.Text = title
        TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TabButton.Size = UDim2.new(0, 95, 1, 0)
        TabButton.Font = Enum.Font.Code
        TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabButton.TextSize = 11
        Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)

        local PageFrame = Instance.new("Frame", PageContainer)
        PageFrame.Name = title .. "_Page"
        PageFrame.Size = UDim2.new(1, 0, 1, 0)
        PageFrame.BackgroundTransparency = 1

        -- คอลัมน์ซ้าย (Left Column)
        local MainFramePage = Instance.new("ScrollingFrame", PageFrame)
        MainFramePage.Name = "LeftCol"
        MainFramePage.Position = UDim2.new(0, 8, 0, 5)
        MainFramePage.Size = UDim2.new(0.48, 0, 0.96, 0)
        MainFramePage.BackgroundTransparency = 1
        MainFramePage.ScrollBarThickness = 2

        -- คอลัมน์ขวา (Right Column)
        local MainFramePage2 = Instance.new("ScrollingFrame", PageFrame)
        MainFramePage2.Name = "RightCol"
        MainFramePage2.Position = UDim2.new(0.51, 0, 0, 5)
        MainFramePage2.Size = UDim2.new(0.48, 0, 0.96, 0)
        MainFramePage2.BackgroundTransparency = 1
        MainFramePage2.ScrollBarThickness = 2

        local LayoutL = Instance.new("UIListLayout", MainFramePage)
        LayoutL.Padding = UDim.new(0, 5)
        local LayoutR = Instance.new("UIListLayout", MainFramePage2)
        LayoutR.Padding = UDim.new(0, 5)

        LayoutL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            MainFramePage.CanvasSize = UDim2.new(0, 0, 0, LayoutL.AbsoluteContentSize.Y + 15)
        end)
        LayoutR:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            MainFramePage2.CanvasSize = UDim2.new(0, 0, 0, LayoutR.AbsoluteContentSize.Y + 15)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, btn in pairs(TabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                end
            end
            TabButton.TextColor3 = Color3.fromRGB(0, 255, 255)
            TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            PageLayout:JumpTo(PageFrame)
        end)

        if firstTab then
            TabButton.TextColor3 = Color3.fromRGB(0, 255, 255)
            TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            firstTab = false
        end

        TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabBar.CanvasSize = UDim2.new(0, TabListLayout.AbsoluteContentSize.X + 10, 0, 0)
        end)

        -- Component Library (Elements)
        local elements = {}

        -- 1. Separators & Dividers
        local function addSep(parent, text)
            local sep = Instance.new("Frame", parent)
            sep.Size = UDim2.new(0.98, 0, 0, 22)
            sep.BackgroundTransparency = 1
            local label = Instance.new("TextLabel", sep)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "── " .. text .. " ──"
            label.Font = Enum.Font.Code
            label.TextColor3 = Color3.fromRGB(0, 255, 255)
            label.TextSize = 13
        end
        function elements:AddSeperatorL(text) addSep(MainFramePage, text) end
        function elements:AddSeperatorR(text) addSep(MainFramePage2, text) end
        function elements:AddLineL() addSep(MainFramePage, "──────") end
        function elements:AddLineR() addSep(MainFramePage2, "──────") end

        -- 2. Labels
        local function addLab(parent, text)
            local lbl = Instance.new("TextLabel", parent)
            lbl.Size = UDim2.new(0.98, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.Font = Enum.Font.Code
            lbl.TextColor3 = Color3.fromRGB(225, 225, 225)
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            local obj = {}
            function obj:Set(newT) lbl.Text = newT end
            return obj
        end
        function elements:AddLabelL(text) return addLab(MainFramePage, text) end
        function elements:AddLabelR(text) return addLab(MainFramePage2, text) end

        -- 3. Buttons
        local function addBtn(parent, text, cb)
            local btn = Instance.new("TextButton", parent)
            btn.Size = UDim2.new(0.98, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.Text = text
            btn.Font = Enum.Font.Code
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 12
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local s = Instance.new("UIStroke", btn)
            s.Color = Color3.fromRGB(60, 60, 60)
            btn.MouseButton1Click:Connect(function()
                if cb then pcall(cb) end
            end)
        end
        function elements:AddButtonL(text, cb) addBtn(MainFramePage, text, cb) end
        function elements:AddButtonR(text, cb) addBtn(MainFramePage2, text, cb) end

        -- 4. Toggles
        local function addTog(parent, text, default, cb)
            local toggled = default or false
            local frame = Instance.new("Frame", parent)
            frame.Size = UDim2.new(0.98, 0, 0, 30)
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = Color3.fromRGB(60, 60, 60)

            local lbl = Instance.new("TextLabel", frame)
            lbl.Size = UDim2.new(0.75, 0, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.Font = Enum.Font.Code
            lbl.TextColor3 = Color3.fromRGB(225, 225, 225)
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left

            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(0, 22, 0, 22)
            btn.Position = UDim2.new(1, -30, 0, 4)
            btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 50)
            btn.Text = toggled and "✔" or ""
            btn.Font = Enum.Font.Code
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 12
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            local clickZone = Instance.new("TextButton", frame)
            clickZone.Size = UDim2.new(1, 0, 1, 0)
            clickZone.BackgroundTransparency = 1
            clickZone.Text = ""

            clickZone.MouseButton1Click:Connect(function()
                toggled = not toggled
                btn.Text = toggled and "✔" or ""
                btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 50)
                if cb then pcall(cb, toggled) end
            end)
        end
        function elements:AddToggleL(text, default, cb) addTog(MainFramePage, text, default, cb) end
        function elements:AddToggleR(text, default, cb) addTog(MainFramePage2, text, default, cb) end

        -- 5. Dropdowns
        local function addDrop(parent, title, list, default, cb)
            local dropFrame = Instance.new("Frame", parent)
            dropFrame.Size = UDim2.new(0.98, 0, 0, 52)
            dropFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke", dropFrame)
            stroke.Color = Color3.fromRGB(60, 60, 60)

            local tLbl = Instance.new("TextLabel", dropFrame)
            tLbl.Size = UDim2.new(1, -20, 0, 20)
            tLbl.Position = UDim2.new(0, 10, 0, 4)
            tLbl.BackgroundTransparency = 1
            tLbl.Text = title
            tLbl.Font = Enum.Font.Code
            tLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            tLbl.TextSize = 11
            tLbl.TextXAlignment = Enum.TextXAlignment.Left

            local selBtn = Instance.new("TextButton", dropFrame)
            selBtn.Size = UDim2.new(1, -16, 0, 22)
            selBtn.Position = UDim2.new(0, 8, 0, 25)
            selBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            selBtn.Text = tostring(default or "Select...")
            selBtn.Font = Enum.Font.Code
            selBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
            selBtn.TextSize = 11
            Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 4)

            local scroll = Instance.new("ScrollingFrame", dropFrame)
            scroll.Position = UDim2.new(0, 8, 0, 50)
            scroll.Size = UDim2.new(1, -16, 0, 0)
            scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            scroll.ScrollBarThickness = 2
            scroll.Visible = false
            scroll.ZIndex = 50
            Instance.new("UIListLayout", scroll)

            local open = false
            local function toggleDrop()
                open = not open
                scroll.Visible = open
                local extraH = math.min(#list * 24, 120)
                dropFrame.Size = open and UDim2.new(0.98, 0, 0, 55 + extraH) or UDim2.new(0.98, 0, 0, 52)
                scroll.Size = open and UDim2.new(1, -16, 0, extraH) or UDim2.new(1, -16, 0, 0)
                scroll.CanvasSize = UDim2.new(0, 0, 0, #list * 24)
            end

            selBtn.MouseButton1Click:Connect(toggleDrop)

            for _, item in ipairs(list) do
                local itemBtn = Instance.new("TextButton", scroll)
                itemBtn.Size = UDim2.new(1, 0, 0, 24)
                itemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                itemBtn.Text = tostring(item)
                itemBtn.Font = Enum.Font.Code
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.TextSize = 11
                itemBtn.ZIndex = 51

                itemBtn.MouseButton1Click:Connect(function()
                    selBtn.Text = tostring(item)
                    toggleDrop()
                    if cb then pcall(cb, item) end
                end)
            end
        end
        function elements:AddDropdownL(title, list, default, cb) addDrop(MainFramePage, title, list, default, cb) end
        function elements:AddDropdownR(title, list, default, cb) addDrop(MainFramePage2, title, list, default, cb) end

        -- 6. Sliders
        local function addSlide(parent, text, min, max, set, cb)
            local val = set or min
            local sFrame = Instance.new("Frame", parent)
            sFrame.Size = UDim2.new(0.98, 0, 0, 48)
            sFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke", sFrame)
            stroke.Color = Color3.fromRGB(60, 60, 60)

            local label = Instance.new("TextLabel", sFrame)
            label.Size = UDim2.new(0.7, 0, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 4)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.Code
            label.TextColor3 = Color3.fromRGB(225, 225, 225)
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left

            local valLbl = Instance.new("TextLabel", sFrame)
            valLbl.Size = UDim2.new(0.25, 0, 0, 20)
            valLbl.Position = UDim2.new(0.72, 0, 0, 4)
            valLbl.BackgroundTransparency = 1
            valLbl.Text = tostring(val)
            valLbl.Font = Enum.Font.Code
            valLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
            valLbl.TextSize = 11
            valLbl.TextXAlignment = Enum.TextXAlignment.Right

            local bar = Instance.new("Frame", sFrame)
            bar.Size = UDim2.new(1, -20, 0, 6)
            bar.Position = UDim2.new(0, 10, 0, 30)
            bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame", bar)
            fill.Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local btn = Instance.new("TextButton", bar)
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""

            local dragging = false
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local relX = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
                    local perc = relX / bar.AbsoluteSize.X
                    local curVal = math.floor(min + (max - min) * perc)
                    fill.Size = UDim2.new(perc, 0, 1, 0)
                    valLbl.Text = tostring(curVal)
                    if cb then pcall(cb, curVal) end
                end
            end)
        end
        function elements:AddSliderL(text, min, max, set, cb) addSlide(MainFramePage, text, min, max, set, cb) end
        function elements:AddSliderR(text, min, max, set, cb) addSlide(MainFramePage2, text, min, max, set, cb) end

        -- 7. MultiDropdowns
        function elements:AddMultiDropdownR(title, list, default, cb)
            local selected = {}
            if type(default) == "table" then
                for _, v in ipairs(default) do selected[v] = true end
            end
            local mFrame = Instance.new("Frame", MainFramePage2)
            mFrame.Size = UDim2.new(0.98, 0, 0, 52)
            mFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Instance.new("UICorner", mFrame).CornerRadius = UDim.new(0, 6)
            local stroke = Instance.new("UIStroke", mFrame)
            stroke.Color = Color3.fromRGB(60, 60, 60)

            local tLbl = Instance.new("TextLabel", mFrame)
            tLbl.Size = UDim2.new(1, -20, 0, 20)
            tLbl.Position = UDim2.new(0, 10, 0, 4)
            tLbl.BackgroundTransparency = 1
            tLbl.Text = title
            tLbl.Font = Enum.Font.Code
            tLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
            tLbl.TextSize = 11
            tLbl.TextXAlignment = Enum.TextXAlignment.Left

            local selBtn = Instance.new("TextButton", mFrame)
            selBtn.Size = UDim2.new(1, -16, 0, 22)
            selBtn.Position = UDim2.new(0, 8, 0, 25)
            selBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            selBtn.Text = "Multi Select..."
            selBtn.Font = Enum.Font.Code
            selBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
            selBtn.TextSize = 11
            Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 4)

            local scroll = Instance.new("ScrollingFrame", mFrame)
            scroll.Position = UDim2.new(0, 8, 0, 50)
            scroll.Size = UDim2.new(1, -16, 0, 0)
            scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            scroll.ScrollBarThickness = 2
            scroll.Visible = false
            scroll.ZIndex = 50
            Instance.new("UIListLayout", scroll)

            local open = false
            local function toggleDrop()
                open = not open
                scroll.Visible = open
                local extraH = math.min(#list * 24, 120)
                mFrame.Size = open and UDim2.new(0.98, 0, 0, 55 + extraH) or UDim2.new(0.98, 0, 0, 52)
                scroll.Size = open and UDim2.new(1, -16, 0, extraH) or UDim2.new(1, -16, 0, 0)
                scroll.CanvasSize = UDim2.new(0, 0, 0, #list * 24)
            end

            selBtn.MouseButton1Click:Connect(toggleDrop)

            for _, item in ipairs(list) do
                local itemBtn = Instance.new("TextButton", scroll)
                itemBtn.Size = UDim2.new(1, 0, 0, 24)
                itemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                itemBtn.Text = (selected[item] and "☑ " or "☐ ") .. tostring(item)
                itemBtn.Font = Enum.Font.Code
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.TextSize = 11
                itemBtn.ZIndex = 51

                itemBtn.MouseButton1Click:Connect(function()
                    selected[item] = not selected[item]
                    itemBtn.Text = (selected[item] and "☑ " or "☐ ") .. tostring(item)
                    local out = {}
                    for k, v in pairs(selected) do
                        if v then table.insert(out, k) end
                    end
                    if cb then pcall(cb, out) end
                end)
            end
        end

        return elements
    end

    return uitab
end


-- ================================================================
-- [PART 8] BUILD INTERFACE
-- ================================================================
local HubUI = Update:AddWindow("IDekhere Hub", "", Enum.KeyCode.RightControl)

local MS = HubUI:AddTab("Main - Setting", "")
local IE = HubUI:AddTab("Item - Event", "")
local RS = HubUI:AddTab("Race - Sea", "")
local FS = HubUI:AddTab("Fruit - Shop", "")
local PM = HubUI:AddTab("Player - Misc", "")

-- ----------------------------------------------------------------
-- TAB 1: MAIN - SETTING
-- ----------------------------------------------------------------
MS:AddSeperatorL("Info")
MS:AddLabelL("Welcome To IDekhere Hub")
MS:AddLabelL("Game: Blox Fruits")
MS:AddLabelL("Date: " .. os.date("%d %B %Y"))
MS:AddLineL()

MS:AddSeperatorL("Farm Level")
MS:AddToggleL("Auto Farm Level", _G.SST.Auto_Farm_Level, function(vu)
    _G.SST.Auto_Farm_Level = vu
    SS()
    if not vu then StopTween() end
end)

if World1 or World2 then
    MS:AddSeperatorL("Next World Quest")
end

if World1 then
    MS:AddToggleL("Auto Second Sea", _G.SST.Auto_Second_Sea, function(vu)
        _G.SST.Auto_Second_Sea = vu
        SS()
        if not vu then StopTween() end
    end)
elseif World2 then
    MS:AddToggleL("Auto Third Sea", _G.SST.Auto_Third_Sea, function(vu)
        _G.SST.Auto_Third_Sea = vu
        SS()
        if not vu then StopTween() end
    end)
end

-- Materials List
MS:AddSeperatorL("Find Materials")
local Materials = {
    ["Leather"]              = { Namemon = {"Pirate", "Brute"}, CFrameMon = CFrame.new(-1136, 57, 4118) },
    ["Scrap Metal"]          = { Namemon = {"Pirate", "Brute"}, CFrameMon = CFrame.new(-1136, 57, 4118) },
    ["Angel Wings"]          = { Namemon = {"God's Guard", "Shanda"}, CFrameMon = CFrame.new(-4721, 843, -1949) },
    ["Fish Tail"]            = { Namemon = {"Fishman Warrior", "Fishman Commando"}, CFrameMon = CFrame.new(60875, 35, 1434) },
    ["Magma Ore"]            = { Namemon = {"Magma Ninja", "Lava Pirate"}, CFrameMon = CFrame.new(-5229, 20, -5297) },
    ["Bones"]                = { Namemon = {"Posessed Mummy", "Demonic Soul", "Living Zombie", "Reborn Skeleton"}, CFrameMon = CFrame.new(-9515, 164, 5786) },
    ["Dragon Scale"]         = { Namemon = {"Dragon Crew Warrior", "Dragon Crew Archer"}, CFrameMon = CFrame.new(6241, 51, -1243) },
    ["Mini Tusk"]            = { Namemon = {"Mythological Pirate"}, CFrameMon = CFrame.new(-13869, 564, -7084) },
    ["Demonic Wisp"]         = { Namemon = {"Demonic Soul"}, CFrameMon = CFrame.new(-9712, 204, 6193) },
    ["Vampire Fang"]         = { Namemon = {"Zombie"}, CFrameMon = CFrame.new(-5695, 124, -775) },
}

local MatList = {}
for k, _ in pairs(Materials) do table.insert(MatList, k) end

MS:AddDropdownL("Select Materials", MatList, _G.SST.Select_Materials, function(v)
    _G.SST.Select_Materials = v
    SS()
end)

MS:AddToggleL("Auto Farm Material", _G.SST.Auto_Farm_Material, function(v)
    _G.SST.Auto_Farm_Material = v
    SS()
    if not v then StopTween() end
end)

-- Bosses List
MS:AddSeperatorL("Boss Hunting")
local BossList = {
    "The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader", "Vice Admiral", "Warden",
    "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
    "Ice Admiral", "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral",
    "Awakened Ice Admiral", "Tide Keeper", "Order", "Darkbeard", "rip_indra", "Stone",
    "Island Empress", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Cake Queen", "Soul Reaper"
}

MS:AddDropdownL("Select Boss", BossList, _G.SST.Select_Boss, function(vu)
    _G.SST.Select_Boss = vu
    SS()
end)

MS:AddToggleL("Auto Farm Boss", _G.SST.Auto_Farm_Boss, function(vu)
    _G.SST.Auto_Farm_Boss = vu
    SS()
    if not vu then StopTween() end
end)

MS:AddToggleL("Auto Farm All Boss", _G.SST.Auto_Farm_All_Boss, function(vu)
    _G.SST.Auto_Farm_All_Boss = vu
    SS()
    if not vu then StopTween() end
end)

MS:AddToggleL("Auto Farm All Boss Hop", _G.SST.Auto_Farm_All_Boss_Hop, function(vu)
    _G.SST.Auto_Farm_All_Boss_Hop = vu
    SS()
end)

-- Right Column (MS)
MS:AddSeperatorR("Weapon & Attack")
MS:AddDropdownR("Select Weapon Type", {"Melee", "Sword", "Gun", "Blox Fruit"}, _G.SST.Select_Item_Type, function(vu)
    _G.SST.Select_Item_Type = vu
    SS()
end)

MS:AddDropdownR("Attack Speed", {"Fast", "Normal", "Slow"}, _G.SST.Select_Mode_Attack, function(vu)
    _G.SST.Select_Mode_Attack = vu
    SS()
    if vu == "Fast" then _G.SpeedAttack = 0.01
    elseif vu == "Normal" then _G.SpeedAttack = 0.1
    elseif vu == "Slow" then _G.SpeedAttack = 0.25 end
end)

MS:AddToggleR("Auto Attack", _G.SST.Auto_Attack, function(vu)
    _G.SST.Auto_Attack = vu
    SS()
end)

MS:AddSeperatorR("Mob Bringer")
MS:AddSliderR("Bring Distance", 50, 400, _G.SST.Select_Bring_Distance, function(vu)
    _G.SST.Select_Bring_Distance = vu
    SS()
end)

MS:AddToggleR("Bring Mob", _G.SST.Bring_Mob, function(vu)
    _G.SST.Bring_Mob = vu
    SS()
end)

MS:AddSeperatorR("Tween Settings")
MS:AddSliderR("Tween Speed", 100, 350, _G.SST.Tween_Speed, function(vu)
    _G.SST.Tween_Speed = vu
    SS()
end)

MS:AddSliderR("Distance for TP", 50, 300, _G.SST.Distance_For_Tp, function(vu)
    _G.SST.Distance_For_Tp = vu
    SS()
end)

MS:AddSliderR("Farm Height (Pos Y)", 0, 60, _G.SST.Pos_Y, function(vu)
    _G.SST.Pos_Y = vu
    SS()
end)

MS:AddSeperatorR("Stats Upgrades")
MS:AddMultiDropdownR("Select Stats", {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, _G.SST.Select_Stats, function(vu)
    _G.SST.Select_Stats = vu
    SS()
end)

MS:AddSliderR("Points Per Upgrade", 1, 100, _G.SST.Select_Point_Stats, function(vu)
    _G.SST.Select_Point_Stats = vu
    SS()
end)

MS:AddToggleR("Auto Stats", _G.SST.Auto_Stats, function(vu)
    _G.SST.Auto_Stats = vu
    SS()
end)

-- ----------------------------------------------------------------
-- TAB 2: ITEM - EVENT (MELEES & SWORDS)
-- ----------------------------------------------------------------
IE:AddSeperatorL("Fighting Styles (Melee)")
IE:AddToggleL("Auto Superhuman", _G.SST.Auto_Super_Human, function(vu)
    _G.SST.Auto_Super_Human = vu
    SS()
end)

IE:AddToggleL("Auto Death Step", _G.SST.Auto_Death_Step, function(vu)
    _G.SST.Auto_Death_Step = vu
    SS()
end)

IE:AddToggleL("Auto Sharkman Karate", _G.SST.Auto_Shark_Man, function(vu)
    _G.SST.Auto_Shark_Man = vu
    SS()
end)

IE:AddToggleL("Auto Electric Claw", _G.SST.Auto_Electric_Claw, function(vu)
    _G.SST.Auto_Electric_Claw = vu
    SS()
end)

IE:AddToggleL("Auto Dragon Talon", _G.SST.Auto_Dragon_Talon, function(vu)
    _G.SST.Auto_Dragon_Talon = vu
    SS()
end)

IE:AddToggleL("Auto Godhuman", _G.SST.Auto_God_Human, function(vu)
    _G.SST.Auto_God_Human = vu
    SS()
end)

IE:AddSeperatorR("Swords Hunting")
local SwordList = {
    "Katana", "Cutlass", "Dual Katana", "Iron Mace", "Triple Katana", "Pipe", "Dual Headed Blade",
    "Shark Saw", "Twin Hooks", "Bisento", "Soul Cane", "Saber", "Warden Sword", "Trident",
    "Gravity Cane", "Longsword", "Jitte", "Shisui", "Wando", "Saddi", "True Triple Katana",
    "Rengoku", "Dragon Trident", "Midnight Blade", "Yama", "Tushita", "Cursed Dual Katana",
    "Canvander", "Buddy Sword", "Spikey Trident", "Hallow Scythe", "Dark Dagger", "Shark Anchor"
}

IE:AddDropdownR("Select Sword", SwordList, _G.SST.Select_Sword, function(vu)
    _G.SST.Select_Sword = vu
    SS()
end)

IE:AddToggleR("Auto Get / Farm Sword", _G.SST.Auto_Find_Sword, function(vu)
    _G.SST.Auto_Find_Sword = vu
    SS()
    if not vu then StopTween() end
end)

-- ----------------------------------------------------------------
-- TAB 3: RACE - SEA
-- ----------------------------------------------------------------
RS:AddSeperatorL("Race Awakening")
RS:AddToggleL("Auto Activate Race V3", _G.SST.Auto_Activate_Race_Ability, function(vu)
    _G.SST.Auto_Activate_Race_Ability = vu
    SS()
end)

RS:AddToggleL("Auto Activate Race V4", _G.SST.Auto_Activate_RaceV4_Ability, function(vu)
    _G.SST.Auto_Activate_RaceV4_Ability = vu
    SS()
end)

-- ----------------------------------------------------------------
-- TAB 4: FRUIT & SHOP
-- ----------------------------------------------------------------
FS:AddSeperatorL("Devil Fruit Actions")
FS:AddButtonL("Random Fruit (Spin)", function()
    ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
end)

FS:AddToggleL("Auto Store Fruit", _G.SST.Auto_Store_Fruit, function(vu)
    _G.SST.Auto_Store_Fruit = vu
    SS()
end)

-- ----------------------------------------------------------------
-- TAB 5: PLAYER - MISC
-- ----------------------------------------------------------------
PM:AddSeperatorL("Player Modifications")
PM:AddSliderL("WalkSpeed", 16, 250, 16, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

PM:AddSliderL("JumpPower", 50, 300, 50, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)

PM:AddToggleL("Auto Buso Haki", _G.SST.Auto_Buso, function(v)
    _G.SST.Auto_Buso = v
    SS()
end)

PM:AddToggleL("Auto Observation Haki", _G.SST.Auto_Ken, function(v)
    _G.SST.Auto_Ken = v
    SS()
end)

PM:AddSeperatorR("Server Utilities")
PM:AddButtonR("Server Hop", function() Hop() end)
PM:AddButtonR("Rejoin Current Server", function() Rejoin() end)


-- ================================================================
-- [PART 9] BACKGROUND RUNTIME LOOPS
-- ================================================================

-- 1. Auto Equip Weapon Detective
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                if v:IsA("Tool") and (v.ToolTip == _G.SST.Select_Item_Type or (_G.SST.Select_Item_Type == "Blox Fruit" and v.ToolTip == "Fruit")) then
                    _G.ItemName = v.Name
                end
            end
        end)
    end
end)

-- 2. Fast Attack Loop
task.spawn(function()
    while task.wait() do
        if _G.SST.Auto_Attack then
            Click()
            task.wait(_G.SpeedAttack or 0.05)
        else
            task.wait(0.2)
        end
    end
end)

-- 3. Auto Stats Loop
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if _G.SST.Auto_Stats and _G.SST.Select_Stats and #_G.SST.Select_Stats > 0 then
                local pts = LocalPlayer.Data.Points.Value
                if pts > 0 then
                    for _, stat in ipairs(_G.SST.Select_Stats) do
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", stat, _G.SST.Select_Point_Stats or 1)
                    end
                end
            end
        end)
    end
end)

-- 4. Melee Automation Loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.SST.Auto_Super_Human then ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman") end
            if _G.SST.Auto_Death_Step then ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep") end
            if _G.SST.Auto_Shark_Man then ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate") end
            if _G.SST.Auto_Electric_Claw then ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") end
            if _G.SST.Auto_Dragon_Talon then ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon") end
            if _G.SST.Auto_God_Human then ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman") end
        end)
    end
end)

-- 5. Auto Store Fruit Loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.SST.Auto_Store_Fruit then
                for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if string.find(item.Name, "Fruit") then
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", item:GetAttribute("OriginalName") or item.Name, item)
                    end
                end
                if LocalPlayer.Character then
                    for _, item in pairs(LocalPlayer.Character:GetChildren()) do
                        if string.find(item.Name, "Fruit") then
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", item:GetAttribute("OriginalName") or item.Name, item)
                        end
                    end
                end
            end
        end)
    end
end)

-- 6. Race Abilities Loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.SST.Auto_Activate_Race_Ability then
                ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
            end
            if _G.SST.Auto_Activate_RaceV4_Ability and LocalPlayer.Backpack:FindFirstChild("Awakening") then
                LocalPlayer.Backpack.Awakening.RemoteFunction:InvokeServer(true)
            end
        end)
    end
end)

-- 7. Mob Bringer Routine
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if _G.SST.Bring_Mob and PosMon and NameMon then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local enemies = workspace:FindFirstChild("Enemies")
                if hrp and enemies then
                    local count = 0
                    for _, v in pairs(enemies:GetChildren()) do
                        if v.Name == NameMon and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            local dist = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if dist <= (_G.SST.Select_Bring_Distance or 250) then
                                v.HumanoidRootPart.CFrame = PosMon
                                v.HumanoidRootPart.CanCollide = false
                                if v:FindFirstChild("Head") then v.Head.CanCollide = false end
                                count = count + 1
                                if count >= 3 then break end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 8. Auto Farm Level Main Loop
task.spawn(function()
    while task.wait(0.05) do
        if _G.SST.Auto_Farm_Level then
            pcall(function()
                local player = LocalPlayer
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local questGui = player.PlayerGui.Main:FindFirstChild("Quest")
                QuestFunction()

                -- ถ้ายังไม่ได้รับเควส ให้ไปรับเควสก่อน
                if not questGui or not questGui.Visible then
                    PosMon = nil
                    if CFrameQuest then
                        local dist = (CFrameQuest.Position - hrp.Position).Magnitude
                        if dist > 5 then
                            Tween(CFrameQuest)
                        else
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, LevelQuest)
                            task.wait(0.5)
                        end
                    end
                    return
                end

                -- หาเป้าหมายมอนสเตอร์ที่ตรงกับเควส
                local enemies = workspace:FindFirstChild("Enemies")
                local targetMob = nil

                if enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        if (v.Name == Mon or string.find(v.Name, NameMon)) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            targetMob = v
                            break
                        end
                    end
                end

                if targetMob then
                    PosMon = targetMob.HumanoidRootPart.CFrame
                    repeat
                        task.wait()
                        Equip(_G.ItemName)
                        AutoHaki()
                        if targetMob:FindFirstChild("HumanoidRootPart") and targetMob:FindFirstChild("Humanoid") then
                            local farmPos = targetMob.HumanoidRootPart.CFrame * CFrame.new(_G.SST.Pos_X or 0, _G.SST.Pos_Y or 25, _G.SST.Pos_Z or 0)
                            Tween(farmPos)
                            targetMob.Humanoid.WalkSpeed = 0
                            targetMob.HumanoidRootPart.CanCollide = false
                            if targetMob:FindFirstChild("Head") then targetMob.Head.CanCollide = false end
                        end
                    until not _G.SST.Auto_Farm_Level or not targetMob.Parent or not targetMob:FindFirstChild("Humanoid") or targetMob.Humanoid.Health <= 0 or not questGui.Visible
                else
                    -- ถ้ามอนยังไม่เกิด ให้บินไปรอที่จุด Spawn
                    if PUK then
                        Tween(PUK)
                    end
                end
            end)
        end
    end
end)

print("[IDekhere Hub] โหลดสคริปต์สำเร็จ 100% พร้อมใช้งาน!")
