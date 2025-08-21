local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);
local modPropertiesVariable = shared.require(game.ReplicatedStorage.Library.PropertiesVariable);

local eventPackage = {
	Id = "banditcamps";
	Name = "Bandit Camps";

	MapMarkers = {
		["SmallBanditCamp"] = {
			Icon = "rbxassetid://13111861634";
			Color = Color3.fromRGB(99, 67, 53);
			IconSize = 0.7;
			Label = "Small Bandit Camp";
		};
	};

	CampInstances = {};

	TemplateEventMap = nil;
	Prefabs = nil;
};


--==
local EnemyCamp = {};
EnemyCamp.__index = EnemyCamp;
EnemyCamp.CorePart = nil;
EnemyCamp.EventInstance = nil;

function EnemyCamp.new(key, prefab)
	prefab.Parent = script;
	local campType = prefab:GetAttribute("CampType");

	local self: PropertiesVariable<anydict> = modPropertiesVariable.new{
		State = "Idle";
		Active = false;

		Key = key;
		Name = prefab.Name;
		Prefab = prefab;
		CFrame = prefab:GetPivot();
		Type = campType;
		Garbage = modGarbageHandler.new();

		Spawns = {};
		BanditNpcClasses = {};

		RewardId = nil;
		MarkerAtt = nil;
		FirebarrelLandmark = nil;
		CrateSpawnCFrame = nil;
	};
	self:SetMetatable(EnemyCamp);

	if campType == "SmallBanditCamp" then
		self.RewardId = "smallbanditcamp";
	end

	local newAtt = Instance.new("Attachment");
	newAtt.Name = campType;
	newAtt.Parent = EnemyCamp.CorePart;
	newAtt.WorldCFrame = self.CFrame;
	newAtt:SetAttribute("MarkerId", key);
	newAtt:SetAttribute("Disabled", true);
	self.MarkerAtt = newAtt;

	-- firebarrel
	local firebarrel = prefab:WaitForChild("Firebarrel");
	local newFirebarrel = eventPackage.Prefabs.Firebarrel:Clone();
	newFirebarrel:PivotTo(firebarrel:GetPivot());
	newFirebarrel.Parent = newAtt;
	self.FirebarrelLandmark = newFirebarrel;

	local fireLight = newFirebarrel:WaitForChild("_lightSource"):WaitForChild("_lightPoint"):WaitForChild("PointLight");
	local fireParticle = newFirebarrel:WaitForChild("_lightSource"):WaitForChild("firePoint"):WaitForChild("Fire");
	fireLight.Enabled = false;
	fireParticle.Enabled = false;

	function self:ToggleLandmarkFire(v)
		if v == true then
			newFirebarrel.Parent = newAtt;
		else
			newFirebarrel.Parent = script;
		end
	end

	-- crate spawn
	local crateSpawn = prefab:WaitForChild("CrateSpawn");
	self.CrateSpawnCFrame = crateSpawn:GetPivot();
	crateSpawn:Destroy();

	table.insert(eventPackage.CampInstances, self);

	return self;
end

function EnemyCamp:Activate()
	if self.Active then return end;
	self.Active = true;

	self.State = "Active";

	self:ToggleLandmarkFire(false);
	self.MarkerAtt:SetAttribute("Disabled", false);
	
	local publicData = self.EventInstance.Public;
	publicData[self.Key] = true;

	local newPrefab = self.Prefab:Clone();
	newPrefab.Parent = workspace.Environment.Game;
	self.Garbage:Tag(newPrefab);

	local banditSpawns: {CFrame} = {};
	for _, obj in pairs(self.Prefab:GetChildren()) do
		if obj.Name == "BanditSpawn" then
			table.insert(banditSpawns, obj:GetPivot());
		end
	end

	local function spawnReward()
		if self.RewardId == nil then return end;

		local rewardId = self.RewardId;
		local crateSpawnCFrame = self.CrateSpawnCFrame;

		local rewardsTable = modCrates.GenerateRewards(rewardId);
		
		local crateModel: Model;
		local interactable: InteractableInstance;
		local storage: Storage;

		crateModel, interactable, storage = modCrates.Create(rewardId, crateSpawnCFrame);

		if crateModel then
			crateModel.Parent = self.MarkerAtt;
			self.Garbage:Tag(crateModel);
		end
		
		for b=1, #rewardsTable do
			local item = rewardsTable[b];
			local itemId = item.ItemId;
			local quantity = item.Quantity or 1;

			if type(item.Quantity) == "table" then
				quantity = math.random(item.Quantity.Min, item.Quantity.Max);
			end

			storage:Add(itemId, {Quantity=quantity;});
		end
	end

	for a=1, #banditSpawns do
		local banditNpcClass: NpcClass = shared.modNpcs.spawn2{
			Name = "Bandit";
			CFrame = banditSpawns[a] * CFrame.new(0, 1.5, 0);
		};

		banditNpcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
			if not isDead then return end;

			for a=#self.BanditNpcClasses, 1, -1 do
				if self.BanditNpcClasses[a] == banditNpcClass then
					table.remove(self.BanditNpcClasses, a);
				end
			end

			if #self.BanditNpcClasses <= 0 and self.Active and self.State == "Active" then
				self.MarkerAtt:SetAttribute("Disabled", true);
				self.State = "Complete";

				spawnReward();

				task.delay(120, function()
					self:ToggleLandmarkFire(true);
					self.Garbage:Destruct();
				end)
			end
		end)

		table.insert(self.BanditNpcClasses, banditNpcClass);
		self.Garbage:Tag(banditNpcClass.Character);
	end
	Debugger:Warn(`Camp activated:`, self.Name);
end

function EnemyCamp:Deactivate()
	if not self.Active then return end;
	self.Active = false;

	self:ToggleLandmarkFire(true);
	self.MarkerAtt:SetAttribute("Disabled", true);

	local publicData = self.EventInstance.Public;
	publicData[self.Key] = false;

	self.Garbage:Destruct();
	Debugger:Warn(`Camp deactivated:`, self.Name);
end



function eventPackage.onRequire()
	if RunService:IsClient() then return end;

	local prefabStorage = game.ServerStorage.Prefabs;
	eventPackage.Prefabs = {
		Firebarrel = prefabStorage:WaitForChild("Misc"):WaitForChild("Firebarrel");
	};
	
	shared.modCommandsLibrary.bind{
		["banditcamps"] = {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Bandit camps commands
            
            /banditcamps activateall
            /banditcamps deactivateall
            ]];

			RequiredArgs = 0;
			UsageInfo = "/banditcamps action";
			Function = function(player, args)
				local actionId = args[1];

				if actionId == "activateall" then
					for _, campInstance in pairs(eventPackage.CampInstances) do
						campInstance:Activate();
					end
				elseif actionId == "deactivateall" then
					for _, campInstance in pairs(eventPackage.CampInstances) do
						campInstance:Deactivate();
					end
				end

				return true;
			end;
		};
	};
end

function eventPackage.newInstance(eventInstance: WorldEventInstance)
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local eventMap = eventInstance.TemplateEventMap;

	local globalProperties = eventInstance.WorldEvents.GlobalProperties;

	local scheduler: Scheduler = eventInstance.Scheduler;
	local properties: PropertiesVariable<{}> = eventInstance.Properties;
	local garbageHandler: GarbageHandler = eventInstance.Garbage;
	local publicData = eventInstance.Public;

	local eventCorePart = eventMap:WaitForChild("Core");
	EnemyCamp.EventInstance = eventInstance;
	EnemyCamp.CorePart = eventCorePart;

	local MAX_CAMP_COUNT = 0;
	for _, obj in pairs(eventCorePart:GetChildren()) do
		local campModel = obj;
		campModel.Parent = script;

		MAX_CAMP_COUNT = MAX_CAMP_COUNT +1;
		local campKey = `BanditCamp${MAX_CAMP_COUNT}`;
			
		EnemyCamp.new(campKey, campModel);
	end

	eventMap.Parent = workspace.Environment.Game.Events;

	local function spawnCamps()
		local campQuota = math.min(math.ceil(#game.Players:GetPlayers()/2), MAX_CAMP_COUNT);
		if RunService:IsStudio() then
			campQuota = MAX_CAMP_COUNT;
		end

		local activeCamps = 0;
		for _, campInstance in pairs(eventPackage.CampInstances) do
			if campInstance.Active then
				activeCamps = activeCamps + 1;
			end
		end

		for _=1, MAX_CAMP_COUNT do
			if activeCamps >= campQuota then break end;

			local nonActiveCamps = {};
			for _, campInstance in pairs(eventPackage.CampInstances) do
				if campInstance.Active then continue end;
				table.insert(nonActiveCamps, campInstance);
			end

			if #nonActiveCamps <= 0 then break end;

			local campInstance = nonActiveCamps[math.random(1, #nonActiveCamps)];
			campInstance:Activate();
		end

	end
	spawnCamps();

	globalProperties.OnChanged:Connect(function(k, v)
		if k ~= "StormState" then return end;
		if v == "Active" then
			for _, campInstance in pairs(eventPackage.CampInstances) do
				campInstance:Deactivate();
			end

		elseif v == "Idle" then
			spawnCamps();
			
		end
	end)
end

function eventPackage.RenderMarker(mapMarker: MapMarker, eventPublicData: anydict)
	local radialImage: RadialImage = mapMarker.RadialElement.RadialImage;
	local imageLabel: ImageLabel = radialImage.ImageLabel;
	local markerAtt: Attachment = mapMarker.Target :: Attachment;

	-- local markerLib = eventPackage.MapMarkers[markerAtt.Name];

	radialImage:UpdateLabel(0);
end

return eventPackage;