local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

function modRemotesManager.onRequire()
    if RunService:IsServer() then
        modRemotesManager:NewFunctionRemote("TestFuncRemote", 1);

        --== Menu
        modRemotesManager:NewFunctionRemote("MainMenuRemote", 1);
        modRemotesManager:NewFunctionRemote("LiveServersRemote", 1);

        --== Systmes;
        modRemotesManager:NewFunctionRemote("PortableStorage", 0.1).Secure = true;
        modRemotesManager:NewFunctionRemote("BaseSystem", 0.1).Secure = true;

        --== Structures;
        modRemotesManager:NewEventRemote("StructureAttachmentBuild");
        modRemotesManager:NewEventRemote("StructurePlaceablePlace");
        modRemotesManager:NewEventRemote("StructureReinforce");
        modRemotesManager:NewEventRemote("SeedPlant");
        modRemotesManager:NewEventRemote("AttachableLock");

        --== Factory Handlers
        modRemotesManager:NewFunctionRemote("ItemFactory", 0.1);
    end
end

return modRemotesManager;