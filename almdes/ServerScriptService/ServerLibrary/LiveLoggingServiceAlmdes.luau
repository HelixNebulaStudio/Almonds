
local modLiveLoggingService = shared.require(game.ServerScriptService.ServerLibrary.LiveLoggingService);

function modLiveLoggingService.onRequire()
    modLiveLoggingService.registerSecret("D", "MMLogs", "MMLogs");
end

return modLiveLoggingService;