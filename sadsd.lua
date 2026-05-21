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
    InfStamina     = false,
    NeverWanted    = false,
    ExplosiveAmmo  = false,
    FireAmmo       = false,
    ESP            = false,
    ESPSkeleton    = false,
    Nightvision    = false,
    ThermalVision  = false,
    Freecam        = false,
    ShowCoords     = false,
    ShowSpeedo     = false,
    OneShot        = false,
    RapidFire      = false,
    Aimbot         = false,
    SilentAim      = false,
    MagicBullet    = false,
    NoRecoil       = false,
    VehicleGodmode = false,
    RainbowVehicle = false,
    SuperSpeed     = false,
    InfAmmo        = false,
    MagnetoMode    = false,
    FlingPlayer    = false,
    ESPDistance    = 500.0,
    AutoBypass     = false,
}

local Settings = {
    NoclipSpeed    = 7.0,
    FreecamSpeed   = 7.0,
    AimbotFOV      = 100.0,
    AimbotSmoothing= 5.0,
    SuperSpeedVal  = 80.0,
}

-- Slider values storage
local noclipSpeedVal = 7.0
local espDistVal = 500.0
local superSpeedVal = 80.0
local aimbotFovVal = 100.0
local aimbotSmoothVal = 5.0

-- ============================================================
--   BYPASS FUNCTIONS
-- ============================================================

-- FiveGuard Bypass
local function FiveGuardBypass()
    MachoMenuNotification("S1Dev", "Applying FiveGuard Bypass...")
    
    -- Spoof resource name
    local _origGCRN = GetCurrentResourceName
    rawset(_G, 'GetCurrentResourceName', function() return "monitor" end)
    Citizen.SetTimeout(5000, function()
        rawset(_G, 'GetCurrentResourceName', _origGCRN)
    end)
    
    -- Block FiveGuard events
    local fgEvents = {
        "fg:kickPlayer", "fg:BanPlayer", "fg:screenshot", "fg:checkClient",
        "fg:forceUpdate", "fg:detection", "fg:ban", "fg:kick", "fg:warn",
        "fiveguard:ban", "fiveguard:kick", "fiveguard:screenshot",
        "FiveGuard:Ban", "FiveGuard:Kick", "FiveGuard:Screenshot"
    }
    for _, ev in ipairs(fgEvents) do
        AddEventHandler(ev, function() CancelEvent() end)
    end
    
    -- Block NUI screenshots
    AddEventHandler("__cfx_nui:fg_screenshot", function() return end)
    AddEventHandler("__cfx_nui:screenshot", function() return end)
    
    Features.AutoBypass = true
    Features.MaskGodmode = true
    MachoMenuNotification("S1Dev", "FiveGuard Bypass Applied!")
end

-- ElectronAC Bypass
local function ElectronACBypass()
    MachoMenuNotification("S1Dev", "Applying ElectronAC Bypass...")
    
    -- Block Electron events
    local electronEvents = {
        "ElectronAC:playerBanned", "ElectronAC:playerWarned", "ElectronAC:playerKicked",
        "electron:playerBanned", "electron:playerKicked", "electronAC:ban"
    }
    for _, ev in ipairs(electronEvents) do
        AddEventHandler(ev, function() CancelEvent() end)
    end
    
    -- Block resource protection
    AddEventHandler("__cfx_internal:resourceProtection", function() CancelEvent() end)
    
    -- Block resource stop for this script
    AddEventHandler("onClientResourceStop", function(res)
        if res == GetCurrentResourceName() then CancelEvent() end
    end)
    
    Features.AutoBypass = true
    MachoMenuNotification("S1Dev", "ElectronAC Bypass Applied!")
end

-- WaveShield Bypass
local function WaveShieldBypass()
    MachoMenuNotification("S1Dev", "Applying WaveShield Bypass...")
    
    local waveshieldFound = false
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local lower = string.lower(resourceName)
            if lower:find('waveshield') then
                waveshieldFound = true
                MachoInjectResourceRaw(resourceName, [[
                    _G.OriginalTriggerServerEvent = _G.TriggerServerEvent
                    _G.TriggerServerEvent = function(event, ...)
                        if event and (event:find('detect') or event:find('cheat') or event:find('bypass')) then
                            return
                        end
                        return _G.OriginalTriggerServerEvent(event, ...)
                    end
                    if _G.heartbeat then _G.heartbeat = function() return true end end
                    if _G.sendTelemetry then _G.sendTelemetry = function() return true end end
                    local origQuit = _G.QuitGame or _G.quit
                    _G.QuitGame = function() return end
                    _G.quit = function() return end
                ]])
                break
            end
        end
    end
    
    -- Block WaveShield events
    local wsEvents = {
        "waveshield:ban", "waveshield:kick", "waveshield:warn", "waveshield:detect",
        "waveshield:screenshot", "waveshield:playerBanned", "waveshield:playerKicked",
        "waveshield:playerWarned", "waveshield:clear", "waveshield:serverBan"
    }
    for _, ev in ipairs(wsEvents) do
        AddEventHandler(ev, function() CancelEvent() end)
    end
    
    -- Crash protection
    local crashProtection = [[
        local origError = error
        _G.error = function(msg)
            if msg and (msg:find('crash') or msg:find('detected') or msg:find('anticheat')) then
                print('^2[S1Dev] ^7Blocked crash attempt')
                return
            end
            return origError(msg)
        end
        local origQuitGame = QuitGame
        QuitGame = function() return end
    ]]
    MachoInjectResourceRaw('_G', crashProtection)
    
    if waveshieldFound then
        MachoMenuNotification("S1Dev", "WaveShield Bypass Successful!")
    else
        MachoMenuNotification("S1Dev", "No WaveShield Detected - Bypass Applied Anyway")
    end
    Features.AutoBypass = true
end

-- Universal AC Bypass (all in one)
local function UniversalACBypass()
    MachoMenuNotification("S1Dev", "Running Universal AC Bypass...")
    
    -- Spoof resource name
    local _origGCRN = GetCurrentResourceName
    rawset(_G, 'GetCurrentResourceName', function() return "monitor" end)
    Citizen.SetTimeout(5000, function()
        rawset(_G, 'GetCurrentResourceName', _origGCRN)
    end)
    
    -- Block all common AC events
    local allEvents = {
        "fg:kickPlayer", "fg:BanPlayer", "fg:screenshot", "fg:checkClient",
        "fiveguard:ban", "fiveguard:kick", "FiveGuard:Ban", "FiveGuard:Kick",
        "ElectronAC:playerBanned", "ElectronAC:playerWarned", "ElectronAC:playerKicked",
        "electron:playerBanned", "electron:playerKicked", "electronAC:ban",
        "waveshield:ban", "waveshield:kick", "waveshield:warn", "waveshield:detect",
        "txAdmin:events:playerKicked", "txAdmin:events:announcement",
        "esx_anticheat:ban", "qb-anticheat:ban", "anticheat:detect"
    }
    for _, ev in ipairs(allEvents) do
        AddEventHandler(ev, function() CancelEvent() end)
    end
    
    -- Block NUI
    AddEventHandler("__cfx_nui:fg_screenshot", function() return end)
    AddEventHandler("__cfx_nui:screenshot", function() return end)
    AddEventHandler("__cfx_internal:Screenshot", function() CancelEvent() end)
    AddEventHandler("__cfx_internal:resourceProtection", function() CancelEvent() end)
    
    -- Block resource stop
    AddEventHandler("onClientResourceStop", function(res)
        if res == GetCurrentResourceName() then CancelEvent() end
    end)
    
    -- Crash protection
    local crashProtection = [[
        local origError = error
        _G.error = function(msg)
            if msg and (msg:find('crash') or msg:find('detected') or msg:find('anticheat')) then
                print('^2[S1Dev] ^7Blocked crash attempt')
                return
            end
            return origError(msg)
        end
        local origQuitGame = QuitGame
        QuitGame = function() return end
    ]]
    MachoInjectResourceRaw('_G', crashProtection)
    
    Features.AutoBypass = true
    Features.MaskGodmode = true
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
--   GODMODE THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.Godmode then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            SetEntityProofs(ped, true, true, true, true, true, true, true, true)
            SetEntityHealth(ped, 200)
        end
    end
end)

-- ============================================================
--   SUPER JUMP THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.SuperJump then
            SetSuperJumpThisFrame(PlayerId())
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                if IsControlJustPressed(0, 22) then
                    local vx, vy, vz = table.unpack(GetEntityVelocity(ped))
                    SetEntityVelocity(ped, vx, vy, math.max(vz, 25.0))
                end
            end
        end
    end
end)

-- ============================================================
--   FAST RUN THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.FastRun then
            local ped = PlayerPedId()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
            SetPedMoveRateOverride(ped, 2.5)
            if IsPedRunning(ped) or IsPedSprinting(ped) then
                local vel = GetEntityVelocity(ped)
                local spd = math.sqrt(vel.x*vel.x + vel.y*vel.y)
                if spd > 0.2 and spd < 30.0 then
                    local fwd = GetEntityForwardVector(ped)
                    local boostScale = math.max(0.05, 0.25 - spd * 0.008)
                    SetEntityVelocity(ped, vel.x + fwd.x * boostScale, vel.y + fwd.y * boostScale, vel.z)
                end
            end
        end
    end
end)

-- ============================================================
--   INVISIBLE THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.Invisible and not Features.Noclip then
            local ped = PlayerPedId()
            SetEntityVisible(ped, false, false)
            SetLocalPlayerVisibleLocally(false)
            if IsPedInAnyVehicle(ped, false) then
                SetEntityVisible(GetVehiclePedIsIn(ped, false), false, false)
            end
        elseif not Features.Invisible and not Features.Noclip then
            local ped = PlayerPedId()
            SetEntityVisible(ped, true, false)
            SetLocalPlayerVisibleLocally(true)
        end
    end
end)

-- ============================================================
--   VEHICLE GODMODE THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if Features.VehicleGodmode then
                SetEntityInvincible(veh, true)
                SetVehicleCanBreak(veh, false)
                SetVehicleCanBeVisiblyDamaged(veh, false)
                SetVehicleFixed(veh)
                SetVehicleEngineHealth(veh, 1000.0)
                SetVehicleBodyHealth(veh, 1000.0)
            end
            if Features.RainbowVehicle then
                local t = GetGameTimer() / 1000.0
                SetVehicleCustomPrimaryColour(veh, math.floor(math.sin(t*2)*127+128), math.floor(math.sin(t*2+2)*127+128), math.floor(math.sin(t*2+4)*127+128))
                SetVehicleCustomSecondaryColour(veh, math.floor(math.sin(t*2)*127+128), math.floor(math.sin(t*2+2)*127+128), math.floor(math.sin(t*2+4)*127+128))
            end
            if Features.SuperSpeed then
                SetVehicleEnginePowerMultiplier(veh, superSpeedVal / 10.0)
                SetVehicleEngineTorqueMultiplier(veh, superSpeedVal / 10.0)
            end
        end
    end
end)

-- ============================================================
--   ONE SHOT THREAD
-- ============================================================
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

-- ============================================================
--   NO RECOIL THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.NoRecoil then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                local cam = GetGameplayCamRot(2)
                if cam.x < -5.0 and IsPedShooting(ped) then
                    SetGameplayCamRelativePitch(cam.x * 0.0, 1.0)
                end
            end
        end
    end
end)

-- ============================================================
--   RAPID FIRE THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.RapidFire then
            DisablePlayerFiring(PlayerPedId(), true)
            if IsDisabledControlPressed(0, 24) then
                local _, weapon = GetCurrentPedWeapon(PlayerPedId())
                local camFwd = GetGameplayCamRot(2)
                local camPos = GetGameplayCamCoord()
                local rad = 0.01745329
                local rx = camFwd.x * rad
                local rz = camFwd.z * rad
                local fdx = -math.sin(rz) * math.cos(rx)
                local fdy = math.cos(rz) * math.cos(rx)
                local fdz = math.sin(rx)
                local lx, ly, lz = camPos.x, camPos.y, camPos.z
                local tx = camPos.x + fdx * 200
                local ty = camPos.y + fdy * 200
                local tz = camPos.z + fdz * 200
                ShootSingleBulletBetweenCoords(lx, ly, lz, tx, ty, tz, 5, true, weapon, PlayerPedId(), true, true, 24000.0)
            end
        end
    end
end)

-- ============================================================
--   SHOW COORDS THREAD
-- ============================================================
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

-- ============================================================
--   ESP THREAD
-- ============================================================
local function RGBRainbow(speed)
    local t = GetGameTimer() / (1000.0 / (speed or 1.0))
    return {
        r = math.floor(math.sin(t) * 127 + 128),
        g = math.floor(math.sin(t + 2.0) * 127 + 128),
        b = math.floor(math.sin(t + 4.0) * 127 + 128),
    }
end

local skeletonBones = {
    {11816,24816},{24816,24817},{24817,24818},{24818,65068},{65068,31086},
    {24818,10706},{10706,64016},{64016,36029},{36029,61163},
    {24818,64729},{64729,28252},{28252,2992},{2992,28422},
    {11816,58271},{58271,63931},{63931,14201},{14201,2108},
    {58271,36864},{36864,51826},{51826,14211},
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.ESP or Features.ESPSkeleton then
            local myPed = PlayerPedId()
            local myPos = GetEntityCoords(myPed)
            local rainbow = RGBRainbow(0.8)
            local r, g, b = rainbow.r, rainbow.g, rainbow.b
            
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() and NetworkIsPlayerActive(player) then
                    local tp = GetPlayerPed(player)
                    if DoesEntityExist(tp) and not IsPedDeadOrDying(tp, false) then
                        local pedCoords = GetEntityCoords(tp)
                        local dist = #(myPos - pedCoords)
                        
                        if dist <= espDistVal then
                            if Features.ESP then
                                DrawLine(myPos.x, myPos.y, myPos.z, pedCoords.x, pedCoords.y, pedCoords.z, r, g, b, 80)
                                
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
                            
                            if Features.ESPSkeleton then
                                for _, bp in pairs(skeletonBones) do
                                    local c1 = GetPedBoneCoords(tp, bp[1], 0, 0, 0)
                                    local c2 = GetPedBoneCoords(tp, bp[2], 0, 0, 0)
                                    if c1.x ~= 0 or c1.y ~= 0 then
                                        DrawLine(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, r, g, b, 200)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
--   ANTI-CHEAT DETECTION
-- ============================================================
local function detectAntiCheat()
    local numResources = GetNumResources()
    local detectedName, detectedAc
    
    local fileSignatures = {
        { files = { 'ai_module_fg-obfuscated.lua' }, name = 'FiveGuard' },
        { files = { 'source/client/crasher.lua', 'source/client/ocr.lua' }, name = 'ReasonAC' },
        { files = { 'client/injections.lua', 'client/menu.lua' }, name = 'GreekAC' },
        { files = { 'fini_events.js', 'fini_events.lua' }, name = 'FiniAC' },
        { files = { 'resource/waveshield.js' }, name = 'WaveShield' },
        { files = { 'c_config.lua', 'client/ligma.lua' }, name = 'mAC' },
        { files = { 'src/fire-client.lua', 'src/fire-menu.lua' }, name = 'FireAC' },
        { files = { 'anvil.lua', 'client.lua' }, name = 'AnvilAC' },
        { files = { 'client/cl_crypto.lua', 'client/cl_main.lua' }, name = 'PegasusAC' },
        { files = { 'src/client/main.lua', 'src/include/client.lua' }, name = 'ElectronAC' }
    }
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            for _, sig in ipairs(fileSignatures) do
                local ok = true
                for _, f in ipairs(sig.files) do
                    if not LoadResourceFile(resourceName, f) then ok = false break end
                end
                if ok then
                    detectedName, detectedAc = resourceName, sig.name
                    break
                end
            end
        end
        if detectedAc then break end
    end
    
    return detectedName, detectedAc
end

local detectedACName, detectedACType = detectAntiCheat()

-- ============================================================
--   MENU SYSTEM
-- ============================================================
local MenuSize = vec2(520, 420)
local screenW, screenH = GetActiveScreenResolution()
local MenuStartCoords = vec2(screenW / 2 - MenuSize.x / 2, screenH / 2 - MenuSize.y / 2)
local TabsBarWidth = 130.0
local SectionsPadding = 8
local MachoPaneGap = 6
local SectionChildWidth = MenuSize.x - TabsBarWidth
local SectionColumns = 2
local SectionRows = 2
local TwoByTwoSectionWidth = (SectionChildWidth - (SectionsPadding * (SectionColumns + 1))) / SectionColumns
local TwoByTwoSectionHeight = (MenuSize.y - (SectionsPadding * (SectionRows + 1))) / SectionRows

local function GetSectionCoords(col, row, colspan, rowspan)
    colspan = colspan or 1
    rowspan = rowspan or 1
    local startX = TabsBarWidth + (SectionsPadding * col) + (TwoByTwoSectionWidth * (col - 1))
    local startY = (SectionsPadding * row) + (TwoByTwoSectionHeight * (row - 1)) + MachoPaneGap
    return startX, startY
end

MenuWindow = MachoMenuTabbedWindow('S1Dev', MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSmallText(MenuWindow, "User: " .. (authenticatedUser or "LOADING..."))
MachoMenuSetAccent(MenuWindow, 30, 144, 255)
local MenuKeybind = MachoMenuSetKeybind(MenuWindow, 0x14)

-- ============================================================
--   MAIN TAB
-- ============================================================
local MainTab = MachoMenuAddTab(MenuWindow, 'Main')
local MainSection = MachoMenuGroup(MainTab, 'S1Dev Features', GetSectionCoords(1, 1, 2, 2))

MachoMenuCheckbox(MainSection, 'Godmode', function() Features.Godmode = not Features.Godmode end)
MachoMenuCheckbox(MainSection, 'Noclip', function() ToggleNoclip() end)

-- Noclip Speed Slider
MachoMenuSlider(MainSection, 'Noclip Speed', function(value) noclipSpeedVal = value end, 0.5, 20.0, 0.5)

MachoMenuCheckbox(MainSection, 'Super Jump', function() Features.SuperJump = not Features.SuperJump end)
MachoMenuCheckbox(MainSection, 'Fast Run', function() Features.FastRun = not Features.FastRun end)
MachoMenuCheckbox(MainSection, 'Invisible', function() Features.Invisible = not Features.Invisible end)
MachoMenuCheckbox(MainSection, 'No Ragdoll', function() Features.NoRagdoll = not Features.NoRagdoll end)
MachoMenuCheckbox(MainSection, 'Never Wanted', function() Features.NeverWanted = not Features.NeverWanted end)

MachoMenuButton(MainSection, 'Revive', function() ReviveSelf() end)

MachoMenuButton(MainSection, 'Heal', function()
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    MachoMenuNotification("S1Dev", "Healed!")
end)

-- ============================================================
--   BYPASS TAB
-- ============================================================
local BypassTab = MachoMenuAddTab(MenuWindow, 'Bypass')
local BypassSection = MachoMenuGroup(BypassTab, 'Anti-Cheat Bypass', GetSectionCoords(1, 1, 2, 2))

-- Show detected AC
if detectedACType then
    MachoMenuSmallText(MainSection, "Detected AC: " .. detectedACType)
end

MachoMenuButton(BypassSection, 'Universal AC Bypass (All)', function()
    UniversalACBypass()
end)

MachoMenuButton(BypassSection, 'FiveGuard Bypass', function()
    FiveGuardBypass()
end)

MachoMenuButton(BypassSection, 'ElectronAC Bypass', function()
    ElectronACBypass()
end)

MachoMenuButton(BypassSection, 'WaveShield Bypass', function()
    WaveShieldBypass()
end)

MachoMenuButton(BypassSection, 'Check Anti-Cheat', function()
    local name, ac = detectAntiCheat()
    if ac then
        MachoMenuNotification("S1Dev", "Detected: " .. ac .. " (" .. name .. ")")
    else
        MachoMenuNotification("S1Dev", "No known Anti-Cheat detected")
    end
end)

MachoMenuCheckbox(BypassSection, 'Auto Bypass Mode', function()
    Features.AutoBypass = not Features.AutoBypass
    if Features.AutoBypass then
        UniversalACBypass()
    end
end)

-- ============================================================
--   COMBAT TAB
-- ============================================================
local CombatTab = MachoMenuAddTab(MenuWindow, 'Combat')
local CombatSection = MachoMenuGroup(CombatTab, 'Combat Options', GetSectionCoords(1, 1, 2, 2))

MachoMenuCheckbox(CombatSection, 'One Shot Kill', function() Features.OneShot = not Features.OneShot end)
MachoMenuCheckbox(CombatSection, 'Rapid Fire', function() Features.RapidFire = not Features.RapidFire end)
MachoMenuCheckbox(CombatSection, 'Infinite Ammo', function() Features.InfAmmo = not Features.InfAmmo end)
MachoMenuCheckbox(CombatSection, 'No Recoil', function() Features.NoRecoil = not Features.NoRecoil end)
MachoMenuCheckbox(CombatSection, 'Magneto Mode', function() Features.MagnetoMode = not Features.MagnetoMode end)

MachoMenuSlider(CombatSection, 'Aimbot FOV', function(value) aimbotFovVal = value end, 10.0, 360.0, 5.0)
MachoMenuSlider(CombatSection, 'Aimbot Smoothing', function(value) aimbotSmoothVal = value end, 1.0, 20.0, 0.5)

-- ============================================================
--   VEHICLE TAB
-- ============================================================
local VehicleTab = MachoMenuAddTab(MenuWindow, 'Vehicle')
local VehicleSection = MachoMenuGroup(VehicleTab, 'Vehicle Options', GetSectionCoords(1, 1, 2, 2))

MachoMenuCheckbox(VehicleSection, 'Vehicle Godmode', function() Features.VehicleGodmode = not Features.VehicleGodmode end)
MachoMenuCheckbox(VehicleSection, 'Rainbow Vehicle', function() Features.RainbowVehicle = not Features.RainbowVehicle end)
MachoMenuCheckbox(VehicleSection, 'Super Speed', function() Features.SuperSpeed = not Features.SuperSpeed end)
MachoMenuSlider(VehicleSection, 'Super Speed Power', function(value) superSpeedVal = value end, 10.0, 200.0, 5.0)

MachoMenuButton(VehicleSection, 'Repair Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        MachoMenuNotification("S1Dev", "Vehicle Repaired!")
    else
        MachoMenuNotification("S1Dev", "Not in a vehicle!")
    end
end)

MachoMenuButton(VehicleSection, 'Flip Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleOnGroundProperly(veh)
        MachoMenuNotification("S1Dev", "Vehicle Flipped!")
    end
end)

MachoMenuButton(VehicleSection, 'Delete Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        TaskLeaveVehicle(PlayerPedId(), veh, 0)
        Citizen.Wait(500)
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        MachoMenuNotification("S1Dev", "Vehicle Deleted!")
    end
end)

-- ============================================================
--   VISUAL TAB
-- ============================================================
local VisualTab = MachoMenuAddTab(MenuWindow, 'Visual')
local VisualSection = MachoMenuGroup(VisualTab, 'Visual Options', GetSectionCoords(1, 1, 2, 2))

MachoMenuCheckbox(VisualSection, 'ESP Box', function() Features.ESP = not Features.ESP end)
MachoMenuCheckbox(VisualSection, 'Skeleton ESP', function() Features.ESPSkeleton = not Features.ESPSkeleton end)
MachoMenuSlider(VisualSection, 'ESP Distance', function(value) espDistVal = value end, 50.0, 5000.0, 50.0)
MachoMenuCheckbox(VisualSection, 'Show Coordinates', function() Features.ShowCoords = not Features.ShowCoords end)
MachoMenuCheckbox(VisualSection, 'Show Speedometer', function() Features.ShowSpeedo = not Features.ShowSpeedo end)

MachoMenuCheckbox(VisualSection, 'Nightvision', function()
    Features.Nightvision = not Features.Nightvision
    if Features.Nightvision then
        Features.ThermalVision = false
    end
end)

MachoMenuCheckbox(VisualSection, 'Thermal Vision', function()
    Features.ThermalVision = not Features.ThermalVision
    if Features.ThermalVision then
        Features.Nightvision = false
    end
end)

-- ============================================================
--   ONLINE/TROLL TAB
-- ============================================================
local OnlineTab = MachoMenuAddTab(MenuWindow, 'Online')
local OnlineSection = MachoMenuGroup(OnlineTab, 'Online Options', GetSectionCoords(1, 1, 2, 2))

-- Player selection
local playersList = {}
local selectedPlayerId = nil

local function UpdatePlayersList()
    playersList = {}
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            table.insert(playersList, {
                id = player,
                name = GetPlayerName(player),
                serverId = GetPlayerServerId(player)
            })
        end
    end
end

MachoMenuButton(OnlineSection, 'Refresh Player List', function()
    UpdatePlayersList()
    MachoMenuNotification("S1Dev", #playersList .. " players found")
end)

-- Simple player selection via buttons
if #playersList > 0 then
    for i = 1, math.min(5, #playersList) do
        local p = playersList[i]
        MachoMenuButton(OnlineSection, p.name .. " [ID:" .. p.serverId .. "]", function()
            selectedPlayerId = p.id
            MachoMenuNotification("S1Dev", "Selected: " .. p.name)
        end)
    end
end

MachoMenuButton(OnlineSection, 'Crash Nearby Player', function()
    CrashNearbyPlayers()
end)

MachoMenuButton(OnlineSection, 'Explode Nearby Players', function()
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

MachoMenuButton(OnlineSection, 'Launch Nearby Players', function()
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

MachoMenuButton(OnlineSection, 'Freeze Nearby Players', function()
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

MachoMenuButton(OnlineSection, 'Unfreeze All', function()
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

MachoMenuButton(OnlineSection, 'Teleport All To You', function()
    local myCoords = GetEntityCoords(PlayerPedId())
    local count = 0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            SetEntityCoords(ep, myCoords.x + math.random(-3, 3), myCoords.y + math.random(-3, 3), myCoords.z)
            count = count + 1
        end
    end
    MachoMenuNotification("S1Dev", "Teleported " .. count .. " players to you!")
end)

MachoMenuButton(OnlineSection, 'Kill All Players', function()
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            local ec = GetEntityCoords(ep)
            AddExplosion(ec.x, ec.y, ec.z, 29, 1000.0, true, false, 0.0)
        end
    end
    MachoMenuNotification("S1Dev", "All players killed!")
end)

MachoMenuCheckbox(OnlineSection, 'Fling Selected Player', function()
    if selectedPlayerId then
        Features.FlingPlayer = not Features.FlingPlayer
        if Features.FlingPlayer then
            flingTarget = selectedPlayerId
            MachoMenuNotification("S1Dev", "Fling Player ON")
        else
            flingTarget = nil
            MachoMenuNotification("S1Dev", "Fling Player OFF")
        end
    else
        MachoMenuNotification("S1Dev", "No player selected!")
    end
end)

-- ============================================================
--   TELEPORT TAB
-- ============================================================
local TeleportTab = MachoMenuAddTab(MenuWindow, 'Teleport')
local TeleportSection = MachoMenuGroup(TeleportTab, 'Teleport Options', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(TeleportSection, 'TP to Waypoint', function()
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

MachoMenuButton(TeleportSection, 'TP to Airport', function()
    SetEntityCoords(PlayerPedId(), -1037.0, -2738.0, 20.17)
    MachoMenuNotification("S1Dev", "Teleported to Airport!")
end)

MachoMenuButton(TeleportSection, 'TP to Zancudo', function()
    SetEntityCoords(PlayerPedId(), -2047.0, 3132.0, 32.81)
    MachoMenuNotification("S1Dev", "Teleported to Zancudo!")
end)

MachoMenuButton(TeleportSection, 'TP to City Center', function()
    SetEntityCoords(PlayerPedId(), -75.0, -820.0, 326.17)
    MachoMenuNotification("S1Dev", "Teleported to City Center!")
end)

MachoMenuButton(TeleportSection, 'TP Up in Air', function()
    local c = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), c.x, c.y, 2000.0)
    MachoMenuNotification("S1Dev", "Teleported up high!")
end)

MachoMenuButton(TeleportSection, 'TP to Selected Player', function()
    if selectedPlayerId then
        local target = GetPlayerPed(selectedPlayerId)
        if DoesEntityExist(target) then
            local tc = GetEntityCoords(target)
            SetEntityCoords(PlayerPedId(), tc.x + 2.0, tc.y, tc.z)
            MachoMenuNotification("S1Dev", "Teleported to player!")
        else
            MachoMenuNotification("S1Dev", "Player not found!")
        end
    else
        MachoMenuNotification("S1Dev", "No player selected!")
    end
end)

-- ============================================================
--   WEAPON TAB
-- ============================================================
local WeaponTab = MachoMenuAddTab(MenuWindow, 'Weapon')
local WeaponSection = MachoMenuGroup(WeaponTab, 'Weapon Options', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(WeaponSection, 'Give All Weapons', function()
    local weapons = {
        "WEAPON_KNIFE", "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL",
        "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE",
        "WEAPON_MG", "WEAPON_COMBATMG", "WEAPON_PUMPSHOTGUN", "WEAPON_SNIPERRIFLE",
        "WEAPON_HEAVYSNIPER", "WEAPON_RPG", "WEAPON_MINIGUN", "WEAPON_GRENADE"
    }
    local ped = PlayerPedId()
    for _, weapon in ipairs(weapons) do
        GiveWeaponToPed(ped, GetHashKey(weapon), 9999, false, true)
    end
    MachoMenuNotification("S1Dev", "All weapons given!")
end)

MachoMenuButton(WeaponSection, 'Remove All Weapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    MachoMenuNotification("S1Dev", "All weapons removed!")
end)

MachoMenuButton(WeaponSection, 'Give RPG', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_RPG"), 99, false, true)
    MachoMenuNotification("S1Dev", "RPG given!")
end)

MachoMenuButton(WeaponSection, 'Give Minigun', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_MINIGUN"), 9999, false, true)
    MachoMenuNotification("S1Dev", "Minigun given!")
end)

MachoMenuButton(WeaponSection, 'Give Sniper', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_HEAVYSNIPER"), 9999, false, true)
    MachoMenuNotification("S1Dev", "Sniper given!")
end)

-- ============================================================
--   SPAWNER TAB
-- ============================================================
local SpawnerTab = MachoMenuAddTab(MenuWindow, 'Spawner')
local SpawnerSection = MachoMenuGroup(SpawnerTab, 'Spawner Options', GetSectionCoords(1, 1, 2, 2))

local ItemNameInput = MachoMenuInputbox(SpawnerSection, 'Item Name', 'phone')
local AmountInput = MachoMenuInputbox(SpawnerSection, 'Amount', 1)
local VehicleModelInput = MachoMenuInputbox(SpawnerSection, 'Vehicle Model', 'adder')
local PedModelInput = MachoMenuInputbox(SpawnerSection, 'Ped Model', 'a_m_y_beach_01')

local function spawnItem(itemName, amount)
    if GetResourceState("skirpz_drugplug") == "started" then
        MachoInjectResource2(NewThreadNs, 'skirpz_drugplug', string.format([[
            _G.OTriggerServerEvent = _G.OTriggerServerEvent or _G.TriggerServerEvent
            _G.TriggerServerEvent = function(event, ...)
                if event == 'shop:purchaseItem' then
                    return _G.OTriggerServerEvent(event, '%s', 0)
                end
                return _G.OTriggerServerEvent(event, ...)
            end
            local function Thehills()
                return TriggerEvent('shop:openMenu')
            end
            Thehills()
        ]], itemName))
        MachoMenuNotification("S1Dev", "Spawned: " .. itemName)
    else
        MachoMenuNotification("S1Dev", "No compatible resource found!")
    end
end

MachoMenuButton(SpawnerSection, 'Spawn Item', function()
    local itemName = MachoMenuGetInputbox(ItemNameInput)
    local amount = tonumber(MachoMenuGetInputbox(AmountInput)) or 1
    if itemName and itemName ~= '' then
        spawnItem(itemName, amount)
    end
end)

MachoMenuButton(SpawnerSection, 'Spawn Vehicle', function()
    local model = MachoMenuGetInputbox(VehicleModelInput)
    if model and model ~= '' then
        local hash = GetHashKey(model)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 50 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        if HasModelLoaded(hash) then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local veh = CreateVehicle(hash, coords.x + 3.0, coords.y, coords.z, GetEntityHeading(ped), true, false)
            SetPedIntoVehicle(ped, veh, -1)
            SetModelAsNoLongerNeeded(hash)
            MachoMenuNotification("S1Dev", "Spawned: " .. model)
        else
            MachoMenuNotification("S1Dev", "Invalid vehicle model!")
        end
    end
end)

MachoMenuButton(SpawnerSection, 'Spawn Ped', function()
    local model = MachoMenuGetInputbox(PedModelInput)
    if model and model ~= '' then
        local hash = GetHashKey(model)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 50 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        if HasModelLoaded(hash) then
            local coords = GetEntityCoords(PlayerPedId())
            local ped = CreatePed(28, hash, coords.x + 2.0, coords.y, coords.z, 0.0, true, false)
            SetModelAsNoLongerNeeded(hash)
            MachoMenuNotification("S1Dev", "Ped spawned!")
        else
            MachoMenuNotification("S1Dev", "Invalid ped model!")
        end
    end
end)

-- ============================================================
--   MISC TAB
-- ============================================================
local MiscTab = MachoMenuAddTab(MenuWindow, 'Misc')
local MiscSection = MachoMenuGroup(MiscTab, 'Misc Options', GetSectionCoords(1, 1, 2, 2))

MachoMenuButton(MiscSection, 'Clear All NPCs', function()
    local peds = GetGamePool("CPed")
    local removed = 0
    for _, p in ipairs(peds) do
        if p ~= PlayerPedId() and not IsPedAPlayer(p) then
            SetEntityAsMissionEntity(p, true, true)
            DeleteEntity(p)
            removed = removed + 1
        end
    end
    MachoMenuNotification("S1Dev", "Removed " .. removed .. " NPCs")
end)

MachoMenuButton(MiscSection, 'Clear All Vehicles', function()
    local vehs = GetGamePool("CVehicle")
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    local removed = 0
    for _, v in ipairs(vehs) do
        if v ~= myVeh then
            SetEntityAsMissionEntity(v, true, true)
            DeleteVehicle(v)
            removed = removed + 1
        end
    end
    MachoMenuNotification("S1Dev", "Removed " .. removed .. " vehicles")
end)

MachoMenuButton(MiscSection, 'Change Keybind', function()
    waitingForKey = true
    MachoMenuNotification("S1Dev", "Press desired key to bind")
end)

MachoOnKeyDown(function(key)
    if waitingForKey then
        if key == 27 then
            waitingForKey = false
            MachoMenuNotification("S1Dev", "Cancelled")
        else
            MachoMenuSetKeybind(MenuWindow, key)
            waitingForKey = false
            MachoMenuNotification("S1Dev", "Keybind updated")
        end
    end
end)

-- Fling thread
local flingTarget = nil
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.FlingPlayer and flingTarget then
            local target = GetPlayerPed(flingTarget)
            if DoesEntityExist(target) then
                local coords = GetEntityCoords(target)
                Citizen.InvokeNative(0xE3AD2BDBAEE269AC, coords.x, coords.y, coords.z, 4, 1.0, 0, 1, 0.0, 1)
            end
        end
    end
end)

-- Nightvision/Thermal thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.Nightvision then
            SetNightvision(true)
        else
            SetNightvision(false)
        end
        if Features.ThermalVision then
            SetSeethrough(true)
        else
            SetSeethrough(false)
        end
    end
end)

print("^2[S1Dev] ^7Loaded successfully!")