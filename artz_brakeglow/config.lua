Config = {}

Config.Debug = false -- if u active this the brakes get the max temp (used for add new cars)

-- Config 4 Models
Config.CarModels = {
    [GetHashKey("bifta")] = {
        PtfxSize = 1.375,
        PtfxRearSize = 1.666,
        PtfxRearSizeOverride = true,
        Offset = vector3(0.06, 0.0, 0.0),
        OffsetRear = vector3(0.07, 0.0, 0.0),
        OffsetRearOverride = true,
        Rotation = vector3(0.00, 0.0, 90.0),
        HeatRate = 0.25,
        CoolRateMoving = 0.2,
        CoolRateStopped = 0.05,
        AccelerationMult = 0.050,
        Visible = {
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
        },
    }
}