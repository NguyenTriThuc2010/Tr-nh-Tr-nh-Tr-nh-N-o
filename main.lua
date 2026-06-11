--v3 hiện đang có một số lỗi, bay vào không gian có mái che sẽ khiến đứng im mà k hạ độ cao, làm một hàm hàm này sẽ liên tục kiểm tra, cập nhật, raycast trên đỉnh đầu gồm có 2 loại 1 loại sẽ bắt thật xa, còn loại 2 cũng hướng như loại 1 chỉ khác là đo khoảng cách ngắn hơn, nếu khoảng cách này chưa bị chạm thì vẫn an toàn nếu khoảng cách raycast chạm tức ta biết chỗ này có trần thì trạng thái bay sẽ chuyển qua bay trong nhà, còn nếu vượt vật cản nhỡ đưa người chơi lên cao hoặc là cố tình mà chạm phải raycast 2 này thì phải dừng ngay việc le tường và hạ xuống độ cao đã được thiết lập và thực hiện ngay lập tức nhiệm vụ đang làm k được chậm trễ, mọi thứ phải nhanh tróng sử lý mượt mà và gọn gàng chuyên nghiệp. và thêm các kiểm tra nút được bật vào hàm cập nhật, script càng nhiều function càng dễ phát triển trong tương lai, đừng có cố code dài ra hãy nghĩ đến cả tương lai dù bạn đang có code cho chức năng nào thì phải nghĩ tến quy tắc làm việc, chuyên nghiệm gọn gàng nhanh gọn , thêm lời muốn nói, đó là cái láp hình vuông trền đầu mà thay đổi màu đỏ màu xanh ý, lẽ ra nó chuyển qua đỏ thì nên dừng việc vượt vật cản 
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Toggles = Library.Toggles
local dbg

local activeSlab = nil
local obstacleAvoidanceDisabled = false
local lastSlabCollisionStart = nil

local debugFolder = workspace:FindFirstChild("DebugVisuals")
if not debugFolder then
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "DebugVisuals"
	debugFolder.Parent = workspace
end

local function visualizeRay(origin, direction, result, color)
	if not cf or not cf.Debug or not cf.Debug.Enable then return end
	
	if not debugFolder or not debugFolder.Parent then
		debugFolder = workspace:FindFirstChild("DebugVisuals")
		if not debugFolder then
			debugFolder = Instance.new("Folder")
			debugFolder.Name = "DebugVisuals"
			debugFolder.Parent = workspace
		end
	end
	
	local distance = result and result.Distance or direction.Magnitude
	local hitPosition = result and result.Position or (origin + direction)
	
	local rayPart = Instance.new("Part")
	rayPart.Name = "RayVisual"
	rayPart.Anchored = true
	rayPart.CanCollide = false
	rayPart.CastShadow = false
	rayPart.Material = Enum.Material.Neon
	rayPart.Color = color or Color3.fromRGB(255, 255, 0)
	rayPart.Size = Vector3.new(0.15, 0.15, distance)
	rayPart.CFrame = CFrame.lookAt(origin, hitPosition) * CFrame.new(0, 0, -distance/2)
	rayPart.Parent = debugFolder
	
	local hitSph = nil
	if result then
		hitSph = Instance.new("Part")
		hitSph.Name = "RayHitVisual"
		hitSph.Shape = Enum.PartType.Ball
		hitSph.Anchored = true
		hitSph.CanCollide = false
		hitSph.CastShadow = false
		hitSph.Material = Enum.Material.Neon
		hitSph.Color = Color3.fromRGB(255, 0, 0)
		hitSph.Size = Vector3.new(0.5, 0.5, 0.5)
		hitSph.Position = hitPosition
		hitSph.Parent = debugFolder
	end
	
	task.spawn(function()
		local duration = 1.0
		local steps = 10
		for i = 1, steps do
			task.wait(duration / steps)
			if rayPart and rayPart.Parent then
				rayPart.Transparency = 0.2 + (0.8 * (i / steps))
			end
			if hitSph and hitSph.Parent then
				hitSph.Transparency = (i / steps)
			end
		end
		pcall(function() rayPart:Destroy() end)
		pcall(function() if hitSph then hitSph:Destroy() end end)
	end)
end

local function setupSlab(char)
	print("[Slab Sensor] Setting up slab sensor for character...")
	if activeSlab then
		pcall(function() activeSlab:Destroy() end)
		activeSlab = nil
	end
	if not char then return end
	
	local hrp = char:WaitForChild("HumanoidRootPart", 20)
	if not hrp then
		warn("[Slab Sensor] HumanoidRootPart not found after 20 seconds!")
		return
	end
	
	local slab = Instance.new("Part")
	slab.Name = "SlabSensor"
	slab.Size = Vector3.new(2, 1, 2)
	slab.Transparency = 0.5
	slab.Color = Color3.fromRGB(0, 255, 0)
	slab.CanCollide = false
	slab.Massless = true
	slab.Material = Enum.Material.Neon
	slab.Anchored = false
	
	local weld = Instance.new("WeldConstraint")
	weld.Name = "SlabWeld"
	weld.Part0 = hrp
	weld.Part1 = slab
	slab.CFrame = hrp.CFrame * CFrame.new(0, 4.5, 0)
	weld.Parent = slab
	
	slab.Parent = char
	activeSlab = slab
	print("[Slab Sensor] Slab sensor successfully created and welded.")
end

if LocalPlayer.Character then
	task.spawn(setupSlab, LocalPlayer.Character)
end


local cf = {
	Enable = true,

	Debug = {
		Enable = false,
		showHit = true,
		showFly = true,
		showNPC = true,
		ShowRemotes = true,
		showFarm = true,
		showQuest = true,
		showStats = true,
	},

	AutoImpel = {
		Enable = false,
	},

	Farm = {
		Enable = false,
		Mode = {
			["Idle"] = false,
			["Chase"] = false,
		},
		SafeHeight = 2,
		ComboSize = 5,
		Method    = "Melee",
		M1Mode    = "Ground",   -- "Ground" or "Air"
		AutoEquip = true,
		Range     = 9999999,
		HitDelay      = 0.01,
		FinisherDelay = 1.5,
		AttackY = 10,
	},

	Movement = {
		Noclip = { Enabled = false },
		Fly    = { Speed = 80, Enabled = false },
		Speed  = { Speed = 0,  Enabled = false },
	},

	Exploit = {
		No_Stun = { Enabled = false },
		Anti_Afk = { Enabled = true },
	},

	AutoStats = {
		Enable = true,
		Points = 1,
		Priority = {
			["Strength"] = false,
			["Defense"] = false,
			["Stamina"] = false,
			["SwordMastery"] = false,
			["GunMastery"] = false,
			["BlackLegMastery"] = false,
			["ElectroMastery"] = false,
			["DevilFruitMastery"] = false,
			["FishmanKarateMastery"] = false,
			["DragonClawMastery"] = false,
			["CyborgMastery"] = false,
			["RokushikiMastery"] = false,
			["FightingStyleMastery"] = false,
		},
	},

	AutoQuest = {
		Enable = false,
		Quests = {
			[1] = {
				Help = "Help Daph",
				NPCName = "Daph",
				Island = "Town of Beginnings",
				PositionIsland = Vector3.new(-578.5939331054688, 5.875, -3431.510498046875),
				PositionQuest = Vector3.new(-578.5939331054688, 5.875, -3431.510498046875),
				Target = "Bandit"
			},
			[5] = {
				Help = "Help Ronny",
				NPCName = "Ronny",
				Island = "Town of Beginnings",
				PositionIsland = Vector3.new(-578.5939331054688, 5.875, -3431.510498046875),
				PositionQuest = Vector3.new(-539.673095703125, 5.983512878417969, -3281.850341796875),
				Target = "Bandit Boss"
			},
			[10] = {
				Help = "Help Noah",
				NPCName = "Noah",
				Island = "Sandora",
				PositionIsland = Vector3.new(-1710.19, 4.06, -3377.11),
				PositionQuest = Vector3.new(-1710.19, 4.06, -3377.11),
				Target = "Desert Bandit"
			},
			[15] = {
				Help = "Help Tyrone",
				NPCName = "Tyrone",
				Island = "Sandora",
				PositionIsland = Vector3.new(-1710.19, 4.06, -3377.11),
				PositionQuest = Vector3.new(-1842.38, 10.64, -3420.77),
				Target = "Lucid's Lad"
			},
			[20] = {
				Help = "Help Robert",
				NPCName = "Robert",
				Island = "Shell's Town",
				PositionIsland = Vector3.new(-1445.13, 10.15, -5102.67),
				PositionQuest = Vector3.new(-1445.13, 10.15, -5102.67),
				Target = "Corrupt Marine"
			},
			[25] = {
				Help = "Help Gozen",
				NPCName = "Gozen",
				Island = "Shell's Town",
				PositionIsland = Vector3.new(-1445.13, 10.15, -5102.67),
				PositionQuest = Vector3.new(-1364.70, 84.98, -5383.00),
				Target = "Axe Hand Logan"
			},
			[30] = {
				Help = "Help Zen",
				NPCName = "Zen",
				Island = "Island Of Zou",
				PositionIsland = Vector3.new(-3015.830078125, 7.734528541564941, -5269.5087890625),
				PositionQuest = Vector3.new(-3172.533203125, 11.641794204711914, -5226.86767578125),
				Target = "Zou Inhabitant"
			},
			[70] = {
				Help = "Help Waby",
				NPCName = "Waby",
				Island = "Shark Park",
				PositionIsland = Vector3.new(-1889.695068359375, 12.5871000289917, -10231.46875),
				PositionQuest = Vector3.new(-1889.695068359375, 12.5871000289917, -10231.46875),
				Target = "Saw Shark Pirate"
			}
		},
		OnlyFlyToIsland = false,
	},

	IslandTravel = {
		FlyToSelected = false,
		SelectedIsland = nil,
	},
}

cf.Target = {}

-- ============================================================
--  REMOTES / FOLDERS
-- ============================================================
local Events = ReplicatedStorage:WaitForChild("Events", 20)
local StatsEvent = Events and Events:WaitForChild("stats", 20)
local QuestEvent = Events and Events:WaitForChild("Quest", 20)
local CombatRegisterEvent = Events and Events:WaitForChild("CombatRegister", 20)
local NPCsForder = workspace:WaitForChild("NPCs", 20)
local CombatAnimations = ReplicatedStorage:WaitForChild("CombatAnimations", 20)

if not CombatRegisterEvent then warn("[Script] không tìm thấy CombatRegister") end
if not NPCsForder then warn("[Script] không tìm thấy folder NPCs") end
if not QuestEvent then warn("[Script] không tìm thấy Quest Event") end
if not StatsEvent then warn("[Script] không tìm thấy stats") end
if not CombatAnimations then warn("[Script] không tìm thấy CombatAnimations Folder") end

local Animations = {
	Air = { "AirPunch1", "AirPunch2", "AirPunch3", "AirPunch4", "AirPunch5", "Punch1", "Punch2", "Punch3" },
	Ground = { "Punch1", "Punch2", "Punch3", "Punch4", "GroundPunch4", "GroundPunch5" }
}

-- ============================================================
--  HELPERS
-- ============================================================
local function player()
	local character = LocalPlayer.Character
	if not character then return nil, nil, nil end
	local Humanoid = character:FindFirstChildOfClass("Humanoid")
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	return character, Humanoid, HumanoidRootPart
end

local function getHRP()
	local _, _, hrp = player()
	return hrp
end

local function getHum()
	local _, hum, _ = player()
	return hum
end

local function isAlive()
	local character, Humanoid, HumanoidRootPart = player()
	return character and Humanoid.Health > 0 and HumanoidRootPart
end

local function findnpc(npcName)
	local list = {}
	local character, Humanoid, HumanoidRootPart = player()

	for _, npc in ipairs(NPCsForder:GetChildren()) do
		if not npc:IsA("Model") then continue end
		if npc.Name ~= npcName then continue end
		
		local Info = npc:FindFirstChild("Info")
		if not Humanoid and not HumanoidRootPart and npcName == "Shark" and Info then continue end
		local Hostile = Info and Info:FindFirstChild("Hostile")
		if not Hostile then continue end
		
		local realPos = npc:FindFirstChild("realPos")
		local Position = realPos and realPos.Value and realPos.Value.Position or npc.PrimaryPart and npc.PrimaryPart.Position or npc:GetPivot().Position
		
		if Hostile.Value == false and npcName == npc.Name then
			table.insert(list, {target = npc, Position = Position, isNpc = true})
		else
			table.insert(list, {target = npc, Position = Position, isNpc = false})
		end
	end
	return list
end

local function findtar(tarName)
	local list = {}
	local character, Humanoid, HumanoidRootPart = player()
	for _, target in ipairs(NPCsForder:GetChildren()) do
		if not target:IsA("Model") then continue end
		if target.Name ~= tarName then continue end
		
		local Info = target:FindFirstChild("Info")
		if not Humanoid and not HumanoidRootPart and tarName == "Shark" and Info then continue end
		local Hostile = Info and Info:FindFirstChild("Hostile")
		if not Hostile then continue end
		
		local realPos = target:FindFirstChild("realPos")
		local Position = realPos and realPos.Value and realPos.Value.Position or target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
		
		if Hostile.Value == true and tarName == target.Name and target.Humanoid.Health > 0 then
			table.insert(list, {target = target, Position = Position, isTar = true})
		else
			table.insert(list, {target = target, Position = Position, isTar = false})
		end
	end
	return list
end

local function findtarboss(tarBossName)
	local list = {}
	local character, Humanoid, HumanoidRootPart = player()
	for _, target in ipairs(NPCsForder:GetChildren()) do
		if not target:IsA("Model") then continue end
		if target.Name ~= tarBossName then continue end
		
		local Info = target:FindFirstChild("Info")
		if not Humanoid and not HumanoidRootPart and tarBossName == "Shark" and Info then continue end
		local Hostile = Info and Info:FindFirstChild("Hostile")
		if not Hostile then continue end
		
		local realPos = target:FindFirstChild("realPos")
		local Position = realPos and realPos.Value and realPos.Value.Position or target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
		
		if Hostile.Value == true and tarBossName == target.Name and (target:FindFirstChild("Boost") or target:FindFirstChild("BoostedDMG")) then
			table.insert(list, {target = target, Position = Position, isTar = true})
		else
			table.insert(list, {target = target, Position = Position, isTar = false})
		end
	end
	return list
end



--[[
	getCurrentIsland()
	Kiểm tra đồng bộ: player đang đứng trong hitbox của đảo nào.
	Trả về: tên đảo (string) hoặc nil nếu không ở trên đảo nào.
--]]
local function getCurrentIsland()
	local _, _, HRP = player()
	if not HRP then return nil end
 
	local IslandFolder = workspace:FindFirstChild("Islands")
	if not IslandFolder then
		warn("[Island] Không tìm thấy folder Islands trong workspace")
		return nil
	end
 
	for _, islandModel in ipairs(IslandFolder:GetChildren()) do
		if not islandModel:IsA("Model") then continue end
 
		local sizeAttr = islandModel:GetAttribute("islandSize")
		if not sizeAttr then continue end
 
		local islandCF   = islandModel:GetBoundingBox()
		local localPos   = islandCF:PointToObjectSpace(HRP.Position)
		local half       = sizeAttr / 2
 
		if  math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z then
			return islandModel.Name
		end
	end
 
	return nil
end

--[[
	getIslandsList()
	Lấy danh sách tên tất cả các đảo từ workspace.Islands
--]]
local function getIslandsList()
	local list = {}
	local IslandFolder = workspace:FindFirstChild("Islands")
	if IslandFolder then
		for _, islandModel in ipairs(IslandFolder:GetChildren()) do
			if islandModel:IsA("Model") then
				table.insert(list, islandModel.Name)
			end
		end
	end
	table.sort(list)
	if #list == 0 then
		list = {
			"Starter Island",
			"Sandora",
			"Shell's Town",
			"Island Of Zou",
			"Restaurant Baratie",
			"Sphinx Island"
		}
	end
	return list
end



local function stats()
	local playerStats = ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
	if not playerStats then return nil, nil end
	local statsFolder = playerStats:FindFirstChild("Stats")
	if not statsFolder then return nil, nil end
	return playerStats, statsFolder
end

local function Level()
	local _, statsFolder = stats()
	if not statsFolder then return 0 end
	local level = statsFolder:FindFirstChild("Level")
	return level and level.Value or 0
end
local function abandonQuest()
    if not QuestEvent then return false end
    dbg("QUEST", "Abandoning current quest...")
    local ok = pcall(function()
        QuestEvent:InvokeServer({"quit"})
    end)
    task.wait(0.5)
    return ok
end
local function getBestQuest()
	local currentLevel = math.max(Level(), 1)
	local bestLevel, bestQuest = nil, nil
 
	for questLevel, questData in pairs(cf.AutoQuest.Quests) do
		if type(questLevel) ~= "number" then continue end
		if currentLevel >= questLevel and (not bestLevel or questLevel > bestLevel) then
			bestLevel = questLevel
			bestQuest = questData
		end
	end
	
	return bestQuest, bestLevel
end

local function getActiveQuestName()
	local playerStats = stats()
	if not playerStats then return nil end
 
	local questFolder  = playerStats:FindFirstChild("Quest")
	if not questFolder  then return nil end
 
	local currentQuest = questFolder:FindFirstChild("CurrentQuest")
	if not currentQuest then return nil end
 
	local v = currentQuest.Value
	return (v and v ~= "" and v ~= "None") and v or nil
end

local function hasActiveQuest()
	return getActiveQuestName() ~= nil
end

--[[
	checkquest()
	Trả về:  state (string),  questData (table | nil)
--]]
local function checkquest()
	local quest, questLevel = getBestQuest()
 
	if not quest then
		dbg("QUEST", "Không có quest phù hợp với level %d", Level())
		return "Không có Quest", nil
	end
 
	dbg("QUEST", "Lv.%d → Quest lv.%d | Đảo: %s | Mục tiêu: %s", Level(), questLevel, quest.Island, quest.Target)
 
	local currentIsland = getCurrentIsland()
	if currentIsland ~= quest.Island then
		dbg("QUEST", "Đang ở: [%s] → Cần đến: [%s]", tostring(currentIsland), quest.Island)
		return "Tới đảo", quest
	end
 
	local activeQuest = getActiveQuestName()
	if not activeQuest then
		dbg("QUEST", "Đã đến đảo → Chưa nhận quest → AcceptQuest")
		return "Không có Quest", quest
	end
 
	dbg("QUEST", "Quest đang làm: [%s]", activeQuest)
	return "Đang làm Quest", quest
end


local function getQuestNPCPosition(questCfg)
	local npc = NPCsForder:FindFirstChild(questCfg.NPCName)
	if npc and npc:FindFirstChild("HumanoidRootPart") then
		return npc.HumanoidRootPart.Position
	end
	if questCfg.PositionQuest then
		return questCfg.PositionQuest
	end
	local islandModel = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild(questCfg.Island)
	if islandModel then
		local cfrm, size = islandModel:GetBoundingBox()
		return cfrm.Position
	end
	return nil
end

local function takeQuestRemote(npcName, questName)
	if not QuestEvent then return false end
	dbg("QUEST", "Accepting Quest '%s' from NPC '%s'", questName, npcName)
	pcall(function() QuestEvent:InvokeServer({"npcChat", true}) end)
	task.wait(0.4)
	local ok = pcall(function() QuestEvent:InvokeServer({"takequest", questName}) end)
	task.wait(0.3)
	pcall(function() QuestEvent:InvokeServer({"npcChat", false}) end)
	return ok
end

-- ============================================================
--  NOCLIP & FLIGHT & OBSTACLE AVOIDANCE
-- ============================================================
local noclipConn = nil

local function disableNoclip()
	-- 1. Ngắt ngay vòng lặp noclip để dừng việc ép tắt va chạm
	if noclipConn then 
		noclipConn:Disconnect()
		noclipConn = nil 
	end
	
	local char = LocalPlayer.Character
	if not char then return end
	
	-- 2. Quét lại cơ thể nhưng CHỈ bật lại va chạm cho những phần cần thiết
	for _, p in pairs(char:GetDescendants()) do
		if p:IsA("BasePart")
		-- Giữ nguyên trạng thái KHÔNG va chạm cho các ngoại lệ dưới đây:
		and not p:IsDescendantOf(char:FindFirstChild("RaceAssest"))
		and not p:IsDescendantOf(char:FindFirstChild("Pants"))
		and not p:IsDescendantOf(char:FindFirstChild("Shirt"))
		and not p.Name ~= "Hair2"
		and not  p.Name ~= "Hair1" and not p:IsDescendantOf(char:FindFirstChild("Shoes")) and not p:IsDescendantOf(char:FindFirstChild("Shoes")) -- có 2 shoes
		then
			pcall(function() 
				p.CanCollide = true 
			end)
		end
	end
end
local noclipErrors = 0
local function enableNoclip()
    if noclipConn then return end
    noclipErrors = 0
    noclipConn = RunService.Stepped:Connect(function()
        local ok, err = pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart")
                and not p:IsDescendantOf(char:FindFirstChild("RaceAssest"))
                and not p:IsDescendantOf(char:FindFirstChild("Pants"))
                and not p:IsDescendantOf(char:FindFirstChild("Shirt"))
                and p.Name ~= "Hair2"
                and p.Name ~= "Hair1"
                then
                    p.CanCollide = false
                end
            end
        end)
        if not ok then
            noclipErrors = noclipErrors + 1
            if noclipErrors > 10 then
                warn("[Crash Safeguard]: Too many consecutive noclip errors. Disconnecting noclip loop.")
                disableNoclip()
            end
        else
            noclipErrors = 0
        end
    end)
end
local AvoidState = {
	Armed = false,
	Avoiding = false,
	NoclipTemp = false,
	LastPosition = nil,
	MoveTimer = 0,
	LastCheck = 0,
	CooldownEnd = 0,
	
	TRIGGER_TIME = 2.0,
	CHECK_INTERVAL = 0.1,
	PROBE_DIST = 15,
	THIN_THRESHOLD = 4,
	NOCLIP_DURATION = 1.5,
	COOLDOWN = 2.0,
	MIN_SPEED = 5,
}

local avoidFilter = RaycastParams.new()
avoidFilter.FilterType = Enum.RaycastFilterType.Exclude

local function refreshAvoidFilter()
	avoidFilter.FilterDescendantsInstances = { LocalPlayer.Character, NPCsForder, debugFolder }
end

local function probeThickness(firstHitPos, dir)
	local probeOrigin = firstHitPos + dir * 0.25
	local result = workspace:Raycast(probeOrigin, dir * 60, avoidFilter)
	visualizeRay(probeOrigin, dir * 60, result, Color3.fromRGB(255, 127, 0))
	return result and result.Distance or 999
end
local lastFindTopTime = 0
local cachedTopY = nil


local function findTopY(hitPos, dir)
    local now = tick()
    -- Chỉ tính lại mỗi 0.1s (10 lần/giây thay vì 60)
    if cachedTopY and (now - lastFindTopTime) < 0.002  then
        return cachedTopY
    end
    lastFindTopTime = now
    
    local maxY = hitPos.Y
    for _, depth in ipairs({0, 2, 5}) do
        local probePos = dir
            and Vector3.new(hitPos.X + dir.X * depth, hitPos.Y, hitPos.Z + dir.Z * depth)
            or  hitPos
        local origin = Vector3.new(probePos.X, probePos.Y + 200, probePos.Z)
        
        local excludeList = { LocalPlayer.Character, NPCsForder, debugFolder }
        local tempFilter = RaycastParams.new()
        tempFilter.FilterType = Enum.RaycastFilterType.Exclude
        
        for attempt = 1, 5 do
            tempFilter.FilterDescendantsInstances = excludeList
            local result = workspace:Raycast(origin, Vector3.new(0, -300, 0), tempFilter)
            visualizeRay(origin, Vector3.new(0, -300, 0), result, Color3.fromRGB(0, 127, 255))
            if not result then break end
            
            if isBlockingPart(result.Instance) then
                if result.Position.Y > maxY then
                    maxY = result.Position.Y
                end
                break
            else
                table.insert(excludeList, result.Instance)
            end
        end
    end
    
    cachedTopY = maxY
    return maxY
end

local function doAvoidance(hrp, dir, hitPos, thickness, hitInstance)
	AvoidState.Avoiding = true
	-- KHÔNG dùng noclip (làm hỏng CanCollide các parts) - chỉ leo lên qua vật cản
	local topY = findTopY(hitPos)
	local targetHeight = cf.Farm.Mode.Chase and cf.Farm.AttackY or cf.Farm.SafeHeight
	local climbY = topY + targetHeight + 1
	dbg("FLY", "🏔 Obstacle (thick=%.1f) -> Climb to Y=%.1f", thickness, climbY)
	
	task.spawn(function()
		local t0 = tick()
		while flyActive and isAlive() and tick() - t0 < 3 do
			local h = getHRP()
			if not h then break end
			if h.Position.Y >= climbY - 1 then break end
			if flyBV and flyBV.Parent then
				local dy = climbY - h.Position.Y
				flyBV.Velocity = Vector3.new(0, math.clamp(dy * 6, 5, 40), 0)
			end
			task.wait(0.05)
		end
		AvoidState.Avoiding = false
		AvoidState.Armed = false
		AvoidState.MoveTimer = 0
		AvoidState.CooldownEnd = tick() + AvoidState.COOLDOWN
	end)
end
local function isBlockingPart(instance)
	if not instance then return false end
	-- Bỏ qua nếu thuộc folder debug
	if debugFolder and instance:IsDescendantOf(debugFolder) then return false end
	-- Bỏ qua nếu tàng hình hoàn toàn
	if instance.Transparency >= 1 then return false end
	-- Bỏ qua nếu không va chạm
	if not instance.CanCollide then return false end
	-- Terrain luôn là vật cản thật
	if instance:IsA("Terrain") then return true end
	return true
end


local function updateObstacleAvoidance(hrp, dir)
	local now = tick()
	if now - AvoidState.LastCheck < AvoidState.CHECK_INTERVAL then return end
	AvoidState.LastCheck = now
	
	if AvoidState.Avoiding or now < AvoidState.CooldownEnd then
		AvoidState.LastPosition = hrp.Position
		return
	end
	
	local moved = AvoidState.LastPosition and (hrp.Position - AvoidState.LastPosition).Magnitude or 0
	AvoidState.LastPosition = hrp.Position
	
	local threshold = AvoidState.MIN_SPEED * AvoidState.CHECK_INTERVAL
	if moved > threshold then
		AvoidState.MoveTimer = AvoidState.MoveTimer + AvoidState.CHECK_INTERVAL
	else
		AvoidState.MoveTimer = 0
		AvoidState.Armed = false
		return
	end
	
	if not AvoidState.Armed and AvoidState.MoveTimer >= AvoidState.TRIGGER_TIME then
		AvoidState.Armed = true
		dbg("FLY", "🔍 Obstacle avoidance ARMED")
	end
	if not AvoidState.Armed then return end
	
	refreshAvoidFilter()
	local hit = workspace:Raycast(hrp.Position, dir * AvoidState.PROBE_DIST, avoidFilter)
	visualizeRay(hrp.Position, dir * AvoidState.PROBE_DIST, hit, Color3.fromRGB(255, 0, 0))
	if not hit then return end
	
	if not isBlockingPart(hit.Instance) then return end  -- bỏ qua part tàng hình
	local thickness = probeThickness(hit.Position, dir)
	doAvoidance(hrp, dir, hit.Position, thickness, hit.Instance)
end

local function getGroundHeight(pos)
	local gParams = RaycastParams.new()
	local excludeList = { LocalPlayer.Character, NPCsForder, debugFolder }
	gParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayOrigin = Vector3.new(pos.X, pos.Y + 60, pos.Z)
	local rayDirection = Vector3.new(0, -350, 0)
	
	local groundY = 1
	for attempt = 1, 5 do
		gParams.FilterDescendantsInstances = excludeList
		local result = workspace:Raycast(rayOrigin, rayDirection, gParams)
		visualizeRay(rayOrigin, rayDirection, result, Color3.fromRGB(0, 255, 0))
		if not result then break end
		
		if result.Instance.CanCollide == true or result.Instance:IsA("Terrain") then
			groundY = result.Position.Y
			break
		else
			table.insert(excludeList, result.Instance)
		end
	end
	
	if groundY < 1 then
		groundY = 1
	end
	return groundY
end

local flyActive = false
local flyConn   = nil
local flyBV, flyGyro = nil, nil
local flytarget = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- ============================================================
--  HỆ THỐNG TÍNH ĐỘ CAO Y - 5 TRƯỜNG HỢP
-- ============================================================
--[[
  TH1: Mặt biển  → groundY ≤ 1 → cố định floorY = 1
  TH2: Đất bình thường → floorY = groundY dưới chân
  TH3: Chase mode  → dùng AttackY thay vì SafeHeight
  TH4: Vật cản phíd trước → forward ray phát hiện tường/cliff → leo lên đỉnh
  TH5: Dốc cao phíd trước → kiểm tra groundY ở điểm 10 studs phía trước
]]

local fwdRayParams = RaycastParams.new()
fwdRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function computeTargetY(currentPos, moveDir)
	local isChase = cf.Farm.Mode.Chase
	local targetHeight = isChase and cf.Farm.AttackY or cf.Farm.SafeHeight

	-- TH1 + TH2: Raycast xuống tìm mặt đất hiện tại
	local groundY = getGroundHeight(currentPos)
	local floorY = math.max(groundY, -2.5) -- TH1: không bao giờ xuống dưới biển
	local baseY = floorY + targetHeight  -- TH2+TH3

	if obstacleAvoidanceDisabled then
		return baseY
	end

	local isCeilingAbove = false
	local ceilParams = RaycastParams.new()
	ceilParams.FilterType = Enum.RaycastFilterType.Exclude
	ceilParams.FilterDescendantsInstances = { LocalPlayer.Character, NPCsForder, debugFolder }
	
	-- Check ceiling straight above player
	local pCeil = workspace:Raycast(currentPos, Vector3.new(0, 80, 0), ceilParams)
	visualizeRay(currentPos, Vector3.new(0, 80, 0), pCeil, Color3.fromRGB(0, 255, 255))
	if pCeil and isBlockingPart(pCeil.Instance) then
		isCeilingAbove = true
	end

	if moveDir and moveDir.Magnitude > 0.01 then
		local dir = moveDir.Unit
		fwdRayParams.FilterDescendantsInstances = { LocalPlayer.Character, NPCsForder, debugFolder }

		-- TH4: Raycast phía trước phát hiện tường/cliff
		local fwdHit = workspace:Raycast(currentPos, dir * 18, fwdRayParams)
		visualizeRay(currentPos, dir * 18, fwdHit, Color3.fromRGB(127, 0, 255))
		
		-- Check ceiling above the hit point to prevent climbing room/tunnel walls
		if fwdHit and not isCeilingAbove then
			local wCeil = workspace:Raycast(fwdHit.Position + Vector3.new(0, 2, 0), Vector3.new(0, 80, 0), ceilParams)
			visualizeRay(fwdHit.Position + Vector3.new(0, 2, 0), Vector3.new(0, 80, 0), wCeil, Color3.fromRGB(0, 255, 255))
			if wCeil and isBlockingPart(wCeil.Instance) then
				isCeilingAbove = true
			end
		end

		if fwdHit and fwdHit.Instance and not isCeilingAbove and
		   (fwdHit.Instance.CanCollide or fwdHit.Instance:IsA("Terrain")) and fwdHit.Instance.Transparency < 1 then
			local wallTopY = findTopY(fwdHit.Position)
			local climbY = wallTopY + targetHeight + 1
			if climbY > baseY then
				baseY = climbY -- leo lên đỉnh vật cản
			end
		end

		local right = Vector3.new(-dir.Z, 0, dir.X)
		for _, offset in ipairs({ right * 1.5, -right * 1.5 }) do
			local sideHit = workspace:Raycast(currentPos + offset, dir * 18, fwdRayParams)
			visualizeRay(currentPos + offset, dir * 18, sideHit, Color3.fromRGB(127, 0, 255))
			if sideHit and not isCeilingAbove and isBlockingPart(sideHit.Instance) then
				local sideTopY = findTopY(sideHit.Position)
				local sideClimbY = sideTopY + targetHeight + 3
				if sideClimbY > baseY then
					baseY = sideClimbY
				end
			end
		end
		-- TH5: Raycast xuống ở 10 studs phía trước kiểm tra dốc
		local aheadPos = currentPos + dir * 10
		local aheadGroundY = getGroundHeight(aheadPos)
		local aheadFloorY = math.max(aheadGroundY, 1)
		local aheadY = aheadFloorY + targetHeight
		if aheadY > baseY and not isCeilingAbove then
			baseY = aheadY -- leo lên dốc phía trước
		end
	end

	return baseY
end

local function stopFly()
	flyActive = false
	if flyConn  then flyConn:Disconnect();  flyConn  = nil end
	pcall(function() if flyBV   then flyBV:Destroy()   end end)
	pcall(function() if flyGyro then flyGyro:Destroy() end end)
	flyBV, flyGyro = nil, nil
	-- Chỉ khôi phục AutoRotate - KHÔNG đụng CanCollide để tránh làm hỏng hitbox gốc
	local hum = getHum()
	if hum then pcall(function() hum.AutoRotate = true end) end
	-- Noclip chỉ tắt nếu user tự bật, hệ thống fly không được tự quản lý CanCollide
	AvoidState.Armed     = false
	AvoidState.Avoiding  = false
	AvoidState.MoveTimer = 0
	AvoidState.LastPosition = nil
	AvoidState.NoclipTemp   = false
end

local function startFly()
	local hrp = getHRP()
	local hum = getHum()
	if not hrp or not hum or flyActive then return end
	flyActive = true

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent   = hrp

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyGyro.D = 250; flyGyro.P = 50000
	flyGyro.Parent = hrp

	-- KHÔNG dùng PlatformStand=true vì nó đổi hitbox nhân vật thành hình nằm ngang -> bị kẹt khe hẹp
	-- Chỉ tắt AutoRotate để BodyGyro kiểm soát hướng nhìn
	hum.AutoRotate = false
	rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
	
	local consecutiveErrors = 0
	local lastACFloorCheck = 0
	
	flyConn = RunService.Heartbeat:Connect(function()
		local ok, err = pcall(function()
			if not flyActive then return end
			local hrp2 = getHRP()
			if not hrp2 then stopFly(); return end

			-- Chỉ đọc vị trí hiện tại, KHÔNG force-teleport xuống (gây đánh nhau với physics)
			local currentPos = hrp2.Position

			-- 1. Collision & Ceiling Check
			local hasCeiling = false
			local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
			if head then
				local ceilParams = RaycastParams.new()
				ceilParams.FilterType = Enum.RaycastFilterType.Exclude
				ceilParams.FilterDescendantsInstances = { LocalPlayer.Character, NPCsForder, debugFolder }
				local ceilHit = workspace:Raycast(head.Position, Vector3.new(0, 80, 0), ceilParams)
				visualizeRay(head.Position, Vector3.new(0, 80, 0), ceilHit, Color3.fromRGB(0, 255, 255))
				if ceilHit and isBlockingPart(ceilHit.Instance) then
					hasCeiling = true
				end
			end

			local isSlabColliding = false
			if activeSlab and activeSlab.Parent then
				local overlapParams = OverlapParams.new()
				overlapParams.FilterType = Enum.RaycastFilterType.Exclude
				overlapParams.FilterDescendantsInstances = { LocalPlayer.Character, NPCsForder, debugFolder }
				local parts = workspace:GetPartsInPart(activeSlab, overlapParams)
				for _, part in ipairs(parts) do
					if isBlockingPart(part) then
						isSlabColliding = true
						break
					end
				end
			end

			if isSlabColliding then
				if not lastSlabCollisionStart then
					lastSlabCollisionStart = tick()
				end
				if tick() - lastSlabCollisionStart >= 4 then
					obstacleAvoidanceDisabled = true
				end
			else
				lastSlabCollisionStart = nil
				if not hasCeiling then
					obstacleAvoidanceDisabled = false
				end
			end

			if hasCeiling then
				obstacleAvoidanceDisabled = true
			end

			if activeSlab and activeSlab.Parent then
				if obstacleAvoidanceDisabled then
					activeSlab.Color = Color3.fromRGB(255, 0, 0)
				else
					activeSlab.Color = Color3.fromRGB(0, 255, 0)
				end
			end

			if not flyBV or not flyBV.Parent then return end

			if obstacleAvoidanceDisabled then
				local isChase = cf.Farm.Mode.Chase
				local targetHeight = isChase and cf.Farm.AttackY or cf.Farm.SafeHeight
				local groundY = getGroundHeight(currentPos)
				local targetY = groundY + targetHeight
				
				local dy = targetY - currentPos.Y
				local velY = math.clamp(dy * 5, -35, 35)
				
				local isBlockedBelow = false
				if dy < 0 then
					refreshAvoidFilter()
					local downHit = workspace:Raycast(currentPos, Vector3.new(0, -12, 0), avoidFilter)
					visualizeRay(currentPos, Vector3.new(0, -12, 0), downHit, Color3.fromRGB(255, 60, 60))
					if downHit and isBlockingPart(downHit.Instance) then
						isBlockedBelow = true
					end
				end
				
				local finalVelXZ = Vector3.zero
				if isBlockedBelow then
					local forward = hrp2.CFrame.LookVector
					if flytarget then
						local diff = flytarget - currentPos
						if diff.Magnitude > 1 then
							forward = diff.Unit
						end
					end
					local forwardXZ = Vector3.new(forward.X, 0, forward.Z).Unit
					
					local bestOffset = nil
					for angleDeg = -90, 90, 30 do
						local angleRad = math.rad(angleDeg)
						local cosA = math.cos(angleRad)
						local sinA = math.sin(angleRad)
						local testDir = Vector3.new(
							forwardXZ.X * cosA - forwardXZ.Z * sinA,
							0,
							forwardXZ.X * sinA + forwardXZ.Z * cosA
						).Unit
						
						local testDist = 8
						local testPos = currentPos + testDir * testDist
						
						refreshAvoidFilter()
						local pathHit = workspace:Raycast(currentPos, testDir * testDist, avoidFilter)
						visualizeRay(currentPos, testDir * testDist, pathHit, Color3.fromRGB(255, 255, 127))
						if not pathHit or not isBlockingPart(pathHit.Instance) then
							local belowTestHit = workspace:Raycast(testPos, Vector3.new(0, -12, 0), avoidFilter)
							visualizeRay(testPos, Vector3.new(0, -12, 0), belowTestHit, Color3.fromRGB(255, 255, 127))
							if not belowTestHit or not isBlockingPart(belowTestHit.Instance) then
								bestOffset = testDir * testDist
								break
							end
						end
					end
					
					if bestOffset then
						finalVelXZ = bestOffset.Unit * cf.Movement.Fly.Speed
					end
				else
					if flytarget then
						local diff = flytarget - currentPos
						local diffXZ = Vector3.new(diff.X, 0, diff.Z)
						if diffXZ.Magnitude > 1 then
							finalVelXZ = diffXZ.Unit * cf.Movement.Fly.Speed
						end
					end
				end
				
				if flyGyro and flyGyro.Parent then
					local moveDir = finalVelXZ.Magnitude > 0.1 and finalVelXZ.Unit or hrp2.CFrame.LookVector
					local lookPos = hrp2.Position + moveDir
					flyGyro.CFrame = CFrame.lookAt(
						hrp2.Position,
						Vector3.new(lookPos.X, hrp2.Position.Y, lookPos.Z),
						Vector3.new(0, 1, 0)
					)
				end
				
				flyBV.Velocity = Vector3.new(finalVelXZ.X, velY, finalVelXZ.Z)
				AvoidState.MoveTimer = 0
				AvoidState.Armed     = false
			else
				if flytarget then
					local diff = flytarget - hrp2.Position
					local diffXZ = Vector3.new(diff.X, 0, diff.Z)
					
					if diffXZ.Magnitude > 1 then
						-- Đang di chuyển tới target: có hướng đi
						local dir = diffXZ.Unit
						local velXZ = dir * cf.Movement.Fly.Speed
						
						-- Tính targetY đầy đủ 5 trường hợp (có forward look-ahead)
						local targetY = computeTargetY(currentPos, dir)
						local dy = targetY - currentPos.Y
						-- Deadzone ±0.4: giảm dao động nhỏ
						local velY = math.abs(dy) > 0.4 and math.clamp(dy * 5, -35, 35) or 0
						
						-- Xoay mặt nhân vật hướng về target chỉ trên XZ (không xoay Y/pitch)
						if flyGyro and flyGyro.Parent then
							local lookPos = hrp2.Position + dir  -- cùng Y, chỉ dịch XZ
							flyGyro.CFrame = CFrame.lookAt(
								hrp2.Position,
								lookPos,
								Vector3.new(0, 1, 0)  -- up vector = world Y, giữ thẳng đứng
							)
						end
						
						flyBV.Velocity = Vector3.new(velXZ.X, velY, velXZ.Z)
					else
						-- Đã tới nơi (diffXZ <= 1): hiệu chỉnh XZ nhỏ + giữ độ cao
						local targetY = computeTargetY(currentPos, nil)
						local dy = targetY - currentPos.Y
						local velY = math.abs(dy) > 0.4 and math.clamp(dy * 5, -35, 35) or 0
						-- Hiệu chỉnh XZ nhỏ để không drift
						local corrXZ = diffXZ.Magnitude > 0.1 and (diffXZ * 3) or Vector3.zero
						-- Giữ gyro hướng về target nếu vẫn còn hướng lệch
						if flyGyro and flyGyro.Parent and diffXZ.Magnitude > 0.1 then
							local dir2 = diffXZ.Unit
							flyGyro.CFrame = CFrame.lookAt(
								hrp2.Position,
								hrp2.Position + dir2,
								Vector3.new(0, 1, 0)
							)
						end
						flyBV.Velocity = Vector3.new(corrXZ.X, velY, corrXZ.Z)
						AvoidState.MoveTimer = 0
						AvoidState.Armed     = false
					end
				else
					-- Không có target (Idle hover): chỉ giữ độ cao an toàn
					AvoidState.MoveTimer = 0
					AvoidState.Armed     = false
					
					local targetY = computeTargetY(currentPos, nil)
					local dy = targetY - currentPos.Y
					local velY = math.abs(dy) > 0.4 and math.clamp(dy * 5, -35, 35) or 0
					
					flyBV.Velocity = Vector3.new(0, velY, 0)
				end
			end
		end)
		if not ok then
			consecutiveErrors = consecutiveErrors + 1
			warn("[Fly Loop Error]: " .. tostring(err))
			if consecutiveErrors > 5 then
				warn("[Crash Safeguard]: Too many consecutive flight errors. Disconnecting flight loop to prevent client crash.")
				stopFly()
			end
		else
			consecutiveErrors = 0
		end
	end)
end

local function flyTo(targetPos, stopDist, timeout, breakCondition)
	if not flyActive then startFly() end
	stopDist = stopDist or 8
	timeout = timeout or 10
	local t0 = tick()

	while tick() - t0 < timeout do
		if not isAlive() then break end
		if breakCondition and breakCondition() then break end

		local myHRP = getHRP()
		if not myHRP then break end

		local currentTarget = typeof(targetPos) == "function" and targetPos() or targetPos
		if not currentTarget then break end

		flytarget = currentTarget

		local diffXZ = Vector3.new(
			myHRP.Position.X - currentTarget.X,
			0,
			myHRP.Position.Z - currentTarget.Z
		)
		local diffY = math.abs(myHRP.Position.Y - currentTarget.Y)

		if diffXZ.Magnitude <= stopDist and diffY <= cf.Farm.AttackY then
			break
		end

		task.wait(0.05)  -- poll nhanh hơn để đuổi quái gần như real-time
	end
	-- KHÔNG dừng flyBV hay xóa flytarget toàn bộ:
	-- chỉ báo hiệu cho Heartbeat loop là không còn điểm đến
	flytarget = nil
	-- Heartbeat loop sẽ tự giữ độ cao hover, không cần zero velocity ở đây
end

-- ============================================================
--  COMBAT & AUTO-STATS
-- ============================================================
local function getSkillPoints()
	local pStats = ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
	if not pStats then return 0 end
	local statsFolder = pStats:FindFirstChild("Stats")
	if not statsFolder then return 0 end
	local sp = statsFolder:FindFirstChild("SkillPoints")
	return sp and sp.Value or 0
end

local function doAutoStats()
	if not StatsEvent then return end

	local hasActive = false
	for _, v in pairs(cf.AutoStats.Priority) do
		if v then hasActive = true break end
	end
	if not hasActive then return end

	while getSkillPoints() > 0 do
		local firedAny = false

		for skill, enabled in pairs(cf.AutoStats.Priority) do
			if not enabled then continue end
			if getSkillPoints() <= 0 then break end

			local spBefore = getSkillPoints()
			local currentSP = getSkillPoints()
			if currentSP <= 0 then return end
			pcall(function()
				StatsEvent:FireServer(skill, nil, math.min(cf.AutoStats.Points, currentSP))
			end)

			task.wait(0.4)

			local spAfter = getSkillPoints()
			if spAfter < spBefore then
				firedAny = true
			else
				dbg("STATS", "⚠️ %s failed to add points. Stopping AutoStats.", skill)
				return
			end
		end

		if not firedAny then break end
	end
end

local function ensureWeaponEquipped()
	if not cf.Farm.AutoEquip then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local currentTool = char:FindFirstChildWhichIsA("Tool")
	if currentTool and currentTool:FindFirstChild("Combat") then
		return
	end

	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, bpTool in ipairs(backpack:GetChildren()) do
			if bpTool:IsA("Tool") and bpTool:FindFirstChild("Combat") then
				hum:EquipTool(bpTool)
				dbg("FARM", "🎒 Auto-equipped weapon: %s", bpTool.Name)
				return
			end
		end
	end
end

local function getWeaponName()
	if not cf.Farm.AutoEquip then return "Melee" end

	local char = LocalPlayer.Character
	if not char then return "Melee" end

	local tool = char:FindFirstChildWhichIsA("Tool")
	if tool then return tool.Name end

	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, bpTool in ipairs(backpack:GetChildren()) do
			if bpTool:IsA("Tool") and bpTool:FindFirstChild("Combat") then
				return bpTool.Name
			end
		end
	end

	return "Melee"
end

local function sendHit(targets, comboStep)
	if not isAlive() then return false end
	ensureWeaponEquipped()
	if not targets or #targets == 0 then return false end
	local myHRP = getHRP()
	if not myHRP then return false end

	local hrpList = {}
	for _, npc in ipairs(targets) do
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		local hum = npc:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end
		
		local dist = (hrp.Position - myHRP.Position).Magnitude
		if dist <= cf.Farm.Range then
			table.insert(hrpList, hrp)
		end
	end
	if #hrpList == 0 then return false end

	local weapon  = getWeaponName()
	local step    = comboStep or 1
	local mode    = cf.Farm.M1Mode
	local punches = Animations[mode] or Animations.Ground

	-- Play swing SFX once for the visual swing representation
	local weaponAnims = CombatAnimations and CombatAnimations:FindFirstChild(weapon)
	if weaponAnims then
		pcall(function()
			local anim = weaponAnims:FindFirstChild(punches[step] or "")
			if anim then
				CombatRegisterEvent:InvokeServer({ "swingsfx", weapon, step, mode, false, anim, 2, 1.5 })
			end
		end)
	end

	local currentHRP = getHRP()
	if not currentHRP then return false end   

	local ok = pcall(function()
		local validHRPs = {}
		for _, hrp in ipairs(hrpList) do
			if hrp and hrp.Parent then
				local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
            	if not hum or hum.Health < 0 then continue end
				table.insert(validHRPs, hrp)
			end
		end
		if #validHRPs == 0 then return end
		
		local args = {
			"damage",
			validHRPs,
			weapon,
			{ step, mode, weapon },
			true,
			currentHRP.CFrame,
			aircombo = mode,
		}
		CombatRegisterEvent:InvokeServer(args)
	end)

	return ok
end


local function getCentroid(npcs)
	local totalX, totalY, totalZ = 0, 0, 0
	local count = 0
	for _, npc in ipairs(npcs) do
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp then
			totalX = totalX + hrp.Position.X
			totalY = totalY + hrp.Position.Y
			totalZ = totalZ + hrp.Position.Z
			count = count + 1
		end
	end
	if count == 0 then return nil end
	return Vector3.new(totalX / count, totalY / count, totalZ / count)
end

local function pullPassiveEnemies(aliveNPCs)
	local myHRP = getHRP()
	if not myHRP then return end
	
	for _, npc in ipairs(aliveNPCs) do
		local hum = npc:FindFirstChildOfClass("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then continue end
		
		local dist = (hrp.Position - myHRP.Position).Magnitude
		if dist > 25 then
			dbg("FARM", "Aggroing passive enemy: %s", npc.Name)
			local pullPos = Vector3.new(hrp.Position.X, hrp.Position.Y + cf.Farm.AttackY, hrp.Position.Z)
			flyTo(pullPos, 8, 4, function()
				return not npc.Parent or hum.Health <= 0 or not cf.Farm.Enable
			end)
			
			if hum.Health > 0 and cf.Farm.Enable and isAlive() then
				sendHit({ npc }, 1)
				task.wait(0.15)
			end
		end
	end
end


-- ============================================================
--  LOS CHECK + OBSTACLE SIDESTEP
-- ============================================================
--[[
  Hệ thống kiểm tra Line-of-Sight (LOS) giữa player và targets khi đang farm.
  Nếu tất cả targets đều bị vật cản chắn (tường, nhà, địa hình) thì:
    1. Probe 8 hướng 45° quanh player trong mặt phẳng XZ
    2. Thêm probe xuống biên (down-cast) để phát hiện ledge
    3. Chọn hướng thoáng nhất, ưu tiên hướng gần centroid
    4. Bay sang hướng đó một đoạn nhỏ rồi thử lại
--]]

local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude

local sideStepParams = RaycastParams.new()
sideStepParams.FilterType = Enum.RaycastFilterType.Exclude

-- 16 hướng probe, mỗi 22.5° (giống như hình ảnh với nhiều tia quét)
local PROBE_DIRS_16 = {}
for i = 0, 15 do
	local angle = math.rad(i * 22.5)
	PROBE_DIRS_16[i + 1] = Vector3.new(math.cos(angle), 0, math.sin(angle))
end

--[[
  checkLineOfSight(hrp, targets)
  Raycast theo 3 hướng cho mỗi target:
    • Ngang XZ thẳng (player.Y → target.X, target.Z tại cùng Y)
    • Chéo 3D thật sự (player → target)
    • Chéo xuống biên: từ player bắn xuống tại X/Z của target để check ledge
  Trả về true nếu thấy ÍT NHẤT 1 target, false nếu tất cả bị chắn.
--]]
local function checkLineOfSight(hrp, targets)
	losParams.FilterDescendantsInstances = { LocalPlayer.Character }
	local myPos = hrp.Position

	for _, npc in ipairs(targets) do
		local npcHRP = npc:FindFirstChild("HumanoidRootPart")
		local npcHum = npc:FindFirstChildOfClass("Humanoid")
		if not npcHRP or not npcHum or npcHum.Health <= 0 then continue end

		local tarPos = npcHRP.Position

		-- ① Raycast ngang XZ (giữ Y của player)
		local flatTarget = Vector3.new(tarPos.X, myPos.Y, tarPos.Z)
		local flatDir    = flatTarget - myPos
		if flatDir.Magnitude > 0.1 then
			local r = workspace:Raycast(myPos, flatDir, losParams)
			visualizeRay(myPos, flatDir, r, Color3.fromRGB(255, 0, 255))
			if not r then return true end  -- không trúng gì = nhìn thấy
			local hitModel = r.Instance:FindFirstAncestorOfClass("Model")
			if hitModel == npc then return true end
		end

		-- ② Raycast 3D thật (có cả chênh Y)
		local dir3D = tarPos - myPos
		if dir3D.Magnitude > 0.1 then
			local r2 = workspace:Raycast(myPos, dir3D, losParams)
			visualizeRay(myPos, dir3D, r2, Color3.fromRGB(255, 0, 255))
			if not r2 then return true end
			local hitModel2 = r2.Instance:FindFirstAncestorOfClass("Model")
			if hitModel2 == npc then return true end
		end

		-- ③ Raycast xuống biên: từ myPos.X/Z, tarPos.Y+50, bắn xuống
		--    Nếu hit trúng target (hoặc phần của nó) → ledge hở
		local downOrigin = Vector3.new(tarPos.X, myPos.Y + 20, tarPos.Z)
		local r3 = workspace:Raycast(downOrigin, Vector3.new(0, -80, 0), losParams)
		visualizeRay(downOrigin, Vector3.new(0, -80, 0), r3, Color3.fromRGB(255, 0, 255))
		if r3 then
			local hitModel3 = r3.Instance:FindFirstAncestorOfClass("Model")
			if hitModel3 == npc then return true end
		end
	end

	return false  -- tất cả bị chắn
end

--[[
  findEdgeOrOpenDir(hrp, targets)
  Probe 16 hướng xung quanh player (như radar).
  Tìm tia vươn xa nhất mà không bị cản (khoảng trống rộng nhất).
  Nếu có nhiều hướng cùng khoảng trống max, ưu tiên hướng xa vực sâu và gần centroid.
--]]
local function findEdgeOrOpenDir(hrp, targets)
	sideStepParams.FilterDescendantsInstances = { LocalPlayer.Character, NPCsForder }
	local myPos    = hrp.Position
	local PROBE_H  = 25  -- bắn tia xa 25 studs để tìm khoảng trống

	-- Hướng XZ về centroid
	local centroid = getCentroid(targets)
	local towardUnit = Vector3.new(1, 0, 0)
	if centroid then
		local toXZ = Vector3.new(centroid.X - myPos.X, 0, centroid.Z - myPos.Z)
		if toXZ.Magnitude > 0.1 then towardUnit = toXZ.Unit end
	end

	-- Phát hiện scenario: target ở THẤP HƠN player > 5 studs (đứng trên mái)
	local roofScenario = centroid and (myPos.Y - centroid.Y) > 5

	local bestDir   = nil
	local bestScore = -math.huge

	for _, dir in ipairs(PROBE_DIRS_16) do
		-- 1. Probe ngang tìm vật cản
		local hHit      = workspace:Raycast(myPos, dir * PROBE_H, sideStepParams)
		visualizeRay(myPos, dir * PROBE_H, hHit, Color3.fromRGB(255, 255, 0))
		local clearDist = hHit and hHit.Distance or PROBE_H

		-- 2. Check rơi mép (xuống vực) tại điểm tới
		local edgePt    = myPos + dir * math.min(clearDist, PROBE_H)
		local dHit      = workspace:Raycast(edgePt, Vector3.new(0, -50, 0), sideStepParams)
		visualizeRay(edgePt, Vector3.new(0, -50, 0), dHit, Color3.fromRGB(255, 255, 0))
		local dropDist  = dHit and dHit.Distance or 50

		local score

		if roofScenario then
			-- Trên mái nhà: Ưu tiên tìm "mép" (dropDist lớn)
			if clearDist < 2 then
				score = -999 -- Bị tường chặn sát sạt
			elseif dropDist > 4 then
				-- Rất tốt, tia đi đến mép mái
				score = dropDist * 2 + clearDist + dir:Dot(towardUnit) * 5
			else
				score = clearDist + dir:Dot(towardUnit) * 2 - dropDist
			end
		else
			-- Dưới đất: Chọn tia đi xa nhất (khoảng trống lớn nhất)
			if clearDist < 3 then
				score = -999 -- Quá hẹp
			elseif dropDist < 3 then
				score = -500 -- Sắp rơi xuống vực / biển
			else
				-- Yếu tố quyết định chính: clearDist (vươn xa nhất)
				-- Kết hợp một chút hướng về quái (towardUnit) để không chạy ngược hẳn
				score = clearDist * 10 + dir:Dot(towardUnit) * 5
			end
		end

		if score > bestScore then
			bestScore = score
			bestDir   = dir
		end
	end

	return bestDir, roofScenario
end

--[[
  doObstacleSidestep(hrp, targets)
  Kiểm tra LOS; nếu bị chắn:
    • Scenario mái nhà → bay ra mép mái xa hơn (10–14 studs), KHÔNG fix Y
      để fly system tự điều chỉnh xuống sau khi qua mép
    • Scenario tường ngang → bay sang hướng thoáng 7 studs, giữ Y
--]]
local function doObstacleSidestep(hrp, targets)
	if obstacleAvoidanceDisabled then return false end
	if checkLineOfSight(hrp, targets) then return false end
	dbg("FARM", "⚠️ LOS bị chắn! Phân tích hướng thoáng...")

	local openDir, isRoof = findEdgeOrOpenDir(hrp, targets)
	if not openDir then
		dbg("FARM", "⚠️ Không tìm thấy hướng thoáng, giữ nguyên")
		return false
	end

	local stepDist, stepPos

	if isRoof then
		-- 🏠 Scenario mái nhà: cần ra tới MÉP mái → bước xa hơn
		stepDist = 12
		local rawPos = hrp.Position + openDir * stepDist
		-- KHÔNG fix Y: để computeTargetY + fly tự hạ xuống sau khi qua mép
		stepPos = rawPos
		dbg("FARM", "🏠 Roof sidestep → mép mái (%.2f,%.2f) × %d studs", openDir.X, openDir.Z, stepDist)
	else
		-- 🧱 Scenario tường ngang: bước sang ngang, giữ Y
		stepDist = 8
		local rawPos = hrp.Position + openDir * stepDist
		stepPos = Vector3.new(rawPos.X, hrp.Position.Y, rawPos.Z)
		dbg("FARM", "🧱 Wall sidestep → (%.2f,%.2f) × %d studs", openDir.X, openDir.Z, stepDist)
	end

	flyTo(stepPos, 2, 3, function()
		return not farmRunning or not isAlive()
	end)
	task.wait(0.15)
	return true
end

-- ============================================================
--  FARM LOOP
-- ============================================================
local farmRunning = false
local wasIdle = false -- theo dõi trạng thái Idle để chỉ gọi emote 1 lần

local function stopFarmLoop()
	farmRunning = false
	wasIdle = false
	stopFly()
end

local function startFarmLoop()
	if farmRunning then return end
	farmRunning = true
	local lastScan = 0
	wasIdle = false
	
	task.spawn(function()
		while farmRunning do
			task.wait()  -- poll nhanh hơn để phản ứng chase gần real-time
			
			if not isAlive() then
				flytarget = nil
				wasIdle = false
				task.wait(0.5)
				continue
			end
			
			-- Stop loop if all active features are disabled
			if not cf.Farm.Enable 
			and not cf.AutoQuest.Enable 
			and not cf.AutoQuest.OnlyFlyToIsland 
			and not cf.IslandTravel.FlyToSelected then
				stopFarmLoop()
				continue
			end
			
			
			-- Đảm bảo fly luôn active khi farm đang chạy
			-- (có thể bị tắt ngầm sau quest/flyTo kết thúc)
			if not flyActive then startFly() end
			
			-- Auto Stats
			if cf.AutoStats.Enable and getSkillPoints() > 0 then
				doAutoStats()
			end

			-- Fly to Selected Island
			if cf.IslandTravel.FlyToSelected and cf.IslandTravel.SelectedIsland then
				local islandName = cf.IslandTravel.SelectedIsland
				local islandModel = workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild(islandName)
				if islandModel then
					local currentIsland = getCurrentIsland()
					if currentIsland ~= islandName then
						dbg("TRAVEL", "Traveling to selected island: %s", islandName)
						local cfrm, size = islandModel:GetBoundingBox()
						local destPos = cfrm.Position + Vector3.new(0, cf.Farm.SafeHeight + 10, 0)
						flyTo(destPos, 50, 90)
					else
						cf.Farm.Mode.Idle = true
						cf.Farm.Mode.Chase = false
						if not wasIdle then
							wasIdle = true
							pcall(function()
								local EmoteUtils = require(game.ReplicatedStorage.Modules.Shared.EmoteUtils)
								EmoteUtils:PlayEmote("float")
							end)
							dbg("FARM", "🛸 Idle (At Selected Island) - Playing float emote")
						end
						local hrp = getHRP()
						if hrp then
							local groundY = getGroundHeight(hrp.Position)
							flytarget = Vector3.new(hrp.Position.X, groundY + cf.Farm.SafeHeight, hrp.Position.Z)
						else
							flytarget = nil
						end
						task.wait(1)
					end
				else
					dbg("TRAVEL", "Selected island not found: %s", islandName)
					task.wait(1)
				end
				continue
			end

			-- Auto Quest State Machine
			local questData = nil
			if cf.AutoQuest.Enable or cf.AutoQuest.OnlyFlyToIsland then
				local state, qData = checkquest()
				questData = qData
				
				if state == "Tới đảo" then
					dbg("QUEST", "Traveling to island: %s", questData.Island)
					local destPos = questData.PositionIsland or questData.PositionQuest
					if destPos then
						flyTo(destPos, 50, 90)
					end
					continue
				elseif cf.AutoQuest.OnlyFlyToIsland then
					-- We are at the quest island! Just hover here.
					cf.Farm.Mode.Idle = true
					cf.Farm.Mode.Chase = false
					if not wasIdle then
						wasIdle = true
						pcall(function()
							local EmoteUtils = require(game.ReplicatedStorage.Modules.Shared.EmoteUtils)
							EmoteUtils:PlayEmote("float")
						end)
						dbg("FARM", "🛸 Idle (Only Fly To Island) - Playing float emote")
					end
					local hrp = getHRP()
					if hrp then
						local groundY = getGroundHeight(hrp.Position)
						flytarget = Vector3.new(hrp.Position.X, groundY + cf.Farm.SafeHeight, hrp.Position.Z)
					else
						flytarget = nil
					end
					task.wait(1)
					continue
				elseif state == "Không có Quest" and questData then
                    local npcPos = getQuestNPCPosition(questData)
					dbg("QUEST", "Accepting quest: %s from NPC: %s", questData.Help, questData.NPCName)
                    print("[DEBUG] npcPos =", npcPos)  -- thêm dòng này
					if npcPos then
						flyTo(npcPos + Vector3.new(0, 3, 0), 8, 20)
						task.wait(0.3)
						takeQuestRemote(questData.NPCName, questData.Help)
					end
					continue
				end
			end

			-- Target Selection
			local targetName = nil
			if cf.AutoQuest.Enable and questData then
				targetName = questData.Target
			end

			local npcs = {}
			if targetName then
				local found = findtar(targetName)
				for _, item in ipairs(found) do
					if item.isTar then table.insert(npcs, item.target) end
				end
				
				local foundBoss = findtarboss(targetName)
				for _, item in ipairs(foundBoss) do
					if item.isTar then table.insert(npcs, 1, item.target) end
				end
			else
				-- Manual Targets Checked in UI
				for name, enabled in pairs(cf.Target) do
					if enabled then
						local found = findtar(name)
						for _, item in ipairs(found) do
							if item.isTar then table.insert(npcs, item.target) end
						end
						
						local foundBoss = findtarboss(name)
						for _, item in ipairs(foundBoss) do
							if item.isTar then table.insert(npcs, 1, item.target) end
						end
					end
				end
			end

			-- Filter Dead
			local aliveNPCs = {}
			for _, npc in ipairs(npcs) do
				local hum = npc:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					table.insert(aliveNPCs, npc)
				end
			end

			if #aliveNPCs == 0 then
				if cf.AutoQuest.Enable and getActiveQuestName() then
					task.wait(0.5)
					continue  -- rescan ngay, không hover idle
				end
				cf.Farm.Mode.Idle = true
				cf.Farm.Mode.Chase = false
				
				-- Gọi emote float 1 lần khi vào Idle (không spam mỗi tick)
				if not wasIdle then
					wasIdle = true
					pcall(function()
						local EmoteUtils = require(game.ReplicatedStorage.Modules.Shared.EmoteUtils)
						EmoteUtils:PlayEmote("float")
					end)
					dbg("FARM", "🛸 Idle mode - Playing float emote")
				end
				
				-- Hover safely at a spawn center or near quest NPC
				local idlePos = nil
				if questData then
					idlePos = questData.PositionQuest
				end
				
				if idlePos then
					local groundY = getGroundHeight(idlePos)
					local hoverPos = Vector3.new(idlePos.X, groundY + cf.Farm.SafeHeight, idlePos.Z)
					flytarget = hoverPos
				else
					flytarget = nil
					if flyBV and flyBV.Parent then flyBV.Velocity = Vector3.zero end
				end
				
				task.wait(0.5)
				continue
			end

			-- Targets found: Transition to Chase (Active Farm)
			cf.Farm.Mode.Idle = false
			cf.Farm.Mode.Chase = true
			wasIdle = false -- reset để lần Idle tiếp theo sẽ gọi emote lại

			if not flyActive then startFly() end

			-- Centroid/Group Farming
			local centroid = getCentroid(aliveNPCs)
			if centroid then
				local pullCounter = 0
				local PULL_EVERY = 1  
				
				local groundY = getGroundHeight(centroid)
				local targetY = math.max(centroid.Y + cf.Farm.AttackY, groundY + cf.Farm.SafeHeight)
				local targetPos = Vector3.new(centroid.X, targetY, centroid.Z)

				flyTo(targetPos, 4, 30, function()  -- stopDist=4 không cần sát hẳn mới dừng
					return not farmRunning or not isAlive()
				end)
				-- Đợi ngắn để gyro ổn định hướng trước khi đánh
				task.wait(0.05)
				local _keepCentroid = getCentroid(aliveNPCs)
				if _keepCentroid then
					local gY = getGroundHeight(_keepCentroid)
					local tY = math.max(_keepCentroid.Y + cf.Farm.AttackY, gY + cf.Farm.SafeHeight)
					flytarget = Vector3.new(_keepCentroid.X, tY, _keepCentroid.Z)
				end

				while farmRunning and isAlive() do
					local freshAlive = {}
					if targetName then
						local foundBoss = findtarboss(targetName)
						for _, item in ipairs(foundBoss) do
							if item.isTar then
								local hum = item.target:FindFirstChildOfClass("Humanoid")
								if hum and hum.Health > 0 then
									table.insert(freshAlive, item.target)
								end
							end
						end
						local found = findtar(targetName)
						for _, item in ipairs(found) do
							if item.isTar then
								local hum = item.target:FindFirstChildOfClass("Humanoid")
								if hum and hum.Health > 0 then
									table.insert(freshAlive, item.target)
								end
							end
						end
					else
						for name, enabled in pairs(cf.Target) do
							if enabled then
								local foundBoss = findtarboss(name)
								for _, item in ipairs(foundBoss) do
									if item.isTar then
										local hum = item.target:FindFirstChildOfClass("Humanoid")
										if hum and hum.Health > 0 then
											table.insert(freshAlive, item.target)
										end
									end
								end
								local found = findtar(name)
								for _, item in ipairs(found) do
									if item.isTar then
										local hum = item.target:FindFirstChildOfClass("Humanoid")
										if hum and hum.Health > 0 then
											table.insert(freshAlive, item.target)
										end
									end
								end
							end
						end
					end

					if #freshAlive == 0 then break end
					if cf.AutoQuest.Enable and not getActiveQuestName() then break end
                    if cf.AutoQuest.Enable then
                        local newQuest, _ = getBestQuest()
                        if newQuest and newQuest.Target ~= targetName then
                            dbg("QUEST", "Level up! Abandoning quest, switching to: %s", newQuest.Target)
                            abandonQuest()
                            break
                        end
                    end
					-- ← THÊM: cập nhật centroid bay theo nhóm mới
					local newCentroid = getCentroid(freshAlive)
					if newCentroid then
						local gY = getGroundHeight(newCentroid)
						local tY = math.max(newCentroid.Y + cf.Farm.AttackY, gY + cf.Farm.SafeHeight)
						flytarget = Vector3.new(newCentroid.X, tY, newCentroid.Z)
					end
					pullCounter = pullCounter + 1
					if pullCounter >= PULL_EVERY then
						pullCounter = 0
						-- Chỉ gom những NPC đang còn sống và đứng xa
						local toAggro = {}
						local myHRP = getHRP()
						if myHRP then
							for _, npc in ipairs(freshAlive) do
								local hum = npc:FindFirstChildOfClass("Humanoid")
								local hrp = npc:FindFirstChild("HumanoidRootPart")
								if hum and hrp and hum.Health > 0 then
									local dist = (hrp.Position - myHRP.Position).Magnitude
									if dist > 25 then
										table.insert(toAggro, npc)
									end
								end
							end
						end
						if #toAggro > 0 then
							dbg("FARM", "🔄 Re-pulling %d passive NPCs", #toAggro)
							pullPassiveEnemies(toAggro)
						end
					end
					-- Kiểm tra LOS trước khi đánh: nếu vật cản chắn tất cả targets → sidestep
					local myHRP_los = getHRP()
                    if myHRP_los and #freshAlive > 0 then
                        doObstacleSidestep(myHRP_los, freshAlive)
                    end
					for i = 1, cf.Farm.ComboSize do
						if not farmRunning or not isAlive() then break end
						-- Lọc lại freshAlive trước mỗi hit
						local stillAlive = {}
						for _, npc in ipairs(freshAlive) do
							local hum = npc:FindFirstChildOfClass("Humanoid")
							if hum and hum.Health > 0 then
								table.insert(stillAlive, npc)
							end
						end
						if #stillAlive == 0 then break end

						-- ✅ Cập nhật vị trí target real-time mỗi hit
						local rtCentroid = getCentroid(stillAlive)
						if rtCentroid then
							local gY = getGroundHeight(rtCentroid)
							local tY = math.max(rtCentroid.Y + cf.Farm.AttackY, gY + cf.Farm.SafeHeight)
							flytarget = Vector3.new(rtCentroid.X, tY, rtCentroid.Z)
						end

						sendHit(stillAlive, i)
						local isFinisher = (i == cf.Farm.ComboSize)
						task.wait(isFinisher and cf.Farm.FinisherDelay or cf.Farm.HitDelay)
					end
					-- không wait: vòng lặp chạy lại ngay để cập nhật centroid và bay tới quái tiếp
				end
			end
		end
		stopFly()
	end)
end

-- ============================================================
--  TARGET DISCOVERY SCAN
-- ============================================================
local function scanNPCs()
	for _, npc in pairs(NPCsForder:GetChildren()) do
		if not npc:IsA("Model") then continue end
		local h   = npc:FindFirstChildOfClass("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if not h or not hrp then continue end

		local info    = npc:FindFirstChild("Info")
		local hostile = info and info:FindFirstChild("Hostile")
		if npc.Name == "Shark" then continue end
		
		local isEnemy = not info or (hostile and hostile.Value == true) 
		if isEnemy and cf.Target[npc.Name] == nil then
			cf.Target[npc.Name] = false
		end
	end
end

local function scanQuestTargets()
	for _, questCfg in pairs(cf.AutoQuest.Quests) do
		if questCfg.Target and cf.Target[questCfg.Target] == nil then
			cf.Target[questCfg.Target] = false
		end
	end
end

scanNPCs()
scanQuestTargets()

-- ============================================================
--  DEBUG LOGGING SYSTEM
-- ============================================================
local dbgCount = { total = 0, error = 0 }

local TAG_FILTER = {
	HIT    = function() return cf.Debug.showHit    end,
	FLY    = function() return cf.Debug.showFly    end,
	NPC    = function() return cf.Debug.showNPC    end,
	REMOTE = function() return cf.Debug.ShowRemotes end,
	FARM   = function() return cf.Debug.showFarm   end,
	ERROR  = function() return true end,
	QUEST  = function() return cf.Debug.showQuest  end,
	STATS  = function() return cf.Debug.showStats  end,
}

dbg = function(tag, msg, ...)
	if not cf.Debug.Enable then return end
	local filter = TAG_FILTER[tag:upper()]
	if filter and not filter() then return end

	dbgCount.total = dbgCount.total + 1
	local formatted = string.format(msg, ...)
	local time = string.format("[%06.2f]", tick() % 1000)

	local prefix = ""
	local uTag = tag:upper()
	if uTag == "ERROR" then
		dbgCount.error = dbgCount.error + 1
		prefix = "❌ "
		Library:Notify({
			Title    = "❌ Debug Error",
			Content  = formatted,
			Duration = 5,
		})
	elseif uTag == "HIT" then prefix = "⚔ "
	elseif uTag == "FLY" then prefix = "✈ "
	elseif uTag == "FARM" then prefix = "🚜 "
	elseif uTag == "REMOTE" then prefix = "📡 "
	elseif uTag == "NPC" then prefix = "👾 "
	elseif uTag == "QUEST" then prefix = "📜 "
	elseif uTag == "STATS" then prefix = "📊 "
	end

	print(string.format("%s %s[%s] %s (call#%d)", time, prefix, uTag, formatted, dbgCount.total))
end

-- Anti-AFK
if cf.Exploit.Anti_Afk then
	LocalPlayer.Idled:Connect(function()
		local vjs = LocalPlayer:FindFirstChild("PlayerGui")
		if vjs then
			game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end
	end)
end

-- ============================================================
--  GUI CREATION
-- ============================================================
local Window = Library:CreateWindow({
	Title         = "Grand Piece Online Premium Script v2",
	Center        = true,
	AutoShow      = true,
	ToggleKeybind = Enum.KeyCode.RightShift,
})

local Tab = {
	Farm = Window:AddTab("Farm", "home"),
	Quest = Window:AddTab("Quest", "scroll"),
	Stats = Window:AddTab("Stats", "bar-chart"),
	Targets = Window:AddTab("Targets", "crosshair"),
	Settings = Window:AddTab("Settings", "settings"),
}

local GBFarm = Tab.Farm:AddLeftGroupbox("Auto Farm Control")
local GBFSettings = Tab.Farm:AddRightGroupbox("Farm Settings")

GBFarm:AddToggle("ToggleFarm", {
	Text     = "Enable Auto Farm",
	Default  = cf.Farm.Enable,
	Callback = function(v)
		cf.Farm.Enable = v
		if v then startFarmLoop() else stopFarmLoop() end
	end,
})

GBFarm:AddToggle("ToggleNoclip", {
	Text     = "NoClip",
	Default  = cf.Movement.Noclip.Enabled,
	Callback = function(v)
		cf.Movement.Noclip.Enabled = v
		if v then enableNoclip() else disableNoclip() end
	end,
})


GBFarm:AddDropdown("DropM1Mode", {
	Text     = "M1 Attack Mode",
	Values   = { "Ground", "Air" },
	Default  = cf.Farm.M1Mode,
	Callback = function(v) cf.Farm.M1Mode = v end,
})

GBFSettings:AddSlider("AttackY", {
	Text = "Attack Y Offset",
	Default = cf.Farm.AttackY,
	Min = 0, Max = 30, Rounding = 0, -- ngoại lệ 
	Callback = function(v) cf.Farm.AttackY = v end, 
})


GBFSettings:AddSlider("FlySpeed", {
	Text    = "Flight Speed",
	Default = cf.Movement.Fly.Speed,
	Min = 50, Max = 300, Rounding = 0,
	Callback = function(v) cf.Movement.Fly.Speed = v end,
})

GBFSettings:AddSlider("SliderCombo", {
	Text     = "Combo Chain Size",
	Default  = cf.Farm.ComboSize,
	Min = 1, Max = 10, Rounding = 0,
	Callback = function(v) cf.Farm.ComboSize = v end,
})

GBFSettings:AddSlider("SafeHeight", {
	Text    = "Safe Y Height",
	Default = cf.Farm.SafeHeight,
	Min = 1, Max = 5, Rounding = 0,
	Callback = function(v) cf.Farm.SafeHeight = v end,
})

GBFarm:AddToggle("ToggleDebug", {
    Text = "Debug Visualizer",
    Default = cf.Debug.Enable,
    Callback = function(v) cf.Debug.Enable = v end,
})

-- Quest Tab
local GBQuest = Tab.Quest:AddLeftGroupbox("Auto Quest Control")
local GBQuestInfo = Tab.Quest:AddRightGroupbox("Quest Status")

GBQuest:AddToggle("ToggleAutoQuest", {
    Text     = "Enable Auto Quest",
    Default  = cf.AutoQuest.Enable,
    Callback = function(v)
        cf.AutoQuest.Enable = v
        dbg("QUEST", "AutoQuest toggled: %s", tostring(v))
        if v then
            if not farmRunning then startFarmLoop() end
        else
            stopFarmLoop()
        end
    end,
})

GBQuest:AddToggle("ToggleOnlyFlyToIsland", {
	Text     = "Only Fly to Quest Island",
	Default  = cf.AutoQuest.OnlyFlyToIsland,
	Callback = function(v)
		cf.AutoQuest.OnlyFlyToIsland = v
		dbg("QUEST", "OnlyFlyToIsland toggled: %s", tostring(v))
		if v then
			if not farmRunning then
				startFarmLoop()
			end
		end
	end,
})



local GBIslandTravel = Tab.Quest:AddLeftGroupbox("Island Travel")

local islands = getIslandsList()
local defaultIsland = islands[1] or "Starter Island"
cf.IslandTravel.SelectedIsland = defaultIsland

GBIslandTravel:AddDropdown("DropSelectedIsland", {
	Text     = "Select Target Island",
	Values   = islands,
	Default  = defaultIsland,
	Callback = function(v)
		cf.IslandTravel.SelectedIsland = v
		dbg("TRAVEL", "Selected island changed to: %s", tostring(v))
	end,
})

GBIslandTravel:AddToggle("ToggleFlyToSelected", {
	Text     = "Fly to Selected Island",
	Default  = cf.IslandTravel.FlyToSelected,
	Callback = function(v)
		cf.IslandTravel.FlyToSelected = v
		dbg("TRAVEL", "Fly to Selected Island toggled: %s", tostring(v))
		if v then
			if not farmRunning then
				startFarmLoop()
			end
		end
	end,
})

local QuestLevelLabel = GBQuestInfo:AddLabel({ Text = "Current Level: 0" })
local QuestActiveLabel = GBQuestInfo:AddLabel({ Text = "Active Quest: None" })
local QuestTargetLabel = GBQuestInfo:AddLabel({ Text = "Quest Target: None" })

task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			QuestLevelLabel:SetText("Current Level: " .. tostring(Level()))
			local activeQ = getActiveQuestName()
			QuestActiveLabel:SetText("Active Quest: " .. (activeQ or "None"))
			
			local bestQ, bestL = getBestQuest()
			if bestQ then
				QuestTargetLabel:SetText("Target: " .. bestQ.Target .. " (Lv." .. tostring(bestL) .. ")")
			else
				QuestTargetLabel:SetText("Target: None")
			end
		end)
	end
end)

-- Stats Tab
local GBStats = Tab.Stats:AddLeftGroupbox("Auto Stats Control")
local GBStatsPriority = Tab.Stats:AddRightGroupbox("Stats Allocation Priority")
local GBStatsDep = GBStatsPriority:AddDependencyBox()

GBStats:AddToggle("AutoStats", {
	Text = "Enable AutoStats",
	Default = cf.AutoStats.Enable,
	Callback = function(v)
		cf.AutoStats.Enable = v
		if v then
			task.spawn(function()
				while cf.AutoStats.Enable do
					if getSkillPoints() > 0 then
						doAutoStats()
					end
					task.wait(1)
				end
			end)
		end
	end
})

GBStats:AddSlider("Points", {
	Text = "Allocation Points/Click",
	Default = cf.AutoStats.Points,
	Min = 1, Max = 1000, Rounding = 0,
	Callback = function(v) cf.AutoStats.Points = v end
})

for name, _ in pairs(cf.AutoStats.Priority) do
	GBStatsDep:AddToggle("StatPriority_" .. name, {
		Text = name,
		Default = cf.AutoStats.Priority[name],
		Callback = function(v) cf.AutoStats.Priority[name] = v end,
	})
end

GBStatsDep:SetupDependencies({
	{ Toggles.AutoStats, true }
})

-- Targets Tab
local GBTargets = Tab.Targets:AddLeftGroupbox("Manual Targets")
task.spawn(function()
	-- Load targets UI checkboxes dynamically
	for name, _ in pairs(cf.Target) do
		GBTargets:AddToggle("TargetCheck_" .. name, {
			Text     = name,
			Default  = cf.Target[name],
			Callback = function(v) cf.Target[name] = v end,
		})
	end
end)



-- Nút hủy script
GBFarm:AddButton("BtnDestroyScript", {
    Text = "💀 Destroy Script",
    Callback = function()
        Library:Notify({
            Title   = "💀 Script Destroyed",
            Content = "Đang dừng tất cả vòng lặp...",
            Duration = 3,
        })

        -- Dừng farm + fly
        stopFarmLoop()

        -- Ngắt noclip nếu đang bật
        if cf.Movement.Noclip.Enabled then
            disableNoclip()
        end

        -- Xóa toàn bộ debug visuals
        clearDebugLine()
        clearNPCBoxes()
        clearStateLabel()
        clearStopMarker()
        clearPrevMarker()
		if activeSlab then
			pcall(function() activeSlab:Destroy() end)
			activeSlab = nil
		end

        -- Hủy UI
        task.wait(0.5)
        pcall(function() Library:Destroy() end)
    end,
})

-- Settings Tab
local TabUI = Tab.Settings
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:ApplyToTab(TabUI)
SaveManager:SetFolder("GrandPiece_Farm_V2")
SaveManager:BuildConfigSection(TabUI)
SaveManager:LoadAutoloadConfig()


-- ============================================================
--  DEBUG VISUALIZER
-- ============================================================
local debugVisuals = {
	flyLine   = nil,  -- line từ player → flytarget
	npcBoxes  = {},   -- SelectionBox cho từng NPC đang bị target
	stateLabel = nil, -- BillboardGui hiện state
	stopMarker = nil,
	prevMarker     = nil,
	lastKnownTarget = nil,
}

local function createDebugLine()
	local p = Instance.new("Part")
	p.Name        = "_DebugFlyLine"
	p.Anchored    = true
	p.CanCollide  = false
	p.CastShadow  = false
	p.Material    = Enum.Material.Neon
	p.Color       = Color3.fromRGB(0, 200, 255)
	p.Size        = Vector3.new(0.08, 0.08, 1)
	p.Transparency = 0.2
	p.Parent      = debugFolder
	return p
end

local function updateDebugLine(from, to)
	if not debugVisuals.flyLine then
		debugVisuals.flyLine = createDebugLine()
	end
	local dist = (to - from).Magnitude
	if dist < 0.1 then
		debugVisuals.flyLine.Size = Vector3.new(0.08, 0.08, 0.1)
		return
	end
	debugVisuals.flyLine.Size  = Vector3.new(0.08, 0.08, dist)
	debugVisuals.flyLine.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
end

local function clearDebugLine()
	if debugVisuals.flyLine then
		debugVisuals.flyLine:Destroy()
		debugVisuals.flyLine = nil
	end
end

local function updateNPCBoxes(npcs)
	-- xoá box cũ
	for _, box in pairs(debugVisuals.npcBoxes) do
		pcall(function() box:Destroy() end)
	end
	debugVisuals.npcBoxes = {}

	if not npcs then return end
	for i, npc in ipairs(npcs) do
		local box = Instance.new("SelectionBox")
		box.Color3        = (i == 1) and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 200, 0)
		box.LineThickness = 0.04
		box.SurfaceTransparency = 0.8
		box.Adornee = npc
		box.Parent  = workspace
		table.insert(debugVisuals.npcBoxes, box)
	end
end

local function clearNPCBoxes()
	for _, box in pairs(debugVisuals.npcBoxes) do
		pcall(function() box:Destroy() end)
	end
	debugVisuals.npcBoxes = {}
end

local function getStateLabel(hrp)
	if debugVisuals.stateLabel and debugVisuals.stateLabel.Parent then
		return debugVisuals.stateLabel
	end
	local bb = Instance.new("BillboardGui")
	bb.Name          = "_DebugStateLabel"
	bb.Size          = UDim2.new(0, 200, 0, 50)
	bb.StudsOffset   = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop   = true
	bb.Adornee       = hrp
	bb.Parent        = hrp

	local lbl = Instance.new("TextLabel", bb)
	lbl.Name            = "Lbl"
	lbl.Size            = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	lbl.BackgroundTransparency = 0.4
	lbl.TextColor3      = Color3.fromRGB(255, 255, 255)
	lbl.TextScaled      = true
	lbl.Font            = Enum.Font.Code
	lbl.Text            = "..."

	debugVisuals.stateLabel = bb
	return bb
end

local function clearStateLabel()
	if debugVisuals.stateLabel then
		pcall(function() debugVisuals.stateLabel:Destroy() end)
		debugVisuals.stateLabel = nil
	end
end

local function updateStopMarker(pos)
	if not debugVisuals.stopMarker then
		local p = Instance.new("Part")
		p.Name         = "_DebugStopMarker"
		p.Anchored     = true
		p.CanCollide   = false
		p.CastShadow   = false
		p.Material     = Enum.Material.Neon
		p.Shape        = Enum.PartType.Ball
		p.Color        = Color3.fromRGB(255, 100, 0)
		p.Size         = Vector3.new(1.5, 1.5, 1.5)
		p.Transparency = 0.3
		p.Parent       = debugFolder

		-- Vòng tròn đánh dấu radius dừng
		local ring = Instance.new("Part")
		ring.Name         = "_DebugStopRing"
		ring.Anchored     = true
		ring.CanCollide   = false
		ring.CastShadow   = false
		ring.Material     = Enum.Material.Neon
		ring.Color        = Color3.fromRGB(255, 100, 0)
		ring.Size         = Vector3.new(cf.Farm.AttackY * 2, 0.1, cf.Farm.AttackY * 2)
		ring.Shape        = Enum.PartType.Cylinder
		ring.Transparency = 0.6
		ring.Parent       = debugFolder

		debugVisuals.stopMarker = { ball = p, ring = ring }
	end

	debugVisuals.stopMarker.ball.Position = pos
	debugVisuals.stopMarker.ring.CFrame   = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	debugVisuals.stopMarker.ring.Size     = Vector3.new(0.1, cf.Farm.AttackY * 2, cf.Farm.AttackY * 2)
end

local function clearStopMarker()
	if debugVisuals.stopMarker then
		pcall(function() debugVisuals.stopMarker.ball:Destroy() end)
		pcall(function() debugVisuals.stopMarker.ring:Destroy() end)
		debugVisuals.stopMarker = nil
	end
end

local function updatePrevMarker(pos)
	if not debugVisuals.prevMarker then
		local p = Instance.new("Part")
		p.Name         = "_DebugPrevMarker"
		p.Anchored     = true
		p.CanCollide   = false
		p.CastShadow   = false
		p.Material     = Enum.Material.Neon
		p.Shape        = Enum.PartType.Ball
		p.Color        = Color3.fromRGB(180, 80, 255) -- tím, phân biệt với cam
		p.Size         = Vector3.new(1, 1, 1)
		p.Transparency = 0.55
		p.Parent       = debugFolder

		local ring = Instance.new("Part")
		ring.Name         = "_DebugPrevRing"
		ring.Anchored     = true
		ring.CanCollide   = false
		ring.CastShadow   = false
		ring.Material     = Enum.Material.Neon
		ring.Color        = Color3.fromRGB(180, 80, 255)
		ring.Shape        = Enum.PartType.Cylinder
		ring.Transparency = 0.75
		ring.Parent       = debugFolder

		debugVisuals.prevMarker = { ball = p, ring = ring }
	end

	debugVisuals.prevMarker.ball.Position = pos
	debugVisuals.prevMarker.ring.CFrame   = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	debugVisuals.prevMarker.ring.Size     = Vector3.new(0.1, cf.Farm.AttackY * 2, cf.Farm.AttackY * 2)
end

local function clearPrevMarker()
	if debugVisuals.prevMarker then
		pcall(function() debugVisuals.prevMarker.ball:Destroy() end)
		pcall(function() debugVisuals.prevMarker.ring:Destroy() end)
		debugVisuals.prevMarker = nil
		debugVisuals.lastKnownTarget = nil
	end
end

-- Loop cập nhật visuals
task.spawn(function()
	while true do
		task.wait(0.05)
		
		if not cf.Debug.Enable then
			clearDebugLine()
			clearNPCBoxes()
			clearStateLabel()
			clearStopMarker()
			clearPrevMarker()
		else
			local hrp = getHRP()
			if hrp then
				-- 1. Line tới flytarget
				if flytarget then
					updateDebugLine(hrp.Position, flytarget)
					updateStopMarker(flytarget)
				else
					clearDebugLine()
					clearStopMarker()
					clearPrevMarker()
				end

				-- 2. SelectionBox quanh NPC đang target
				local targetName = nil
				if cf.AutoQuest.Enable then
					local q, _ = getBestQuest()
					if q then targetName = q.Target end
				end

				local currentTargets = {}
				if targetName then
					local foundBoss = findtarboss(targetName)
					for _, item in ipairs(foundBoss) do
						if item.isTar then
							local hum = item.target:FindFirstChildOfClass("Humanoid")
							if hum and hum.Health > 0 then table.insert(currentTargets, item.target) end
						end
					end
					local found = findtar(targetName)
					for _, item in ipairs(found) do
						if item.isTar then
							local hum = item.target:FindFirstChildOfClass("Humanoid")
							if hum and hum.Health > 0 then table.insert(currentTargets, item.target) end
						end
					end
				else
					for name, enabled in pairs(cf.Target) do
						if enabled then
							local found = findtar(name)
							for _, item in ipairs(found) do
								if item.isTar then
									local hum = item.target:FindFirstChildOfClass("Humanoid")
									if hum and hum.Health > 0 then table.insert(currentTargets, item.target) end
								end
							end
						end
					end
				end
				updateNPCBoxes(currentTargets)

				-- 3. Label trạng thái
				local bb = getStateLabel(hrp)
				local lbl = bb:FindFirstChild("Lbl")
				if lbl then
					local mode = cf.Farm.Mode.Chase and "CHASE" or (cf.Farm.Mode.Idle and "IDLE" or "---")
					local tgt  = flytarget and string.format("(%.0f,%.0f,%.0f)", flytarget.X, flytarget.Y, flytarget.Z) or "nil"
					local aq   = getActiveQuestName() or "none"
					lbl.Text = string.format("[%s] quest:%s\ntarget:%s", mode, aq, tgt)
				end
			else
				clearDebugLine()
				clearNPCBoxes()
				clearStateLabel()
			end
		end
	end
end)

-- Respawn Listener
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1)
	setupSlab(char)
	flyBV, flyGyro = nil, nil
	flyActive = false
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	
	if farmRunning then
		farmRunning = false
		task.wait(0.5)
		startFarmLoop()
	end
end)
