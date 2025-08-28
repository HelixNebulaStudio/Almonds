local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modRegion = shared.require(game.ReplicatedStorage.Library.Region);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDeployableTool = shared.require(game.ReplicatedStorage.Library.ToolHandler.DeployableTool);
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibrary);

local eventPackage = {
	Id = "barrication";
	Name = "Barrication";

	SetupBarricades = function() end;
};

--==

function eventPackage.onRequire()
	if RunService:IsClient() then return end;
	
	shared.modCommandsLibrary.bind{
		["barrication"] = {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Barrication commands
            
            /barrication reset
            ]];

			RequiredArgs = 0;
			UsageInfo = "/barrication action";
			Function = function(player, args)
				local actionId = args[1];

				if actionId == "reset" then
					eventPackage.SetupBarricades();
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


	local function setupBarricades()
		for _, interactConfig in pairs(CollectionService:GetTagged("Interactable")) do
			if interactConfig:GetAttribute("_Name") ~= "DeployableSocket" then continue end;
            if interactConfig:GetAttribute("SkipPrebuild") then continue end;

            local socketInteractable: InteractableInstance = modInteractables.getOrNew(interactConfig);
            if socketInteractable.Name ~= "DeployableSocket" then continue end;
			if socketInteractable.Values.ActiveDeployable.Value then continue end;
            
			local attachPoint: Attachment = socketInteractable.Values.AttachmentPoint;
            local placeCf = attachPoint.WorldCFrame;
            local itemId;
            local blockadeName;

			local playersInRange = shared.modPlayers.getPlayersInRange(attachPoint.WorldPosition, 128);
			if #playersInRange > 0 then continue end;

            if socketInteractable.Variant == "WindowFrame" then
                local windowItemIds = {
                    "woodwindowbarricade";
                };
                itemId = windowItemIds[math.random(1, #windowItemIds)];

            elseif socketInteractable.Variant == "WallFrame" then
                local windowItemIds = {
                    "wooddoubledoors";
                    "cellwall";
                };
                itemId = windowItemIds[math.random(1, #windowItemIds)];

                if itemId:match("door") then
                    blockadeName = "BlockadeDouble";
                end

            elseif socketInteractable.Variant == "Doorway" then
                local windowItemIds = {
                    "wooddoor";
                };
                itemId = windowItemIds[math.random(1, #windowItemIds)];
                
                if itemId:match("door") then
                    blockadeName = "BlockadeSingle";
                end
            end

            if itemId == nil then continue end;

            local toolPackage = modToolsLibrary.get(itemId);
            modDeployableTool.spawnDeployable(itemId, nil, placeCf, {
                Configurations = toolPackage.Configurations;
                SocketInteractable = socketInteractable;
                AddBlockade = blockadeName;
            });
        end;
		
	end


	globalProperties.OnChanged:Connect(function(k, v)
		if k ~= "StormState" then return end;
		if v == "Idle" then
			setupBarricades();
		end
	end)
	setupBarricades();

	eventPackage.SetupBarricades = setupBarricades;
end


return eventPackage;