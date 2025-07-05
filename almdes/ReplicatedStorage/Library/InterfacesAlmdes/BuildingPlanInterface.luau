local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)

    local frame = script:WaitForChild("BuildingPlanFrame"):Clone();
    frame.Parent = interface.ScreenGui;

    local window: InterfaceWindow = interface:NewWindow("BuildingPlan", frame);
    window.DisableInteractables = true;
    window.CloseWithInteract = true;

    local binds = window.Binds;

    local windowFrame = frame:WaitForChild("BuildOptions");
    local buttons = windowFrame:WaitForChild("Buttons");
    
    buttons:WaitForChild("closeButton").MouseButton1Click:Connect(function()
        interface:PlayButtonClick();
        window:Close();
    end)

    for _, obj in pairs(windowFrame:WaitForChild("ContentList"):GetChildren()) do
        if not obj:IsA("ImageButton") then continue end;

        obj.MouseButton1Click:Connect(function()
            binds.ActiveBuildId = obj.Name;
            interface:PlayButtonClick();
            window:Close();
        end)
    end

    --MARK: OnToggle
    window.OnToggle:Connect(function(isVisible, toolHandler)
        if isVisible then
            binds.ToolHandler = toolHandler;
            window:Update();
        else
            binds.ToolHandler = nil;
            frame.Visible = false;
        end
    end)

    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        
    end)

end

return interfacePackage;

