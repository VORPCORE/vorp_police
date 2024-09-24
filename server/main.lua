local Core      = exports.vorp_core:GetCore()
local Inv       = exports.vorp_inventory
local T         = Translation.Langs[Config.Lang]

local function registerStorage(prefix, name, limit)
    local isInvRegstered <const> = Inv:isCustomInventoryRegistered(prefix)
    if not isInvRegstered then
        local data <const> = {
            id = prefix,
            name = name,
            limit = limit,
            acceptWeapons = true,
            shared = true,
            ignoreItemStackLimit = true,
            whitelistItems = false,
            UsePermissions = false,
            UseBlackList = false,
            whitelistWeapons = false,
            webhook = ""  --Add webhook Url here
        
        }
        Inv:registerInventory(data)
    end
end

local function hasJob(user)
    local Character <const> = user.getUsedCharacter
    return Config.PoliceJobs[Character.job]
end

local function isOnDuty(source)
    return Player(source).state.isPoliceDuty
end

local function isPlayerNear(source, target)
    local sourcePos <const> = GetEntityCoords(GetPlayerPed(source))
    local targetPos <const> = GetEntityCoords(GetPlayerPed(target))
    local distance <const> = #(sourcePos - targetPos)
    return distance <= 5
end

local function openPoliceMenu(source)
    local user <const> = Core.getUser(source)
    if not user then return end

    if not hasJob(user) then
        return Core.NotifyObjective(source, T.Jobs.YouAreNotAPoliceOfficer, 5000)
    end

    TriggerClientEvent('vorp_police:Client:OpenPoliceMenu', source)
end


--* OPEN STORAGE
RegisterNetEvent("vorp_police:Server:OpenStorage", function(key)
    local _source <const> = source
    local User <const> = Core.getUser(_source)
    if not User then return end

    if not hasJob(User) then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotAPoliceOfficer, 5000)
    end

    if not isOnDuty(_source) then
        return Core.NotifyObjective(_source, T.Duty.YouAreNotOnDuty, 5000)
    end

    local prefix = "vorp_police_storage_" .. key
    if Config.ShareStorage then
        prefix = "vorp_police_storage"
    end

    local storageName <const> = Config.Storage[key].Name
    local storageLimit <const> = Config.Storage[key].Limit
    registerStorage(prefix, storageName, storageLimit)
    Inv:openInventory(_source, prefix)
end)

--* CLEANUP
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, value in pairs(Config.Storage) do
        local prefix = "vorp_police_storage_" .. key
        if Config.ShareStorage then
            prefix = "vorp_police_storage"
        end
        Inv:removeInventory(prefix)
    end

    local players <const> = GetPlayers()
    for i = 1, #players do
        local _source <const> = players[i]
        Player(_source).state:set('isPoliceDuty', nil, true)
    end
end)

--* REGISTER STORAGE
AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, value in pairs(Config.Storage) do
        local prefix = "vorp_police_storage_" .. key
        if Config.ShareStorage then
            prefix = "vorp_police_storage"
        end
        registerStorage(prefix, value.Name, value.Limit)
    end

        if Config.DevMode then
           TriggerClientEvent("chat:addSuggestion", -1, "/" .. Config.PoliceMenuCommand, T.Menu.OpenPoliceMenu, {})
           RegisterCommand(Config.PoliceMenuCommand, openPoliceMenu, false)
        end
end)

-- vorpCharSelect
AddEventHandler("vorp:SelectedCharacter", function(source, char)
    if not Config.PoliceJobs[char.job] then return end
    -- add chat suggestion
    TriggerClientEvent("chat:addSuggestion", source, "/" .. Config.PoliceMenuCommand, T.Menu.OpenPoliceMenu, {})
    RegisterCommand(Config.PoliceMenuCommand, openPoliceMenu, false)
end)

--* HIRE PLAYER
RegisterNetEvent("vorp_police:server:hirePlayer", function(id, job)
    local _source <const> = source
    local User <const> = Core.getUser(_source)
    if not User then return end

    if not hasJob(User) then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotAPoliceOfficer, 5000)
    end

    local label <const> = Config.JobLabels[job]
    if not label then return print(T.Jobs.Nojoblabel) end

    local target <const> = id
    local targetUser <const> = Core.getUser(target)
    if not targetUser then return Core.NotifyObjective(_source, T.Player.NoPlayerFound, 5000) end

    local targetCharacter <const> = targetUser.getUsedCharacter
    local targetJob <const> = targetCharacter.job
    if job == targetJob then
        return Core.NotifyObjective(_source, T.Player.PlayeAlreadyHired .. label, 5000)
    end

    if not isPlayerNear(_source, target) then
        return Core.NotifyObjective(_source, T.Player.NotNear, 5000)
    end

    targetCharacter.setJob(job, true)
    targetCharacter.setJobLabel(label, true)

    Core.NotifyObjective(target, T.Player.HireedPlayer .. label, 5000)
    Core.NotifyObjective(_source, T.Menu.HirePlayer, 5000)

    TriggerClientEvent("chat:addSuggestion", _source, "/" .. Config.PoliceMenuCommand, T.Menu.OpenPoliceMenu, {})
    RegisterCommand(Config.PoliceMenuCommand, openPoliceMenu, false)

    TriggerClientEvent("vorp_police:Client:JobUpdate", target)
end)

--* FIRE PLAYER
RegisterNetEvent("vorp_police:server:firePlayer", function(id)
    local _source <const> = source
    local user <const> = Core.getUser(_source)
    if not user then return end

    if not hasJob(user) then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotAPoliceOfficer, 5000)
    end

    local target <const> = id
    local targetUser <const> = Core.getUser(target)
    if not targetUser then return Core.NotifyObjective(_source, T.Player.NoPlayerFound, 5000) end

    local targetCharacter <const> = targetUser.getUsedCharacter
    local targetJob <const> = targetCharacter.job
    if not Config.PoliceJobs[targetJob] then
        return Core.NotifyObjective(_source, T.Player.CantFirenotHired, 5000)
    end

    targetCharacter.setJob("unemployed", true)
    targetCharacter.setJobLabel("Unemployed", true)

    Core.NotifyObjective(target, T.Player.BeenFireed, 5000)
    Core.NotifyObjective(_source, T.Player.FiredPlayer, 5000)

    if isOnDuty(target) then
        Player(target).state:set('isPoliceDuty', nil, true)
    end

    TriggerClientEvent("vorp_police:Client:JobUpdate", target)
end)

RegisterServerEvent('vorp_police:Server:dragPlayer', function(target)
    local _source <const> = source
    local _target <const> = target
    local user = Core.getUser(_source)
    if not user then return end
    if not hasJob(user) then return end

    if target > 0 and Core.getUser(_target) then
        TriggerClientEvent("vorp_police:Client:dragPlayer", _target, _source)
    end
end)

CreateThread(function()
    if not Config.CuffItem or not Config.KeysItem then return end

    -- register cuffs
    Inv:registerUsableItem(Config.CuffItem, function(data)
        local _source <const> = data.source

        Inv:closeInventory(_source)

        local result <const> = Core.Callback.TriggerAwait("vorp_police:server:isPlayerCuffed", _source)
        if result[1] then
            Core.NotifyObjective(_source, T.Cuff.PlayerCuffAlready, 5000)
            return
        end
        -- no player nearby
        if not result[2] or result[2] == 0 then return end

        Inv:subItem(_source, Config.CuffItem, 1)
        TriggerClientEvent("vorp_police:Client:PlayerCuff", result[2], "cuff")
    end)

    Inv:registerUsableItem(Config.KeysItem, function(data)
        local _source <const> = data.source

        Inv:closeInventory(_source)

        local result <const> = Core.Callback.TriggerAwait("vorp_police:server:isPlayerCuffed", _source)
        if not result[1] then
            Core.NotifyObjective(_source, T.Cuff.PlayerNotcuffed, 5000)
            return
        end

        if not result[2] then return end

        local hasCuffs <const> = Inv:getItem(_source, Config.CuffItem)
        if not hasCuffs then
            Inv:addItem(_source, Config.CuffItem, 1)
        end

        TriggerClientEvent("vorp_police:Client:PlayerCuff", result[2], "uncuff")
    end)
end)

--* CHECK IF PLAYER IS ON DUTY
Core.Callback.Register("vorp_police:server:checkDuty", function(source, CB, args)
    local user <const> = Core.getUser(source)
    if not user then return end

    if not hasJob(user) then
        return CB(false)
    end

    if not isOnDuty(source) then
        Player(source).state:set('isPoliceDuty', true, true)
        return CB(true)
    end

    Player(source).state:set('isPoliceDuty', false, true)
    return CB(false)
end)

--* ON PLAYER DROP
AddEventHandler("playerDropped", function()
    local _source = source
    if Player(_source).state.isPoliceDuty then
        Player(_source).state:set('isPoliceDuty', nil, true)
    end
end)

--* ON PLAYER JOB CHANGE
AddEventHandler("vorp:playerJobChange", function(source, new, old)
    if not Config.PoliceJobs[new] then return end
    TriggerClientEvent("vorp_police:Client:JobUpdate", source)
end)
