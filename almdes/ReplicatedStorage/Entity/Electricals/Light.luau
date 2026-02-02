local electricalPackage = {};

function electricalPackage.init(super) -- Server/Client
    local Light = {
		Name = "Light";
        Type = "Light";
    };

    function Light.BindToggle(electrical: Electrical, v: boolean)
        local model: Model = electrical.Config.Parent :: Model;

        for _, obj in pairs(model:GetDescendants()) do
            if obj:IsA("PointLight") then
                obj.Enabled = electrical.IsOn;
                
            elseif obj.Name == "_lightSource" then
                obj.Material = electrical.IsOn and Enum.Material.Neon or Enum.Material.Plastic;
                
            end
        end
    end

    super.registerPackage(Light);
end

return electricalPackage;