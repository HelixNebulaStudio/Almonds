local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");

local camera = workspace.CurrentCamera;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerAlmdes);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interfacePackage = {
    Name = script.Name;
    Type = "Player";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteMainMenuRemote = modRemotesManager:Get("MainMenuRemote");

    local uiElement: InterfaceElement = interface:GetOrDefaultElement("DeathScreenElement");
    uiElement.BoolStringWhenActive = {String="!CharacterHud"; Priority=6;};

    local frame = script:WaitForChild("AlmdesDeath"):Clone();
    frame.Parent = uiElement.Frame;
    
    local buttonsFrame = frame:WaitForChild("Buttons"):WaitForChild("Content");
    
    local helpButton = buttonsFrame:WaitForChild("HelpButton");
    local returnButton = buttonsFrame:WaitForChild("ReturnButton");

    returnButton.MouseButton1Click:Connect(function()
        interface:PlayButtonClick();

        local timeLeft = math.round(workspace:GetAttribute("StormCycleTick") - workspace:GetServerTimeNow());
        modClientGuis.promptDialogBox({
            Title=`Are you sure you want to return to menu?`;
            Desc=`You can not respawn for <b>{timeLeft} seconds</b>, you should call for help instead.`;
            Buttons={
                {
                    Text="Return";
                    Style="Confirm";
                    OnPrimaryClick=function(dialogWindow)
                        interface:ToggleGameBlinds(false, 3);

                        local rPacket = remoteMainMenuRemote:InvokeServer("returnmenu");
                        if rPacket.Success then
                            modClientGuis.reload();
                        end
                    end;
                };
                {
                    Text="Cancel";
                    Style="Cancel";
                };
            }
        });
    end)

    helpButton.MouseButton1Click:Connect(function()
        interface:PlayButtonClick();
        Debugger:Warn("Help button clicked");
    end)
end

return interfacePackage;

