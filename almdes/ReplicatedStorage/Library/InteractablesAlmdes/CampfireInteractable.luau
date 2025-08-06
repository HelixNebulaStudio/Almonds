local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local Campfire = {
		Name = "Campfire";
        Type = "Button";
    };

    function Campfire.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;

        interactable.CanInteract = true;
        interactable.Label = `Use`;
    end

    function Campfire.BindDestroy(interactable: InteractableInstance)
        if RunService:IsClient() then return end;

        local interactPart = interactable.Part;
        Debugger:StudioLog(`BindDestroy interactPart {interactPart}`, interactable);
        if interactPart == nil then return end;

        local naturalLightAtt: Attachment = interactPart:FindFirstChild("_naturalLight") :: Attachment;
        game.Debris:AddItem(naturalLightAtt, 0);
        modAudio.Play("FireBallBurst", interactPart.Position);
    end

    function Campfire.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config: Configuration = interactable.Config;
        if config.Parent == nil then return end;

        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;


        if info.NpcClass then
            local npcClass: NpcClass = info.NpcClass;
            return;
        end

        local player: Player? = info.Player;
        if player == nil then 
            return; 
        end;

        if RunService:IsServer() then
            local naturalLightAtt: Attachment = config.Parent:WaitForChild("PrimaryPart"):WaitForChild("_naturalLight") :: Attachment;
            interactable.Values.IsActive = not interactable.Values.IsActive;

            config:SetAttribute("IsCampfireActive", interactable.Values.IsActive);
            if interactable.Values.IsActive then
                interactable.Values.SndFire = modAudio.Play("Fire", naturalLightAtt);
                interactable.Values.SndFire.Looped = true;
            else
                modAudio.Play("FireBallBurst", naturalLightAtt);
                interactable.Values.SndFire:Destroy();
            end

            for _, obj in pairs(naturalLightAtt:GetChildren()) do
                if obj:IsA("Fire") then
                    obj.Enabled = interactable.Values.IsActive;
                elseif obj:IsA("PointLight") then
                    obj.Enabled = interactable.Values.IsActive;
                end
            end
        end
    end
    
    -- When interactable pops up on screen.
    function Campfire.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        
        local clientData = info.ClientData;
        if clientData == nil then return end;

    end


    super.registerPackage(Campfire);

end

return interactablePackage;

