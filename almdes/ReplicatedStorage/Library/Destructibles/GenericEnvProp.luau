local destructiblePackage = {
    Name = "GenericEnvProp";
};

function destructiblePackage.BindNew(destructible: DestructibleInstance)
    local healthComp: HealthComp = destructible.HealthComp;
    healthComp:SetMaxHealth(100);
    healthComp:SetHealth(100);
end

return destructiblePackage;