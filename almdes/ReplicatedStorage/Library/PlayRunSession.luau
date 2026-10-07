local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PlayRunSession = {};
PlayRunSession.__index = PlayRunSession;

local SESSION_STATS = {
    StorageOpened = 0;
    NpcKills = 0;
    PlayerKills = 0;
    ContractsCompleted = 0;
    MissionsCompleted = 0;
};

function PlayRunSession.new(player: Player)
    local meta = {
        Player = player;
    };
    meta.__index = meta;

    local self = {
        Stats = {};
    };

    setmetatable(meta, PlayRunSession);
    setmetatable(self, meta);

    self:Wipe();

    return self;
end

function PlayRunSession:Load(data)
    for k, v in pairs(data) do
        self[k] = v;
    end

    return self;
end

function PlayRunSession:Wipe()
    self.Status = "Active";
    self.StartTime = workspace:GetServerTimeNow();

    self.JobId = nil; -- server id;

    self.EndTime = nil;
    self.EndReason = nil;

    table.clear(self.Stats);
    for k, v in pairs(SESSION_STATS) do
        self.Stats[k] = v;
    end
end

function PlayRunSession:EndRun(runStatus: string, reason: string)
    if self.Status ~= "Active" then return end;

    local playerClass: PlayerClass = shared.modPlayers.get(self.Player);

    Debugger:Warn(`EndRun {runStatus} Reason: {reason}`);
    playerClass.Properties.PlayRunStatus = runStatus;

    self.EndTime = workspace:GetServerTimeNow();

    self.Status = runStatus;
    self.EndReason = reason;

    local profile: ProfileAlmdes = shared.modProfile:Get(self.Player) :: ProfileAlmdes;
    local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

    profile:Save();
end

function PlayRunSession:GetSummary()
    local r = {
        StartTime = self.StartTime;
        EndTime = self.EndTime;
        Status = self.Status;
        EndReason = self.EndReason;

        Stats = table.clone(self.Stats);
    };
    return r;
end

function PlayRunSession:AddStat(key: string, value)
    if typeof(value) == "number" then
        self.Stats[key] = (self.Stats[key] or 0) + value;
    end
end

function PlayRunSession:Destroy()
end

return PlayRunSession;