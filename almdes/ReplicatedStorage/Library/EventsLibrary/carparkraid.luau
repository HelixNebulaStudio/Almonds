local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRegion = shared.require(game.ReplicatedStorage.Library.Region);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local eventPackage = {
	Id = "carparkraid";
	Name = "Car Park Raid";
	
	Type = "Raid";
	CycleTimer = 120;
	
	Icon = "rbxassetid://7304930076";
	
	RewardsId = "carparkraid";
	LootMarkOnMap = true;
};
--==

function eventPackage.newInstance(worldEventHandler: WorldEventInstance)
	local modNpcs = shared.require(game.ServerScriptService.ServerLibrary.Entity.Npcs);
	Debugger:Warn(`newInstance {eventPackage.Id}`);

	local voidClips = game.ServerStorage.Prefabs.Events:WaitForChild("carparkraidVoid");
	voidClips.Parent = script;

	local templateEventMap = worldEventHandler.TemplateEventMap;

	local scheduler: Scheduler = worldEventHandler.Scheduler;
	local properties: PropertiesVariable<{}> = worldEventHandler.Properties;

	local function OnStateUpdate(state, oldState)
		Debugger:Warn(`{eventPackage.Id} State Update: {state}`);

		if properties.ActiveJob then
			scheduler:Unschedule(properties.ActiveJob);
			properties.ActiveJob = nil;
		end

		if state == "Cooldown" then
			local cooldownDuration = 30;
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

		elseif state == "Idle" then
			voidClips.Parent = workspace.Clips;

			local newMap = templateEventMap:Clone();
			newMap.Parent = workspace.Environment.Game.Events;
			properties.ActiveMap = newMap;

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
			properties.ActiveTick = tick();

			local activeMap = properties.ActiveMap;

			properties.BanditNpcClasses = {};
			local banditSpawns = activeMap:WaitForChild("Spawns");
			for _, spawnAtt in pairs(banditSpawns:GetChildren()) do
				if not spawnAtt:IsA("Attachment") then continue end;

				local banditNpcClass: NpcClass = modNpcs.spawn2{
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
			end

		elseif state == "Complete" then

		end
	end

	properties.OnChanged:Connect(function(k, v, ov)
		if k == "State" then
			OnStateUpdate(v, ov);
		end
	end)
	properties.State = "Cooldown";

end


return eventPackage;