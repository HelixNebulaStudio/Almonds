local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassAlmdes).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileAlmdes = shared.modProfile:WaitForProfile(player) :: ProfileAlmdes;
            if profile == nil then return end;

            Debugger:Warn(`{player.Name} has joined the world!`);

        end, 999);
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