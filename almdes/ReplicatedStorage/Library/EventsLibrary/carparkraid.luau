local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
local modRegion = shared.require(game.ReplicatedStorage.Library.Region);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local eventPackage = {
	Id = "carparkraid";
	Name = "Car Park Raid";
	
	Type = "Raid";
	CycleTimer = 120;
	CooldownDuration = 60;
	
	MapMarkers = {
		["CrateSpawn"] = {
			Icon="rbxassetid://7304930076";
		};
	};
	
	RewardsId = "carparkraid";
};
--==

function eventPackage.newInstance(eventInstance: WorldEventInstance)
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local voidClips = game.ServerStorage.Prefabs.Events:WaitForChild("carparkraidVoid");
	voidClips.Parent = script;

	local templateEventMap = eventInstance.TemplateEventMap;

	local scheduler: Scheduler = eventInstance.Scheduler;
	local properties: PropertiesVariable<{}> = eventInstance.Properties;
	local garbageHandler: GarbageHandler = eventInstance.Garbage;
	local publicData = eventInstance.Public;

	local function OnStateUpdate(state, oldState)
		Debugger:Warn(`{eventPackage.Id} State Update: {state}`);

		if properties.ActiveJob then
			scheduler:Unschedule(properties.ActiveJob);
			properties.ActiveJob = nil;
		end

		publicData.State = state;
		if state == "Cooldown" then
			local cooldownDuration = eventPackage.CooldownDuration;
			if oldState == nil then
				cooldownDuration = 1;
			end

			properties.CooldownEndTick = tick()+cooldownDuration;
			
			local function setIdle()
				local players = modRegion:GetPlayersWithin(voidClips);
				if #players > 0 then
					Debugger:Warn(`{#players} Players in vicinity.`);
					properties.CooldownEndTick = tick()+2;
					properties.ActiveJob = scheduler:ScheduleFunction(setIdle, properties.CooldownEndTick);
					return;
				end

				properties.State = "Idle";
			end
			properties.ActiveJob = scheduler:ScheduleFunction(setIdle, properties.CooldownEndTick);

			publicData.RadialDuration = cooldownDuration;
			publicData.RadialTick = workspace:GetServerTimeNow() + cooldownDuration;

		elseif state == "Idle" then
			voidClips.Parent = workspace.Clips;

			garbageHandler:Destruct();

			local newMap = templateEventMap:Clone();
			newMap.Parent = workspace.Environment.Game.Events;
			properties.ActiveMap = newMap;
			garbageHandler:Tag(newMap);

			for _, obj in pairs(newMap:GetDescendants()) do
				if not obj:IsA("Configuration") or obj.Name ~= "Destructible" then continue end;
				
				local destructibleConfig: Configuration = obj;
				local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
				destructible.HealthComp:SetMaxHealth(200);
				destructible.HealthComp:SetHealth(200);
				destructible.OnDestroy:Connect(function()
					if properties.State ~= "Idle" then return end;
					properties.State = "Active"; 
				end)
			end

		elseif state == "Active" then
			voidClips.Parent = script;
			
			local activeMap = properties.ActiveMap;

			properties.BanditNpcClasses = {};
			local banditSpawns = activeMap:WaitForChild("Spawns");
			for _, spawnAtt in pairs(banditSpawns:GetChildren()) do
				if not spawnAtt:IsA("Attachment") then continue end;

				local banditNpcClass: NpcClass = shared.modNpcs.spawn2{
					Name = "Bandit";
					CFrame = spawnAtt.WorldCFrame;
				};

				banditNpcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
					if not isDead then return end;

					for a=#properties.BanditNpcClasses, 1, -1 do
						if properties.BanditNpcClasses[a] == banditNpcClass then
							table.remove(properties.BanditNpcClasses, a);
						end
					end

					if #properties.BanditNpcClasses <= 0 then
						properties.State = "Complete";
					end
				end)

				table.insert(properties.BanditNpcClasses, banditNpcClass);
				garbageHandler:Tag(banditNpcClass.Character);
			end

		elseif state == "Complete" then

			local activeMap = properties.ActiveMap;
			local corePart = activeMap:WaitForChild("Core");
			local crateSpawnAtt: Attachment = corePart:WaitForChild("CrateSpawn");

			local rewardsId = eventPackage.RewardsId;

			local rewardsTable = modCrates.GenerateRewards(rewardsId);
			
			local crateModel: Model;
			local interactable: InteractableInstance;
			local storage: Storage;

			crateModel, interactable, storage = modCrates.create(rewardsId, crateSpawnAtt.WorldCFrame);

			if crateModel then
				crateModel.Parent = activeMap;
				garbageHandler:Tag(crateModel);
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

			task.delay(60, function()
				properties.State = "Cooldown";
			end)
		end
	end

	properties.OnChanged:Connect(function(k, v, ov)
		if k == "State" then
			OnStateUpdate(v, ov);
		end
	end)
	properties.State = "Cooldown";

end

function eventPackage.RenderMarker(mapMarker: MapMarker, eventPublicData: anydict)
	local radialImage: RadialImage = mapMarker.RadialElement.RadialImage;
	local imageLabel: ImageLabel = radialImage.ImageLabel;
	
	local serverTime = workspace:GetServerTimeNow();

	local duration = eventPublicData.RadialDuration;
	local activeTime = eventPublicData.RadialTick or serverTime;

	local alpha = 0;
	if eventPublicData.State == "Cooldown" then
		alpha = 1-math.clamp((activeTime-serverTime)/duration, 0, 1);
		imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255);

	elseif eventPublicData.State == "Idle" or eventPublicData.State == "Active" then
		alpha = 1;
		imageLabel.ImageColor3 = modClientGuis.ActiveInterface.Colors.Branch;

	else
		alpha = 0;
		imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255);
	end
				
	radialImage:UpdateLabel(alpha);
end

return eventPackage;