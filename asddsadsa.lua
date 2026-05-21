MachoMenuNotification("S1Dev", "S1Dev Private 3.5v\n\nCapsLock to open menu")

local function isResourceRunning(resourceName)
    return GetResourceState(resourceName) == "started"
end

local bp = setmetatable({}, {
    __index = function(_, k)
        local v = _G[k]
        return type(v) == "function" and function(...) return v(...) end or v
    end
})

_G.X9Bypass = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end

-- ============================================================
--   FEATURES SYSTEM
-- ============================================================
local Features = {
    Godmode        = false,
    Noclip         = false,
    SuperJump      = false,
    FastRun        = false,
    Invisible      = false,
    NoRagdoll      = false,
    NeverWanted    = false,
    OneShot        = false,
    RapidFire      = false,
    InfAmmo        = false,
    NoRecoil       = false,
    VehicleGodmode = false,
    RainbowVehicle = false,
    SuperSpeed     = false,
    ESP            = false,
    ShowCoords     = false,
    ESPDistance    = 500.0,
}

local noclipSpeedVal = 7.0
local superSpeedVal = 80.0
local espDistVal = 500.0

-- ============================================================
--   BYPASS FUNCTIONS
-- ============================================================
local function UniversalACBypass()
    MachoMenuNotification("S1Dev", "Running Universal AC Bypass...")
    
    local _origGCRN = GetCurrentResourceName
    rawset(_G, 'GetCurrentResourceName', function() return "monitor" end)
    Citizen.SetTimeout(5000, function()
        rawset(_G, 'GetCurrentResourceName', _origGCRN)
    end)
    
    local allEvents = {
        "fg:kickPlayer", "fg:BanPlayer", "fg:screenshot", "fg:checkClient",
        "fiveguard:ban", "fiveguard:kick", "FiveGuard:Ban", "FiveGuard:Kick",
        "ElectronAC:playerBanned", "ElectronAC:playerWarned", "ElectronAC:playerKicked",
        "electron:playerBanned", "electron:playerKicked", "electronAC:ban",
        "waveshield:ban", "waveshield:kick", "waveshield:warn", "waveshield:detect",
        "txAdmin:events:playerKicked", "txAdmin:events:announcement"
    }
    for _, ev in ipairs(allEvents) do
        AddEventHandler(ev, function() CancelEvent() end)
    end
    
    AddEventHandler("__cfx_nui:fg_screenshot", function() return end)
    AddEventHandler("__cfx_nui:screenshot", function() return end)
    AddEventHandler("__cfx_internal:Screenshot", function() CancelEvent() end)
    AddEventHandler("onClientResourceStop", function(res)
        if res == GetCurrentResourceName() then CancelEvent() end
    end)
    
    MachoMenuNotification("S1Dev", "Universal AC Bypass Applied!")
end

-- ============================================================
--   CRASH NEARBY FUNCTION
-- ============================================================
local function CrashNearbyPlayers()
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetId = nil
    local closestDist = 150.0
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            if DoesEntityExist(ep) then
                local ec = GetEntityCoords(ep)
                local dist = #(myCoords - ec)
                if dist < closestDist then
                    closestDist = dist
                    targetId = player
                end
            end
        end
    end
    
    if targetId then
        local targetPed = GetPlayerPed(targetId)
        local targetCoords = GetEntityCoords(targetPed)
        local modelHash = GetHashKey("player_one")
        
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 50 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        
        if HasModelLoaded(modelHash) then
            local myPed = PlayerPedId()
            for i = 1, 200 do
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * 6
                local x = targetCoords.x + (distance * math.cos(angle))
                local y = targetCoords.y + (distance * math.sin(angle))
                local z = targetCoords.z
                
                local hasGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
                if hasGround then z = groundZ end
                
                local ped = CreatePed(28, modelHash, x, y, z, math.random(0, 359), true, false)
                if DoesEntityExist(ped) then
                    SetEntityAlpha(ped, 0, false)
                    SetEntityVisible(ped, false, false)
                    FreezeEntityPosition(ped, true)
                    SetEntityCollision(ped, false, false)
                    SetEntityNoCollisionEntity(ped, myPed, true)
                    SetEntityCanBeDamaged(ped, false)
                    SetEntityInvincible(ped, true)
                end
                if i % 10 == 0 then Citizen.Wait(50) end
            end
            SetModelAsNoLongerNeeded(modelHash)
            MachoMenuNotification("S1Dev", "Crash executed on nearest player!")
            return true
        end
    end
    MachoMenuNotification("S1Dev", "No players nearby!")
    return false
end

-- ============================================================
--   NOCLIP FUNCTION
-- ============================================================
local function ToggleNoclip()
    Features.Noclip = not Features.Noclip
    local ped = PlayerPedId()
    
    if Features.Noclip then
        MachoMenuNotification("S1Dev", "Noclip ON - Use WASD + Space/Ctrl to fly")
    else
        SetEntityVisible(ped, true, false)
        SetLocalPlayerVisibleLocally(true)
        MachoMenuNotification("S1Dev", "Noclip OFF")
    end
end

-- Noclip Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.Noclip then
            local ped = PlayerPedId()
            local inVeh = IsPedInAnyVehicle(ped, false)
            local entity = inVeh and GetVehiclePedIsIn(ped, false) or ped
            
            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(ped)
            local pitch = GetGameplayCamRelativePitch()
            local rh = heading * 0.01745329
            local rp = pitch * 0.01745329
            local dx = -math.sin(rh) * math.cos(rp)
            local dy = math.cos(rh) * math.cos(rp)
            local dz = math.sin(rp)
            
            local spd = noclipSpeedVal * 0.05
            if IsControlPressed(0, 21) then spd = spd * 3.0 end
            
            local c = GetEntityCoords(entity)
            local nx, ny, nz = c.x, c.y, c.z
            
            if IsControlPressed(0, 32) then
                nx = nx + dx * spd
                ny = ny + dy * spd
                nz = nz + dz * spd
            end
            if IsControlPressed(0, 33) then
                nx = nx - dx * spd
                ny = ny - dy * spd
                nz = nz - dz * spd
            end
            if IsControlPressed(0, 22) then
                nz = nz + spd
            end
            if IsControlPressed(0, 36) then
                nz = nz - spd
            end
            
            SetEntityCoordsNoOffset(entity, nx, ny, nz, true, true, true)
            SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            SetEntityVisible(entity, false, false)
            SetLocalPlayerVisibleLocally(false)
        end
    end
end)

-- ============================================================
--   REVIVE FUNCTION
-- ============================================================
local function ReviveSelf()
    local myId = GetPlayerServerId(PlayerId())
    
    TriggerServerEvent('esx_ambulancejob:revive', myId)
    TriggerServerEvent('esx_ambulancejob:revivePlayer', myId)
    TriggerServerEvent('esx-ambulancejob:revive', myId)
    TriggerServerEvent('hospital:revive', myId)
    TriggerServerEvent('qb-ambulancejob:server:RevivePlayer', myId)
    TriggerEvent('RespectEMS:triggers:client:revivePlayer')
    
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, 0.0, true, false)
    
    Citizen.SetTimeout(200, function()
        SetEntityHealth(PlayerPedId(), 200)
        SetPedArmour(PlayerPedId(), 100)
        ClearPedBloodDamage(PlayerPedId())
        ClearPedTasksImmediately(PlayerPedId())
    end)
    
    MachoMenuNotification("S1Dev", "Revived!")
end

-- ============================================================
--   THREADS
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.Godmode then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            SetEntityHealth(ped, 200)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.SuperJump then
            SetSuperJumpThisFrame(PlayerId())
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.FastRun then
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.Invisible and not Features.Noclip then
            SetEntityVisible(PlayerPedId(), false, false)
            SetLocalPlayerVisibleLocally(false)
        elseif not Features.Invisible and not Features.Noclip then
            SetEntityVisible(PlayerPedId(), true, false)
            SetLocalPlayerVisibleLocally(true)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.NoRagdoll then
            SetPedCanRagdoll(PlayerPedId(), false)
        else
            SetPedCanRagdoll(PlayerPedId(), true)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.NeverWanted then
            ClearPlayerWantedLevel(PlayerId())
            SetMaxWantedLevel(0)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.OneShot then
            SetPlayerWeaponDamageModifier(PlayerId(), 9999.0)
        else
            SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.RapidFire then
            DisablePlayerFiring(PlayerPedId(), true)
            if IsDisabledControlPressed(0, 24) then
                local _, weapon = GetCurrentPedWeapon(PlayerPedId())
                local camPos = GetGameplayCamCoord()
                local camRot = GetGameplayCamRot(2)
                local rad = 0.01745329
                local rx = camRot.x * rad
                local rz = camRot.z * rad
                local fdx = -math.sin(rz) * math.cos(rx)
                local fdy = math.cos(rz) * math.cos(rx)
                local fdz = math.sin(rx)
                local tx = camPos.x + fdx * 200
                local ty = camPos.y + fdy * 200
                local tz = camPos.z + fdz * 200
                ShootSingleBulletBetweenCoords(camPos.x, camPos.y, camPos.z, tx, ty, tz, 5, true, weapon, PlayerPedId(), true, true, 24000.0)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.InfAmmo then
            SetPedInfiniteAmmoClip(PlayerPedId(), true)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.NoRecoil then
            local cam = GetGameplayCamRot(2)
            if cam.x < -5.0 and IsPedShooting(PlayerPedId()) then
                SetGameplayCamRelativePitch(cam.x * 0.0, 1.0)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if Features.VehicleGodmode then
                SetEntityInvincible(veh, true)
                SetVehicleFixed(veh)
                SetVehicleEngineHealth(veh, 1000.0)
            end
            if Features.RainbowVehicle then
                local t = GetGameTimer() / 1000.0
                SetVehicleCustomPrimaryColour(veh, math.floor(math.sin(t*2)*127+128), math.floor(math.sin(t*2+2)*127+128), math.floor(math.sin(t*2+4)*127+128))
            end
            if Features.SuperSpeed then
                SetVehicleEnginePowerMultiplier(veh, superSpeedVal / 10.0)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.ShowCoords then
            local c = GetEntityCoords(PlayerPedId())
            SetTextFont(0)
            SetTextScale(0.30, 0.30)
            SetTextColour(30, 144, 255, 255)
            SetTextCentre(true)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(string.format("X: %.1f  Y: %.1f  Z: %.1f", c.x, c.y, c.z))
            EndTextCommandDisplayText(0.5, 0.95)
        end
    end
end)

-- ESP Thread
local function RGBRainbow(speed)
    local t = GetGameTimer() / (1000.0 / (speed or 1.0))
    return {
        r = math.floor(math.sin(t) * 127 + 128),
        g = math.floor(math.sin(t + 2.0) * 127 + 128),
        b = math.floor(math.sin(t + 4.0) * 127 + 128),
    }
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.ESP then
            local myPed = PlayerPedId()
            local myPos = GetEntityCoords(myPed)
            local rainbow = RGBRainbow(0.8)
            
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local tp = GetPlayerPed(player)
                    if DoesEntityExist(tp) and not IsPedDeadOrDying(tp, false) then
                        local pedCoords = GetEntityCoords(tp)
                        local dist = #(myPos - pedCoords)
                        
                        if dist <= espDistVal then
                            DrawLine(myPos.x, myPos.y, myPos.z, pedCoords.x, pedCoords.y, pedCoords.z, rainbow.r, rainbow.g, rainbow.b, 80)
                            
                            local head = GetPedBoneCoords(tp, 31086, 0, 0, 0)
                            local onScreen, sx, sy = World3dToScreen2d(head.x, head.y, head.z + 0.25)
                            if onScreen then
                                SetTextFont(4)
                                SetTextScale(0.27, 0.27)
                                SetTextColour(255, 255, 255, 230)
                                SetTextCentre(true)
                                BeginTextCommandDisplayText("STRING")
                                AddTextComponentSubstringPlayerName(GetPlayerName(player))
                                EndTextCommandDisplayText(sx, sy)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
--   MENU SYSTEM (TABBED VERSION)
-- ============================================================
local screenW, screenH = GetActiveScreenResolution()
local MenuSizeX = 700
local MenuSizeY = 500
local MenuPosX = screenW / 2 - MenuSizeX / 2
local MenuPosY = screenH / 2 - MenuSizeY / 2
local TabsBarWidth = 150

-- Create tabbed window
MenuWindow = MachoMenuTabbedWindow('S1Dev', MenuPosX, MenuPosY, MenuSizeX, MenuSizeY, TabsBarWidth)
MachoMenuSetAccent(MenuWindow, 30, 144, 255) -- Blue accent
MachoMenuSetKeybind(MenuWindow, 0x14) -- CapsLock

-- Calculate group sizes
local GroupPadding = 10
local GroupWidth = MenuSizeX - TabsBarWidth - (GroupPadding * 2)
local GroupHeight = MenuSizeY - (GroupPadding * 2)

-- ============================================================
--   TAB 1: PLAYER
-- ============================================================
local PlayerTab = MachoMenuAddTab(MenuWindow, 'Player')
local PlayerGroup = MachoMenuGroup(PlayerTab, 'Player Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(PlayerGroup, 'Godmode [TOGGLE]', function()
    Features.Godmode = not Features.Godmode
    MachoMenuNotification("S1Dev", "Godmode: " .. (Features.Godmode and "ON" or "OFF"))
end)

MachoMenuButton(PlayerGroup, 'Noclip [TOGGLE]', function()
    ToggleNoclip()
end)

MachoMenuButton(PlayerGroup, 'Super Jump [TOGGLE]', function()
    Features.SuperJump = not Features.SuperJump
    MachoMenuNotification("S1Dev", "Super Jump: " .. (Features.SuperJump and "ON" or "OFF"))
end)

MachoMenuButton(PlayerGroup, 'Fast Run [TOGGLE]', function()
    Features.FastRun = not Features.FastRun
    MachoMenuNotification("S1Dev", "Fast Run: " .. (Features.FastRun and "ON" or "OFF"))
end)

MachoMenuButton(PlayerGroup, 'Invisible [TOGGLE]', function()
    Features.Invisible = not Features.Invisible
    MachoMenuNotification("S1Dev", "Invisible: " .. (Features.Invisible and "ON" or "OFF"))
end)

MachoMenuButton(PlayerGroup, 'No Ragdoll [TOGGLE]', function()
    Features.NoRagdoll = not Features.NoRagdoll
    MachoMenuNotification("S1Dev", "No Ragdoll: " .. (Features.NoRagdoll and "ON" or "OFF"))
end)

MachoMenuButton(PlayerGroup, 'Never Wanted [TOGGLE]', function()
    Features.NeverWanted = not Features.NeverWanted
    MachoMenuNotification("S1Dev", "Never Wanted: " .. (Features.NeverWanted and "ON" or "OFF"))
end)

MachoMenuButton(PlayerGroup, 'Revive', function()
    ReviveSelf()
end)

MachoMenuButton(PlayerGroup, 'Heal', function()
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    MachoMenuNotification("S1Dev", "Healed!")
end)

-- Noclip Speed Slider
MachoMenuSlider(PlayerGroup, "Noclip Speed", noclipSpeedVal, 0.5, 20.0, "", 1, function(Value)
    noclipSpeedVal = Value
end)

-- ============================================================
--   TAB 2: COMBAT
-- ============================================================
local CombatTab = MachoMenuAddTab(MenuWindow, 'Combat')
local CombatGroup = MachoMenuGroup(CombatTab, 'Combat Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(CombatGroup, 'One Shot Kill [TOGGLE]', function()
    Features.OneShot = not Features.OneShot
    MachoMenuNotification("S1Dev", "One Shot Kill: " .. (Features.OneShot and "ON" or "OFF"))
end)

MachoMenuButton(CombatGroup, 'Rapid Fire [TOGGLE]', function()
    Features.RapidFire = not Features.RapidFire
    MachoMenuNotification("S1Dev", "Rapid Fire: " .. (Features.RapidFire and "ON" or "OFF"))
end)

MachoMenuButton(CombatGroup, 'Infinite Ammo [TOGGLE]', function()
    Features.InfAmmo = not Features.InfAmmo
    MachoMenuNotification("S1Dev", "Infinite Ammo: " .. (Features.InfAmmo and "ON" or "OFF"))
end)

MachoMenuButton(CombatGroup, 'No Recoil [TOGGLE]', function()
    Features.NoRecoil = not Features.NoRecoil
    MachoMenuNotification("S1Dev", "No Recoil: " .. (Features.NoRecoil and "ON" or "OFF"))
end)

-- ============================================================
--   TAB 3: VEHICLE
-- ============================================================
local VehicleTab = MachoMenuAddTab(MenuWindow, 'Vehicle')
local VehicleGroup = MachoMenuGroup(VehicleTab, 'Vehicle Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(VehicleGroup, 'Vehicle Godmode [TOGGLE]', function()
    Features.VehicleGodmode = not Features.VehicleGodmode
    MachoMenuNotification("S1Dev", "Vehicle Godmode: " .. (Features.VehicleGodmode and "ON" or "OFF"))
end)

MachoMenuButton(VehicleGroup, 'Rainbow Vehicle [TOGGLE]', function()
    Features.RainbowVehicle = not Features.RainbowVehicle
    MachoMenuNotification("S1Dev", "Rainbow Vehicle: " .. (Features.RainbowVehicle and "ON" or "OFF"))
end)

MachoMenuButton(VehicleGroup, 'Super Speed [TOGGLE]', function()
    Features.SuperSpeed = not Features.SuperSpeed
    MachoMenuNotification("S1Dev", "Super Speed: " .. (Features.SuperSpeed and "ON" or "OFF"))
end)

MachoMenuButton(VehicleGroup, 'Repair Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        MachoMenuNotification("S1Dev", "Vehicle Repaired!")
    else
        MachoMenuNotification("S1Dev", "Not in a vehicle!")
    end
end)

MachoMenuButton(VehicleGroup, 'Flip Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleOnGroundProperly(veh)
        MachoMenuNotification("S1Dev", "Vehicle Flipped!")
    end
end)

MachoMenuButton(VehicleGroup, 'Delete Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        TaskLeaveVehicle(PlayerPedId(), veh, 0)
        Citizen.Wait(500)
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        MachoMenuNotification("S1Dev", "Vehicle Deleted!")
    end
end)

-- Super Speed Slider
MachoMenuSlider(VehicleGroup, "Super Speed Power", superSpeedVal, 10.0, 200.0, "", 1, function(Value)
    superSpeedVal = Value
end)

-- ============================================================
--   TAB 4: VISUAL
-- ============================================================
local VisualTab = MachoMenuAddTab(MenuWindow, 'Visual')
local VisualGroup = MachoMenuGroup(VisualTab, 'Visual Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(VisualGroup, 'ESP Box [TOGGLE]', function()
    Features.ESP = not Features.ESP
    MachoMenuNotification("S1Dev", "ESP: " .. (Features.ESP and "ON" or "OFF"))
end)

MachoMenuButton(VisualGroup, 'Show Coordinates [TOGGLE]', function()
    Features.ShowCoords = not Features.ShowCoords
    MachoMenuNotification("S1Dev", "Show Coordinates: " .. (Features.ShowCoords and "ON" or "OFF"))
end)

-- ESP Distance Slider
MachoMenuSlider(VisualGroup, "ESP Distance", espDistVal, 50.0, 5000.0, "m", 1, function(Value)
    espDistVal = Value
end)

-- ============================================================
--   TAB 5: TROLL
-- ============================================================
local TrollTab = MachoMenuAddTab(MenuWindow, 'Troll')
local TrollGroup = MachoMenuGroup(TrollTab, 'Troll Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(TrollGroup, 'Crash Nearby Player', function()
    CrashNearbyPlayers()
end)

MachoMenuButton(TrollGroup, 'Explode Nearby Players', function()
    local myCoords = GetEntityCoords(PlayerPedId())
    local count = 0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            local ec = GetEntityCoords(ep)
            local dist = #(myCoords - ec)
            if dist < 100.0 then
                AddExplosion(ec.x, ec.y, ec.z, 2, 100.0, true, false, 0.0)
                count = count + 1
            end
        end
    end
    MachoMenuNotification("S1Dev", "Exploded " .. count .. " players!")
end)

MachoMenuButton(TrollGroup, 'Launch Nearby Players', function()
    local myCoords = GetEntityCoords(PlayerPedId())
    local count = 0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            local ec = GetEntityCoords(ep)
            local dist = #(myCoords - ec)
            if dist < 80.0 then
                SetEntityVelocity(ep, 0, 0, 120)
                count = count + 1
            end
        end
    end
    MachoMenuNotification("S1Dev", "Launched " .. count .. " players!")
end)

MachoMenuButton(TrollGroup, 'Freeze Nearby Players', function()
    local myCoords = GetEntityCoords(PlayerPedId())
    local count = 0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            local ec = GetEntityCoords(ep)
            local dist = #(myCoords - ec)
            if dist < 80.0 then
                FreezeEntityPosition(ep, true)
                count = count + 1
            end
        end
    end
    MachoMenuNotification("S1Dev", "Froze " .. count .. " players!")
end)

MachoMenuButton(TrollGroup, 'Unfreeze All', function()
    local count = 0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            FreezeEntityPosition(ep, false)
            count = count + 1
        end
    end
    MachoMenuNotification("S1Dev", "Unfroze " .. count .. " players!")
end)

MachoMenuButton(TrollGroup, 'Kill All Players', function()
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            local ec = GetEntityCoords(ep)
            AddExplosion(ec.x, ec.y, ec.z, 29, 1000.0, true, false, 0.0)
        end
    end
    MachoMenuNotification("S1Dev", "All players killed!")
end)

-- ============================================================
--   TAB 6: TELEPORT
-- ============================================================
local TeleportTab = MachoMenuAddTab(MenuWindow, 'Teleport')
local TeleportGroup = MachoMenuGroup(TeleportTab, 'Teleport Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(TeleportGroup, 'TP to Waypoint', function()
    local blip = GetFirstBlipInfoId(8)
    if DoesBlipExist(blip) then
        local wc = GetBlipInfoIdCoord(blip)
        local found, gz = GetGroundZFor_3dCoord(wc.x, wc.y, 100.0, false)
        SetEntityCoords(PlayerPedId(), wc.x, wc.y, found and gz + 1.0 or wc.z + 2.0)
        MachoMenuNotification("S1Dev", "Teleported to waypoint!")
    else
        MachoMenuNotification("S1Dev", "No waypoint set!")
    end
end)

MachoMenuButton(TeleportGroup, 'TP to Airport', function()
    SetEntityCoords(PlayerPedId(), -1037.0, -2738.0, 20.17)
    MachoMenuNotification("S1Dev", "Teleported to Airport!")
end)

MachoMenuButton(TeleportGroup, 'TP to Zancudo', function()
    SetEntityCoords(PlayerPedId(), -2047.0, 3132.0, 32.81)
    MachoMenuNotification("S1Dev", "Teleported to Zancudo!")
end)

MachoMenuButton(TeleportGroup, 'TP to City Center', function()
    SetEntityCoords(PlayerPedId(), -75.0, -820.0, 326.17)
    MachoMenuNotification("S1Dev", "Teleported to City Center!")
end)

MachoMenuButton(TeleportGroup, 'TP Up in Air', function()
    local c = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), c.x, c.y, 2000.0)
    MachoMenuNotification("S1Dev", "Teleported up high!")
end)

-- ============================================================
--   TAB 7: WEAPON
-- ============================================================
local WeaponTab = MachoMenuAddTab(MenuWindow, 'Weapon')
local WeaponGroup = MachoMenuGroup(WeaponTab, 'Weapon Options', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(WeaponGroup, 'Give All Weapons', function()
    local weapons = {
        "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_MICROSMG",
        "WEAPON_SMG", "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE", "WEAPON_MG",
        "WEAPON_COMBATMG", "WEAPON_PUMPSHOTGUN", "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER",
        "WEAPON_RPG", "WEAPON_MINIGUN", "WEAPON_GRENADE"
    }
    local ped = PlayerPedId()
    for _, weapon in ipairs(weapons) do
        GiveWeaponToPed(ped, GetHashKey(weapon), 9999, false, true)
    end
    MachoMenuNotification("S1Dev", "All weapons given!")
end)

MachoMenuButton(WeaponGroup, 'Remove All Weapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    MachoMenuNotification("S1Dev", "All weapons removed!")
end)

MachoMenuButton(WeaponGroup, 'Give RPG', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_RPG"), 99, false, true)
    MachoMenuNotification("S1Dev", "RPG given!")
end)

MachoMenuButton(WeaponGroup, 'Give Minigun', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_MINIGUN"), 9999, false, true)
    MachoMenuNotification("S1Dev", "Minigun given!")
end)

MachoMenuButton(WeaponGroup, 'Give Sniper', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_HEAVYSNIPER"), 9999, false, true)
    MachoMenuNotification("S1Dev", "Sniper given!")
end)

-- ============================================================
--   TAB 8: BYPASS
-- ============================================================
local BypassTab = MachoMenuAddTab(MenuWindow, 'Bypass')
local BypassGroup = MachoMenuGroup(BypassTab, 'Anti-Cheat Bypass', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(BypassGroup, 'Universal AC Bypass', function()
    UniversalACBypass()
end)

MachoMenuButton(BypassGroup, 'Check Anti-Cheat', function()
    local detected = false
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local lower = string.lower(resourceName)
            if lower:find('fiveguard') or lower:find('electron') or lower:find('waveshield') then
                detected = true
                MachoMenuNotification("S1Dev", "Detected: " .. resourceName)
                break
            end
        end
    end
    if not detected then
        MachoMenuNotification("S1Dev", "No known Anti-Cheat detected")
    end
end)

-- ============================================================
--   TAB 9: SETTINGS
-- ============================================================
local SettingsTab = MachoMenuAddTab(MenuWindow, 'Settings')
local SettingsGroup = MachoMenuGroup(SettingsTab, 'Settings', GroupPadding, GroupPadding, GroupWidth, GroupHeight)

MachoMenuButton(SettingsGroup, 'Change Keybind', function()
    waitingForKey = true
    MachoMenuNotification('S1Dev', 'Press desired key to bind')
end)

local waitingForKey = false
MachoOnKeyDown(function(key)
    if waitingForKey then
        if key == 27 then
            waitingForKey = false
            MachoMenuNotification('S1Dev', 'Cancelled')
        else
            MachoMenuSetKeybind(MenuWindow, key)
            waitingForKey = false
            MachoMenuNotification('S1Dev', 'Keybind updated')
        end
    end
end)

print("^2[S1Dev] ^7Loaded successfully! Press CapsLock to open menu")