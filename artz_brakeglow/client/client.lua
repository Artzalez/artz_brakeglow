--Vars
brakeTemps = {
	[1] = 0.0,
	[2] = 0.0,
	[3] = 0.0,
	[4] = 0.0
}

ptfxIds = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0
}

_vehicle = 0
_model = 0
currentSpeed = 0
lastSpeed = 0
Acceleration = 0
-- end vars

Citizen.CreateThread(function ()
    while true do
        if IsPedInAnyVehicle(PlayerPedId(), false) and GetPedInVehicleSeat(PlayerPedId(), -1) then
            _vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
			if Config.Debug then
				print("v" .. _vehicle)
				print("m" .. GetEntityModel(_vehicle))
				print("mc" .. GetHashKey("bifta"))
			end
            if Config.CarModels[GetEntityModel(_vehicle)] then
                _model = GetEntityModel(_vehicle)
            else
                _model = 0
            end
        end
        if DoesEntityExist(_vehicle) and _model ~= 0 then
            ABG.Update()
            ABG.DrawDisks()
        end
        Citizen.Wait(50)
    end
end)