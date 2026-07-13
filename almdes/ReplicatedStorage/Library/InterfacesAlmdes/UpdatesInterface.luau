local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modMarkupFormatter = shared.require(game.ReplicatedStorage.Library.MarkupFormatter);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteGeneralUIRemote = modRemotesManager:Get("GeneralUIRemote");
    local remoteApiRequest = modRemotesManager:Get("ApiRequest");

    local frameButton = script:WaitForChild("UpdateLogFrame"):Clone();
    frameButton.Parent = interface.ScreenGui;
    
    local titleLabel = frameButton:WaitForChild("Content"):WaitForChild("TitleFrame"):WaitForChild("Title");
    local textLabel = frameButton:WaitForChild("Content"):WaitForChild("notes"):WaitForChild("textLabel");

    local versionStr = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
	titleLabel.Text = "InDev "..versionStr.." Update";
	
	local window: InterfaceWindow = interface:NewWindow("UpdateWindow", frameButton);
	modKeyBindsHandler:SetDefaultKey("KeyWindowUpdateWindow", Enum.KeyCode.F1);

    if modConfigurations.SafehomeMode then
        local insetHeight = interface.Properties.TopbarInset.Height+35;
        window:SetClosePosition(UDim2.new(1.5, -20, 0, insetHeight), UDim2.new(1, -20, 0, insetHeight));
    else
        window:SetClosePosition(UDim2.new(1.5, -20, 0, -20));
    end

    local expanded = false;
	window.OnToggle:Connect(function(visible)
		if visible then
            expanded = false;
            window:Update();
			interface:HideAll{[window.Name]=true;};
		else
			remoteGeneralUIRemote:InvokeServer("closeupdatelog");
		end
	end)
    
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);
    window.OnUpdate:Connect(function()
        if expanded then
            TweenService:Create(frameButton, tweenInfo, {
                Size = UDim2.new(1, -40, 1, -(frameButton.Position.Y.Offset+10));
            }):Play();
        else
            TweenService:Create(frameButton, tweenInfo, {
                Size = UDim2.new(0.3, 0, 0.6, 0);
            }):Play();
        end

        local updateLogText = remoteApiRequest:InvokeServer("updatelog") or "";

        local success, message = pcall(function()
            textLabel.Text = modMarkupFormatter.Format(updateLogText);
        end)
        if not success then
            Debugger:Warn("Failed to fetch update log:", message);
        end
    end)

    frameButton.MouseButton1Click:Connect(function()
        expanded = not expanded;
        window:Update();

    end)
end

return interfacePackage;

