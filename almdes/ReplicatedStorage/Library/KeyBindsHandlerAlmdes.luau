
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);

function modKeyBindsHandler.onRequire()
    modKeyBindsHandler.DefaultKeybind.KeyRotate = {Key=Enum.KeyCode.R};
end

return modKeyBindsHandler;