local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PlayRunSession = {};
PlayRunSession.__index = PlayRunSession;

function PlayRunSession.new()
    local self = {
        StartTime = workspace:GetServerTimeNow();
        EndTime = nil;
    };

    setmetatable(self, PlayRunSession);
    return self;
end

function PlayRunSession:GetSummary()
    local r = {
        StartTime = self.StartTime;
        EndTime = self.EndTime;
    };
    return r;
end

function PlayRunSession:Destroy()
end

return PlayRunSession;