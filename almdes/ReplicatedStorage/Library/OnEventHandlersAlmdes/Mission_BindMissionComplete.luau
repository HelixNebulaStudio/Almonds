local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

return function(event: EventPacket, ...)
    local player = event.Player;
    if player == nil then return end;

    local mission: Mission = ...;
    if mission == nil then return end;
end;
