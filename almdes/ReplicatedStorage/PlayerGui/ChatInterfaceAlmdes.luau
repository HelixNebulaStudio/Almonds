local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local ChatInterfaceAlmdes = {};
--==

function ChatInterfaceAlmdes.onRequire(chatInterfaceConfig: anydict, chatInterfaceScreenGui: ScreenGui)
    
    local chatFrame: Frame = chatInterfaceScreenGui:WaitForChild("ChatFrame") :: Frame;

    local function refresh()
        local isFocused = chatInterfaceScreenGui:GetAttribute("InFocus");
        for _, guiObj in pairs(chatFrame:GetChildren()) do
            guiObj.AutomaticSize = isFocused and Enum.AutomaticSize.None or Enum.AutomaticSize.Y;
        end

        local chatFrameYOffset = 100;

        local activeInterface: InterfaceInstance = modClientGuis.ActiveInterface;
        if activeInterface then
            local mapHudBuffer = activeInterface.Properties.HudMapSize;
            if mapHudBuffer then
                chatFrameYOffset += (mapHudBuffer.Y +20);
            end
        end
        

        if isFocused then
            chatFrame.AutomaticSize = Enum.AutomaticSize.None;
            chatFrame.AnchorPoint = Vector2.zero;
            chatFrame.Position = UDim2.new(0, 0, 0, chatFrameYOffset);
            chatFrame.Size = UDim2.new(0, 500, 0, 300);

        else
            chatFrame.AutomaticSize = Enum.AutomaticSize.Y;
            chatFrame.AnchorPoint = Vector2.zero;
            chatFrame.Position = UDim2.new(0, 0, 0, chatFrameYOffset);
            chatFrame.Size = UDim2.new(0, 500, 0, 0);

        end
    end

    refresh();
    chatInterfaceScreenGui:GetAttributeChangedSignal("InFocus"):Connect(refresh);

end

return ChatInterfaceAlmdes;