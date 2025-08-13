local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modFlareParticle = shared.require(game.ReplicatedStorage.Particles.FlareParticle);
local modExfilSystem = shared.require(game.ReplicatedStorage.Library.ExfilSystem);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    --MARK: ExfilFlares
    local ExfilFlares = {
		Name = "ExfilFlares";
        Type = "Button";

        IndicatorPresist = false;
        InteractableRange = 16;
    };

    function ExfilFlares.new(interactable: InteractableInstance, npcName: string)
        local config: Configuration = interactable.Config;

        interactable.CanInteract = true;
        interactable.Label = `Signal Helicopter Exfil`;
    end

    -- When interacting with interactable.
    function ExfilFlares.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" or RunService:IsClient() then return end;
        
        local part: BasePart = interactable.Part;
        local config: Configuration = interactable.Config;


        if not interactable.CanInteract then return end;
        interactable.CanInteract = false;
        interactable.Label = `Exfil Signaled...`;
        interactable:Sync();

        if RunService:IsStudio() then
            task.delay(1, function()
                interactable.CanInteract = true;
                interactable.Label = `Signal Helicopter Exfil`;
                interactable:Sync();
            end)
        end

        task.spawn(function()
            local flareParticle = interactable.Values.FlareParticle;
            if flareParticle then
                flareParticle:Destroy();
            end
            flareParticle = modFlareParticle.new(part.Position);
            flareParticle:Launch();

            interactable.Values.FlareParticle = flareParticle;
        end)

        if interactable.Values.ExfilCalled ~= true then
            interactable.Values.ExfilCalled = true;
            interactable:Sync();
            modExfilSystem:SpawnExfilHelicopter(part.Position, false);
        end
    end
    
    super.registerPackage(ExfilFlares);

    --MARK: ExfilSubmarines
end

return interactablePackage;

