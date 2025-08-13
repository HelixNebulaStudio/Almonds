local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PlayRunSession = {};
PlayRunSession.__index = PlayRunSession;

function PlayRunSession.new(playerClass: PlayerClass)
    local meta = {
        PlayerClass = playerClass;
    };
    meta.__index = meta;

    local self = {
        Status = "Active";
        StartTime = workspace:GetServerTimeNow();
        EndTime = nil;
        EndReason = nil;
    };

    setmetatable(meta, PlayRunSession);
    setmetatable(self, meta);

    self.PlayerClass.Properties.PlayRunStatus = "Active";

    return self;
end

function PlayRunSession:EndRun(status: string, reason: string)
    if self.Status ~= "Active" then return end;
    
    self.PlayerClass.Properties.PlayRunStatus = status;

    self.EndTime = workspace:GetServerTimeNow();

    self.Status = status;
    self.EndReason = reason;
end

function PlayRunSession:GetSummary()
    local r = {
        StartTime = self.StartTime;
        EndTime = self.EndTime;
        Status = self.Status;
        EndReason = self.EndReason;

        Stats = {
            NpcKills = math.random(1, 999);
            PlayerKills = math.random(1, 999);
            ContractsCompleted = math.random(1, 999);
            MissionsCompleted = math.random(1, 999);
        };
    };
    return r;
end

function PlayRunSession:Destroy()
end

return PlayRunSession;