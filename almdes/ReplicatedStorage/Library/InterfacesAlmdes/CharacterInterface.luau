local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local FRAME_TWEENINFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);

local interfacePackage = {
    Type = "Character";
    LoadOrder = 1;
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)

    local charFrame = script:WaitForChild("CharacterFrame"):Clone();
    charFrame.Parent = interface.ScreenGui;

    local lPanel = charFrame:WaitForChild("LPanel");
    local rPanel = charFrame:WaitForChild("RPanel");
    local mPanel = charFrame:WaitForChild("MPanel");

    local buttons = rPanel:WaitForChild("Buttons");
    local closeButton = buttons:WaitForChild("closeButton");

    local charWindow: InterfaceWindow = interface:NewWindow("CharacterWindow", charFrame);
    charWindow.IgnoreHideAll = true;
	charWindow.UseTween = false;
	charWindow.UseMenuBlur = true;
    charWindow.DisableInteractables = true;
    charWindow.DisableHotKeysHint = true;
    charWindow.BoolStringWhenActive = {String="!CharacterHud"; Priority=5;};
    charWindow:SetClosePosition(charFrame.Position, charFrame.Position);

    local binds = charWindow.Binds;
    binds.LPanel = lPanel;
    binds.RPanel = rPanel;
    binds.MPanel = mPanel;

    --MARK: OnToggle
    charWindow.OnToggle:Connect(function(visible)
        if visible then
            charFrame.Visible = true;
            charWindow._visible = true;
            charFrame.BackgroundTransparency = 1;
            TweenService:Create(charFrame, FRAME_TWEENINFO, {
                BackgroundTransparency = 0.75;
            }):Play();

        else
            local tween: Tween = TweenService:Create(charFrame, FRAME_TWEENINFO, {
                BackgroundTransparency = 1;
            });
            tween.Completed:Once(function(status)
                if status ~= Enum.PlaybackState.Completed then return end;
            end)
            charWindow._visible = false;
            charFrame.Visible = false;
            interface:HideAll();
            tween:Play();

        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
        charWindow:Close();
    end)

    interface.Properties.OnChanged:Connect(function(k, v)
        if k == "CharacterInterfaceVisible" then
            if v then
                charWindow:Open();
            else
                charWindow:Close();
            end
        end
    end)
end

return interfacePackage;

