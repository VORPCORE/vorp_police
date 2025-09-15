local LIB                 = Import("/configs/config.lua", "/languages/translation.lua", "blips", "prompts")
local Config <const>      = LIB.Config --[[@as vorp_police_config]]
local Translation <const> = LIB.Translation --[[@as vorp_police_translation]]
local Blips <const>       = LIB.Blips --[[@as MAP]]
local Prompts <const>     = LIB.Prompts --[[@as PROMPTS]]

local Core <const>        = exports.vorp_core:GetCore()
local MenuData <const>    = exports.vorp_menu:GetMenuData()
local T <const>           = Translation.Langs[Config.Lang]
local draggedBy           = -1
local drag                = false
local wasDragged          = false
local blip                = 0
local Poly                = nil
local playerInJail        = false
local prompts <const>     = {}

-- on resource stop
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if drag then
        DetachEntity(PlayerPedId(), true, false)
    end

    if Poly then
        Poly:destroy()
    end
end)

local function getClosestPlayer()
    local players <const> = GetActivePlayers()
    local coords <const> = GetEntityCoords(PlayerPedId())

    for _, value in ipairs(players) do
        if PlayerId() ~= value then
            local targetPed <const> = GetPlayerPed(value)
            local targetCoords <const> = GetEntityCoords(targetPed)
            local distance <const> = #(coords - targetCoords)
            if distance < 3.0 then
                return true, targetPed, value
            end
        end
    end
    return false, nil
end

local function applyBadge(result)
    local playerPed <const> = PlayerPedId()
    if result then
        RemoveTagFromMetaPed(playerPed, 0x3F7F3587, 0)
        UpdatePedVariation(playerPed, false, true, true, true, false)
        if IsPedMale(playerPed) then
            ApplyShopItemToPed(playerPed, 0x1FC12C9C, true, true, true)
        else
            ApplyShopItemToPed(playerPed, 0x929677D, true, true, true)
        end
        UpdatePedVariation(playerPed, false, true, true, true, false)
    else
        RemoveTagFromMetaPed(playerPed, 0x3F7F3587, 0)
        UpdatePedVariation(playerPed, false, true, true, true, false)
    end
end

local function getPlayerJob()
    local job <const> = LocalPlayer.state.Character.Job
    return Config.PoliceJobs[job]
end

local function isOnDuty()
    if not LocalPlayer.state.isPoliceDuty then
        Core.NotifyObjective(T.Duty.YouAreNotOnDuty, 5000)
        return false
    end
    return true
end

local function createBlips()
    for _, value in pairs(Config.Stations) do
        Blips:Create('coords', {
            Pos = value.Coords,
            Blip = Config.Blips.Style,
            Options = {                       -- optional
                sprite = Config.Blips.Sprite, --string or integer if type is entity or coords
                name = value.Name,
                modifier = Config.Blips.Color,
            },
        })
    end
end


local function registerLocations()
    for key, value in pairs(Config.Stations) do
        local data = {
            sleep = 800,
            locations = {
                { coords = value.Coords,                label = value.Name,                distance = 2.0 },
                { coords = value.Storage[key].Coords,   label = value.Storage[key].Name,   distance = 1.5 },
                { coords = value.Teleports[key].Coords, label = value.Teleports[key].Name, distance = 2.0 },
            },
            prompts = {
                {
                    type = T.Menu.Press,
                    key = Config.Keys.B,
                    label = 'press',
                    mode = 'Standard',
                },
            }
        }
        local prompt <const> = Prompts:Register(data, function(prompt, index, self)
            if index == 2 then
                if isOnDuty() then
                    local isAnyPlayerClose <const> = getClosestPlayer()
                    if not isAnyPlayerClose then
                        TriggerServerEvent("vorp_police:Server:OpenStorage", key)
                    else
                        Core.NotifyObjective(T.Error.PlayerNearbyCantOpenInventory, 5000)
                    end
                end
            end

            if index == 3 then
                if isOnDuty() then
                    OpenTeleportMenu(key)
                end
            end

            if index == 1 then
                local job <const> = LocalPlayer.state.Character.Job
                if Config.SheriffJobs[job] then
                    OpenSheriffMenu()
                else
                    Core.NotifyObjective(T.Error.OnlyPoliceopenmenu, 5000)
                end
            end
        end, true) -- auto start on register

        table.insert(prompts, prompt)
    end
end

--* DRAG PLAYER
local function dragHandle()
    if not isOnDuty() then
        Core.NotifyObjective(T.Duty.YouAreNotOnDuty, 5000)
        return
    end

    local isclose <const>, _, player <const> = getClosestPlayer()
    if isclose then
        local serverid <const> = GetPlayerServerId(player)
        TriggerServerEvent("vorp_police:Server:dragPlayer", serverid)
    end
end

--* ON JOB UPDATE
RegisterNetEvent("vorp_police:Client:JobUpdate", function()
    local hasJob = getPlayerJob()

    if not hasJob then
        RegisterCommand(Config.Dragcommand, function()
            Core.NotifyObjective(T.Jobs.YouAreNotAPoliceOfficer, 5000)
        end, false)

        for _, value in pairs(prompts) do
            value:Destroy()
        end

        table.wipe(prompts)
        return
    end

    -- already exists no need to register or start them
    if #prompts > 0 then
        return
    end

    registerLocations()
    RegisterCommand(Config.Dragcommand, dragHandle, false)
end)

--* CREATE BLIPS AND START HANDLE
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession

    createBlips()
    local hasJob <const> = getPlayerJob()
    if not hasJob then return end

    RegisterCommand(Config.Dragcommand, dragHandle, false)
    registerLocations()
end)

function OpenSheriffMenu()
    MenuData.CloseAll()
    local elements <const> = {
        {
            label = T.Menu.HirePlayer,
            value = "hire",
            desc = T.Menu.HirePlayer .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        },
        {
            label = T.Menu.FirePlayer,
            value = "fire",
            desc = T.Menu.FirePlayer .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        }
    }

    MenuData.Open("default", GetCurrentResourceName(), "OpenSheriffMenu", {
        title = T.Menu.SheriffMenu,
        subtext = T.Menu.HireFireMenu,
        align = Config.Align,
        elements = elements,

    }, function(data, _)
        if data.current.value == "hire" then
            OpenHireMenu()
        elseif data.current.value == "fire" then
            local MyInput <const> = {
                type = "enableinput",
                inputType = "input",
                button = T.Player.Confirm,
                placeholder = T.Player.PlayerId,
                style = "block",
                attributes = {
                    inputHeader = T.Menu.FirePlayer,
                    type = "number",
                    pattern = "[0-9]",
                    title = T.Player.OnlyNumbersAreAllowed,
                    style = "border-radius: 10px; background-color: ; border:none;",
                }
            }

            local res = exports.vorp_inputs:advancedInput(MyInput)
            res = tonumber(res)
            if res and res > 0 then
                TriggerServerEvent("vorp_police:server:firePlayer", res)
            end
        end
    end, function(_, menu)
        menu.close()
    end)
end

function OpenHireMenu()
    MenuData.CloseAll()
    local elements = {}
    for key, _ in pairs(Config.PoliceJobs) do
        table.insert(elements, { label = T.Jobs.Job .. ": " .. key, value = key, desc = T.Jobs.Job .. key })
    end

    MenuData.Open("default", GetCurrentResourceName(), "OpenHireFireMenu", {
        title = T.Menu.HireFireMenu,
        subtext = T.Menu.SubMenu,
        elements = elements,
        align = Config.Align,
        lastmenu = "OpenSheriffMenu"

    }, function(data, menu)
        if (data.current == "backup") then
            return _G[data.trigger]()
        end

        menu.close()
        local MyInput = {
            type = "enableinput",
            inputType = "input",
            button = T.Player.Confirm,
            placeholder = T.Player.PlayerId,
            style = "block",
            attributes = {
                inputHeader = T.Menu.HirePlayer,
                type = "number",
                pattern = "[0-9]",
                title = T.Player.OnlyNumbersAreAllowed,
                style = "border-radius: 10px; background-color: ; border:none;",
            }
        }

        local res = exports.vorp_inputs:advancedInput(MyInput)
        res = tonumber(res)
        if res and res > 0 then
            TriggerServerEvent("vorp_police:server:hirePlayer", res, data.current.value)
        end
    end, function(_, menu)
        menu.close()
    end)
end

function OpenTeleportMenu(location)
    MenuData.CloseAll()
    local elements = {}
    for key, value in pairs(Config.Teleports) do
        if location then
            if location ~= key then
                table.insert(elements, {
                    label = key,
                    value = key,
                    desc = T.Teleport.TeleportTo .. ": " .. value.Name
                })
            end
        else
            table.insert(elements, {
                label = key,
                value = key,
                desc = T.Teleport.TeleportTo .. ": " .. value.Name
            })
        end
    end

    MenuData.Open("default", GetCurrentResourceName(), "OpenTeleportMenu", {
        title = T.Teleport.TeleportMenu,
        subtext = T.Menu.SubMenu,
        align = Config.Align,
        elements = elements,

    }, function(data, menu)
        menu.close()
        local coords <const> = Config.Teleports[data.current.value].Coords
        DoScreenFadeOut(1000)
        repeat Wait(0) until IsScreenFadedOut()

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
        repeat Wait(0) until HasCollisionLoadedAroundEntity(PlayerPedId()) == 1

        Wait(4000)
        DoScreenFadeIn(1000)
        repeat Wait(0) until IsScreenFadedIn()
    end, function(_, menu)
        menu.close()
    end)
end

local function OpenPoliceMenu()
    MenuData.CloseAll()
    local isONduty <const> = LocalPlayer.state.isPoliceDuty
    local label <const> = isONduty and T.Duty.OffDuty or T.Duty.OnDuty
    local desc <const> = isONduty and T.Duty.GoOffDuty or T.Duty.GoOnDuty
    local elements <const> = {
        {
            label = label,
            value = "duty",
            desc = desc .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        }
    }

    if Config.UseTeleportsMenu then
        table.insert(elements, {
            label = T.Teleport.TeleportTo,
            value = "teleports",
            desc = T.Teleport.TeleportToDifferentLocations .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        })
    end

    MenuData.Open("default", GetCurrentResourceName(), "OpenPoliceMenu", {
        title = T.Menu.SheriffMenu,
        subtext = T.Menu.SubMenu,
        align = Config.Align,
        elements = elements,

    }, function(data, menu)
        if data.current.value == "teleports" then
            OpenTeleportMenu()
        elseif data.current.value == "duty" then
            local result = Core.Callback.TriggerAwait("vorp_police:server:checkDuty")
            if result then
                Core.NotifyObjective(T.Duty.YouAreNowOnDuty, 5000)
                applyBadge(true)
            else
                Core.NotifyObjective(T.Duty.YouAreNotOnDuty, 5000)
                applyBadge(false)
            end
            menu.close()
        end
    end, function(_, menu)
        menu.close()
    end)
end

--* OPEN POLICE MENU
RegisterNetEvent("vorp_police:Client:OpenPoliceMenu", function()
    OpenPoliceMenu()
end)

--* CUFF PLAYER
RegisterNetEvent('vorp_police:Client:PlayerCuff', function(action)
    local playerPed <const> = PlayerPedId()
    if action == "cuff" then
        CuffPed(playerPed)
        SetEnableHandcuffs(playerPed, true, false)
        SetPedCanPlayGestureAnims(playerPed, false)
        DisplayRadar(false)
    else
        UncuffPed(playerPed)
        SetEnableHandcuffs(playerPed, false, false)
        SetPedCanPlayGestureAnims(playerPed, true)
        DisplayRadar(true)
    end
end)

--* CHECK IF PLAYER IS CUFFED
Core.Callback.Register("vorp_police:server:isPlayerCuffed", function(CB)
    local isclose <const>, playerped <const>, player <const> = getClosestPlayer()
    if not isclose then
        Core.NotifyObjective(T.Player.NoPlayerFound, 5000)
        return CB({ false, false })
    end

    local isCuffed <const> = IsPedCuffed(playerped)
    local serverid <const> = GetPlayerServerId(player)

    return CB({ isCuffed, serverid })
end)

--* DRAG PLAYER
RegisterNetEvent("vorp_police:Client:dragPlayer", function(_source)
    draggedBy = _source
    drag = not drag
end)

--* ON PLAYER DEATH
AddEventHandler("vorp_core:Client:OnPlayerDeath", function()
    if drag then
        drag = false
        wasDragged = true
    end
end)

--* DRAG PLAYER
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession

    while true do
        local sleep = 1000
        if drag then
            wasDragged = true
            local entity2 = GetPlayerPed(GetPlayerFromServerId(draggedBy))
            AttachEntityToEntity(PlayerPedId(), entity2, 4103, 11816, 0.48, 0.00, 0.0, 0.0, 0.0, false, false, false, false, 2, false, true, false)
        else
            if wasDragged then
                wasDragged = false
                DetachEntity(PlayerPedId(), true, false)
            end
        end
        Wait(sleep)
    end
end)

--* ALERT POLICE
RegisterNetEvent("vorp_police:Client:AlertPolice", function(targetCoords)
    if blip ~= 0 then return end -- dont allow more than one call

    blip = BlipAddForCoords(Config.AlertBlips.Style, targetCoords.x, targetCoords.y, targetCoords.z)
    SetBlipSprite(blip, Config.AlertBlips.Sprite, false)
    BlipAddModifier(blip, Config.AlertBlips.Color)
    SetBlipName(blip, Config.AlertBlips.Name)

    blip = Blips:Create('coords', {
        Pos = targetCoords,
        Blip = Config.AlertBlips.Style,
        Options = {
            sprite = Config.AlertBlips.Sprite,
            name = T.Alerts.playeralert,
            modifier = Config.AlertBlips.Color,
        },
    })

    StartGpsMultiRoute(joaat(Config.AlertBlips.Color), true, true)
    AddPointToGpsMultiRoute(targetCoords.x, targetCoords.y, targetCoords.z, false)
    SetGpsMultiRouteRender(true)

    repeat Wait(1000) until #(GetEntityCoords(PlayerPedId()) - targetCoords) < 15.0 or blip == 0

    if blip ~= 0 then
        Core.NotifyObjective(T.Alerts.arive, 5000)
        blip:Remove()
        blip = 0
    end
    ClearGpsMultiRoute()
end)

--* REMOVE BLIP FROM ALERT
RegisterNetEvent("vorp_police:Client:RemoveBlip", function()
    if blip == 0 then return end
    blip:Remove()
    blip = 0
    ClearGpsMultiRoute()
end)

--*RELEASE FROM JAIL
RegisterNetEvent("vorp_police:Client:JailFinished", function()
    playerInJail = false
    if Poly then
        Poly:destroy()
        Poly = nil
    end

    DoScreenFadeOut(1000)
    repeat Wait(0) until IsScreenFadedOut()

    local spawnCoords <const> = Config.jail.FreedSpawnCoords
    RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetEntityCoordsAndHeading(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z, Config.jail.FreedSpawnHeading, false, false, false)
    repeat Wait(0) until HasCollisionLoadedAroundEntity(PlayerPedId()) == 1
    Wait(4000)

    DoScreenFadeIn(1000)
    repeat Wait(0) until IsScreenFadedIn()

    SetTimeout(5000, function()
        Core.NotifyObjective(T.Jail.playerReleasedFromJail, 5000)
    end)
end)

--* JAIL PLAYER
RegisterNetEvent("vorp_police:Client:JailPlayer", function()
    if Poly then return end

    DoScreenFadeOut(1000)
    repeat Wait(0) until IsScreenFadedOut()

    --todo: here we can add prison outfits for players

    local spawnCoords <const> = Config.jail.JailSpawnCoords
    RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetEntityCoordsAndHeading(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z, Config.jail.JailSpawnHeading, false, false, false)
    repeat Wait(0) until HasCollisionLoadedAroundEntity(PlayerPedId()) == 1
    Wait(4000)
    DoScreenFadeIn(1000)
    repeat Wait(0) until IsScreenFadedIn()

    local centerCoords <const> = Config.jail.JailCenterCoords
    local radius <const> = Config.jail.JailRadius
    Poly = CircleZone:Create(centerCoords, radius, { name = "prison" })
    if not Poly then return end

    Poly:onPlayerInOut(function(isPointInside, point)
        if not isPointInside then
            Core.NotifyObjective(T.Jail.cantLeaveJail, 5000)
            Wait(3000)
            SetEntityCoordsAndHeading(PlayerPedId(), Config.jail.JailSpawnCoords.x, Config.jail.JailSpawnCoords.y, Config.jail.JailSpawnCoords.z, Config.jail.JailSpawnHeading, false, false, false)
        end
    end)

    if not playerInJail then
        playerInJail = true
        CreateThread(function()
            --* disable certain actions here
            repeat
                Wait(0)
                DisableControlAction(0, `INPUT_WHISTLE`, true)      -- disable call horse
                DisableControlAction(0, `INPUT_OPEN_JOURNAL`, true) -- disable call wagon
            until not playerInJail
        end)
    end

    SetTimeout(5000, function()
        Core.NotifyObjective(string.format(T.Jail.jailSuggestions.checkJailTimeCommand, Config.jail.Commands.CheckJailTime), 5000)
    end)
end)
