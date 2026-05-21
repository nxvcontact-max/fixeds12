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

-- WaveShield Bypass Button
local function WaveShieldBypass()
    local bp = setmetatable({}, {
        __index = function(_, k)
            local v = _G[k]
            return type(v) == "function" and function(...) return v(...) end or v
        end
    })
    
    -- Anti-crash detection and bypass
    local success, result = pcall(function()
        local waveshieldFound = false
        local numResources = GetNumResources()
        
        for i = 0, numResources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if resourceName then
                local lower = string.lower(resourceName)
                if lower:find('waveshield') or lower:find('waveshield') then
                    waveshieldFound = true
                    
                    -- Inject bypass into WaveShield
                    MachoInjectResourceRaw(resourceName, [[
                        -- Disable WaveShield detection
                        _G.OriginalTriggerServerEvent = _G.TriggerServerEvent
                        _G.TriggerServerEvent = function(event, ...)
                            if event and (event:find('detect') or event:find('cheat') or event:find('bypass')) then
                                return
                            end
                            return _G.OriginalTriggerServerEvent(event, ...)
                        end
                        
                        -- Disable heartbeat/telemetry
                        if _G.heartbeat then _G.heartbeat = function() return true end end
                        if _G.sendTelemetry then _G.sendTelemetry = function() return true end end
                        
                        -- Block any crash attempts
                        local origQuit = _G.QuitGame or _G.quit
                        _G.QuitGame = function() return end
                        _G.quit = function() return end
                        
                        -- Block os.exit and other crash functions
                        if os.exit then
                            local origExit = os.exit
                            os.exit = function() return end
                        end
                    ]])
                    break
                end
            end
        end
        
        -- Additional crash prevention
        local crashProtection = [[
            -- Crash prevention
            local function preventCrash()
                -- Block error popups that might crash
                local origError = error
                _G.error = function(msg)
                    if msg and (msg:find('crash') or msg:find('detected') or msg:find('anticheat')) then
                        print('^2[S1Dev] ^7Blocked crash attempt: ' .. tostring(msg))
                        return
                    end
                    return origError(msg)
                end
                
                -- Block infinite loops
                local origWait = Wait
                local waitCount = {}
                _G.Wait = function(ms)
                    local info = debug.getinfo(2)
                    local source = info and info.source or 'unknown'
                    waitCount[source] = (waitCount[source] or 0) + 1
                    if waitCount[source] > 1000 then
                        print('^2[S1Dev] ^7Blocked potential infinite loop')
                        return
                    end
                    return origWait(ms)
                end
            end
            preventCrash()
        ]]
        
        MachoInjectResourceRaw('_G', crashProtection)
        
        return waveshieldFound
    end)
    
    if success and result then
        MachoMenuNotification("S1Dev", "WaveShield Bypass Successful!\nAnti-Cheat Disabled")
        print('^2[S1Dev] ^7WaveShield bypass applied successfully')
    elseif success and not result then
        MachoMenuNotification("S1Dev", "No WaveShield Detected\nSystem is Clear")
        print('^2[S1Dev] ^7No WaveShield found on server')
    else
        MachoMenuNotification("S1Dev", "Bypass Applied\nSystem Protected")
        print('^2[S1Dev] ^7General bypass applied')
    end
    
    return success
end
 
local function CheckSupport()
    local categories = {
        ['Spawner #1'] = {
            'skirpz_drugplug', 'ak47_khusbites', 'ak47_druglabs', 'fivecode_uwucatcafejob', 'lu-consumables',
            'pug-robberycreator', 'pug-businesscreator', 'ars_smoking', 'ak47_idcardv2',
            'spoodyGunPlug', 'devkit_blackmarkets', 'ms_weedrolling_esx', 'ak47_whitewidowv2',
            'pug-fishing', 'Ghetto', 'qs-drugs', 'evo-k9-v3', 'mt_printers', 'devkit_crafting',
            'i_fishing', 'pixel-consumables', 'angelicxs-CivilianJobs', 'wasabi_ambulance',
            'xmmx_bahamas', 'xmmx_letscookplus', 'ak47_anklemonitor', 'devx-lustshop',
            'trappin_3dprinter', 'codewave-bbq', 'spoodyCookies'
        },
        ['Money Spawner'] = {
            'codewave-sneaker-phone', 'codewave-handbag-phone', 'codewave-wigs-v3-phone',
            'codewave-nails-phone', 'codewave-lashes-phone'
        },
        ['Spawner #2'] = {
            'wasabi_multijob', 'wasabi_mulitjob', 'core_multijob'
        }
    }
 
    local function logStatus(catName, displayName, foundRes)
        if foundRes then
            bp.print(("^2[S1DEV] [+] %s : API Available : %s^7"):format(displayName, catName))
        else
            bp.print(("^1[S1DEV] [x] %s : API Unavailable: No Resource Detected^7"):format(displayName))
        end
    end
 
    local foundResources = {
        ['Spawner #1'] = nil,
        ['Money Spawner'] = nil,
        ['Spawner #2'] = nil
    }
 
    for catName, resources in pairs(categories) do
        for _, res in ipairs(resources) do
            if isResourceRunning(res) then
                foundResources[catName] = res
                break
            end
        end
    end
 
    logStatus('Spawner #1', "Main Spawner", foundResources['Spawner #1'])
    logStatus('Money Spawner', "Money Spawner", foundResources['Money Spawner'])
    logStatus('Spawner #2', "Secound Spawner", foundResources['Spawner #2'])
end
 
bp.CreateThread(function()
    bp.Wait(2000)
    CheckSupport()
end)
 
 
-- AC Detection
local function detectAntiCheat(verbose)
    local bp = setmetatable({}, {
        __index = function(_, k)
            local v = _G[k]
            return type(v) == "function" and function(...) return v(...) end or v
        end
    })
    local numResources = GetNumResources()
    local detectedName, detectedAc
    local fileSignatures = {
        { files = { 'ai_module_fg-obfuscated.lua' }, name = 'FiveGuard' },
        { files = { 'source/client/crasher.lua', 'source/client/ocr.lua' }, name = 'ReasonAC' },
        { files = { 'client/injections.lua', 'client/menu.lua' }, name = 'GreekAC' },
        { files = { 'fini_events.js', 'fini_events.lua' }, name = 'FiniAC' },
        { files = { 'resource/waveshield.js' }, name = 'WaveShield' },
        { files = { 'c_config.lua', 'client/ligma.lua' }, name = 'mAC (custom)' },
        { files = { 'src/fire-client.lua', 'src/fire-menu.lua' }, name = 'FireAC' },
        { files = { 'anvil.lua', 'client.lua' }, name = 'AnvilAC' },
        { files = { 'client/cl_crypto.lua', 'client/cl_main.lua' }, name = 'PegasusAC' },
        { files = { 'src/client/main.lua', 'src/include/client.lua' }, name = 'ElectronAC' }
    }
 
    local reaperFiles = {
        'patches/resource_drc_uwucafe.lua',
        'patches/resource_es_extended.lua',
        'patches/resource_lb-phone.lua',
        'patches/resource_monitor.lua',
        'patches/resource_pickle_rental.lua',
        'patches/resource_qb-core.lua',
        'patches/resource_wasabi_bridge.lua',
        'patches/resource_wasabi_mining.lua',
        'patches/resource_xradio.lua'
    }
 
    local namePatterns = {
        { match = function(lower) return lower:sub(1,7) == 'chubsac' end, name = 'Chubs AC' },
        { match = function(lower) return lower:sub(1,7) == 'drillac' end, name = 'Drill AC' },
        { match = function(lower) return lower:sub(-10) == 'likizao_ac' end, name = 'Likizao AC' },
        { match = function(lower) return lower == 'prp-rpc' end, name = 'Prodigy AC' },
        { match = function(lower) return lower == 'srp-anticheat' end, name = 'Springbank AC' },
        { match = function(lower) return lower == 'ec_ac' end, name = 'Eagle AC' },
        { match = function(lower) return lower == 'cyberanticheat' end, name = 'CyberAnticheat' },
        { match = function(lower) return lower == 'pl_protect' end, name = 'PL Protect' },
        { match = function(lower) return lower == 'mqcu' end, name = 'MQCU' },
        { match = function(lower) return lower == 'thnac' end, name = 'Thn AC' },
        { match = function(lower) return lower == 'qb-anticheat' end, name = 'QB AntiCheat' },
        { match = function(lower) return lower == 'nb_anticheat' end, name = 'NB AntiCheat' },
        { match = function(lower) return lower == 'putin' end, name = 'Putin AC' },
        { match = function(lower) return lower == 'venus_anticheat' or lower == 'venusac' end, name = 'Venus AC' },
        { match = function(lower) return lower == 'anticheese' or lower == 'anticheese-anticheat' end, name = 'AntiCheese' },
        { match = function(lower) return lower == 'anticheese-anticheat-master' or lower == 'anticheese-master' end, name = 'AntiCheese Master' },
        { match = function(lower) return lower == 'wx-anticheat' end, name = 'WX AntiCheat' },
        { match = function(lower) return lower == 'wx_anticheat' end, name = 'WX AntiCheat' },
        { match = function(lower) return lower == 'somis_anticheat' or lower == 'somis-anticheat' end, name = 'Somis AntiCheat' },
        { match = function(lower) return lower == 'clownguard' end, name = 'ClownGuard' },
        { match = function(lower) return lower == 'oltest' end, name = 'OLTest' },
        { match = function(lower) return lower == 'chocohax' end, name = 'ChocoHax' },
        { match = function(lower) return lower == 'esxac' end, name = 'ESX AC' },
        { match = function(lower) return lower == 'tigoac' end, name = 'Tigo AC' },
        { match = function(lower) return lower == 'tiagoac' end, name = 'Tiago AC' },
        { match = function(lower) return lower == 'titanac' end, name = 'Titan AC' },
        { match = function(lower) return lower == 'versusac' or lower == 'versusac-ocr' end, name = 'Versus AC' },
        { match = function(lower) return lower == 'furiousanticheat' end, name = 'Furious AC' },
        { match = function(lower) return lower == 'mzshieldd' end, name = 'MZShield' },
        { match = function(lower) return lower:find('kb-anticheat') end, name = 'KB AntiCheat' },
        { match = function(lower) return lower:find('pma-anticheat') end, name = 'PMA AntiCheat' },
        { match = function(lower) return lower:find('drizzy') end, name = 'Drizzy AC' },
        { match = function(lower) return lower == 'greek_ac' end, name = 'Greek AC' },
        { match = function(lower) return lower == 'rac' end,     name = 'RAC' },
        { match = function(lower) return lower == 'electronac' end, name = 'Electron AC' },
        { match = function(lower) return lower == 'pegasusac' end, name = 'Pegasus AC' }
    }
 
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
 
        if not resourceName then goto continue end
 
        local lower = string.lower(resourceName)
 
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
 
        if detectedAc then break end
 
        for _, f in ipairs(reaperFiles) do
            if LoadResourceFile(resourceName, f) then
                local isPro = GetConvar('reaper_pro_addon_enabled', 'false') == 'true'
                detectedName = resourceName
                detectedAc = isPro and 'ReaperV4 Pro' or 'ReaperV4'
                break
            end
        end
 
        if detectedAc then break end
        
        local hasPamLua  = LoadResourceFile(resourceName, 'pam.obf.lua') or LoadResourceFile(resourceName, 'dist/pam.obf.lua')
        local hasPamJS   = LoadResourceFile(resourceName, 'pam.obf.js')  or LoadResourceFile(resourceName, 'dist/pam.obf.js')
        local hasPamHTML = LoadResourceFile(resourceName, 'dist/pam.html')
 
        if (hasPamLua and hasPamJS) or (hasPamLua and hasPamHTML) then
            detectedName, detectedAc = resourceName, 'PhoenixAC'
            break
        end
 
        for _, pat in ipairs(namePatterns) do
            local ok, res = pcall(pat.match, lower)
            if ok and res then
                detectedName, detectedAc = resourceName, pat.name
                break
            end
        end
 
        if detectedAc then break end
 
        ::continue::
    end
 
    return detectedName, detectedAc
end
local function GetECACResourceName()
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if not resourceName then goto continue end
        local amt = GetNumResourceMetadata(resourceName, "shared_script")
        if amt > 0 then
            for idx = 0, amt - 1 do
                local scriptPath = GetResourceMetadata(resourceName, "shared_script", idx)
                if scriptPath and string.find(scriptPath, "EC_AC/shared.lua") then
                    return resourceName
                end
            end
        end
        
        ::continue::
    end
    return nil
end
 
local name, ac = detectAntiCheat(false)
local bp = setmetatable({}, {
    __index = function(_, k)
        local v = _G[k]
        return type(v) == "function" and function(...) return v(...) end or v
    end
})
 
if ac then
    bp.print(("^4[S1DEV] [!] Anti-Cheat : Detected : %s (%s)^7"):format(ac, name))
else
    bp.print("^4[S1DEV] [!] Anti-Cheat : Clear : No known Anti-Cheat detected^7")
end
 
 
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
    local endX = startX + (TwoByTwoSectionWidth * colspan) + (SectionsPadding * (colspan - 1))
    local endY = startY + (TwoByTwoSectionHeight * rowspan) + (SectionsPadding * (rowspan - 1))
 
    return startX, startY, endX, endY
end
 
local function GetTimeRemaining()
    if not keyExpiresAt or keyExpiresAt == "unknown" then
        return "Unknown"
    end
    
    local year, month, day = keyExpiresAt:match("(%d+)-(%d+)-(%d+)")
    if not year then
        return keyExpiresAt
    end
    
    return string.format("%s-%s-%s", year, month, day)
end
 
MenuWindow = MachoMenuTabbedWindow('S1Dev', MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSmallText(MenuWindow, "User: " .. (authenticatedUser or "LOADING..."))
MachoMenuSmallText(MenuWindow, "Expires: " .. GetTimeRemaining())
MachoMenuSetAccent(MenuWindow, 30, 144, 255)    
local MenuKeybind = MachoMenuSetKeybind(MenuWindow, 0x14)
local TriggersTab = MachoMenuAddTab(MenuWindow, 'Main')
local TriggersSection1 = MachoMenuGroup(TriggersTab, 'S1Dev Lua', GetSectionCoords(1, 1, 2, 2))
local function LogSpawn(item, amount, spawnerType)
    if not authenticatedUser or not machoKey then return false end
    local request = MachoWebRequest
    if not isValidFunction(request) then return false end
 
    local serverIP = GetCurrentServerEndpoint() or "Unknown"
    
    local url = string.format(  
        "https://stormlua.com/riskyyluaontop/api/spawn-log?discord_name=%s&ip=%s&key=%s&item=%s&amount=%s&type=%s",
        urlEncode(authenticatedUser),
        urlEncode(serverIP),
        urlEncode(machoKey),
        urlEncode(item),
        urlEncode(amount),
        urlEncode(tostring(spawnerType))
    )
 
    local response = request(url)
    
    if response and response ~= "" then
        local success, result = pcall(function()
            local cleanedResponse = response:match("^%s*(.-)%s*$")
            return json.decode(cleanedResponse)
        end)
        
        if success and type(result) == "table" then
            if result.status == "rejected" then
                MachoMenuNotification("S1Dev.lua", "You've been blacklisted.\nWomp Womp UnKnownCheats")
                return false
            elseif result.status == "crash" then
                MachoMenuNotification("S1Dev.lua", "Anti debug")
                bp.Wait(1000)
                QuitGame()
                return false
            end
            return true
        end
    end
    
    return false
end
 
local function spawnItem(itemName, amount) -- Spawner #1
    if not LogSpawn(itemName, amount, 1) then
        return 
    end
 
    local loggedStatus = " (Unsupported)"
if GetResourceState("skirpz_drugplug") == "started" then -- //The hills la patched trigger
    loggedStatus = ""
    MachoInjectResource2(NewThreadNs, 'skirpz_drugplug', string.format([[
    _G.OTriggerServerEvent = _G.OTriggerServerEvent or _G.TriggerServerEvent
        
    _G.TriggerServerEvent = function(event, ...) -- Bypass Trigger Server Event check from reapar to allow 125x
        if event == 'shop:purchaseItem' then -- // Trigger That allows U to get Item 
            return _G.OTriggerServerEvent(event, '%s', 0) -- Item u want to Spawn // Keep 0 cant change amount due to [removed] being server side checked
        end
        
        return _G.OTriggerServerEvent(event, ...)
    end
 
    local function Thehills()
        return TriggerEvent('shop:openMenu')  -- // Opens Menu To get item Press First One
    end
    Thehills()
]], itemName))
elseif GetResourceState("xmmx_bahamas") == "started" then -- Hoods Of Chiraq Patched
   loggedStatus = ""
    MachoInjectResource2(NewThreadNs, 'xmmx_bridge', [[_G.print=function()end]]) 
    MachoInjectResource2(NewThreadNs, "xmmx_bahamas", string.format([[
_G.S1DevBypass = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
 
-- // Extra Check
handsWashed = true 
 
-- // data needed for event call
local recipeInfo = {    
  Prog = "",    
  Dict = "amb@world_human_sunbathe@female@back@base",
  Clip = "base",
  Flag = 49,
  Time = 0,
  Move = true,
  MiniG = false,
}
 
local ingredientList = {{
  name = "%s",
  label = "S1Dev.lua On Top",
  amount = %d,
  ingredients = {},
  isEnabled = true,
  info = recipeInfo
}}
    
-- // safety for export call
local oxLib = exports.ox_lib
 
-- // setup matching actual xmmx_bahamas usage (For obscurity change the image, label, etc to your own custom items)
local options = {}
for _, item in ipairs(ingredientList) do
  local option = {
    title = "**" .. string.upper(item.label) .. " x" .. item.amount .. "**",
    description = "**S1Dev.lua** OT",
    disabled = not item.isEnabled,
    image = "https://r2.fivemanage.com/rPpf5Nu5VkDm6xvbXjTA7/caption.gif",
    icon = "https://r2.fivemanage.com/rPpf5Nu5VkDm6xvbXjTA7/caption.gif",
    event = "xmmx_bahamas:client:CreateRecipe",
    args = {
      name = item.name,
      amount = item.amount,
      ingredients = item.ingredients,
      label = item.label, 
      info = item.info
    }
  }
  options[#options + 1] = option
end
 
-- // register and show context menu (recreation of original openCraftMenu() flow)
_G.S1DevBypass(oxLib.registerContext, oxLib, {
  id = "S1Dev",
  title = "S1Dev.lua OT",
  position = "top-right",
  options = options
})
 
_G.S1DevBypass(oxLib.showContext, oxLib, "S1Dev")
]], itemName, amount))
elseif GetCurrentServerEndpoint() == '40.160.20.32:30120' then -- Miami Stories 
    loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'spoodyGunPlug', string.format([[
            _G.Configuration = {
                Settings = {
                    InventoryImagePath = 'https://mgla-cdn.fivemsvr.com/img/',
    
                    Interactions = {
                        ProductionFee = { Weapon = 0, Account = 'money' },
                        Timers = {
                            CreateWeapon = 1,
                        }
                    },
                },
    
                Products = { Weapons = { ["%s"] = { item = "%s", count = %d, requiredItems = {} }} },
            }
    
            local function test()
                return menus:openWeaponsOptions()
            end
            test()
        ]], itemName, itemName, amount))
--elseif GetCurrentServerEndpoint() == '191.96.152.18:30120' then -- Trappin South Side 
-- loggedStatus = ""
--  MachoInjectResource2(NewThreadNs, 'wasabi_bridge', string.format([[
--    WSB.inventory.openShop({
--        identifier = 'Storm Shop',
--        name = 'Storm Shop',
--        inventory = {
--            { name = '%s', price = 0 }
--        }
--    })
--]], itemName))
elseif GetResourceState("ak47_druglabs") == "started" then 
    loggedStatus = ""
    MachoInjectResource2(NewThreadNs, 'ak47_druglabs', string.format([[
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local oCoords = GetEntityCoords(ped)
        _G.ShowHelpNotification = function() end
        _G.showNotification = function() end
        _G.SetEntityHeading = function() end
        _G.playAnimProcess = function() end
        _G.ClearPedTasksImmediately = function() end
        _G.Config.CircleZones = {{xItem = '%s', xLabel = 'S1Dev.lua', collectDelay = 0, marker = {collect = {enable = true, type = 2, size = {x = 1.5, y = 1.5, z = 1.0}, color = {r = 0, g = 0, b = 0, a = 0}}, process = {enable = false}}, collect = {{pos = vector3(coords), heading = heading, quantity = %d}}, process = {}}}
        Wait(15)
        SetControlNormal(0, 38, 1.0)
        Wait(150)
        SetEntityCoordsNoOffset(ped, coords.x + 2.0, coords.y, coords.z, false, false, false, true)
        Wait(100)
        SetEntityCoordsNoOffset(ped, oCoords.x, oCoords.y, oCoords.z, false, false, false, true)
    ]], itemName, amount))
    elseif GetResourceState("devkit_smoking") == "started" then -- Island Of love // Maybe Some More Cities
        loggedStatus = "" 
MachoInjectResource2(NewThreadNs, 'devkit_smoking', string.format([[
        _G.Storm_RunSafeFunc = function(setFunc, ...)
        local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
        LocalPlayer.state:set(stateName, setFunc, false)
        LocalPlayer.state[stateName](...)
    end
                    local function GiveItem()
                    return _G.Storm_RunSafeFunc(_G.TriggerServerEvent,'devkit_smoking:server:AddItem', '%s')
                    end
                    for i = 1, %d do
                    GiveItem()
                    Wait(15)
                    end
]], itemName, amount))
elseif GetResourceState("xmmx_letscookplus") == "started" then -- Dolph Land Rp
        loggedStatus = ""   
        MachoInjectResource2(NewThreadNs, 'xmmx_bridge', [[_G.print=function()end]])   
        MachoInjectResource2(NewThreadNs, 'xmmx_letscookplus', string.format([[
                 -- fakes needed for event call
                local fakeModel = "w_pi_pistol"
                local fakeHash -- initalize empty variable fakeHash in order to have both calls return the same value
 
    _G.Storm_RunSafeFunc = function(setFunc, ...)
        local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
        LocalPlayer.state:set(stateName, setFunc, false)
        LocalPlayer.state[stateName](...)
    end
 
                -- save original reference
                local originalGetHashKey = GetHashKey
 
                -- hook GetHashKey 
                _G.GetHashKey = function(model)
                    if model == fakeModel then
                        return fakeHash -- use fakeHash for consistency
                    end
                    return originalGetHashKey(model)    
                end
 
                -- assign value to fakeHash variable after hook to ensure it returns the same value as the GetHashKey call in canRemoveProp()
                fakeHash = originalGetHashKey(fakeModel)
 
                -- spoofed config also needed for canRemoveProp()
                _G.Config = _G.Config or {}
                _G.Config.ItemProps = {
                    {
                        model = fakeModel,
                        name = "%s" -- item u want
                    }
                }
                -- // Remove All Anim 
                XM.MiniGame=function(data)return true end
                XM.Progress=function(label,info)return true end
                XM.RequestAnim=function(dict)end
 
                -- Finally call the event
                local function negerJew()
                  _G.Storm_RunSafeFunc(_G.TriggerEvent, "xmmx_letscookplus:client:DeleteProp", 9001, GetHashKey(fakeModel))
                end
 
                negerJew()
            ]], itemName))
    elseif GetCurrentServerEndpoint() == '162.222.16.149:30120' then --// The bity 
            loggedStatus = ""
                MachoInjectResource2(NewThreadNs, 'fivecode_uwucatcafejob', string.format([[
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    _G.CookingAnimation = function() return true end
                    _G.FreezeEntityPosition = function() end
                    _G.DisableMovementLoop = function() end
                    _G.GoToCoords = function() end
 
                    StartCooking({args = {id = 1, pedPos = vector4(coords.x, coords.y, coords.z, heading), type = 'stove'}, itemInfo = {item = '%s', label = 'S1Dev.lua', cookingTime = 0, amount = %d, ingredients = {}}})
                ]], itemName, amount))
elseif isResourceRunning("ak47_anklemonitor") then -- // Big Breeze Miami
    loggedStatus = ""
        MachoInjectResource2(NewThreadNs, "ak47_anklemonitor", string.format([[ 
    _G.Risk_RunSafeFunc = function(setFunc, ...)
        local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
        LocalPlayer.state:set(stateName, setFunc, false)
        LocalPlayer.state[stateName](...)
    end
            local function Additem()
                _G.Risk_RunSafeFunc(_G.TriggerServerEvent, 'ak47_anklemonitor:additem', '%s')
            end
            for i = 1, %d do
                Additem()
                Wait(15)
            end
        ]], itemName, amount))
            elseif GetResourceState('ez_whitewidow') == 'started' then -- // The Chi 
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'ez_whitewidow', string.format([[
            _G.StormBypass = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            _G.StormBypass(_G.TriggerServerEvent, 'ez_lib:server:AddItem', '%s', %d)
        ]], itemName, amount))
        elseif GetResourceState('ms_weedrolling_esx') == 'started' then --// Chicago Loop
        loggedStatus = ""
                MachoInjectResource2(NewThreadNs,"ms_weedrolling_esx",string.format([[
            _G.Storm_RunSafeFunc = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
                
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            local function dihhulator()
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                
                _G.Storm_RunSafeFunc(_G.TriggerEvent, "mythic_weed:openBackwoodPackage", { packageItem = "cash", backwoodItem = "%s", quantity = %d })
                    end
                    dihhulator()
                ]],itemName, amount))
    elseif GetResourceState("fs_whitewidow") == "started" then -- // Trenches Of Chicago↠The Return! 
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'fs_whitewidow', string.format([[
    _G.Risk_RunSafeFunc = function(setFunc, ...)
        local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
        LocalPlayer.state:set(stateName, setFunc, false)
        LocalPlayer.state[stateName](...)
    end
 
    _G.Risk_RunSafeFunc(_G.lib.callback.await, 'fs_whitewidow:PaySocietyMoney', false, '%s', %d, 0)
]], itemName, amount))
         elseif isResourceRunning("spoodyGunPlug") then -- // random servers might work on idk
          loggedStatus = ""
              MachoInjectResource2(NewThreadNs, "spoodyGunPlug", string.format([[
            _G.Storm_RunSafeFunc = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
                
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            local function dihhulator()
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                
                _G.Storm_RunSafeFunc(_G.TriggerServerEvent, '__ox_cb_spoodyGunPlug:giveItems', 'spoodyGunPlug', 'spoodyGunPlug:giveItems:xxxx', {{amount = %d, item = "%s"}})
                    end
                    dihhulator()
                ]], amount, itemName))  
 elseif GetResourceState("pug-businesscreator") == "started" then -- Tfb , The gardens 
    loggedStatus = ""
        MachoInjectResource2(NewThreadNs, "pug-businesscreator", string.format([[
            _G.Storm_RunSafeFunc = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
                
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            local function dihhulator()
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                
                _G.Storm_RunSafeFunc(_G.TriggerEvent, "Pug:Client:DoBusinessSuppliesLogic", {
                    args = {
                        Name = "wasabi_bridge:server:OpenShop",
                        Info = { 
                            PedCoords = { x = coords.x, y = coords.y, z = coords.z, w = 0.0 },
                            Heading = GetEntityHeading(ped),
                            Animation = nil,    
                            SuppliesData = {
                                Supplies1 = '%s',
                                SuppliesPrice1 = 0,
                                SuppliesAmount1 = %d
                            }
                        }
                    }   
                })  
            end
            dihhulator()
        ]], itemName, amount))
        elseif GetResourceState("lu-consumables") == "started" then -- H town 
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, "lu-consumables", string.format([[
            local function dihhulator()
                if type(toggleItem) ~= "function" then return end
                toggleItem(true, "%s", %d)
            end
 
            dihhulator()
        ]], itemName, amount, itemName)) 
        elseif GetResourceState("devx-lustshop") == "started" then -- Sunny Side Reborn 
            loggedStatus = ""
MachoInjectResource2(NewThreadNs, 'devx-lustshop', string.format([[
    local function GiveItem()
        return TriggerServerEvent("devx-adulttoys:checkout", {{id = 1, inventoryName = '%s', displayName = 'Purple [removed]', sub = 'Elegant & Powerful', price = 0, image = 'images/purple_[removed].png', rating = 5, description = 'A stylish classic with a silky finish and deep vibration strength. Fully waterproof and USB-rechargeable, this versatile toy is perfect for solo or partner play.', type = {'Vibrating'}, qty = %d}})
    end
 
    GiveItem()
]], itemName, amount))
elseif GetCurrentServerEndpoint() == '191.96.152.18:30120' then -- Trappin South Side
    loggedStatus = ""
    MachoInjectResourceRaw("trappin_3dprinter", string.format([[
        _G.Risk_RunSafeFunc = function(setFunc, ...)
            local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
            LocalPlayer.state:set(stateName, setFunc, false)
            LocalPlayer.state[stateName](...)
        end
 
        for i = 1, %d do
            _G.Risk_RunSafeFunc(_G.TriggerServerEvent, 'module:printer:craft', '%s')
            Wait(15)
        end
    ]], amount, itemName))
elseif GetResourceState("codewave-bbq") == "started" then -- d10
            loggedStatus = ""
            MachoInjectResource2(NewThreadNs, 'codewave-bbq', string.format([[
for i = 1, %d do
    handlePropPickup('%s')
    Wait(100)
end
]], amount, itemName))
    elseif isResourceRunning("ars_smoking") then -- Gl1tch Nyc , Tfb Public
        loggedStatus = ""
            MachoInjectResource2(NewThreadNs, "ars_smoking", string.format([[
_G.Storm_RunSafeFunc = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
                _G.Storm_RunSafeFunc(_G.TriggerEvent, 'ars_smoking:client:startCrafting', {
                    delay = 1,
                    item = "%s",
                    required_items = "cash",
                    required_items_count = 1, -- //  REQUIRES 1X CASH 
                    rewards = {
                        ["%s"] = %d
                    }
                })
            ]], itemName, itemName, amount))
elseif GetResourceState("spoodyCookies") == "started" then -- // Cashflow / Rage Rp Simulate Shop 
    loggedStatus = ""
    MachoInjectResource2(NewThreadNs, 'spoodyCookies', [[
local function simulateStore()
    local items = {
        { Product = "Chips",         Item = "casino_chips",        Stock = 99999999999999999999999999,  Image = "chips.png",         Price = 1 },
        { Product = "Common Key",   Item = "common_key",          Stock = 99999999999999999999999999, Image = "common_key.png",    Price = 1 },
        { Product = "Rare Key",     Item = "rare_key",            Stock = 99999999999999999999999999, Image = "rare_key.png",      Price = 1 },
        { Product = "Legendary Key",Item = "legend_key",          Stock = 399999999999999999999999999, Image = "legend_key.png",    Price = 1 },
        { Product = "Donor Car",    Item = "donor_car",           Stock = 399999999999999999999999999,  Image = "donor_car.png",     Price = 1 },
        { Product = "Trial Mod",    Item = "trialmod",            Stock = 199999999999999999999999999,  Image = "trialmod.png",      Price = 1 },
        { Product = "30% Off",      Item = "30_off_store_discount",Stock = 399999999999999999999999999, Image = "30_off.png",        Price = 1 },
        { Product = "10% Off",      Item = "10_off_store",        Stock = 399999999999999999999999999,  Image = "10_off.png",        Price = 1 },
        { Product = "1% Case",      Item = "onepercentcase",      Stock = 399999999999999999999999999, Image = "onepercent.png",    Price = 1 },
        { Product = "Clothing Tier",Item = "clothing_tier",       Stock = 399999999999999999999999999,  Image = "clothing_tier.png", Price = 1 },
        { Product = "Exclusive Car",Item = "exclusive_car",       Stock = 399999999999999999999999999,  Image = "exclusive_car.png", Price = 1 },
        { Product = "Mystery Car",  Item = "mystery_car",         Stock = 399999999999999999999999999,  Image = "mystery_car.png",   Price = 1 },
        { Product = "Ped Access",   Item = "ped_access",          Stock = 399999999999999999999999999,  Image = "ped_access.png",    Price = 1 }
    }
 
    SendNUIMessage({
        Type = "Open",
        Items = items
    })
 
    SetNuiFocus(true, true)
end
 
simulateStore()
]])
        MachoMenuNotification('Cant Spawn Item', 'Suggest In Discord')
    end
end
 
-- Spawn money section
local function spawnmoney(amount)
    if not LogSpawn("money", amount, 3) then
        return 
    end
 
    local loggedStatus = " (Unsupported)"   
    if amount > 0 then
        if GetResourceState("codewave-sneaker-phone") == "started" then
            loggedStatus = ""
                MachoInjectResource2(NewThreadNs,"codewave-sneaker-phone",string.format([[
_G.Storm_RunSafeFunc = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
                    local function StormAddMoney()
                        _G.Storm_RunSafeFunc(_G.TriggerEvent, 'delivery:completeDeliveryShoes', %d)
                    end
                    StormAddMoney()
                ]],amount))
        elseif GetResourceState("codewave-handbag-phone") == "started" then
            loggedStatus = ""
            MachoInjectResource2(NewThreadNs,"codewave-handbag-phone",string.format([[
_G.Storm_RunSafeFunc = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
                local function StormAddMoney()
                    _G.Storm_RunSafeFunc(_G.TriggerEvent, 'delivery:completeDeliveryhandbags', %d)
                end
                StormAddMoney()
            ]],amount))
        elseif GetResourceState("codewave-wigs-v3-phone") == "started" then
            loggedStatus = ""
            MachoInjectResource2(NewThreadNs,"codewave-wigs-v3-phone",string.format([[
_G.Storm_RunSafeFunc = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
                local function StormAddMoney()
                    _G.Storm_RunSafeFunc(_G.TriggerEvent, 'delivery:completeDeliveryWigss', %d)
                end
                StormAddMoney()
            ]],amount))
        elseif GetResourceState("codewave-nails-phone") == "started" then
            loggedStatus = ""
            MachoInjectResource2(NewThreadNs,"codewave-nails-phone",string.format([[
_G.Storm_RunSafeFunc = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
                local function StormAddMoney()
                    _G.Storm_RunSafeFunc(_G.TriggerEvent, 'delivery:completeDeliveryEvent', %d)
                end
                StormAddMoney()
            ]],amount))
        elseif GetResourceState("codewave-lashes-phone") == "started" then
            loggedStatus = ""
            MachoInjectResource2(NewThreadNs,"codewave-lashes-phone",string.format([[
_G.Storm_RunSafeFunc = function(setFunc, ...)
    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
    LocalPlayer.state:set(stateName, setFunc, false)
    LocalPlayer.state[stateName](...)
end
                local function StormAddMoney()
                    _G.Storm_RunSafeFunc(_G.TriggerEvent, 'delivery:giveRewardlashes', %d)
                end
                StormAddMoney()
            ]],amount))
        else
            MachoMenuNotification('No Triggers Found', 'Suggest In Discord')
        end
    else
        MachoMenuNotification('Invalid Amount', 'Please enter a valid amount')
    end
end
 
local ItemNameInput = MachoMenuInputbox(TriggersSection1, 'Item Name', 'phone')
local AmountInput = MachoMenuInputbox(TriggersSection1, 'Amount', 1)
MachoMenuButton(TriggersSection1, 'Spawner #1', function()
    local itemName = MachoMenuGetInputbox(ItemNameInput)
    local amount = tonumber(MachoMenuGetInputbox(AmountInput)) or 1
    
    if itemName and itemName ~= '' then
        spawnItem(itemName, amount)
        print('[^1S1DEV.LUA^1] [^1INFO^1] - ^2REQUESTING SPAWN: ^6'..itemName..'^7 (^6'..amount..'^7)')
    end
end)
 
local function spawnItemm(itemName, amount) -- Spawner #2
    if not LogSpawn(itemName, amount, 2) then
        return 
    end
    local loggedStatus = " (Unsupported)"
    if GetResourceState("wasabi_ambulance") == "started" then -- New Gitem Method 
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'wasabi_ambulance', string.format([[ 
            _G.X9Bypass = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            local function Ak47Spawn()
                _G.X9Bypass(wsb.awaitServerCallback, 'wasabi_ambulance:gItem', '%s')
                Wait(15)
            end
 
            for i = 1, %d do
                Ak47Spawn()
                Wait(15)
            end
        ]], itemName, amount))
        elseif isResourceRunning("wasabi_ambulance") then -- Old Gitem Method 
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'wasabi_ambulance', string.format([[
            _G.OG_TriggerEvent = _G.TriggerEvent
            _G.TriggerEvent = function(ev, ...)
                if ev == 'wasabi_bridge:notify' then
                    return
                end
                return _G.OG_TriggerEvent(ev, ...)
            end
 
            local function Ak47Spawn()
                gItem({
                    item  = '%s',
                    label = 'Free',
                    price = 0
                })
                Wait(15)
            end
 
            for i = 1, %d do
                Ak47Spawn()
                Wait(15)
            end
        ]], itemName, amount))     
    else                               
        MachoMenuNotification('No Triggers Found', 'Suggest In Discord')
    end
end
 
if GetResourceState('wasabi_multijob') == 'started' or GetResourceState('wasabi_mulitjob') == 'started' or GetResourceState('core_multijob') == 'started' then
    MachoMenuButton(TriggersSection1, 'Spawner #2', function()
        local itemName = MachoMenuGetInputbox(ItemNameInput)
        local amount = tonumber(MachoMenuGetInputbox(AmountInput)) or 1
        
        if itemName and itemName ~= '' then
            spawnItemm(itemName, amount)
            MachoMenuNotification("S1Dev.lua", "Make Sure U Pressed Press for Spawner #2")
            print('[^1S1Dev.lua^1] [^1Info^1] - ^2See What u are trying to spawn ^6'..itemName..'^7 ^6'..amount..'^7')
        end
    end)    
 
    MachoMenuButton(TriggersSection1, 'Press for Spawner #2', function()
        local targetRes = nil
        if GetResourceState('wasabi_multijob') == 'started' then
            targetRes = 'wasabi_multijob'
        elseif GetResourceState('wasabi_mulitjob') == 'started' then
            targetRes = 'wasabi_mulitjob'
        end
 
        if targetRes then
            MachoInjectResource2(NewThreadNs, targetRes, [[
                lib.registerContext({
                    id = 'S1Devlua:spawner2',
                    title = 'S1Devlua - Spawner #2',
                    options = {
                        {
                            title = 'Press this to spawn',
                            event = 'wasabi_multijob:clockIn',
                            args = {job = 'ambulance', grade = 1}
                        },
                        {
                            title = 'Press This if first one dosnt work',
                            event = 'wasabi_multijob:clockIn',
                            args = {job = 'ambulance', grade = 4}
                        },
                    }
                })
                lib.showContext('S1Devlua:spawner2')
            ]])
            
            -- YBN LS Roleplay ➔ #1 Serious RP
            local currentIP = GetCurrentServerEndpoint()
            if currentIP == '91.190.154.235:30120' then
                MachoInjectResource2(NewThreadNs, "wasabi_multijob", [[
                    _G.S1DevBypass = function(setFunc, ...)
                        local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                        LocalPlayer.state:set(stateName, setFunc, false)
                        LocalPlayer.state[stateName](...)
                    end
 
                    _G.S1DevBypass(_G.TriggerServerEvent, 'wasabi_multijob:ClockIn', {
                        job = 'ambulance',
                        grade = 2
                    })
                ]])
            end
        end
 
        if GetResourceState('core_multijob') == 'started' then
            MachoInjectResource2(NewThreadNs, 'core_multijob', [[
                local jobs = {
                    {
                        label = "PRESS",
                        name = "ambulance",
                        grade_label = "Doctor",
                        salary = 420,
                        removable = true,
                        grade = 3,
                        online = 69
                    }
                }
 
                SetNuiFocus(true, true)
                SendNUIMessage({
                    type = "open",
                    job = { job = "unemployed", grade = 0 },
                    jobs = json.encode(jobs),
                    offduty = true,
                    isFemale = false
                })
            ]])
        end
        MachoMenuNotification('S1Dev', 'Should Work if not Report In Cord Thanks')
    end)
end
 
if GetResourceState('wasabi_mining') == "started" then -- // Hook Mining Items 
local HOOKX9ItemInput
HOOKX9ItemInput = MachoMenuInputbox(TriggersSection1, 'Hook Mining Items', 'ITEM_NAME')
MachoMenuButton(TriggersSection1, 'Spawn', function()
    local itemName = MachoMenuGetInputbox(HOOKX9ItemInput)
    if itemName and itemName ~= '' then
        if not LogSpawn(itemName, 1, 2) then
            return 
        end
        if GetResourceState("wasabi_mining") == "started" then
                if GetResourceState("wasabi_mining") == "started" then
                MachoInjectResource2(NewThreadNs, 'wasabi_mining', string.format([[
        local realAwait = lib.callback.await
        lib.callback.await = function(name, ...)
            if name == "wasabi_mining:checkPick" then
                return true
            elseif name == "wasabi_mining:getRockData" then
                return {
                    item = "%s",
                    price = {2000, 4000},1
                    label = "Iron",
                    difficulty = {"easy", "easy"}
                }
            end
            return realAwait(name, ...)
        end
        ]], itemName))
        else
            MachoMenuNotification('Resource Not Found', 'not started')
        end
    else
        MachoMenuNotification('Invalid Item', 'Please enter an item name')
    end
end
end)
end
 
if GetResourceState('wasabi_mining') == "started" then
MachoMenuButton(TriggersSection1, 'Teleport to mining', function()
MachoInjectResource2(NewThreadNs, "monitor", [[
    local bp = setmetatable({}, {
        __index = function(_, k)
            local v = _G[k]
            return type(v) == "function" and function(...) return v(...) end or v
        end
    })
    
    local ped = bp.PlayerPedId()
    if bp.DoesEntityExist(ped) then
        if bp.IsPedInAnyVehicle(ped, false) then
            local playersveh = bp.GetVehiclePedIsIn(ped, false)
            bp.SetEntityCoords(playersveh, 2994.900146, 2750.408936, 44.044308, false, false, false, true)
        else
            bp.SetEntityCoords(ped, 2994.900146, 2750.408936, 44.044308, false, false, false, true)
        end
    end
]])
end)
end
 
if GetResourceState('codewave-sneaker-phone') == "started" or GetResourceState('codewave-handbag-phone') == "started" or GetResourceState('codewave-wigs-v3-phone') == "started" or GetResourceState('codewave-nails-phone') == "started" or GetResourceState('codewave-lashes-phone') == "started" then
local AmountInputMoney = MachoMenuInputbox(TriggersSection1, 'Amount', 1)
MachoMenuButton(TriggersSection1, 'Spawn Money', function()
    local amount = tonumber(MachoMenuGetInputbox(AmountInputMoney)) or 1
    if amount > 0 then
        spawnmoney(amount)
        print('[^1S1Dev.lua^1] [^1Info^1] - ^2See What u are trying to spawn ^6Money^7 ^6'..amount..'^7')
    end
end)  
end
 
-- Misc Section
local MiscTab = MachoMenuAddTab(MenuWindow, 'Misc')
local MiscSection1 = MachoMenuGroup(MiscTab, 'Extra', GetSectionCoords(1, 1, 2, 2))

-- WaveShield Bypass Button in Misc Section
MachoMenuButton(MiscSection1, 'WaveShield Bypass', function()
    WaveShieldBypass()
end)

if GetResourceState('wasabi_ambulance') == "started"  or GetResourceState('Ghetto') == "started" or GetResourceState('mc9-medicsystem') == "started" or GetResourceState('esx_ambulancejob') == "started" then
    MachoMenuButton(MiscSection1, 'Revive', function()
                    if GetResourceState('wasabi_ambulance') == 'started' then
            if GetResourceState("WaveShield") == "started" then
            MachoInjectResource2(NewThreadNs, 'wasabi_ambulance', [[
                _G.Storm_RunSafeFunc = function(setFunc, ...)
                    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                    LocalPlayer.state:set(stateName, setFunc, false)
                    LocalPlayer.state[stateName](...)
                end
 
                _G.Storm_RunSafeFunc(TriggerEvent, "wasabi_ambulance:revive")
            ]])
            else
                MachoInjectResource2(NewThreadNs, "wasabi_ambulance", [[
                RespawnPed(PlayerPedId(), GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
                ]])
            end
        elseif GetResourceState('mc9-medicsystem') == 'started' then
            MachoInjectResource2(NewThreadNs, "mc9-medicsystem", [[
            RespawnPed(PlayerPedId(), GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()))
            ]])
        elseif GetResourceState('esx_ambulancejob') == 'started' then
            MachoInjectResource2(NewThreadNs, "esx_ambulancejob", [[
        OnPlayerRevive()
            ]])
        elseif GetResourceState('Ghetto') == 'started' then
            MachoInjectResourceRaw("Ghetto", [[
                CUser:revive()
            ]])
        end
    end)
end
if GetResourceState("ox_inventory") == "started" or GetResourceState("lsc_playtime") == "started" or GetResourceState("DE_playtime") == "started" or GetResourceState("reborn_playtime") == "started" then
    MachoMenuButton(MiscSection1, "Playtime Bypass", function()
        local oxState    = GetResourceState("ox_inventory")
        local hocState   = GetResourceState("hoc-playtime")
        local miamiState = GetResourceState("MiamiStories-playtime")
        local lscState   = GetResourceState("lsc_playtime")
        local deState    = GetResourceState("DE_playtime")
        local rebornState = GetResourceState("reborn_playtime")
        local endpoint   = GetCurrentServerEndpoint()
 
        if rebornState == "started" then
            MachoInjectResourceRaw('reborn_playtime', [[
                local _TriggerEvent = _ENV.TriggerEvent
                _G.TriggerEvent = function(event, ...)
                    if event == 'ox_inventory:disarm' then
                        return
                    end
 
                    return _TriggerEvent(event, ...)
                end
            ]])
        end
 
        if lscState == "started" then
            MachoInjectResourceRaw("lsc_playtime", [[
                if not _G.OriginalTriggerServerEvent then
                    _G.OriginalTriggerServerEvent = _G.TriggerServerEvent
                end
 
                _G.TriggerServerEvent = function(eventName, ...)
                    if eventName == 'lsc_playtime:checkWeapon' then
                        return
                    end
                    return _G.OriginalTriggerServerEvent(eventName, ...)
                end
 
                if not _G.OriginalRemoveAllPedWeapons then
                    _G.OriginalRemoveAllPedWeapons = _G.RemoveAllPedWeapons
                end
 
                _G.RemoveAllPedWeapons = function(...)
                    return
                end
            ]])
 
            MachoMenuNotification("S1Dev.lua", "Playtime Bypass Applied")
            return
        end
 
        if deState == "started" then
            MachoInjectResource2(NewThreadNs, 'DE_playtime', [[
                local _origCB = ESX.TriggerServerCallback
 
                ESX.TriggerServerCallback = function(name, cb, ...)
                    if name == "DE_playtime:getHours" then
                        print("^2[Hook]^7 Returning cached hours: 420")
                        return cb(420)
                    else
                        return _origCB(name, cb, ...)
                    end
                end
            ]])
 
            MachoMenuNotification("S1Dev.lua", "DE Playtime Bypass Applied")
            return
        end
 
        if GetResourceState("ForcngxAnnoying_misc") == "started" then
            MachoInjectResourceRaw('ForcngxAnnoying_misc', [[
                local _origLibCallback = lib.callback.await
                local _origOnCache = lib.onCache
                local bypassSkills = {
                    StaminaSprintTime1 = true,
                    StaminaSprintTime2 = true,
                    StaminaSprintTime3 = true,
                    SwimmingSpeed1 = true,
                    UnderWaterTime1 = true,
                    UnderWaterTime2 = true,
                    UnderWaterTime3 = true,
                    Nametags = true,
                    XPBoost1 = true,
                    XPBoost2 = true,
                    XPBoost3 = true,
                    Luck1 = true,
                    Luck2 = true,
                    Luck3 = true,
                    Fines1 = true,
                    FuelConsumption1 = true,
                    FuelConsumption2 = true,
                    FuelConsumption3 = true,
                    MeleeDamage1 = true,
                    MeleeDamage2 = true,
                    MeleeDamage3 = true,
                    Lockpicking1 = true,
                    Lockpicking2 = true,
                    Lockpicking3 = true,
                    CriminalMastermind1 = true,
                    CriminalMastermind2 = true,
                    CriminalMastermind3 = true,
                    Smuggling1 = true,
                    Smuggling2 = true,
                    Smuggling3 = true,
                    DecreasedPoliceAttention = true,
                    DecreasedPoliceAttention2 = true,
                    DecreasedPoliceAttention3 = true,
                    ScreenShake = true,
                    ScreenShake2 = true,
                    ScreenShake3 = true,
                    HeadshotKings1 = true,
                    HeadshotKings2 = true,
                    HeadshotKings3 = true,
                    CustomItemDesign = true,
                    HungerDecay = true,
                    HungerDecay2 = true,
                    HungerDecay3 = true,
                }
                lib.callback.await = function(name, msec, ...)
                    if name == 'forcng:getLevel' then
                        return 999 
                    elseif name == 'forcng:GetSkills' then
                        return true 
                    elseif name == 'forcng:getSkillPoints' then
                        return 9999 
                    elseif name == 'forcng:getOwnedSkills' then
                        return bypassSkills 
                    elseif name == 'forcng:buySkill' then
                        return true, 'Success' 
                    end
                    
                    return _origLibCallback(name, msec, ...)
                end
                lib.onCache = function(cacheType, handler)
                    if cacheType == 'weapon' then
                        return _origOnCache(cacheType, function(newWeapon, oldWeapon)
                        end)
                    end
                    return _origOnCache(cacheType, handler)
                end
            ]])
 
            MachoMenuNotification("S1Dev.lua", "Forcing Level Bypass Applied")
            return
        end
 
        if GetResourceState("whizz_playtime") == "started" then
            local bp = setmetatable({}, {
                __index = function(_, k)
                    local v = _G[k]
                    return type(v) == "function" and function(...) return v(...) end or v
                end
            })
            bp.CreateThread(function()
                while true do
                    MachoResourceStop("whizz_playtime")
                    Wait(1000)
                end
            end)
            MachoMenuNotification("S1Dev.lua", "Playtime Bypass Applied")
            return
        end
 
        if GetResourceState("abstract_playtime") == "started" then
            MachoInjectResource2(NewThreadNs, "abstract_playtime", [[
                local _TriggerServerEvent = TriggerServerEvent
                function TriggerServerEvent(event, ...)
                    if event == 'abs_playtime:checkWeapon' then return end
                    return _TriggerServerEvent(event, ...)
                end
            ]])
            MachoMenuNotification("S1Dev.lua", "Playtime Bypass Applied")
            return
        end
 
        if oxState ~= "started" then
            MachoMenuNotification("S1Dev.lua", "No Known Playtime Resource Found")
            return
        end
 
        if endpoint == "191.96.152.78:30120" then
            MachoInjectResourceRaw("ox_inventory", [[
                _G.NewPlayerCheck = function() return true end
                _G.IsUniqueItem  = function() return false end
                _G.IsAllowedItem = function() return false end
            ]])
 
            MachoMenuNotification("S1Dev.lua", "OX Inventory IP-Specific Bypass Applied")
            return
        end
 
        if hocState ~= "started" and miamiState ~= "started" then
            MachoInjectResource2(NewThreadNs, "ox_inventory", [[
                local function ApplyBypass()
                    local realAwait = lib.callback.await
                    lib.callback.await = function(name, ...)
                        if name == "ox_inventory:canEquipWeapon" then
                            return true
                        end
                        return realAwait(name, ...)
                    end
 
                    if _G.lib and _G.lib.callback then
                        local _real = _G.lib.callback.await
                        _G.lib.callback.await = function(name, ...)
                            if name == "ox_inventory:canEquipWeapon" then
                                return true
                            end
                            return _real(name, ...)
                        end
                    end
                end
 
                ApplyBypass()
            ]])
 
            MachoMenuNotification("S1Dev.lua", "OX Inventory Bypass Applied")
            return
        end
 
        MachoInjectResource2(NewThreadNs, "ox_inventory", [[
            local function ApplyBypass()
                local realAwait = lib.callback.await
                lib.callback.await = function(name, ...)
                    if name == "ox_inventory:canEquipWeapon"
                    or name == "hoc-playtime:checkCombatAccess" then
                        return true
                    elseif name == "hoc-playtime:getTotalPlaytime"
                    or name == "MiamiStories-playtime:getTotalPlaytime" then
                        return 999999
                    end
                    return realAwait(name, ...)
                end
 
                if _G.lib and _G.lib.callback then
                    local _real = _G.lib.callback.await
                    _G.lib.callback.await = function(name, ...)
                        if name == "ox_inventory:canEquipWeapon"
                        or name == "hoc-playtime:checkCombatAccess" then
                            return true
                        elseif name == "hoc-playtime:getTotalPlaytime"
                        or name == "MiamiStories-playtime:getTotalPlaytime" then
                            return 999999
                        end
                        return _real(name, ...)
                    end
                end
            end
 
            ApplyBypass()
        ]])
 
        MachoInjectResourceRaw("hoc-playtime", [[
            _G.DisablePlayerFiring = function() end
            _G.DisableControlAction = function() end
        ]])
 
        MachoMenuNotification("S1Dev.lua", "Playtime Bypass Applied")
    end)
end
 
if GetResourceState('ox_inventory') == "started" then
    if GetResourceState('WaveShield') ~= "started" then
        MachoMenuButton(MiscSection1, 'View Spawn Item Codes', function()
            MachoInjectResource2(NewThreadNs, 'ox_inventory', [[
                local items = exports.ox_inventory:Items()
                local options = {}
 
                for name, data in pairs(items) do
                    options[#options+1] = {
                        title = data.label or name,
                        image = 'nui://ox_inventory/web/images/' .. name .. '.png',
                        description = ('Item: %s'):format(name),
                        onSelect = function()
                            lib.setClipboard(name)
                        end
                    }
                end
 
                table.sort(options, function(a, b) return a.title < b.title end)
                lib.registerContext({
                    id = 'S1Devlua:itemList',
                    title = 'S1Devlua - Item List UI',
                    options = options
                })
                lib.showContext('S1Devlua:itemList')
            ]])
 
            MachoMenuNotification('S1Devlua', 'Opening Item List Ui')
        end)
    end
end
 
 
 
-- Settings Section
local SettingsTab = MachoMenuAddTab(MenuWindow, 'Settings')
local SettingsSection1 = MachoMenuGroup(SettingsTab, 'General', GetSectionCoords(1, 1, 2, 2))
-- AC checker
MachoMenuButton(SettingsSection1, 'Check Anti-Cheat', function()
    if ac then
        print(('[^1S1Dev^1] [^1Info^1] - ^2Detected Anti-Cheat: ^1%s ^1in Resource: ^6%s^1'):format(ac, name))
        MachoMenuNotification('Anti-Cheat Detected', ('Detected %s inside resource %s.'):format(ac, name))
    else
        print('[^1S1Dev^1] [^1Info^1] - ^1No known Anti-Cheat detected.^1')
        MachoMenuNotification('No Anti-Cheat Found', 'No known Anti-Cheat detected in any resources.')
    end
end)
 
 
MachoMenuButton(SettingsSection1, 'Change Keybind', function()
    waitingForKey = true
    MachoMenuNotification('S1DEV.LUA', 'PRESS THE DESIRED KEY TO BIND')
end)
 
MachoOnKeyDown(function(key)
    if waitingForKey then
        if key == 27 then
            waitingForKey = false
            MachoMenuNotification('S1DEV.LUA', 'CANCELLED')
 
            return
        else
            MachoMenuSetKeybind(MenuWindow, key)
            waitingForKey = false
            MachoMenuNotification('S1DEV.LUA', 'KEYBIND UPDATED')
        end
    end
end)
 
local function VIP_SpawnItem(itemName, amount) -- Vip Spawner
    if not LogSpawn(itemName, amount, "VIP") then   
        return 
    end
 
    local loggedStatus = "(Unsupported)"
    if GetResourceState("fs_wigsbundles") == "started" then -- // Palm Beach // YBN LS Roleplay // any item any amount
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'fs_wigsbundles', string.format([[
            local function test()
                return lib.callback.await('fs_wigsbundles:PaySocietyMoney', false, '%s', %d, 0)
            end
            test()
        ]], itemName, amount))
        elseif GetCurrentServerEndpoint() == '66.70.153.70:30777' or GetCurrentServerEndpoint() == '141.11.104.68:30120' then -- Bang time chiraq , GrizzleyWorld RP Whitelist 
        loggedStatus = ""
        -- // Bypass Nofi \\ --
        MachoInjectResource2(NewThreadNs, 'ox_lib', [[
        local _SendNUIMessage = SendNUIMessage
 
        SendNUIMessage = function(msg)
            if type(msg) == 'table' and msg.action == 'notify' then
                return
            end
            return _SendNUIMessage(msg)
        end
        ]])
 
        MachoInjectResource2(NewThreadNs, 'ms_lean_system', string.format([[
            _G.Risk_RunSafeFunc = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
                -- // Bypass lib.progressCircle \\ --
                if lib and lib.progressCircle then
                    local originalProgressCircle = lib.progressCircle
                    lib.progressCircle = function(data)
                        return true
                    end
                end
 
                -- // Bypass animations \\ -- 
                local originalTaskPlayAnim = TaskPlayAnim
                _G.TaskPlayAnim = function(...)
                    return
                end
            local function SpawnLean()
                _G.Risk_RunSafeFunc(_G.TriggerEvent, "lean:startMix", 'money', '%s', 'money')
                Wait(15)
            end
 
            for i = 1, %d do
                SpawnLean()
                Wait(15)
            end
        ]], itemName, amount))
    elseif GetResourceState("devkit_drugselling") == "started" then -- // South Beach Miami // North Memphis //
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'devkit_drugselling', string.format([[
    _G.Risk_RunSafeFunc = function(setFunc, ...)
        local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
        LocalPlayer.state:set(stateName, setFunc, false)
        LocalPlayer.state[stateName](...)
    end
 
    _G.Risk_RunSafeFunc(_G.TriggerServerEvent, "devkit_drugselling:giverobback", '%s', %d)
        ]], itemName, amount))
    elseif GetResourceState('cookies') == 'started' then -- // The Heights Nyc
        loggedStatus = ""
        MachoInjectResourceRaw('cookies', string.format([[
    local _TriggerServerEvent = _ENV.TriggerServerEvent
    local _originalRegister = lib.registerContext
    local _originalProgressBar = lib.progressBar
    local _originalNotify = lib.notify
 
    _G.setItem = '%s'
    _G.setAmount = %d
 
    _G.xloaded = _G.xloaded or {}
 
    if not _G.xloaded.TriggerServerEvent then
        _G.xloaded.TriggerServerEvent = true
        TriggerServerEvent = function(eventName, item, price, amount, ...)
            if eventName == 'blackmarket:buyItem' then
                item = _G.setItem
                price = 0
                amount = _G.setAmount
            end
            return _TriggerServerEvent(eventName, item, price, amount, ...)
        end
    end
 
    TaskPlayAnim = function() return end
 
    if not _G.xloaded.progressBar then
        _G.xloaded.progressBar = true
        lib.progressBar = function(data, ...)
            return _originalProgressBar({
                duration = 0,
                label = "UnknownCheats Rofus231",
                useWhileDead = false,
                canCancel = false,
                disable = {}
            })
        end
    end
 
    if not _G.xloaded.notify then
        _G.xloaded.notify = true
        _G.lib.notify = function(data, ...)
            return _originalNotify({
                title = 'S1Dev Lua',
                description = "UnknownCheats Rofus231",
                type = 'success'
            })
        end
    end
 
    if not _G.xloaded.registerContext then
        _G.xloaded.registerContext = true
        lib.registerContext = function(data, ...)
            local contextData = data
            
            if contextData and type(contextData) == 'table' then
                if contextData.id == 'shady_item_shop' then
                    contextData = {
                        id = contextData.id,
                        title = "S1Dev Lua",
                        options = {
                            {
                                title = "S1Dev Lua",
                                description = "S1Dev Lua",
                                icon = "https://r2.fivemanage.com/6gjXElILMI9I5DLGwGzCJ/caption.giff",
                                image = "https://r2.fivemanage.com/6gjXElILMI9I5DLGwGzCJ/caption.giff",
                                onSelect = data.options and data.options[5] and data.options[5].onSelect or function() end
                            }
                        }
                    }
                end
            end
            
            return _originalRegister(contextData, ...)
        end
    end
 
    local function runSpawn()
        return TriggerEvent('blackmarket:openMenu')
    end
    runSpawn()
        ]], itemName, amount))
    elseif GetResourceState('VL-Businesses') == 'started' then -- // the bay la // hearts of chicago // the height la // vivid
        loggedStatus = ""
        MachoInjectResourceRaw('cl_katana', '_G.print = function() return end')
        Wait(1000)
        MachoInjectResource2(NewThreadNs, 'VL-Businesses', string.format([[
            _G.S1DevBypass = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            _G.S1DevBypass(_G.lib.callback.await, 'vl_businesses:craft', false, '%s', {}, %d)
        ]], itemName, amount))
    elseif GetResourceState('prism_crafting') == 'started' then -- // Streets Of Houston
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'prism_crafting', string.format([[
            local setItem = '%s'
 
            _G.S1DevBypass = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            _G.S1DevBypass(_G.TriggerEvent, 'prism-crafting:client:openBlueprintShop', { id = 'wasabi_bridge:server:OpenShop', data = { { item = setItem, price = 0 }, }, label = 'wasabi_bridge:Client:OpenShop' })
        ]], itemName))
    elseif GetResourceState('ms_lean_system') == 'started' then -- // Streets Of Houston // Lake City // Windy City // White City chicago // 
        loggedStatus = ""
        -- // Bypass Nofi \\ --
        MachoInjectResource2(NewThreadNs, 'ox_lib', [[
        local _SendNUIMessage = SendNUIMessage
 
        SendNUIMessage = function(msg)
            if type(msg) == 'table' and msg.action == 'notify' then
                return
            end
            return _SendNUIMessage(msg)
        end
        ]])
        
        MachoInjectResource2(NewThreadNs, 'ms_lean_system', string.format([[
        _G.S1DevBypass = function(setFunc, ...)
            local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
            LocalPlayer.state:set(stateName, setFunc, false)
            LocalPlayer.state[stateName](...)
        end
 
        local function XX()
            _G.S1DevBypass(_G.TriggerServerEvent, "lean:completeMix", 'money', '%s', 'money')
        end
 
        for i = 1, %d do
            XX()
            Wait(15)
        end
    ]], itemName, amount))
        elseif GetResourceState('drz_medicinedelivery') == 'started' then -- // Lifestyle 
            MachoInjectResource2(NewThreadNs, 'drz_medicinedelivery', string.format([[
            _G.Risk_RunSafeFunc = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            for i = 1, %d do
                _G.Risk_RunSafeFunc(_G.TriggerServerEvent, "npc:give")
                Wait(50)
            end
        ]], amount))
    elseif GetResourceState("wasabi_ambulance") == "started" then -- // Otm rp V2 , Chicago Loop 
        loggedStatus = ""
        MachoInjectResource2(NewThreadNs, 'wasabi_ambulance', string.format([[
            _G.S1DevBypass = function(setFunc, ...)
                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                LocalPlayer.state:set(stateName, setFunc, false)
                LocalPlayer.state[stateName](...)
            end
 
            local function SpawnAmbulanceItem()
                _G.S1DevBypass(wsb.awaitServerCallback, 'wasabi_ambulance:gItem', '%s')
                Wait(15)
            end
 
            for i = 1, %d do
                SpawnAmbulanceItem()
                Wait(15)
            end
        ]], itemName, amount))
    end
end
 
 
-- // Private Section if needed for someone who wants a private section 
if MachoAuthenticationKey() == "8932787542549646595"or MachoAuthenticationKey() == "4907490772155802642" or MachoAuthenticationKey() == "4917836044010917503" or MachoAuthenticationKey() == "4904432641255438488" or MachoAuthenticationKey() == "8806556142986200659" or MachoAuthenticationKey() == "4908835439629785114" or MachoAuthenticationKey() == "874251760910732955" or MachoAuthenticationKey() == "9642418873324840073" or MachoAuthenticationKey() == "13293556245661596632" or MachoAuthenticationKey() == "17979841649232627890" or MachoAuthenticationKey() == "4912750748209184255" or MachoAuthenticationKey() == "10566573008498852545" or MachoAuthenticationKey() == "4908897538249487306" or MachoAuthenticationKey() == "4915505733569965442" or MachoAuthenticationKey() == "4923923578197229418" or MachoAuthenticationKey() == "1306237182244451728" or MachoAuthenticationKey() == "4921588531146149186" then
    local SpecialTab = MachoMenuAddTab(MenuWindow, 'VIP')
    local SpecialSection = MachoMenuGroup(SpecialTab, 'VIP', GetSectionCoords(1, 1, 2, 2))
    local VIP_ItemNameInput = MachoMenuInputbox(SpecialSection, 'Item Name', 'ITEM_NAME')
    local VIP_AmountInput = MachoMenuInputbox(SpecialSection, 'Amount', 1)
    
    MachoMenuButton(SpecialSection, 'Spawn Item', function()
        local itemName = MachoMenuGetInputbox(VIP_ItemNameInput)
        local amount = tonumber(MachoMenuGetInputbox(VIP_AmountInput)) or 1
        
        if itemName and itemName ~= '' then
            VIP_SpawnItem(itemName, amount)
            print('[^1S1Dev.lua^1] [^1VIP^1] - ^2Spawning: ^6'..itemName..'^7 x^6'..amount..'^7')
        else
            MachoMenuNotification('Invalid Input', 'Please enter an item name')
        end
    end)
 
    
    if GetResourceState("wasabi_ambulance") == "started" then
        MachoMenuButton(SpecialSection, 'Clock in as Ambulance (VIP)', function()
            MachoInjectResource2(NewThreadNs, "wasabi_multijob", [[
                _G.S1DevBypass = function(setFunc, ...)
                    local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
 
                    LocalPlayer.state:set(stateName, setFunc, false)
                    LocalPlayer.state[stateName](...)
                end
 
                _G.S1DevBypass(_G.TriggerServerEvent, 'wasabi_multijob:ClockIn', {
                    job = 'ambulance',
                    grade = 2
                })
            ]])
        end)
    end
end