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

    function ExfilFlares.Activate(interactable: InteractableInstance, final: boolean?)
        local part: BasePart = interactable.Part;
        local markerAtt: Attachment = interactable.Values.Attachment;

        if not interactable.CanInteract then return end;
        interactable.CanInteract = false;
        interactable.Label = `Exfil Signaled...`;
        interactable:Sync();

        local flareParticle = interactable.Values.FlareParticle;
        if flareParticle then
            flareParticle:Destroy();
        end
        flareParticle = modFlareParticle.new(markerAtt.WorldPosition);
        flareParticle:Launch();

        interactable.Values.FlareParticle = flareParticle;

        task.delay(45, function()
            flareParticle:Destroy();
            game.Debris:AddItem(interactable.Values.InteractModel, 0);
        end)
        
        if interactable.Values.ExfilCalled ~= true then
            markerAtt:SetAttribute("ExfilCalled", true);
            interactable:Sync();
            modExfilSystem:SpawnExfilHelicopter(markerAtt, final);
        end
    end

    -- When interacting with interactable.
    function ExfilFlares.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" or RunService:IsClient() then return end;
        
        ExfilFlares.Activate(interactable);
    end
    
    super.registerPackage(ExfilFlares);

    --MARK: ExfilSubmarines
end

return interactablePackage;

