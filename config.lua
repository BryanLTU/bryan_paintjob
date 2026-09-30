Config = {}

-- 'auto', 'esx', 'qb', 'qbx' or 'standalone'
Config.Framework = 'auto'

Config.UseTarget = true

Config.Locations = {
    {
        control = vector3(-204.18, -1321.64, 31.29),
        vehicle = vector3(-198.85, -1324.42, 31.13),
        sprays = {
            { pos = vector3(-201.01, -1321.78, 31.13), rotation = vector3(0, 25, -90), scale = 1.2 },
            { pos = vector3(-197.49, -1321.78, 31.13), rotation = vector3(0, 25, -90), scale = 1.2 },
            { pos = vector3(-195.2, -1324.85, 31.13), rotation = vector3(0, 25, 180), scale = 1.2 },
            { pos = vector3(-195.2, -1323.96, 31.13), rotation = vector3(0, 25, 180), scale = 1.2 },
            { pos = vector3(-197.52, -1326.85, 31.13), rotation = vector3(0, 25, 90), scale = 1.2 },
            { pos = vector3(-201.13, -1326.85, 31.13), rotation = vector3(0, 25, 90), scale = 1.2 },
        },
        jobs = {'mechanic'}, -- false
    },
}

Config.SprayModel = 'prop_tool_nailgun'

Config.SprayDuration = 10 -- seconds it takes to fully change the colour

-- index: https://docs.fivem.net/docs/game-references/vehicle-references/vehicle-colours/
Config.WheelColours = {
    { label = 'Black', index = 0, hex = '#0d1116' },
    { label = 'Matte Black', index = 12, hex = '#13181f' },
    { label = 'Silver', index = 4, hex = '#99a0a6' },
    { label = 'Chrome', index = 120, hex = '#d2d2d2' },
    { label = 'White', index = 111, hex = '#f0f0f0' },
    { label = 'Red', index = 27, hex = '#c00e1a' },
    { label = 'Orange', index = 38, hex = '#f78616' },
    { label = 'Classic Gold', index = 37, hex = '#c2944f' },
    { label = 'Bronze', index = 90, hex = '#915e3e' },
    { label = 'Yellow', index = 88, hex = '#ffcf20' },
    { label = 'Green', index = 53, hex = '#155c2d' },
    { label = 'Blue', index = 64, hex = '#47578f' },
    { label = 'Hot Pink', index = 135, hex = '#f21f99' },
}
