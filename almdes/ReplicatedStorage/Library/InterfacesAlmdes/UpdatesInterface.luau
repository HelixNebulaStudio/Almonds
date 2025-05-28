local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
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

    local frame = script:WaitForChild("UpdateLogFrame"):Clone();
    frame.Parent = interface.ScreenGui;
    
    local titleLabel = frame:WaitForChild("Content"):WaitForChild("TitleFrame"):WaitForChild("Title");
    local textLabel = frame:WaitForChild("Content"):WaitForChild("notes"):WaitForChild("textLabel");

    local versionStr = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
	titleLabel.Text = "InDev "..versionStr.." Update";
	
	local window: InterfaceWindow = interface:NewWindow("UpdateWindow", frame);
	window:SetClosePosition(UDim2.new(1.5, -20, 0.9, -20));
	modKeyBindsHandler:SetDefaultKey("KeyWindowUpdateWindow", Enum.KeyCode.F1);

	window.OnToggle:Connect(function(visible)
		if visible then
            window:Update();
			interface:HideAll{[window.Name]=true;};
		else
			remoteGeneralUIRemote:InvokeServer("closeupdatelog");
		end
	end)
    
    window.OnUpdate:Connect(function() 
        local updateLogText = remoteApiRequest:InvokeServer("updatelog") or "";

        local success, message = pcall(function()
            textLabel.Text = modMarkupFormatter.Format(updateLogText);
        end)
        if not success then
            Debugger:Warn("Failed to fetch update log:", message);
        end
    end)
    
end

return interfacePackage;

