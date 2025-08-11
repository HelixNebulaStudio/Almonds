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
    WorkbenchSeed: number;
    ItemProcessor: anydict;
    RecipesUnlocked: anydict;
};

-- MARK: WorldEvents
export type WorldEvents = {
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