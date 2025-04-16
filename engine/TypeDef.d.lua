export type anydict = {[any]: any};

-- constant uniontypes
export type GAME_EVENT_KEY =
    | "Profile.OnPlayPoints"
    | "Generic.OnItemPickup"
    ;

export type NOTIFY_TYPE =
    | "Inform"
    | "Positive" 
    | "Negative" 
    | "Reward" 
    | "Message" 
    | "Important"
    ;

export type DAMAGE_TYPE =
    | "Armor"
    | "IgnoreArmor"
    | "ArmorOnly"
    | "Heal"
    ;

--MARK: shared
declare shared: {
    -- @engine globals
    ReviveEngineLoaded: boolean;
    MasterScriptInit: boolean;

    -- @system globals
    IsNan: (number) -> boolean;
    Notify: (player: Player, message: string, notifyTypes: NOTIFY_TYPE) -> nil;

    -- @game globals
    modPlayers: PlayerClasses;
    modProfile: Profiles;
    modCommandsLibrary: CommandsLibrary;
    modStorage: Storages;
    modPlayerEquipment: PlayerEquipment;
    modNpcs: NpcClasses;
    modEventService: EventService;
};

--MARK: Class
export type Class = {
    Script: LuaSourceContainer;
} & anydict;

--MARK: Debugger
export type Debugger = {
    AwaitShared: (string) -> nil;
    Expire: (Instance, number?) -> nil;
    new: (ModuleScript) -> Debugger;

    Require: (self: Debugger, ModuleScript, boolean?) -> any;
    Ray: (self: Debugger, Ray, BasePart?, Vector3?, Vector3?) -> BasePart;
    Point: (self: Debugger, (CFrame | Vector3), Instance) -> Attachment;
    PointPart: (self: Debugger, (CFrame | Vector3)) -> BasePart;

    Stringify: (self: Debugger, ...any) -> string;
    StudioLog: (self: Debugger, ...any) -> nil;
    StudioWarn: (self: Debugger, ...any)  -> nil;
    Warn: (self: Debugger, ...any) -> nil;

    Debounce: (self: Debugger, string, number) -> boolean;
}

--MARK: GarbageHandler
export type GarbageHandler = {
    ClassName: string;
    Trash: {[any]:any};
    new: () -> GarbageHandler;

    Tag: (self:GarbageHandler, item: any) -> nil;
    Untag: (self:GarbageHandler, item: any) -> nil;
    Loop: (self:GarbageHandler, loopFunc: ((index: number, trash: any) -> boolean?) ) -> nil;
    Destruct: (self:GarbageHandler) -> nil;
}

--MARK: EventSignal
export type EventSignal<T> = {
	Name: string?;
	Functions: {(T)->(...any)};
} & {
    new: (name: string?) -> EventSignal<T>;
    Fire: (self: EventSignal<T>, ...any) -> nil;
    Wait: (self: EventSignal<T>, timeOut: number?) -> ...any;
    Connect: (self: EventSignal<T>, func: (T) -> ...any) -> (() -> nil);
    Disconnect: (self: EventSignal<T>, func: any) -> nil;
    Once: (self: EventSignal<T>, func: (T)-> ...any) -> (() -> nil);
    Destroy: (self: EventSignal<T>) -> nil;
    DisconnectAll: (self: EventSignal<T>) -> nil;
};

--MARK: EventPacket
export type EventPacket = {
    Key: string;
    Source: number;

    Cancelled: boolean;
    Completed: boolean;

    Player: Player?;
    Players: {[number]: Player}?;
}

--MARK: EventService
export type EventService = {
    ServerInvoke: (self: EventService, GAME_EVENT_KEY, players: (Player | {Player})?, ...any?) -> EventPacket;
    OnInvoked: (self: EventService, GAME_EVENT_KEY, (event: EventPacket, ...any) -> nil, position: number?) -> (()->nil);
};


--MARK: Profiles
export type Profiles = {
    Get: (self: Profiles, player: Player) -> Profile;
    Find: (self: Profiles, playerName: string) -> Profile;
};

export type Profile = {
    Player: Player;
    UserId: number;

    Garbage: GarbageHandler;

    GameSave: GameSave;
    
    SkillTree: anydict;
} & Profiles;


--MARK: GameSave
export type GameSave = {
    Inventory: Storage;
    Clothing: Storage;
};


--MARK: Storage
export type Storages = {
    GetPrivateStorages: (player: Player) -> {[string]: Storage};
    Get: (id: string, player: Player) -> Storage?;
    FindIdFromStorages: (siid: string, player: Player) -> (StorageItem?, Storage?);
    FindItemIdFromStorages: (itemId: string, player: Player) -> (StorageItem?, Storage?);
    ListItemIdFromStorages: (itemId: string, player: Player, storageIdSearchList: {string}) -> (
        {{Item: StorageItem, Storage: Storage}}, 
        number
    );
    RemoveItemIdFromStorages: (itemId: string, player: Player, amount: number, storageIdSearchList: {string}) -> nil;
};

export type Storage = {
    Id: string;
    Name: string;
    Size: number;
    ViewOnly: boolean;

    Container: {[string]: StorageItem};

    Find: (id: string) -> StorageItem;
};

--MARK: StorageItem
export type StorageItem = {
    -- @properties
    ID: string;
    ItemId: string;
    Player: Player;
    Storage: Storage;
    Library: {[string]: any};
    Values: {[string]: any};
    Quantity: number;
    
    -- @methods
    Sync: (self: StorageItem, keys: {string}?) -> nil;
    GetValues: (self: StorageItem, key: string) -> any;
    SetValues: (self: StorageItem, key: string, value: any?, syncFunc: any?) -> StorageItem;
}


--MARK: PlayerClass
export type PlayerClasses = {
    -- @static
    get: (Player) -> PlayerClass;
    
    -- @signals
    OnPlayerDied: EventSignal<PlayerClass>;
};

export type PlayerClass = CharacterClass & {
    -- @properties
    Name: string;

    IsAlive: boolean;
    IsUnderWater: boolean;
    IsSwimming: boolean;

    MaxOxygen: number;

    CharacterModule: {[any]: any};
    Configurations: ConfigVariable;
    Properties: anydict;

    LastDamageDealt: number;
    LastHealed: number;

    LowestFps: number;
    AverageFps: number;

    IsTeleporting: boolean;
    TeleportPlaceId: number;

    Invisible: boolean;
    CurrentState: Enum.HumanoidStateType;

    -- @methods
    Spawn: (self: PlayerClass) -> nil;
    Kill: (self: PlayerClass, reason: string?) -> nil;
    GetInstance: (self: PlayerClass) -> Player;
    SetProperties: (self: PlayerClass, key: string, value: any) -> nil;
    SyncProperty: (self: PlayerClass, key: string) -> nil;
    GetCFrame: (self: PlayerClass) -> CFrame;
    SetCFrame: (self: PlayerClass, cframe: CFrame) -> CFrame;

    SyncStatus: (self: PlayerClass, statusId: string) -> nil;
    ListStatus: (self: PlayerClass) -> {StatusClass};

    SetHealSource: (self: PlayerClass, srcId: string?, packet: ({[any]: any})?) -> nil;
    SetArmorSource: (self: PlayerClass, srcId: string?, packet: ({[any]: any})?) -> nil;
    RefreshHealRate: (self: PlayerClass) -> nil;

    GetEquippedTools: (self: PlayerClass) -> {ItemId: string};
    UnequipTools: (self: PlayerClass) -> nil;

    SyncIsAlive: (self: PlayerClass) -> nil;
    OnConfigurationsCalculate: (self: PlayerClass) -> nil;
    OnNotIsAlive: (self: PlayerClass, func: (character: Model)-> nil) -> nil;

    OnDeathServer: (self: PlayerClass)->nil;
    OnCharacterAdded: (character: Model)->nil;
    OnPlayerTeleport: ()->nil;
    
    -- @signals
    OnDamageTaken: EventSignal<any>;
    OnHealthChanged: EventSignal<any>;
    OnIsAliveChanged: EventSignal<any>;
    OnCharacterSpawn: EventSignal<any>;
    Died: EventSignal<any>;
};

--MARK: CharacterClass
export type CharacterClass = {
    -- @properties
    ClassName: "PlayerClass" | "NpcClass";

    Name: string;
    Character: Model;
    Humanoid: Humanoid;
    RootPart: BasePart;
    Head: BasePart;
    
    Configurations: ConfigVariable;
    Properties: anydict;

    Garbage: GarbageHandler;

    HealthComp: HealthComp;
    StatusComp: StatusComp;
    WieldComp: WieldComp;

    -- @methods
    GetHealthComp: (self: CharacterClass, bodyPart: BasePart) -> HealthComp?;
    Initialize: () -> nil;
};

--MARK: StatusClass
type StatusPackage = {
    Id: string;
    Icon: string;
    Name: string;
    Description: string;
    Buff: boolean;
    Tags: {string};
};

export type StatusClass = {
    ClassName: string;

    Instance: (self: StatusClass) -> StatusClassInstance;

    OnApply: ((self: StatusClass) -> nil);
    OnExpire: ((self: StatusClass) -> nil);
    OnTick: ((self: StatusClass, tickData: TickData) -> nil);
    OnRelay: ((self: StatusClass) -> nil);
} & StatusPackage;

export type StatusClassInstance = {
    -- @properties
    StatusComp: StatusComp;
    StatusOwner: ComponentOwner;

    Garbage: GarbageHandler;
    
    Visible: boolean;
    Values: anydict;
    IsExpired: boolean;

    Expires: number?;
    ExpiresOnDeath: boolean?;
    Duration: number?;
    
    -- @methods
    Sync: (self: StatusClassInstance)->nil;
} & StatusClass;

--MARK: NpcClasses
export type NpcClasses = {
    -- @static
    ActiveNpcClasses: {NpcClass};
    NpcBaseConstructors: anydict;

    getByModel: (Model) -> NpcClass?;
    getById: (number) -> NpcClass?;
    getByOwner: (player: Player, npcName: string) -> NpcClass?;
    listNpcClasses: (matchFunc: (npcClass: NpcClass) -> boolean) -> {NpcClass};
    listInRange: (origin: Vector3, radius: number, maxRootpart: number?) -> {NpcClass};
    attractNpcs: (model: Model, range: number, func: ((npcClass: NpcClass)-> boolean)? ) -> {Model};

    getNpcPrefab: (npcName: string) -> Model;
    spawn: (
        npcName: string, 
        cframe: CFrame?, 
        preloadCallback: ((prefab: Model, npcClass: NpcClass) -> Model)?, 
        customNpcClassConstructor: any?, 
        customNpcPrefab: (Model)?
    ) -> Model;
    
    -- @signals
    OnNpcSpawn: EventSignal<NpcClass>;
};

--MARK: NpcClass
export type NpcClass = CharacterClass & {
    -- @properties
    Actor: Actor?;
    StatusComp: StatusComp;
    Properties: anydict;
    Owner: Player?;
    NetworkOwners: {Player};
    
    -- @methods
    TeleportHide: (self: NpcClass) -> nil;

    -- @signals
    OnThink: EventSignal<any>;

    -- @dev
    GetImmunity: (self: NpcClass, damageType: string?, damageCategory: string?) -> number; 
    Status: any;
    CustomHealthbar: anydict;
    KnockbackResistant: any;
    BleedResistant: any;
    SpawnTime: number;
    Detectable: boolean;
};

--MARK: Interactables
export type Interactables = {
    new: (ModuleScript, Model?) -> (Interactable, InteractableMeta);
    [any]: any;
}

export type Interactable = {
    CanInteract: boolean;
    Type: string;
    [any]: any;
}

export type InteractableMeta = {
    Label: string,
    [any]: any
}

--MARK: InterfaceClass
export type InterfaceClass = {
    TouchControls: Frame;
    HintWarning: (self: InterfaceClass, label: string) -> nil;
    ToggleWindow: (self: InterfaceClass, windowName: string, visible: boolean) -> nil;
};

--MARK: ToolHandler
export type ToolHandler = {
    -- @static
    loadTypeHandler: (ModuleScript) -> any;
    getTypeHandler: (string) -> any?;
    new: () -> ToolHandler,
    
    -- @properties
    ClassName: string;
    Handlers: {[string]: any};
   
    -- @methods
    Instance: (self: ToolHandler) -> ToolHandlerInstance;
    Destroy: (self: ToolHandler) -> ();

    Init: (toolHandler: ToolHandlerInstance) -> nil;

    ClientEquip: (toolHandler: ToolHandlerInstance) -> nil;
    ClientUnequip: (toolHandler: ToolHandlerInstance) -> nil;

    ActionEvent: (toolHandler: ToolHandlerInstance, packet: {[any]: any}) -> nil;
    InputEvent: (toolHandler: ToolHandlerInstance, inputData: {[any]: any}) -> nil;

    ServerEquip: (toolHandler: ToolHandlerInstance) -> nil;
    ServerUnequip: (toolHandler: ToolHandlerInstance) -> nil;
}

export type ToolHandlerInstance = {
    CharacterClass: CharacterClass;
    WieldComp: WieldComp;

    Binds: {[any]: any};
    Garbage: GarbageHandler;

    StorageItem: StorageItem;
    ToolPackage: {[any]: any};
    ToolAnimator: ToolAnimator;

    Prefabs: {[number]: Model};
    EquipmentClass: EquipmentClass;
} & ToolHandler;

export type ToolAnimator = {
    Play: (
        self: ToolAnimator, 
        animKey: string, 
        param: ({
            FadeTime: number?;
            PlaySpeed: number?;
            PlayLength: number?;
            PlayWeight: number?;
            [any]: any;
        })?
    ) -> AnimationTrack;
    Stop: (self: ToolAnimator,
        animKey: string,
        param: ({
            FadeTime: number?
        })?
    ) -> nil;
    GetPlaying: (self: ToolAnimator, animKey: string) -> AnimationTrack;
    GetKeysPlaying: (self: ToolAnimator, animKeys: {string}) -> {[string]: AnimationTrack};
    LoadToolAnimations: (self: ToolAnimator, animations: {[any]: any}, state: string, prefabs: {Model}) -> nil;
    GetTracks: (self: ToolAnimator, animKey: string) -> {AnimationTrack};
    ConnectMarkerSignal: (self: ToolAnimator, markerKey: string, func: ((animKey: string, track: AnimationTrack, value: any)->nil)) -> nil;
};


--MARK: ConfigVariable
export type ConfigVariable = {
    BaseValues: {[any]: any};
    FinalValues: {[any]: any};
    Modifiers: {ConfigModifier};

    GetKeyPairs: (self: ConfigVariable) -> {[any]: any};
    GetBase: (self: ConfigVariable, key: string) -> any;
    GetFinal: (self: ConfigVariable, key: string) -> any;

    Calculate: (self: ConfigVariable, baseValues: {any}?, modifiers: {any}?, finalValues: {any}?) -> {any};

    GetModifier: (self: ConfigVariable, id: string) -> (number?, ConfigModifier?);
    AddModifier: (self: ConfigVariable, modifier: ConfigModifier, recalculate: boolean?) -> nil;
    RemoveModifier: (self: ConfigVariable, id: string, recalculate: boolean?) -> ConfigModifier?;

    newModifier: (id: string) -> ConfigModifier;

    [string]: any;
};

export type ConfigModifier = {
    Id: string;
    Priority: number;
    Tags: anydict;
    Values: anydict; 

    BaseValues: anydict;
    SetValues: anydict;
    SumValues: anydict;
    ProductValues: anydict;
    MaxValues: anydict;
    MinValues: anydict;
};

--MARK: EquipmentClass
export type EquipmentClass = {
    -- @properties
    Enabled: boolean;

    Class: string;
    Configurations: ConfigVariable;
    Properties: {[any]: any};

    -- @methods
    SetEnabled: (self: EquipmentClass, value: boolean) -> nil;
    Update: (self: EquipmentClass, storageItem: StorageItem?) -> nil;
};


--MARK: CommandsLibrary
export type CommandsLibrary = {
    PermissionLevel: {
        All: number;
        ServerOwner: number;
        DevBranch: number;
        Moderator: number;
        Admin: number;
        GameTester: number;
        DevBranchFree: number;
    };

    HookChatCommand: (self: CommandsLibrary, cmd: string, cmdPacket: {
        Permission: number;
        Description: string;
        RequiredArgs: number?;
        UsageInfo: string?;
        Function: ((speaker: Player, args: {any}) -> boolean)?;
        ClientFunction: ((speaker: Player, args: {any}) -> boolean)?;
    }) -> nil;
};

--MARK: ItemModifier
export type ItemModsLibrary = {
    calculateLayer: (itemModifier: ItemModifier, upgradeKey: string) -> {[any]: any};
};

type ModifierHookNames = "OnBulletHit" | "OnNewDamage" | "OnWeaponRender";
export type ItemModifier = {
    ClassName: string;
    Library: ItemModsLibrary;

    Tags: anydict;
    Hooks: anydict;
    Ready: (self: ItemModifierInstance) -> nil;
    Update: (self: ItemModifierInstance) -> nil;
    SetTickCycle: (self: ItemModifierInstance, value: boolean) -> nil;
   
    Sync: (self: ItemModifier, syncKeys: {string}) -> nil;
    Hook: (self: ItemModifier, functionId: ModifierHookNames, func: (modifier: ItemModifierInstance, ...any)->nil) -> nil;
    
    OnTick: ((self: ItemModifierInstance, tickData: TickData) -> nil)?;
};

export type ItemModifierInstance = {
    Script: ModuleScript;

    Enabled: boolean;
    SetEnabled: (self: ItemModifierInstance, value: boolean) -> nil;
    OnEnabledChanged: EventSignal<boolean>;
    
    Player: Player?;
    ModLibrary: ({any}?);
    EquipmentClass: EquipmentClass?;
    EquipmentStorageItem: StorageItem?;
    ItemModStorageItem: StorageItem?;

} & ItemModifier & ConfigModifier;

--MARK: PlayerEquipment
export type PlayerEquipment = {
    getEquipmentClass: (siid: string, player: Player?) -> EquipmentClass;
    getToolHandler: (storageItem: StorageItem, toolModels: ({Model}?)) -> ToolHandlerInstance;

    getItemModifier: (siid: string, player: Player) -> ItemModifierInstance;
    setItemModifier: (modifierId: string, itemModifier: ItemModifierInstance, player: Player) -> nil;

    getPlayerItemModifiers: (player: Player) -> {ItemModifierInstance};
};

--MARK: Destructible
export type Destructible = {
    -- @properties
    ClassName: string;
    Script: Script;
    Model: Model;

    Class: string;

    HealthComp: HealthComp;
    StatusComp: StatusComp?;
    
    -- @signals
    OnDestroy: EventSignal<any>;
};

--MARK: -- Data Models
-- Data packs that stores values to be passed into functions.
--
--
--
--
--
--MARK: ComponentOwner
export type ComponentOwner = {
    ClassName: string;
    Script: Script?;

    HealthComp: HealthComp?;
    StatusComp: StatusComp?;
    
    Character: Model?;
    Model: Model?;
} & anydict;

--MARK: DamageData
export type DamageData = {
    -- @static
    new: (damageData: DamageData & anydict) -> DamageData;

    -- @properties
    Damage: number;
    DamageType: DAMAGE_TYPE;

    DamageBy: CharacterClass?; 
    DamageTo: CharacterClass?;
    TargetPart: BasePart?;
    TargetModel: Model?;
    DamageCate: string?;
    ToolHandler: ToolHandlerInstance?;
    StorageItem: StorageItem?;

    DamageForce: Vector3?;
    DamagePosition: Vector3?;

    -- @methods
    Clone: (self: DamageData) -> DamageData;
};

export type TickData = {
    Delta: number;
    ms100: boolean;
    ms500: boolean;
    ms1000: boolean;
    s5: boolean;
    s10: boolean;
};

export type StatusCompApplyData = {
    Expires: number?;
    Duration: number?;

    Values: ({
        [any]: any;

        ImmunityReduction: number?;
    })?;
}

export type OnBulletHitPacket = {
    OriginPoint: Vector3;
    
    TargetPart: BasePart;
    TargetPoint: Vector3;
    TargetNormal: Vector3;
    TargetMaterial: Enum.Material;
    TargetIndex: number;
    TargetDistance: number;

    TargetModel: Model;
    IsHeadshot: boolean;
}

export type ArcPoint = {
    -- @properties
    Hit: BasePart?;
    Origin: Vector3;
    Velocity: Vector3;
    Direction: Vector3;
    Point: Vector3;
    Displacement: number;
    Normal: Vector3?;
    Material: Enum.Material?;
    TotalDelta: number;
    
    -- @methods
    Recast: (self: ArcPoint) -> nil;
}

--MARK: -- Components
-- Class composition components, with minimal coupling to external code.
--
--
--
--
--
--MARK: HealthComp
export type HealthComp = {
    -- @static
    base: HealthComp;
    getByModel: (model: Model) -> HealthComp?;

    -- @properties
    CompOwner: ComponentOwner;
    IsDead: boolean;
    
    CurHealth: number;
    MaxHealth: number;
    KillHealth: number;
    
    CurArmor: number;
    MaxArmor: number;

    FirstDamageTaken: number?;
    LastDamagedBy: CharacterClass?;
    
    LastDamageTaken: number;
    LastArmorDamagedTaken: number;
    
    CanBeHurtBy: ({ -- Checks based on CharacterClass properties
        Humanoid: ({string})?;
        ClassName: ({string})?;
        Name: ({string})?;
        Teams: ({string})?; -- Checks for existing TeamComp;
    })?;
    
    -- @methods
    GetModel: (self: HealthComp) -> Model?;
    CanTakeDamageFrom: (self: HealthComp, characterClass: CharacterClass) -> boolean;    
    TakeDamage: (self: HealthComp, DamageData: DamageData) -> nil;
    
    SetArmor: (self: HealthComp, value: number) -> nil;
    SetHealth: (self: HealthComp, value: number) -> nil;
   
    -- @signals
    OnHealthChanged: EventSignal<DamageData?>;
    OnArmorChanged: EventSignal<any>;
}

--MARK: StatusComp
export type StatusComp = { 
    -- @properties
    CompOwner: ComponentOwner;
    List: {[string]: StatusClassInstance};

    -- @methods
    Apply: (self: StatusComp, key: string, value: StatusCompApplyData) -> StatusClassInstance;
    GetOrDefault: (self: StatusComp, key: string, value: anydict?) -> StatusClassInstance;

    Process: (self: StatusComp, loopFunc: ((key: string, statusClass: StatusClassInstance, processData: anydict)->nil)?, fireOnProcess: boolean?) -> nil;
    
    -- @signals
    OnProcess: EventSignal<any>;
};

--MARK: WieldComp
export type WieldComp = {
    -- @properties
    CompOwner: ComponentOwner;
    ToolHandler: ToolHandlerInstance?;
    
    -- @methods
    Equip: (self: WieldComp) -> nil;
    Unequip: (self: WieldComp) -> nil;
}