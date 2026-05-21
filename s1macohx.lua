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
}

local Settings = {
    NoclipSpeed    = 7.0,
    FreecamSpeed   = 7.0,
    AimbotFOV      = 100.0,
    AimbotSmoothing= 5.0,
    SuperSpeedVal  = 80.0,
}

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
            
            local spd = Settings.NoclipSpeed * 0.05
            if IsControlPressed(0, 21) then spd = spd * 3.0 end
            
            local c = GetEntityCoords(entity)
            local nx, ny, nz = c.x, c.y, c.z
            
            if IsControlPressed(0, 32) then  -- W
                nx = nx + dx * spd
                ny = ny + dy * spd
                nz = nz + dz * spd
            end
            if IsControlPressed(0, 33) then  -- S
                nx = nx - dx * spd
                ny = ny - dy * spd
                nz = nz - dz * spd
            end
            if IsControlPressed(0, 22) then  -- Space
                nz = nz + spd
            end
            if IsControlPressed(0, 36) then  -- Ctrl
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
    
    -- Try all common revive events
    TriggerServerEvent('esx_ambulancejob:revive', myId)
    TriggerServerEvent('esx_ambulancejob:revivePlayer', myId)
    TriggerServerEvent('esx-ambulancejob:revive', myId)
    TriggerServerEvent('esx-ambulancejob:revivePlayer', myId)
    TriggerServerEvent('hospital:revive', myId)
    TriggerServerEvent('qb-ambulancejob:server:RevivePlayer', myId)
    TriggerServerEvent('qb-ambulancejob:revive', myId)
    TriggerEvent('RespectEMS:triggers:client:revivePlayer')
    
    -- Direct revive
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
                SetVehicleEnginePowerMultiplier(veh, Settings.SuperSpeedVal / 10.0)
                SetVehicleEngineTorqueMultiplier(veh, Settings.SuperSpeedVal / 10.0)
            end
        end
    end
end)

-- ============================================================
--   INFINITE AMMO THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.InfAmmo then
            local ped = PlayerPedId()
            SetPedInfiniteAmmoClip(ped, true)
            SetPedInfiniteAmmo(ped, true, 0)
        end
    end
end)

-- ============================================================
--   NEVER WANTED THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.NeverWanted then
            ClearPlayerWantedLevel(PlayerId())
            SetMaxWantedLevel(0)
        end
    end
end)

-- ============================================================
--   NO RAGDOLL THREAD
-- ============================================================
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
--   SHOW SPEEDO THREAD
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.ShowSpeedo then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local speed = math.floor(GetEntitySpeed(veh) * 3.6)
                SetTextFont(7)
                SetTextScale(0.45, 0.45)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(speed .. " km/h")
                EndTextCommandDisplayText(0.5, 0.91)
            end
        end
    end
end)

-- ============================================================
--   MAGNETO MODE THREAD
-- ============================================================
local magnetoActive = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Features.MagnetoMode then
            if not magnetoActive then
                magnetoActive = true
                MachoMenuNotification("S1Dev", "Magneto Mode ON - Press E to attract/push")
            end
            
            local forceEnabled = false
            local startPush = false
            local keyPressed = false
            local keyTimer = 0
            
            while Features.MagnetoMode do
                Citizen.Wait(0)
                if keyPressed then
                    keyTimer = keyTimer + 1
                    if keyTimer >= 15 then
                        keyTimer = 0
                        keyPressed = false
                    end
                end
                
                if IsDisabledControlJustPressed(0, 38) and not keyPressed then
                    keyPressed = true
                    if not forceEnabled then
                        forceEnabled = true
                        startPush = false
                    else
                        startPush = true
                        forceEnabled = false
                    end
                end
                
                if startPush then
                    startPush = false
                    local pid = PlayerPedId()
                    local camRot = GetGameplayCamRot(2)
                    local fx = -(math.sin(math.rad(camRot.z)) * 20)
                    local fy = (math.cos(math.rad(camRot.z)) * 20)
                    local fz = 20 * (camRot.x * 0.2)
                    local playerVeh = GetVehiclePedIsIn(pid, false)
                    
                    for _, k in ipairs(GetGamePool("CVehicle")) do
                        SetEntityInvincible(k, false)
                        if IsEntityOnScreen(k) and k ~= playerVeh then
                            NetworkRequestControlOfEntity(k)
                            ApplyForceToEntity(k, 1, fx, fy, fz, 0, 0, 0, true, false, true, true, true, true)
                        end
                    end
                    for _, k in ipairs(GetGamePool("CPed")) do
                        if IsEntityOnScreen(k) and k ~= pid then
                            NetworkRequestControlOfEntity(k)
                            ApplyForceToEntity(k, 1, fx, fy, fz, 0, 0, 0, true, false, true, true, true, true)
                        end
                    end
                end
                
                if forceEnabled then
                    local pid = PlayerPedId()
                    local playerVeh = GetVehiclePedIsIn(pid, false)
                    local camRot = GetGameplayCamRot(2)
                    local camPos = GetGameplayCamCoord()
                    local rad = 0.01745329
                    local rx = camRot.x * rad
                    local rz = camRot.z * rad
                    local fdx = -math.sin(rz) * math.cos(rx)
                    local fdy = math.cos(rz) * math.cos(rx)
                    local fdz = math.sin(rx)
                    local mx = camPos.x + fdx * 20
                    local my = camPos.y + fdy * 20
                    local mz = camPos.z + fdz * 20
                    
                    for _, k in ipairs(GetGamePool("CVehicle")) do
                        if IsEntityOnScreen(k) and k ~= playerVeh then
                            NetworkRequestControlOfEntity(k)
                            SetEntityInvincible(k, true)
                            FreezeEntityPosition(k, false)
                            local kp = GetEntityCoords(k)
                            ApplyForceToEntity(k, 1, (mx-kp.x)*0.8, (my-kp.y)*0.8, (mz-kp.z)*0.8, 0, 0, 0, true, false, true, true, true, true)
                        end
                    end
                    for _, k in ipairs(GetGamePool("CPed")) do
                        if IsEntityOnScreen(k) and k ~= pid then
                            NetworkRequestControlOfEntity(k)
                            FreezeEntityPosition(k, false)
                            SetPedToRagdoll(k, 4000, 5000, 0, true, true, true)
                            local kp = GetEntityCoords(k)
                            ApplyForceToEntity(k, 1, (mx-kp.x)*0.8, (my-kp.y)*0.8, (mz-kp.z)*0.8, 0, 0, 0, true, false, true, true, true, true)
                        end
                    end
                end
            end
            magnetoActive = false
        else
            magnetoActive = false
        end
    end
end)

-- ============================================================
--   FLING PLAYER THREAD
-- ============================================================
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
                        
                        if dist <= Features.ESPDistance then
                            if Features.ESP then
                                -- Draw line to player
                                DrawLine(myPos.x, myPos.y, myPos.z, pedCoords.x, pedCoords.y, pedCoords.z, r, g, b, 80)
                                
                                -- Draw name and health
                                local head = GetPedBoneCoords(tp, 31086, 0, 0, 0)
                                local onScreen, sx, sy = World3dToScreen2d(head.x, head.y, head.z + 0.25)
                                if onScreen then
                                    local hp = math.max(0, GetEntityHealth(tp) - 100)
                                    local mxhp = math.max(1, GetEntityMaxHealth(tp) - 100)
                                    local hpP = hp / mxhp
                                    local er = math.floor((1 - hpP) * 255)
                                    local eg = math.floor(hpP * 215)
                                    
                                    SetTextFont(4)
                                    SetTextScale(0.27, 0.27)
                                    SetTextColour(255, 255, 255, 230)
                                    SetTextCentre(true)
                                    BeginTextCommandDisplayText("STRING")
                                    AddTextComponentSubstringPlayerName(GetPlayerName(player))
                                    EndTextCommandDisplayText(sx, sy)
                                    
                                    SetTextFont(0)
                                    SetTextScale(0.22, 0.22)
                                    SetTextColour(er, eg, 40, 200)
                                    SetTextCentre(true)
                                    BeginTextCommandDisplayText("STRING")
                                    AddTextComponentSubstringPlayerName(math.floor(dist) .. "m")
                                    EndTextCommandDisplayText(sx, sy + 0.018)
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
--   NIGHTVISION/THERMAL THREAD
-- ============================================================
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

-- ============================================================
--   WAVESHIELD BYPASS
-- ============================================================
local function WaveShieldBypass()
    local success, result = pcall(function()
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
        
        local crashProtection = [[
            local origError = error
            _G.error = function(msg)
                if msg and (msg:find('crash') or msg:find('detected') or msg:find('anticheat')) then
                    print('^2[S1Dev] ^7Blocked crash attempt')
                    return
                end
                return origError(msg)
            end
        ]]
        MachoInjectResourceRaw('_G', crashProtection)
        return waveshieldFound
    end)
    
    if success and result then
        MachoMenuNotification("S1Dev", "WaveShield Bypass Successful!")
    elseif success and not result then
        MachoMenuNotification("S1Dev", "No WaveShield Detected")
    else
        MachoMenuNotification("S1Dev", "Bypass Applied")
    end
    return success
end

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

local name, ac = detectAntiCheat()

-- ============================================================
--   MENU SYSTEM
-- ============================================================
local MenuSize = vec2(480, 360)
local screenW, screenH = GetActiveScreenResolution()
local MenuStartCoords = vec2(screenW / 2 - MenuSize.x / 2, screenH / 2 - MenuSize.y / 2)
local TabsBarWidth = 120.0
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

-- Godmode
MachoMenuCheckbox(MainSection, 'Godmode', function() Features.Godmode = not Features.Godmode end)

-- Noclip
MachoMenuCheckbox(MainSection, 'Noclip', function() ToggleNoclip() end)

-- Noclip Speed Slider
local NoclipSpeedSlider = MachoMenuSlider(MainSection, 'Noclip Speed', 0.5, 20.0, 0.5)
MachoMenuSliderValue(NoclipSpeedSlider, function(value) Settings.NoclipSpeed = value end)

-- Super Jump
MachoMenuCheckbox(MainSection, 'Super Jump', function() Features.SuperJump = not Features.SuperJump end)

-- Fast Run
MachoMenuCheckbox(MainSection, 'Fast Run', function() Features.FastRun = not Features.FastRun end)

-- Invisible
MachoMenuCheckbox(MainSection, 'Invisible', function() Features.Invisible = not Features.Invisible end)

-- No Ragdoll
MachoMenuCheckbox(MainSection, 'No Ragdoll', function() Features.NoRagdoll = not Features.NoRagdoll end)

-- Never Wanted
MachoMenuCheckbox(MainSection, 'Never Wanted', function() Features.NeverWanted = not Features.NeverWanted end)

-- Revive Button
MachoMenuButton(MainSection, 'Revive', function() ReviveSelf() end)

-- Heal Button
MachoMenuButton(MainSection, 'Heal', function()
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    MachoMenuNotification("S1Dev", "Healed!")
end)

-- ============================================================
--   COMBAT TAB
-- ============================================================
local CombatTab = MachoMenuAddTab(MenuWindow, 'Combat')
local CombatSection = MachoMenuGroup(CombatTab, 'Combat Options', GetSectionCoords(1, 1, 2, 2))

-- One Shot Kill
MachoMenuCheckbox(CombatSection, 'One Shot Kill', function() Features.OneShot = not Features.OneShot end)

-- Rapid Fire
MachoMenuCheckbox(CombatSection, 'Rapid Fire', function() Features.RapidFire = not Features.RapidFire end)

-- Infinite Ammo
MachoMenuCheckbox(CombatSection, 'Infinite Ammo', function() Features.InfAmmo = not Features.InfAmmo end)

-- No Recoil
MachoMenuCheckbox(CombatSection, 'No Recoil', function() Features.NoRecoil = not Features.NoRecoil end)

-- Magneto Mode
MachoMenuCheckbox(CombatSection, 'Magneto Mode', function() Features.MagnetoMode = not Features.MagnetoMode end)

-- Aimbot FOV Slider
local AimbotFOVSlider = MachoMenuSlider(CombatSection, 'Aimbot FOV', 10.0, 360.0, 5.0)
MachoMenuSliderValue(AimbotFOVSlider, function(value) Settings.AimbotFOV = value end)

-- Aimbot Smoothing Slider
local AimbotSmoothSlider = MachoMenuSlider(CombatSection, 'Aimbot Smoothing', 1.0, 20.0, 0.5)
MachoMenuSliderValue(AimbotSmoothSlider, function(value) Settings.AimbotSmoothing = value end)

-- ============================================================
--   VEHICLE TAB
-- ============================================================
local VehicleTab = MachoMenuAddTab(MenuWindow, 'Vehicle')
local VehicleSection = MachoMenuGroup(VehicleTab, 'Vehicle Options', GetSectionCoords(1, 1, 2, 2))

-- Vehicle Godmode
MachoMenuCheckbox(VehicleSection, 'Vehicle Godmode', function() Features.VehicleGodmode = not Features.VehicleGodmode end)

-- Rainbow Vehicle
MachoMenuCheckbox(VehicleSection, 'Rainbow Vehicle', function() Features.RainbowVehicle = not Features.RainbowVehicle end)

-- Super Speed
MachoMenuCheckbox(VehicleSection, 'Super Speed', function() Features.SuperSpeed = not Features.SuperSpeed end)

-- Super Speed Value Slider
local SuperSpeedSlider = MachoMenuSlider(VehicleSection, 'Super Speed Power', 10.0, 200.0, 5.0)
MachoMenuSliderValue(SuperSpeedSlider, function(value) Settings.SuperSpeedVal = value end)

-- Repair Vehicle
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

-- Flip Vehicle
MachoMenuButton(VehicleSection, 'Flip Vehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleOnGroundProperly(veh)
        MachoMenuNotification("S1Dev", "Vehicle Flipped!")
    end
end)

-- Delete Vehicle
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

-- ESP
MachoMenuCheckbox(VisualSection, 'ESP Box', function() Features.ESP = not Features.ESP end)

-- Skeleton ESP
MachoMenuCheckbox(VisualSection, 'Skeleton ESP', function() Features.ESPSkeleton = not Features.ESPSkeleton end)

-- ESP Distance Slider
local ESPDistanceSlider = MachoMenuSlider(VisualSection, 'ESP Distance', 50.0, 5000.0, 50.0)
MachoMenuSliderValue(ESPDistanceSlider, function(value) Features.ESPDistance = value end)

-- Show Coordinates
MachoMenuCheckbox(VisualSection, 'Show Coordinates', function() Features.ShowCoords = not Features.ShowCoords end)

-- Show Speedometer
MachoMenuCheckbox(VisualSection, 'Show Speedometer', function() Features.ShowSpeedo = not Features.ShowSpeedo end)

-- Nightvision
MachoMenuCheckbox(VisualSection, 'Nightvision', function()
    Features.Nightvision = not Features.Nightvision
    if Features.Nightvision then
        Features.ThermalVision = false
    end
end)

-- Thermal Vision
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

-- Player Selection (simple dropdown style)
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

-- Refresh button
MachoMenuButton(OnlineSection, 'Refresh Player List', function()
    UpdatePlayersList()
    MachoMenuNotification("S1Dev", "Player list refreshed - " .. #playersList .. " players found")
end)

-- Player selection dropdown
if #playersList > 0 then
    local playerNames = {}
    for i, p in ipairs(playersList) do
        playerNames[i] = p.name .. " [ID:" .. p.serverId .. "]"
    end
    local playerSelect = MachoMenuDropdown(OnlineSection, 'Select Player', playerNames, 1)
    MachoMenuDropdownValue(playerSelect, function(index, value)
        if playersList[index] then
            selectedPlayerId = playersList[index].id
            MachoMenuNotification("S1Dev", "Selected: " .. playersList[index].name)
        end
    end)
end

-- Crash Nearby Button
MachoMenuButton(OnlineSection, 'Crash Nearby Player', function()
    CrashNearbyPlayers()
end)

-- Explode Nearby Players
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

-- Launch Nearby Players
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

-- Freeze Nearby Players
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

-- Unfreeze All
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

-- Ragdoll Nearby Players
MachoMenuButton(OnlineSection, 'Ragdoll Nearby Players', function()
    local myCoords = GetEntityCoords(PlayerPedId())
    local count = 0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ep = GetPlayerPed(player)
            local ec = GetEntityCoords(ep)
            local dist = #(myCoords - ec)
            if dist < 80.0 then
                SetPedToRagdoll(ep, 3000, 3000, 0, true, true, false)
                count = count + 1
            end
        end
    end
    MachoMenuNotification("S1Dev", "Ragdolled " .. count .. " players!")
end)

-- Teleport All To You
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

-- Kill All Players
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

-- Fling Selected Player
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

-- TP to Waypoint
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

-- TP to Airport
MachoMenuButton(TeleportSection, 'TP to Airport (LSIA)', function()
    SetEntityCoords(PlayerPedId(), -1037.0, -2738.0, 20.17)
    MachoMenuNotification("S1Dev", "Teleported to Airport!")
end)

-- TP to Zancudo
MachoMenuButton(TeleportSection, 'TP to Zancudo Base', function()
    SetEntityCoords(PlayerPedId(), -2047.0, 3132.0, 32.81)
    MachoMenuNotification("S1Dev", "Teleported to Zancudo!")
end)

-- TP to City Center
MachoMenuButton(TeleportSection, 'TP to City Center', function()
    SetEntityCoords(PlayerPedId(), -75.0, -820.0, 326.17)
    MachoMenuNotification("S1Dev", "Teleported to City Center!")
end)

-- TP Up in Air
MachoMenuButton(TeleportSection, 'TP Up in Air', function()
    local c = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), c.x, c.y, 2000.0)
    MachoMenuNotification("S1Dev", "Teleported up high!")
end)

-- TP to Selected Player
MachoMenuButton(TeleportSection, 'TP to Selected Player', function()
    if selectedPlayerId then
        local target = GetPlayerPed(selectedPlayerId)
        if DoesEntityExist(target) then
            local tc = GetEntityCoords(target)
            SetEntityCoords(PlayerPedId(), tc.x + 2.0, tc.y, tc.z)
            MachoMenuNotification("S1Dev", "Teleported to selected player!")
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

-- Give All Weapons
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

-- Remove All Weapons
MachoMenuButton(WeaponSection, 'Remove All Weapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    MachoMenuNotification("S1Dev", "All weapons removed!")
end)

-- Give RPG
MachoMenuButton(WeaponSection, 'Give RPG', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_RPG"), 99, false, true)
    MachoMenuNotification("S1Dev", "RPG given!")
end)

-- Give Minigun
MachoMenuButton(WeaponSection, 'Give Minigun', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_MINIGUN"), 9999, false, true)
    MachoMenuNotification("S1Dev", "Minigun given!")
end)

-- Give Sniper
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

-- Spawn Vehicle
local VehicleModelInput = MachoMenuInputbox(SpawnerSection, 'Vehicle Model', 'adder')

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

-- Spawn Ped (NPC)
local PedModelInput = MachoMenuInputbox(SpawnerSection, 'Ped Model', 'a_m_y_beach_01')

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

-- WaveShield Bypass
MachoMenuButton(MiscSection, 'WaveShield Bypass', function()
    WaveShieldBypass()
end)

-- Anti-Cheat Scanner
MachoMenuButton(MiscSection, 'Check Anti-Cheat', function()
    local name, ac = detectAntiCheat()
    if ac then
        MachoMenuNotification("S1Dev", "Detected: " .. ac .. " (" .. name .. ")")
    else
        MachoMenuNotification("S1Dev", "No known Anti-Cheat detected")
    end
end)

-- Clear NPCs
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

-- Clear Vehicles
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

-- Change Keybind
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

-- ============================================================
--   SPAWNER FUNCTIONS (from original script)
-- ============================================================
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
        MachoMenuNotification("S1Dev", "Spawned: " .. itemName .. " x" .. amount)
    elseif GetResourceState("ak47_druglabs") == "started" then
        MachoInjectResource2(NewThreadNs, 'ak47_druglabs', string.format([[
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            _G.Config.CircleZones = {{xItem = '%s', xLabel = 'S1Dev', collectDelay = 0, marker = {collect = {enable = true, type = 2, size = {x = 1.5, y = 1.5, z = 1.0}, color = {r = 0, g = 0, b = 0, a = 0}}, process = {enable = false}}, collect = {{pos = vector3(coords), heading = heading, quantity = %d}}, process = {}}}
        ]], itemName, amount))
        MachoMenuNotification("S1Dev", "Spawned: " .. itemName .. " x" .. amount)
    else
        MachoMenuNotification("S1Dev", "No compatible resource found!")
    end
end

-- Spawn Item Button
MachoMenuButton(SpawnerSection, 'Spawn Item', function()
    local itemName = MachoMenuGetInputbox(ItemNameInput)
    local amount = tonumber(MachoMenuGetInputbox(AmountInput)) or 1
    if itemName and itemName ~= '' then
        spawnItem(itemName, amount)
    end
end)

print("^2[S1Dev] ^7Loaded successfully!")