local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modPropertiesVariable = shared.require(game.ReplicatedStorage.Library.PropertiesVariable);

local Electricals = {};
Electricals.ClassName = "Electrical";

Electricals.InstanceList = {};
Electricals.Db = {};

function Electricals.onRequire()
    for _, module in pairs(script:GetChildren()) do
        local package = shared.require(module);
        if package.init then
            package.init(Electricals);
        end
    end
    script.ChildAdded:Connect(function(module)
        local package = shared.require(module);
        if package.init then
            package.init(Electricals);
        end
    end)


    if RunService:IsServer() then
        CollectionService:GetInstanceAddedSignal("Electrical"):Connect(function(config)
            Electricals.getOrNew(config);
        end)
        for _, config in pairs(CollectionService:GetTagged("Electrical")) do
            Electricals.getOrNew(config);
        end
    end
end

function Electricals:__index(k)
    local v = rawget(self, k);
    if v ~= nil then return v end;

    local package = rawget(self, "Package");
    if package[k] ~= nil then
        return package[k];
    end

    return Electricals[k];
end

function Electricals.new(config)
    if not workspace:IsAncestorOf(config) or not config:HasTag("Electrical") or config:GetAttribute("_Name") == nil then
        Debugger:Warn("Invalid electrical config:", config:GetFullName());
        return;
    end

    local name = config:GetAttribute("_Name");

    local package = Electricals.Db[name];
    if package == nil then
        Debugger:Warn("Missing electrical package:", name);
        return;
    end

    local new = {
        -- @properties
        Name = name;
        Config = config;
        Package = package;

        IsOn = false;

        -- @signals
        OnPowerChanged = shared.EventSignal.new("OnPowerChanged");
    };

    setmetatable(new, Electricals);
    return new;
end

function Electricals.getOrNew(config)
    local existing = Electricals.InstanceList[config];
    if existing then return existing end;

    local new = Electricals.new(config);
    Electricals.InstanceList[config] = new;
    return new;
end

function Electricals.registerPackage(package)
    local name = package.Name;
    Electricals.Db[name] = package;
end

function Electricals:Destroy()
    setmetatable(self, nil);
    self.OnPowerChanged:Destroy();
end

function Electricals:ToggleOn(v: boolean)
    self.IsOn = v;

    if self.BindToggle then
        local n = self:BindToggle(v);
        if n ~= nil then
            self.IsOn = n;
        end
    end

    self.OnPowerChanged:Fire(v);
end

return Electricals;