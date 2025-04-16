export type DAMAGE_TYPE_ALMDES = DAMAGE_TYPE
    | "Starvation"
    | "Dehydration"
    ;

--MARK: EquipmentClass
export type EquipmentClassAlmdes = EquipmentClass & { 
    AddModifier: (self: EquipmentClass, modifierId: string, config: {
        BaseValues: anydict?;
        SetValues: anydict?;
        SumValues: anydict?;
        ProductValues: anydict?;
        MaxValues: anydict?;
        MinValues: anydict?;
    }) -> nil;
    
    ApplyModifiers: (self: EquipmentClass, storageItem: StorageItem) -> nil;
    ProcessModifiers: (self: EquipmentClass, processType: string, ...any) -> nil;
    GetClassAsModifier: (self: EquipmentClass, siid: string, configModifier: ConfigModifier?) -> ConfigModifier;

    [any]: any;
};
