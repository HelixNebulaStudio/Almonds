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

        Stats = {
            StorageOpened = 0;
            NpcKills = math.random(1, 999);
            PlayerKills = math.random(1, 999);
            ContractsCompleted = math.random(1, 999);
            MissionsCompleted = math.random(1, 999);
        };
    };

    setmetatable(meta, PlayRunSession);
    setmetatable(self, meta);

    self.PlayerClass.Properties.PlayRunStatus = "Active";

    return self;
end

function PlayRunSession:EndRun(runStatus: string, reason: string)
    if self.Status ~= "Active" then return end;
    Debugger:Warn(`EndRun {runStatus} Reason: {reason}`);
    self.PlayerClass.Properties.PlayRunStatus = runStatus;

    self.EndTime = workspace:GetServerTimeNow();

    self.Status = runStatus;
    self.EndReason = reason;

    local player: Player = self.PlayerClass:GetInstance();
    local profile: ProfileAlmdes = shared.modProfile:Get(player);
    local gameSave: GameSaveAlmdes = profile:GetActiveSave() :: GameSaveAlmdes;

    gameSave.LoadoutSaves:SaveActiveLoadout(runStatus == "Success");

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