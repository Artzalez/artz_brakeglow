ABG = {}

ABG.Clamp = function (num, min, max)
    if num < min then
		num = min
	elseif num > max then
		num = max
	end

	return num
end

ABG.Lerp = function (from, to, t)
    return from + (to - from) * ABG.Clamp(t, 0, 1)
end

ABG.Map = function (x, in_min, in_max, out_min, out_max)
    return (x- in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

ABG.ClearPtfx = function ()
    for i=1, 4, 1 do
        RemoveParticleFx(ptfxIds[i], 0)
        ptfxIds[i] = 0
    end
end

ABG.Update = function ()
    lastSpeed = currentSpeed
    currentSpeed = GetEntitySpeedVector(_vehicle, true)
    Acceleration = (currentSpeed - lastSpeed) / GetFrameTime()
end

ABG.DrawDisks = function ()
    if GetEntityBoneIndexByName(_vehicle, "wheel_lf") == -1 then return end
    if GetEntityBoneIndexByName(_vehicle, "wheel_rf") == -1 then return end
    if GetEntityBoneIndexByName(_vehicle, "wheel_lr") == -1 then return end
    if GetEntityBoneIndexByName(_vehicle, "wheel_rr") == -1 then return end

    local boneIdxs = {}

    boneIdxs[1] = GetEntityBoneIndexByName(_vehicle, "wheel_lf")
    boneIdxs[2] = GetEntityBoneIndexByName(_vehicle, "wheel_rf")
    boneIdxs[3] = GetEntityBoneIndexByName(_vehicle, "wheel_lr")
    boneIdxs[4] = GetEntityBoneIndexByName(_vehicle, "wheel_rr")

    local weightShiftFactor = {
        [1] = -Acceleration.y,
        [2] = -Acceleration.y,
        [3] = Acceleration.y,
        [4] = Acceleration.y
    }

    local wheelRotSpeeds = {
        [1] = GetVehicleWheelRotationSpeed(_vehicle, 0),
        [2] = GetVehicleWheelRotationSpeed(_vehicle, 1),
        [3] = GetVehicleWheelRotationSpeed(_vehicle, 2),
        [4] = GetVehicleWheelRotationSpeed(_vehicle, 3)
    }

    local brakePressures = {
        [1] = GetVehicleWheelBrakePressure(_vehicle, 0),
        [2] = GetVehicleWheelBrakePressure(_vehicle, 1),
        [3] = GetVehicleWheelBrakePressure(_vehicle, 2),
        [4] = GetVehicleWheelBrakePressure(_vehicle, 3)
    }

    for i = 1, 4, 1 do

        if not brakeTemps[i] then brakeTemps[i] = 0.0 end
        local targetVal = 0.0
        if brakePressures[i] > 0.0 then
            targetVal = (brakePressures[i] + weightShiftFactor[i] * Config.CarModels[_model].AccelerationMult) * math.abs(wheelRotSpeeds[i])
        end
        targetVal = ABG.Clamp(targetVal, 0.0, 1.0)
        
        if targetVal > 0.0 then
            local heatRate = Config.CarModels[_model].HeatRate
            heatRate = ABG.Clamp(heatRate, 0.0, 1.0)
            brakeTemps[i] = ABG.Lerp(brakeTemps[i], targetVal, 1.0 - math.pow(1.0 - heatRate, GetFrameTime()))
        else
            local coolRateMoving = Config.CarModels[_model].CoolRateMoving
            coolRateMoving = ABG.Clamp(coolRateMoving, 0.0, 1.0)
            local coolRateStopped = Config.CarModels[_model].CoolRateStopped
            coolRateStopped = ABG.Clamp(coolRateStopped, 0.0, 1.0)
            local coolRateMod = ABG.Map(math.abs(wheelRotSpeeds[i]), 0.0, 60.0, 1.0 - coolRateStopped, 1.0 - coolRateMoving)
            coolRateMod = ABG.Clamp(coolRateMod, 1.0 - coolRateMoving, 1.0 - coolRateStopped)

            brakeTemps[i] = ABG.Lerp(brakeTemps[i], 0.0, 1.0 - math.pow(coolRateMod, GetFrameTime()))
        end
 
        brakeTemps[i] = ABG.Clamp(brakeTemps[i], 0.0, 1.0)

        if not brakeTemps[i] then brakeTemps[i] = 0.0 end

        if Config.Debug then
            brakeTemps[i] = 1.0
        end

        ABG.DrawDiscPtfx(i, boneIdxs)

    end

end

ABG.DrawDiscPtfx = function (i, boneIdxs)
    if brakeTemps[i] > 0.066 then
        if ptfxIds[i] == 0 then
            local offset = Config.CarModels[_model].Offset
            if i >= 2 and Config.CarModels[_model].OffsetRearOverride then
                offset = Config.CarModels[_model].OffsetRear
            end

            local ptfxSize = Config.CarModels[_model].PtfxSize
            if i >= 2 and Config.CarModels[_model].PtfxRearSizeOverride then
                ptfxSize = Config.CarModels[_model].PtfxRearSize
            end

            ABG.RequestEffectLibrary("veh_impexp_rocket")

            UseParticleFxAssetNextCall("veh_impexp_rocket")
            ptfxIds[i] = StartParticleFxLoopedOnEntityBone("veh_rocket_boost", _vehicle, offset.x, offset.y, offset.z, Config.CarModels[_model].Rotation.x, Config.CarModels[_model].Rotation.y, Config.CarModels[_model].Rotation.z, boneIdxs[i], ptfxSize, false, false, false)
        end
        SetParticleFxLoopedEvolution(ptfxIds[i], "boost", 0.0, 0)
        SetParticleFxLoopedEvolution(ptfxIds[i], "charge", 1.0, 0)
        SetParticleFxLoopedAlpha(ptfxIds[i], 100.0)
    end

    if brakeTemps[i] < 0.050 then
        if ptfxIds[i] ~= 0 then
            RemoveParticleFx(ptfxIds[i])
            ptfxIds[i] = 0
        end
    end

    SetParticleFxLoopedAlpha(ptfxIds[i], brakeTemps[i] * 2.0)
end

ABG.RequestEffectLibrary = function (assetName)
    RequestNamedPtfxAsset(assetName)
    if not HasNamedPtfxAssetLoaded(assetName) then
        Citizen.CreateThread(function()
            while not HasNamedPtfxAssetLoaded(assetName) do
                Wait(0)
            end
        end)
    end
end