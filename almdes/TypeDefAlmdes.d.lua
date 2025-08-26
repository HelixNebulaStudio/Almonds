export type DAMAGE_TYPE_ALMDES =
    | "Starvation"
    | "Dehydration"
    ;

--MARK: ProfileAlmdes
export type ProfileAlmdes = Profile & {

};

--MARK: PlayerClassAlmdes
export type PlayerClassAlmdes = PlayerClass & {
};

-- MARK: GameSaveAlmdes
export type GameSaveAlmdes = GameSave & {
    -- @properties
    WorkbenchSeed: number;
    ItemProcessor: anydict;
    LoadoutSaves: LoadoutSaves;

    -- @methods
};

-- MARK: LoadoutSaves
export type LoadoutSaves = {
    -- @properties
    Player: Player;
    GameSave: GameSaveAlmdes;

    ActiveLoadout: number;
    Loadouts: {[number]: anydict};

    -- @methods
    SaveActiveLoadout: (LoadoutSaves) -> nil;
    LoadActiveLoadout: (LoadoutSaves) -> nil;
    Shrink: (LoadoutSaves) -> anydict;
};

-- MARK: WorldEvents
export type WorldEvents = {
    -- @properties
    GlobalProperties: PropertiesVariable<{
        Seed: number;
        StormCounter: number;
    }>;
    Instances: {[string]: WorldEventInstance};
};

-- MARK: WorldEventInstance
export type WorldEventInstance = {
   Id: string;
   Name: string;
   Type: string;

   Scheduler: Scheduler;
   WorldEvents: WorldEvents;

   Garbage: GarbageHandler;
   
   Properties: PropertiesVariable<anydict>;
   TemplateEventMap: Folder;
   Public: anydict;
};

-- MARK: MapMarker
export type MapMarker = {
    Id: string;

    RadialElement: {
        Id: string;
        ImageButton: ImageButton;
        RadialImage: RadialImage;
    };
    Pointer: Frame;
    Target: Vector3 | Model | BasePart | Attachment;

    ToolTip: string?;
    LegendId: string?;

    EventLib: anydict?;
    MarkerName: string?;
};


-- MARK: Vehicle
export type Vehicle = {
    -- @properties
    Model: Model;
    Package: anydict;
    Config: Configuration;

    Garbage: GarbageHandler;
    Properties: PropertiesVariable<anydict>;
    Components: anydict;
    Seats: {[string]: (Seat | VehicleSeat)};

    Destructible: DestructibleInstance;
    HealthComp: HealthComp;
    Animator: Animator;
    AnimationTracks: anydict;

    -- @methods
    SetCFrame: (Vehicle, cf: CFrame)->nil;
    ToggleVelocityDamp: (Vehicle, v: boolean)->nil;
    Destroy: (Vehicle)->nil;
    PlaySound: (Vehicle, sndName: string, params: anydict?)->nil;

    GetComponent: (Vehicle, componentName: string)->any;

    -- @binds
    BindStepped: (Vehicle, timeTotal: number, timeDelta: number)->nil;
};