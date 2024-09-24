Config = {}
Config.DevMode = true
Config.Align                = "top-left"   -- menu alignment
Config.Lang                 = "English"    -- language you want to use please make sure its in the translation.lua
Config.Dragcommand          = "Drag"       --Comand to drag players
Config.PoliceMenuCommand    = 'policemenu' -- Command to go on duty and teleport
-- add any job names here
Config.PoliceJobs = {
    police = true,
    sheriff = true,
    marshall = true,
}

Config.Keys = { -- prompts
    B = 0x4CC0E2FE,
}

-- jobs allowed to hire
Config.JobLabels = {
    police = "Police",
    sheriff = "Sheriff",
    marshall = "Marshall",
}


-- jobs that can open hire menu
Config.SheriffJobs = {
    sheriff = true,
    marshall = true,
}



-- items
Config.CuffItem = "handcuffs"   -- can only uncuff if theres a key for the handcuffs

Config.KeysItem =
"handcuffkey"                   -- when you uncuff a player you will get items handcuffs if it doesnt have one already in your inventory


-- if true storage for every police station will be shared if false they will be unique
Config.ShareStorage = true

-- storage locations
--check the server.lua for webhook url location line 19 in server.lua
Config.Storage = {

    Valentine = {
        Name = "Storage",
        Limit = 1000,
        Coords = vector3(-277.004, 810.934, 118.382),
    },
    Strawberry = {
        Name = "Storage",
        Limit = 1000,
        Coords = vector3(-1811.868, -353.766, 163.649),
    },
    Blackwater = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(-766.4104, -1271.5747, 44.0613),
    },
    Rhodes = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(1361.552, -1303.204, 76.767),

    },
    SaintDenis = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(2507.538, -1301.395, 47.953),

    },
    Tumbleweed = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(-5526.896, -2928.556, -2.360),
    },
    Annesburg = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(2909.674, 1309.006, 43.938),
    },
}

-- if true players can use teleport from the police menu if false only from locations
Config.UseTeleportsMenu = true

-- set up locations to teleport to or from
Config.Teleports = {

    Valentine = {
        Name = " Valentine",
        Coords = vector3(-282.46, 819.99, 119.4),
    },
    Strawberry = {
        Name = "Strawberry",
        Coords = vector3(-1811.868, -353.766, 163.649),
    },
    Blackwater = {
        Name = "Blackwater",
        Coords = vector3(-766.4104, -1271.5747, 44.0613),
    },
    Rhodes = {
        Name = "Rhodes",
        Coords = vector3(1361.552, -1303.204, 76.767),

    },
    SaintDenis = {
        Name = "Saint Denis",
        Coords = vector3(2507.538, -1301.395, 47.953),

    },
    Tumbleweed = {
        Name = "Tumbleweed",
        Coords = vector3(-5526.896, -2928.556, -2.360),
    },
    Annesburg = {
        Name = "Annesburg",
        Coords = vector3(2909.674, 1309.006, 43.938),
    },
}

--blips for stations
Config.Blips = {
    Sprite = "blip_mp_bounty_hunter_introduction",
    Color = "COLOR_WHITE",
    Style = "BLIP_STYLE_FRIENDLY_ON_RADAR",
}

-- police stations  boss menu locations
Config.Stations = {

    Valentine = {
        Name = "Valentine",
        Coords = vector3(-277.07, 803.76, 119.43),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Strawberry = {
        Name = "Strawberry",
        Coords = vector3(-1811.868, -353.766, 163.649),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Blackwater = {
        Name = "Blackwater",
        Coords = vector3(-766.4104, -1271.5747, 44.0613),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Rhodes = {
        Name = "Rhodes",
        Coords = vector3(1361.552, -1303.204, 76.767),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    SaintDenis = {
        Name = "Saint Denis",
        Coords = vector3(2507.538, -1301.395, 47.953),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Tumbleweed = {
        Name = "Tumbleweed",
        Coords = vector3(-5526.896, -2928.556, -2.360),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Annesburg = {
        Name = "Annesburg",
        Coords = vector3(2909.674, 1309.006, 43.938),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
}
