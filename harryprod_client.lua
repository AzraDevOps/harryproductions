--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--
--*--------------------------------- HARRY_PROD BY HARRY "AZRADEVOPS" ------------------------------------------*--
--*																												*--
--*																												*--
--*-- FR --																										*--
--*   v 1.0.0 of 11/12/2021 (pour les différentes étapes du dev, lisez le fichier README_DEV.md)				*--
--*   > fork du script heli_cam de 																				*--
--*   																											*--
--*   	Objectif : Avoir des caméras montées sur des véhicules qui peuvent permettent de filmer					*--
--*																												*--
--*   Tous commentaires ou aides sont les bienvenus, allez sur  https://github.com/AzraDevOps/Harryprod		  	*--
--*																												*--
--*-- Fait --																									*--
--*		1°) Commande "fixcamera" pour monter les props sur les véhicules : 										*--
--*		- XLS, SULTAN, VALKYRIE3, SuperVolito2																	*--
--*																												*--
--*		2°) Touche "E" pour passer en vue Caméra, que l'on soit conducteur ou passager							*--
--*																												*--
--*-- En cours --																								*--
--*																												*--
--*-- RAF --																									*--
--*		Supprimer effet "grain" sur la vision de la caméra pour avoir la même qualité qu'avec le téléphone		*--
--*		Lmiter usage aux passagers afin que le conducteur/pilote ne puissent pas utiliser la caméra (+RP)		*--
--*																												*--
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--
--*																												*--
--*-- EN --																										*--
--*   v 1.0.0 of 11/12/2021 (for the different stages of the dev, read the README_DEV.md file) 					*--
--*   > fork of the heli_cam script from																		*--
--*   																											*--
--*     Objective: To have cameras mounted on vehicles that can film											*--
--*   																											*--
--*   Any comments or help are welcome, go to https://github.com/AzraDevOps/Harryprod 							*--
--*   																											*--
--*-- Done --																									*--
--*    1°) "fixcamera" command to mount props on vehicles: 														*--
--*    - XLS, SULTAN, VALKYRIE3, SuperVolito2 																	*--
--*   																											*--
--*    2°) "E" key to switch to Camera view, whether you are driver or passenger								*--
--*   																											*--
--*-- WIP --																									*--
--*   																											*--
--*-- Todo -- 																									*--
--*    Delete "sand" effect on the vision of the camera, search having same quality like using the phone 		*--
--*    Limit use to passengers, the driver/pilot can't use the camera (most RP) 								*--
--*																												*--
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- ZONE COMMUNE --------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ESX                             = nil
local PlayerData                = {}
local open 						= false
Triggers = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)

        TriggerEvent("esx:getSharedObject", function(xPlayer)
            ESX = xPlayer
        end)
    end

    while not ESX.IsPlayerLoaded() do 
        Citizen.Wait(500)
    end

    if ESX.IsPlayerLoaded() then
        PlayerData = ESX.GetPlayerData()
    end
end)


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- DECLARATIONS VBLs ---------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local fov_max = 80.0
local fov_min = 10.0 						-- max zoom level (smaller fov is more zoom)
local zoomspeed = 2.0 						-- camera zoom speed
local speed_lr = 3.0 						-- speed by which the camera pans left-right 
local speed_ud = 3.0 						-- speed by which the camera pans up-down
local toggle_helicam = 51 					-- control id of the button by which to toggle the helicam mode. Default: INPUT_CONTEXT (E)
local toggle_vision = 25 					-- control id to toggle vision mode. Default: INPUT_AIM (Right mouse btn)
local toggle_rappel = 154 					-- control id to rappel out of the heli. Default: INPUT_DUCK (X)
local toggle_spotlightOr2ndCam = 183 		-- control id to toggle the front spotlight Default: INPUT_PhoneCameraGrid (G)
local toggle_lock_on = 22 					-- control id to lock onto a vehicle with the camera. Default is INPUT_SPRINT (spacebar)

local helicam = false
local carcamAR = false
local polmav_hash = GetHashKey("polmav")
local fov = (fov_max+fov_min)*0.5
local vision_state = 0 						-- 0 is normal, 1 is nightmode, 2 is thermal vision

local timingscript = 18000					-- Init of the script timer (optim resource)

local job1ok = 'casino'						-- Job authorize to use the camera (in slot 1 if u could have 2 jobs)
local job2ok = 'casino'						-- Job authorize to use the camera (in slot 1 if u could have 2 jobs)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- THREADS -------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	while true do
		
		Citizen.Wait(timingscript)
        --Citizen.Wait(20)

		--if IsPlayerInPolmav() then
		local lPed = PlayerPedId()
		local xPlayer = ESX.GetPlayerData()
		
		--print(timingscript)
		
		if PlayerData.job ~= nil and (PlayerData.job.name == job1ok or PlayerData.job2.name == job2ok) then
		
			timingscript = 1000
			
			local vehicle = GetVehiclePedIsIn(lPed)
			local polmav_hashveh = GetEntityModel(vehicle)
			local playerHeading = GetEntityHeading(PersoPed)	
			
			-- Test pour savoir si véhicule autorisé à utiliser la caméra // Check if autorized vehicles for using camera
			if 	polmav_hashveh == 1203490606 or 	-- XLS
				polmav_hashveh == 970598228 or 		-- SULTAN
				polmav_hashveh == -1671539132 or 	-- SUPERVOLITO2
				polmav_hashveh == 1780283536 or 	-- VALKYRIE3
				polmav_hashveh == 353883353 then	-- HELI POLICE "Henri"

				timingscript = 10
				
				local lPed = GetPlayerPed(-1)
				local heli = GetVehiclePedIsIn(lPed)
				
				if IsHeliHighEnough(heli) then

					if IsControlJustPressed(0, toggle_helicam) then -- Toggle Helicam
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						helicam = true
					end
					
					local helicoOuPas = GetVehicleClass(heli)
					
					if IsControlJustPressed(0, toggle_rappel) and helicoOuPas == 15 then -- Descente en rappel uniquement si hélico // Abseiling possible only if users in choppers
						if GetPedInVehicleSeat(heli, 1) == lPed or GetPedInVehicleSeat(heli, 2) == lPed then
							PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
							TaskRappelFromHeli(GetPlayerPed(-1), 1)
						else
							SetNotificationTextEntry( "STRING" )
							AddTextComponentString("~r~Siege incompatible pour une descente en rappel")
							DrawNotification(false, false )
							PlaySoundFrontend(-1, "5_Second_Timer", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", false) 
						end
					end

					if IsControlJustPressed(0, toggle_spotlightOr2ndCam) then 
						if helicoOuPas == 15 then 											-- si hélico allume le spot // if Choppers can switch on the directional light
							spotlight_state = not spotlight_state
							TriggerServerEvent("heli:spotlight", spotlight_state)
							PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						elseif helicoOuPas ~= 15 then 										-- Si pas classe 15 hélico donc Classe 6 voitures // if not choppers so it's a car ^^
							helicam = true
							carcamAR = true						
						end
					end

				end
				
			end 
			-- Fin test véhicle autorisé ou non // End of checking autorized vehicle
			
			if helicam then
				SetTimecycleModifier("heliGunCam")
				SetTimecycleModifierStrength(0.3)
				local scaleform = RequestScaleformMovie("HELI_CAM")
				while not HasScaleformMovieLoaded(scaleform) do
					Citizen.Wait(0)
				end
				local lPed = GetPlayerPed(-1)
				local heli = GetVehiclePedIsIn(lPed)
				local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
				
				-- Positionnement de la vision caméra en fonction du véhicules utilisé // Fix camera vision depending of the vehicle used
				if polmav_hashveh == 1203490606 then							-- XLS Perche caméra // Dolly inside XLS, with high vision
					AttachCamToEntity(cam, heli, 0.0,3.15,4.99, true)			
				elseif polmav_hashveh == 970598228 and carcamAR == false then 	-- Sultan Caméra AVANT // Front camera vision on Sultan
					AttachCamToEntity(cam, heli, 0.5,1.95,0.80, true)
				elseif polmav_hashveh == 970598228 and carcamAR == true then 	-- Sultan Caméra ARRIERE // Back camera vision on Sultan
					AttachCamToEntity(cam, heli, 0.4,-1.95,1.30, true)
				elseif polmav_hashveh == -1671539132 then						-- SuperVolito2
					AttachCamToEntity(cam, heli, 0.0,3.90,-1.15, true)				
				elseif polmav_hashveh == 1780283536 then 						-- Valkyrie3
					AttachCamToEntity(cam, heli, 0.0,5.15,-0.90, true)				
				end
							
				-- Si Camera AVANT ou ARRIERE Sur Sultan // Depending FRONT or BACK on Sultan, fix the vision of camera
				if carcamAR == false then 
					SetCamRot(cam, 0.0,0.0,GetEntityHeading(heli))
				else
					SetCamRot(cam, 0.0,0.0,GetEntityHeading(heli) + 180)				
				end
				
				SetCamFov(cam, fov)
				RenderScriptCams(true, false, 0, 1, 0)
				PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
				PushScaleformMovieFunctionParameterInt(0) -- 0 for nothing, 1 for LSPD logo
				PopScaleformMovieFunctionVoid()
				local locked_on_vehicle = nil
				
				while helicam and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == heli) and IsHeliHighEnough(heli) do
					
					if IsControlJustPressed(0, toggle_helicam) then 								-- Active ou non la caméra // Toggle Helicam
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						helicam = false
					end
					
					if IsControlJustPressed(0, toggle_vision) and polmav_hashveh == 353883353 then	-- Si HELI POLICE "Henri" alors on peut passer en vision nocturne et autres // if HELI POLICE we can change type of vision (IR, night, ...)
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						ChangeVision()
					end

					if IsControlJustPressed(0, toggle_spotlightOr2ndCam) then 						-- Active ou non le projecteur // Toggle light
						if helicoOuPas ~= 15 then
							carcamAR = false
						end
					end

					-- Si on verouille la caméra sur un véhicule la caméra suit le véhicule // If we lock a vehicule the camera will follow
					if locked_on_vehicle then
						if DoesEntityExist(locked_on_vehicle) then
							PointCamAtEntity(cam, locked_on_vehicle, 0.0, 0.0, 0.0, true)
							RenderVehicleInfo(locked_on_vehicle)
							if IsControlJustPressed(0, toggle_lock_on) then
								PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
								locked_on_vehicle = nil
								local rot = GetCamRot(cam, 2) -- All this because I can't seem to get the camera unlocked from the entity
								local fov = GetCamFov(cam)
								local old cam = cam
								DestroyCam(old_cam, false)
								cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
								AttachCamToEntity(cam, heli, 0.0,0.0,-1.5, true)
								SetCamRot(cam, rot, 2)
								SetCamFov(cam, fov)
								RenderScriptCams(true, false, 0, 1, 0)
							end
						else
							locked_on_vehicle = nil -- Cam will auto unlock when entity doesn't exist anyway
						end
					else
						local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
						CheckInputRotation(cam, zoomvalue)
						local vehicle_detected = GetVehicleInView(cam)
						if DoesEntityExist(vehicle_detected) then
							RenderVehicleInfo(vehicle_detected)
							if IsControlJustPressed(0, toggle_lock_on) then
								PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
								locked_on_vehicle = vehicle_detected
							end
						end
					end
					HandleZoom(cam)
					HideHUDThisFrame()
					
					-- Si hélico police on garde les infos avioniques sinon on désactive pour caméra film // if heli police we keep aero informations if not we hide them for movie camera onboard
					if polmav_hashveh == 353883353 then
						PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
						PushScaleformMovieFunctionParameterFloat(GetEntityCoords(heli).z)
						PushScaleformMovieFunctionParameterFloat(zoomvalue)
						PushScaleformMovieFunctionParameterFloat(GetCamRot(cam, 2).z)
						PopScaleformMovieFunctionVoid()
						DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
					end
					
					Citizen.Wait(0)
				end
				
				helicam = false
				carcamAR = false
				ClearTimecycleModifier()
				fov = (fov_max+fov_min)*0.5 							-- reset to starting zoom level
				RenderScriptCams(false, false, 0, 1, 0) 				-- Return to gameplay camera
				SetScaleformMovieAsNoLongerNeeded(scaleform) 			-- Cleanly release the scaleform
				DestroyCam(cam, false)
				SetNightvision(false)
				SetSeethrough(false)
				
			end -- Fin IF HELICAM
		
		end -- Fin IF JOB
		
	end -- Fin WHILE TRUE
	
end)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- NETEVENT ------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent('hlcam:spotlight')
AddEventHandler('hlcam:spotlight', function(serverID, state)
	local heli = GetVehiclePedIsIn(GetPlayerPed(GetPlayerFromServerId(serverID)), false)
	SetVehicleSearchlight(heli, state, false)
	--Citizen.Trace("Set heli light state to "..tostring(state).." for serverID: "..serverID)
end)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- COMMAND -------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Commande pour fixer une caméra sur un véhicule pour les événements MOVIES // command to install camera props on vehicles for movie action
RegisterCommand("fixcamera", function()
	local PersoPed = PlayerPedId()
	local xPlayer = ESX.GetPlayerData()
	-- local playerCoords = GetEntityCoords(PersoPed)
	local playerHeading = GetEntityHeading(PersoPed)	
	if PlayerData.job ~= nil and PlayerData.job.name == 'casino' and PlayerData.job.grade >= 1 then
		
		if IsPedInAnyVehicle(PersoPed, false) then
				
			local dolly = GetHashKey('prop_dolly_02')
			local camfilm = GetHashKey('prop_film_cam_01')
			RequestModel(dolly)
			RequestModel(camfilm)
			while not HasModelLoaded(dolly) do Citizen.Wait(0) end
			while not HasModelLoaded(camfilm) do Citizen.Wait(0) end
		
            local myVehicle = GetVehiclePedIsIn(PersoPed, false)
			local myVehicleHash = GetEntityModel(myVehicle)
			--print("hash")
			--print(myVehicleHash)
			local vehCoords = GetEntityCoords(myVehicle)
			local vehRotation = GetEntityRotation(myVehicle)		
							
			if myVehicleHash == 1203490606 then -- XLS
				local ObjDollyCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				local newObjDolly = CreateObject(dolly, ObjDollyCoords.x, ObjDollyCoords.y, ObjDollyCoords.z, true, false)
				local ObjCamCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				local newObjCam = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)			
				SetEntityHeading(newObjCam, vehRotation)

				AttachEntityToEntity(newObjDolly,myVehicle, 0, 0.0,-1.2,0.0, 0.0, 0.0, 90.0, true, true, true, true, 1, true)								
				AttachEntityToEntity(newObjCam,myVehicle, 0, 0.0,1.85,4.85, 0.0, 0.0, 90.0, true, true, true, true, 1, true)											

			elseif myVehicleHash == 970598228 then -- SULTAN
				local ObjCamCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				local newObjCam = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)			
				local newObjCam2 = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)						
				SetEntityHeading(newObjCam, vehRotation)
				SetEntityHeading(newObjCam2, vehRotation)			

				AttachEntityToEntity(newObjCam,myVehicle, 0, 0.45,1.25,0.65, 0.0, 0.0, 90.0, true, true, true, true, 1, true)											
				AttachEntityToEntity(newObjCam2,myVehicle, 0, 0.35,-0.75,1.10, 0.0, 0.0, 270.0, true, true, true, true, 1, true)											
			
			-- elseif myVehicleHash == 2186977100 then -- GUARDIAN
				-- local ObjDollyCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				-- local newObjDolly = CreateObject(dolly, ObjDollyCoords.x, ObjDollyCoords.y, ObjDollyCoords.z, true, false)
				-- local ObjCamCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				-- local newObjCam = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)			
				-- SetEntityHeading(newObjCam, vehRotation)

				-- AttachEntityToEntity(newObjDolly,myVehicle, 0, 0.0,-1.2,0.0, 0.0, 0.0, 90.0, true, true, true, true, 1, true)								
				-- AttachEntityToEntity(newObjCam,myVehicle, 0, 0.0,1.85,4.85, 0.0, 0.0, 90.0, true, true, true, true, 1, true)												
			
			elseif myVehicleHash == -1671539132 then -- SUPERVOLITO2 (Carbon)
				local ObjCamCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				local newObjCam = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)			
				SetEntityHeading(newObjCam, vehRotation)
				AttachEntityToEntity(newObjCam,myVehicle, 0, 0.0,2.50,-1.15, 180.0, 0.0, 90.0, true, true, true, true, 1, true)
	
			elseif myVehicleHash == 1780283536 then -- Valkyrie3
				local ObjCamCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				local newObjCam = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)			
				SetEntityHeading(newObjCam, vehRotation)
				AttachEntityToEntity(newObjCam,myVehicle, 0, 0.0,4.25,-0.99, 180.0, 0.0, 90.0, true, true, true, true, 1, true)
								
			elseif myVehicleHash == 353883353 then -- Valkyrie3
				local ObjCamCoords = GetOffsetFromEntityInWorldCoords(myVehicle, 0, 0, 0)	
				local newObjCam = CreateObject(camfilm, ObjCamCoords.x, ObjCamCoords.y, ObjCamCoords.z, true, false)			
				SetEntityHeading(newObjCam, vehRotation)
				AttachEntityToEntity(newObjCam,myVehicle, 0, 0.0,4.25,-0.99, 180.0, 0.0, 90.0, true, true, true, true, 1, true)
							
			end

		end
	end
end)

--Commande pour mettre des éléments de travaux pour signaler le tournage // Commande to install prop "works" to indicate action movie
RegisterCommand("caswork01", function()
	local PersoPed = PlayerPedId()
	local xPlayer = ESX.GetPlayerData()
	local playerHeading = GetEntityHeading(PersoPed)	
	if PlayerData.job ~= nil and PlayerData.job.name == 'casino' and PlayerData.job.grade >= 1 then
		local WorkObj = GetHashKey('prop_barrier_work01b')		
		RequestModel(WorkObj)
		while not HasModelLoaded(WorkObj) do Citizen.Wait(0) end
		local ObjCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.1, 0.95, -1.0)	
		local newObjCasino = CreateObject(WorkObj, ObjCoords.x, ObjCoords.y, ObjCoords.z, true, false)			
		SetEntityHeading(newObjCasino, playerHeading + 180)
	end
end)

RegisterCommand("caswork02", function()
	local PersoPed = PlayerPedId()
	local xPlayer = ESX.GetPlayerData()
	local playerHeading = GetEntityHeading(PersoPed)	
	if PlayerData.job ~= nil and PlayerData.job.name == 'casino' and PlayerData.job.grade >= 2 then
		local WorkObj = GetHashKey('prop_barrier_work06a')		
		RequestModel(WorkObj)
		while not HasModelLoaded(WorkObj) do Citizen.Wait(0) end
		local ObjCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.1, 0.95, -1.0)	
		local newObjCasino = CreateObject(WorkObj, ObjCoords.x, ObjCoords.y, ObjCoords.z, true, false)			
		SetEntityHeading(newObjCasino, playerHeading + 180)
	end
end)

RegisterCommand("caswork03", function()
	local PersoPed = PlayerPedId()
	local xPlayer = ESX.GetPlayerData()
	local playerHeading = GetEntityHeading(PersoPed)	
	if PlayerData.job ~= nil and PlayerData.job.name == 'casino' and PlayerData.job.grade >= 2 then
		local WorkObj = GetHashKey('prop_worklight_04d')		
		RequestModel(WorkObj)
		while not HasModelLoaded(WorkObj) do Citizen.Wait(0) end
		local ObjCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.1, 0.95, -1.0)	
		local newObjCasino = CreateObject(WorkObj, ObjCoords.x, ObjCoords.y, ObjCoords.z, true, false)			
		SetEntityHeading(newObjCasino, playerHeading + 180)
	end
end)

RegisterCommand("caswork04", function()
	local PersoPed = PlayerPedId()
	local xPlayer = ESX.GetPlayerData()
	local playerHeading = GetEntityHeading(PersoPed)	
	if PlayerData.job ~= nil and PlayerData.job.name == 'casino' and PlayerData.job.grade >= 2 then
		local WorkObj = GetHashKey('xm_prop_base_work_station_01')		
		RequestModel(WorkObj)
		while not HasModelLoaded(WorkObj) do Citizen.Wait(0) end
		local ObjCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.1, 0.95, -1.0)	
		local newObjCasino = CreateObject(WorkObj, ObjCoords.x, ObjCoords.y, ObjCoords.z, true, false)			
		SetEntityHeading(newObjCasino, playerHeading)
	end
end)

RegisterCommand("caswork05", function()
	local PersoPed = PlayerPedId()
	local xPlayer = ESX.GetPlayerData()
	local playerHeading = GetEntityHeading(PersoPed)	
	if PlayerData.job ~= nil and PlayerData.job.name == 'casino' and PlayerData.job.grade >= 2 then
		local WorkObj = GetHashKey('prop_roadpole_01a')		
		RequestModel(WorkObj)
		while not HasModelLoaded(WorkObj) do Citizen.Wait(0) end
		local ObjCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.1, 0.95, -1.0)	
		local newObjCasino = CreateObject(WorkObj, ObjCoords.x, ObjCoords.y, ObjCoords.z, true, false)			
		SetEntityHeading(newObjCasino, playerHeading)
	end
end)

--Commande pour supprimer des éléments de travaux pour signaler le tournage // command for delete props "works"
RegisterCommand("casworkoff", function()
local playerCoords = GetEntityCoords(PlayerPedId())
    local WorkObj01 = GetClosestObjectOfType(playerCoords.x,playerCoords.y,playerCoords.z,GetEntityHeading(PlayerPedId()),GetHashKey("prop_barrier_work01b"),0,0,0)
    local WorkObj02 = GetClosestObjectOfType(playerCoords.x,playerCoords.y,playerCoords.z,GetEntityHeading(PlayerPedId()),GetHashKey("prop_barrier_work06a"),0,0,0)
    local WorkObj03 = GetClosestObjectOfType(playerCoords.x,playerCoords.y,playerCoords.z,GetEntityHeading(PlayerPedId()),GetHashKey("prop_worklight_04d"),0,0,0)
    local WorkObj04 = GetClosestObjectOfType(playerCoords.x,playerCoords.y,playerCoords.z,GetEntityHeading(PlayerPedId()),GetHashKey("xm_prop_base_work_station_01"),0,0,0)	
	local WorkObj05 = GetClosestObjectOfType(playerCoords.x,playerCoords.y,playerCoords.z,GetEntityHeading(PlayerPedId()),GetHashKey("prop_roadpole_01a"),0,0,0)	
    if DoesEntityExist(WorkObj01) then
		SetEntityAsNoLongerNeeded (WorkObj01, true, true)
		SetEntityCoords(WorkObj01, 0.0, 0.0, -500.00, false, false, false, true)
		DeleteEntity (WorkObj01)
	elseif DoesEntityExist(WorkObj02) then
		SetEntityAsNoLongerNeeded (WorkObj02, true, true)
		SetEntityCoords(WorkObj02, 0.0, 0.0, -500.00, false, false, false, true)
		DeleteEntity (WorkObj02)
	elseif DoesEntityExist(WorkObj03) then
		SetEntityAsNoLongerNeeded (WorkObj03, true, true)
		SetEntityCoords(WorkObj03, 0.0, 0.0, -500.00, false, false, false, true)
		DeleteEntity (WorkObj03)
	elseif DoesEntityExist(WorkObj04) then
		SetEntityAsNoLongerNeeded (WorkObj04, true, true)
		SetEntityCoords(WorkObj04, 0.0, 0.0, -500.00, false, false, false, true)
		DeleteEntity (WorkObj04)
	elseif DoesEntityExist(WorkObj05) then
		SetEntityAsNoLongerNeeded (WorkObj05, true, true)
		SetEntityCoords(WorkObj05, 0.0, 0.0, -500.00, false, false, false, true)
		DeleteEntity (WorkObj05)
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- RAGEUI --------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------- FONCTIONS -----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function IsPlayerInPolmav()
	local lPed = GetPlayerPed(-1)
	local vehicle = GetVehiclePedIsIn(lPed)
	--return IsVehicleModel(vehicle, polmav_hash)
end

function IsHeliHighEnough(heli)
	--return GetEntityHeightAboveGround(heli) > 1.5
	return GetEntityHeightAboveGround(heli) > 0.0	
end

function ChangeVision()
	if vision_state == 0 then
		SetNightvision(true)
		vision_state = 1
	elseif vision_state == 1 then
		SetNightvision(false)
		SetSeethrough(true)
		vision_state = 2
	else
		SetSeethrough(false)
		vision_state = 0
	end
end

function HideHUDThisFrame()
	HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end

function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam)
	if IsControlJustPressed(0,241) then -- Scrollup
		fov = math.max(fov - zoomspeed, fov_min)
	end
	if IsControlJustPressed(0,242) then
		fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown		
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov)*0.05) -- Smoothing of camera zoom
end

function GetVehicleInView(cam)
	local coords = GetCamCoord(cam)
	local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))
	--DrawLine(coords, coords+(forward_vector*100.0), 255,0,0,255) -- debug line to show LOS of cam
	local rayhandle = CastRayPointToPoint(coords, coords+(forward_vector*200.0), 10, GetVehiclePedIsIn(GetPlayerPed(-1)), 0)
	local _, _, _, _, entityHit = GetRaycastResult(rayhandle)
	if entityHit>0 and IsEntityAVehicle(entityHit) then
		return entityHit
	else
		return nil
	end
end

function RenderVehicleInfo(vehicle)
	local model = GetEntityModel(vehicle)
	local vehname = GetLabelText(GetDisplayNameFromVehicleModel(model))
	local licenseplate = GetVehicleNumberPlateText(vehicle)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.55)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	--AddTextComponentString("Model: "..vehname.."\nPlate: "..licenseplate)
	AddTextComponentString("Lock vehicule possible - Espace pour activer et desactiver")
	DrawText(0.25, 0.9)
end

function HandleSpotlight(cam)
	if IsControlJustPressed(0, toggle_spotlightOr2ndCam) then
		PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
		spotlight_state = not spotlight_state
	end
	if spotlight_state then
		local rotation = GetCamRot(cam, 2)
		local forward_vector = RotAnglesToVec(rotation)
		local camcoords = GetCamCoord(cam)
		DrawSpotLight(camcoords, forward_vector, 255, 255, 255, 300.0, 10.0, 0.0, 2.0, 1.0)
	end
end

function RotAnglesToVec(rot) -- input vector3
	local z = math.rad(rot.z)
	local x = math.rad(rot.x)
	local num = math.abs(math.cos(x))
	return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end
