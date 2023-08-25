local sprayGuns = {}
local isSpraying, isBusy = false, {}
local currLocation

RegisterNetEvent('bryan_paintjob:client:setLocationBusy', function(pos, value)
    isBusy[pos] = value
end)

RegisterNetEvent('bryan_paintjob:client:initalizePaint', function(id, vehicle, color, isPrimary)
    if #(GetEntityCoords(PlayerPedId()) - Config.Locations[id].control) <= 15.0 then
        PaintVehicle(NetToVeh(vehicle), color, isPrimary)
        InitializeParticles(id, color, NetToVeh(vehicle))
        isSpraying = true
    end
end)

RegisterNetEvent('bryan_paintjob:client:stopPaint', function(id)
    if #(GetEntityCoords(PlayerPedId()) - Config.Locations[id].control) <= 15.0 then
        isSpraying = false
    end
end)

Citizen.CreateThread(function()
    for k, v in ipairs(Config.Locations) do SpawnSprayGuns(k) end

    if Config.UseTarget then
        for k, v in ipairs(Config.Locations) do
            exports.ox_target:addSphereZone({
                coords = v.control,
                radius = 0.5,
                options = {
                    {
                        label = 'Paint Job',
                        name = 'paint_job',
                        distance = 2.0,
                        canInteract = function(entity, distance, coords, bone)
                            return DoesHaveRequiredJob(k) and not isBusy[k]
                        end,
                        onSelect = function()
                            InitializePaint(k)
                        end
                    }
                }
            })
        end
    else
        while true do
            local coords = GetEntityCoords(PlayerPedId())

            for k, v in ipairs(Config.Locations) do
                local distance = #(coords - v.control)

                if distance <= 15 and DoesHaveRequiredJob(k) then
                    currLocation = k
                end
            end

            Citizen.Wait(1000)
        end
    end
end)

if not Config.UseTarget then
    Citizen.CreateThread(function()
        local isDrawn = false

        while true do
            local sleep = true

            if currLocation then
                sleep = false

                DrawMarker(27, Config.Locations[currLocation].control.x, Config.Locations[currLocation].control.y, Config.Locations[currLocation].control.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 255, 0, 150, false, false, 2, true, nil, nil, false)

                if #(GetEntityCoords(PlayerPedId()) - Config.Locations[currLocation].control) <= 1.5 then
                    if not isBusy[currLocation] then
                        if not isDrawn then
                            _ShowHelpNotification('Press [E] to open Paint Options')
                            isDrawn = true
                        end

                        if IsControlJustPressed(1, 51) then
                            lib.hideTextUI()
                            isDrawn = false
                            
                            InitializePaint(currLocation)
                        end
                    elseif not isDrawn then
                        _ShowHelpNotification('Paint Room is Busy')
                        isDrawn = true
                    end
                elseif isDrawn then
                    lib.hideTextUI()
                    isDrawn = false
                end
            end

            if sleep then Citizen.Wait(500) end
            Citizen.Wait(0)
        end
    end)
end

DoesHaveRequiredJob = function(pos)
    if not Config.Locations[pos].jobs then return true end

    for k, v in ipairs(Config.Locations[pos].jobs) do
        if v == _GetPlayerJobName() then
            return true
        end
    end

    return false
end

InitializePaint = function(pos)
    currLocation = pos
    local vehicle = GetVehicleInSprayCoords(Config.Locations[pos].vehicle)

    if not vehicle then return _ShowNotification('No vehicle in position') end

    TriggerServerEvent('bryan_paintjob:server:setLocationBusy', pos, true)

    local input = lib.inputDialog('Paint Job', {
        { type = 'select', label = 'Option', options = {
            { value = 'primary', label = 'Primary' },
            { value = 'secondary', label = 'Secondary' }
        }, default = 'primary', clearable = false },
        { type = 'select', label = 'Type', options = {
            { value = '0', label = 'Normal' },
            { value = '1', label = 'Metalic' },
            { value = '2', label = 'Pearl' },
            { value = '3', label = 'Matte' },
            { value = '4', label = 'Metal' },
            { value = '5', label = 'Chrome' },
        }, default = '0', clearable = false },
        { type = 'color', label = 'Colour', default = '#ffffff' }
    })

    if not input then
        TriggerServerEvent('bryan_paintjob:server:setLocationBusy', pos, false)
        return
    end

    local isPrimary = input[1] == 'primary'

    if isPrimary then
        SetVehicleModColor_1(vehicle, tonumber(input[2]), 0, 0)
        SetVehicleExtraColours(vehicle, 0, 0)
    else
        SetVehicleModColor_2(vehicle, tonumber(input[2]), 0)
    end

    TriggerServerEvent('bryan_paintjob:server:initalizePaint', pos, VehToNet(vehicle), Hex2Rgb(input[3]), isPrimary)

    Citizen.CreateThread(function()
        Citizen.Wait(1000)
        while isSpraying do Citizen.Wait(100) end

        TriggerServerEvent('bryan_paintjob:server:setLocationBusy', pos, false)
        TriggerServerEvent('bryan_paintjob:server:stopPaint', pos)
    end)
end

GetVehicleInSprayCoords = function(location)
    local closestVehicle, closestDistance = _GetClosestVehicle(location)

    if closestVehicle ~= -1 and closestDistance <= 2.0 then return closestVehicle end
    
    return nil
end

PaintVehicle = function(vehicle, color, primary)
    local r, g, b = primary and GetVehicleCustomPrimaryColour(vehicle) or GetVehicleCustomSecondaryColour(vehicle)

    Citizen.CreateThread(function()
        isSpraying = true

        while r ~= color.r or g ~= color.g or b ~= color.b do
            Citizen.Wait(100)

            r = color.r ~= r and (color.r > r and r + 1 or r - 1) or r
            g = color.g ~= g and (color.g > g and g + 1 or g - 1) or g
            b = color.b ~= b and (color.b > b and b + 1 or b - 1) or b

            if primary then SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            else SetVehicleCustomSecondaryColour(vehicle, r, g, b) end
        end

        isSpraying = false
    end)
end

InitializeParticles = function(id, color, vehicle)
    Citizen.CreateThread(function()
        local particles = {}

        for k, v in ipairs(sprayGuns) do
            if v.id == id then
                table.insert(particles, SprayParticles('core', 'ent_amb_steam', Config.Locations[v.id].sprays[v.location].scale, color, v.object, Config.Locations[v.id].sprays[v.location].rotation))
            end
        end

        FreezeEntityPosition(vehicle, true)
        
        while isSpraying do Citizen.Wait(100) end
        
        FreezeEntityPosition(vehicle, false)
        
        for k, v in ipairs(particles) do
            StopParticleFxLooped(v, 0)
        end
        
        SprayParticles('scr_paintnspray', 'scr_respray_smoke', 0.5, color, vehicle, vector3(0.0, 0.0, 0.0))
        Citizen.Wait(10 * 1000)
        StopParticleFxLooped(v, 0)
    end)
end

SprayParticles = function(dict, name, scale, color, entity, rotation)
    while not HasNamedPtfxAssetLoaded(dict) do
        RequestNamedPtfxAsset(dict)
        Citizen.Wait(10)
    end

    UseParticleFxAsset(dict)

    local particleHandle = StartParticleFxLoopedOnEntity(name, entity, 0.2, 0.0, 0.1, 0.0, 80.0, 0.0, scale, 0, 0, 0)

    SetParticleFxLoopedAlpha(particleHandle, 100.0)
    SetParticleFxLoopedColour(particleHandle, color.r / 255.0, color.g / 255.0, color.b / 255.0)

    return particleHandle
end

Hex2Rgb = function(hex)
    hex = hex:gsub('#', '')
    return { r = tonumber('0x' .. hex:sub(1, 2)), g = tonumber('0x' .. hex:sub(3, 4)), b = tonumber('0x' .. hex:sub(5, 6)) }
end

SpawnSprayGuns = function(id, vehicleLocation)
    local hash = GetHashKey(Config.SprayModel)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Citizen.Wait(10)
    end

    for k, v in ipairs(Config.Locations[id].sprays) do
        local object = CreateObject(hash, v.pos.x, v.pos.y, v.pos.z, false, true, 0)

        SetEntityRotation(object, v.rotation.x, v.rotation.y, v.rotation.z, 0, 1)
        FreezeEntityPosition(object, true)
        table.insert(sprayGuns, {
            object = object,
            id = id,
            location = k,
        })
    end
end

DeleteSprayGuns = function()
    for k, v in ipairs(sprayGuns) do DeleteObject(v.object) end
end

RegisterNetEvent('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DeleteSprayGuns()
    end
end)