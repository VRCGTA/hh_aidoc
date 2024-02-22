local QBCore = exports['qb-core']:GetCoreObject()

local Active = false
local doctorVeh = nil
local doctorPed = nil
local canCall = true

 


RegisterCommand("help", function(source, args, raw)
	if (QBCore.Functions.GetPlayerData().metadata["isdead"]) or (QBCore.Functions.GetPlayerData().metadata["inlaststand"]) and canCall then
		QBCore.Functions.TriggerCallback('hhfw:docOnline', function(EMSOnline, hasEnoughMoney)
			if EMSOnline <= Config.Doctor and hasEnoughMoney and canCall then
				SpawnVehicle(GetEntityCoords(PlayerPedId()))
				Notify("Medic is arriving")
			else
				if EMSOnline > Config.Doctor then
					Notify("There is too many medics online", "error")
				elseif not hasEnoughMoney then
					Notify("Not Enough Money", "error")
				else
					Notify("Wait Paramadic is on its Way", "primary")
				end	
			end
		end)
	else
		Notify("This can only be used when dead", "error")
	end
end)



function SpawnVehicle(x, y, z)  
	canCall = false
	local vehhash = GetHashKey("ambulance")                                                     
	local loc = GetEntityCoords(PlayerPedId())
	RequestModel(vehhash)
	while not HasModelLoaded(vehhash) do
		Wait(1)
	end
	RequestModel('s_m_m_doctor_01')
	while not HasModelLoaded('s_m_m_doctor_01') do
		Wait(1)
	end
	local spawnRadius = 40                                                    
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(loc.x + math.random(-spawnRadius, spawnRadius), loc.y + math.random(-spawnRadius, spawnRadius), loc.z, 0, 3, 0)

	if not DoesEntityExist(vehhash) then
        mechVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)                        
        ClearAreaOfVehicles(GetEntityCoords(mechVeh), 5000, false, false, false, false, false);  
        SetVehicleOnGroundProperly(mechVeh)
		SetVehicleNumberPlateText(mechVeh, "HHFW")
		SetEntityAsMissionEntity(mechVeh, true, true)
		SetVehicleEngineOn(mechVeh, true, true, false)
        
        mechPed = CreatePedInsideVehicle(mechVeh, 26, GetHashKey('s_m_m_doctor_01'), -1, true, false)              	
        
        mechBlip = AddBlipForEntity(mechVeh)                                                        	
        SetBlipFlashes(mechBlip, true)  
        SetBlipColour(mechBlip, 5)


		PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
		Wait(2000)
		TaskVehicleDriveToCoord(mechPed, mechVeh, loc.x, loc.y, loc.z, 20.0, 0, GetEntityModel(mechVeh), 524863, 2.0)
		doctorVeh = mechVeh
		doctorPed = mechPed
		Active = true
    end
end

Citizen.CreateThread(function()
    while true do
      Citizen.Wait(200)
        if Active then
			if not (QBCore.Functions.GetPlayerData().metadata["isdead"]) and not(QBCore.Functions.GetPlayerData().metadata["inlaststand"]) then
				Active = false
				ClearPedTasksImmediately(doctorPed)
				RemovePedElegantly(doctorPed)
				DeleteEntity(doctorVeh)
				Wait(5000)
				DeleteEntity(doctorPed)
				canCall = true
			else
				local loc = GetEntityCoords(GetPlayerPed(-1))
				local lc = GetEntityCoords(doctorVeh)
				local ld = GetEntityCoords(doctorPed)
				local distVeh = Vdist(loc.x, loc.y, loc.z, lc.x, lc.y, lc.z)
				local distPed = Vdist(loc.x, loc.y, loc.z, ld.x, ld.y, ld.z)
				if distVeh <= 10 then
					if Active then
						TaskGoToCoordAnyMeans(doctorPed, loc.x, loc.y, loc.z, 1.0, 0, 0, 786603, 0xbf800000)
					end
					if distPed <= 1 then 
						Active = false
						ClearPedTasksImmediately(doctorPed)
						DoctorNPC()
					end
				end
			end
        end
    end
end)


function DoctorNPC()
	RequestAnimDict("mini@cpr@char_a@cpr_str")
	while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
		Citizen.Wait(1000)
	end

	TaskPlayAnim(doctorPed, "mini@cpr@char_a@cpr_str","cpr_pumpchest",1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
	QBCore.Functions.Progressbar("revive_doc", "The doctor is giving you medical aid", Config.ReviveTime, false, false, {
		disableMovement = false,
		disableCarMovement = false,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		ClearPedTasks(doctorPed)
		Citizen.Wait(500)
		TriggerEvent("hospital:client:Revive")
		StopScreenEffect('DeathFailOut')
		TriggerServerEvent('hhfw:charge')
		Notify("Your treatment is done, you were charged: "..Config.Price, "success")
		RemovePedElegantly(doctorPed)
		DeleteEntity(doctorVeh)
		Wait(5000)
		DeleteEntity(doctorPed)
		canCall = true
	end)
end


function Notify(msg, state)
    QBCore.Functions.Notify(msg, state)
end
