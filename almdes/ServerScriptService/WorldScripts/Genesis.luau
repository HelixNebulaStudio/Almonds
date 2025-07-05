local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDeployableTool = shared.require(game.ReplicatedStorage.Library.ToolHandler.DeployableTool);
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibrary);

if RunService:IsServer() then
    modWorldLoot = shared.require(game.ServerScriptService.ServerLibrary.WorldLoot);
end


local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassAlmdes).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileAlmdes = shared.modProfile:WaitForProfile(player) :: ProfileAlmdes;
            if profile == nil then return end;

            Debugger:Warn(`{player.Name} has joined the world!`);

        end, 999);

        modWorldLoot.init();

        for _, interactConfig in pairs(CollectionService:GetTagged("Interactable")) do
            local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
            if interactable.Name ~= "DeployableSocket" then continue end;
            if interactConfig:GetAttribute("SkipPrebuild") then continue end;
            
            local placeCf = interactable.Values.AttachmentPoint.WorldCFrame;
            local itemId;

            if interactable.Variant == "WindowFrame" then
                local windowItemIds = {
                    "woodwindowbarricade";
                };
                itemId = windowItemIds[math.random(1, #windowItemIds)];

            elseif interactable.Variant == "WallFrame" then
                local windowItemIds = {
                    "wooddoubledoors";
                    "cellwall";
                };
                itemId = windowItemIds[math.random(1, #windowItemIds)];

            elseif interactable.Variant == "Doorway" then
                local windowItemIds = {
                    "wooddoor";
                };
                itemId = windowItemIds[math.random(1, #windowItemIds)];

            end

            if itemId == nil then continue end;

            local toolPackage = modToolsLibrary.get(itemId);
            modDeployableTool.spawnDeployable(itemId, nil, placeCf, {
                Configurations = toolPackage.Configurations;
                Interactable = interactable;
            });

        end;
    end

	shared.modCommandsLibrary.bind{
		["deletetutorialobjects"]={
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = `Deletes all tutorial objects in this world.`;

			RequiredArgs = 0;
			UsageInfo = "/deletetutorialobjects";
			Function = function(player, args)

                local list = CollectionService:GetTagged("TutorialItem")
                for _, obj in pairs(list) do
                    obj:Destroy();
                end

				return true;
			end;
		};
	};

end


return WorldCore;