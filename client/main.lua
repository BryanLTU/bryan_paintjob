local sprayGuns = {}
local isSpraying, isBusy = false, {}
local currLocation
local manualJobs, sprayGunProp = {}, nil

RegisterNetEvent('bryan_paintjob:client:setLocationBusy', function(pos, value)
    isBusy[pos] = value
end)

RegisterNetEvent('bryan_paintjob:client:startManualPaint', function(id, netVehicle, color, target, paletteIndex)
    if #(GetEntityCoords(PlayerPedId()) - Config.Locations[id].control) > 15.0 then return end

    local vehicle = NetToVeh(netVehicle)
    local job = {
        vehicle = vehicle,
        color = color,
        target = target,
        paletteIndex = paletteIndex,
        start = not paletteIndex and GetVehicleCustomColour(vehicle, target == 'primary') or nil,
        progress = 0.0,
        shown = 0.0,
    }

    manualJobs[id] = job
    FreezeEntityPosition(vehicle, true)

    -- Remote updates arrive in steps, so ease the colour towards the latest progress
    Citizen.CreateThread(function()
        while manualJobs[id] == job do
            if job.shown < job.progress then
                job.shown = math.min(job.progress, job.shown + math.max((job.progress - job.shown) * 0.25, 0.01))

                if job.start then ApplyFadedColour(vehicle, job.start, color, target == 'primary', job.shown) end
            end

            Citizen.Wait(100)
        end
    end)
end)

RegisterNetEvent('bryan_paintjob:client:updateManualPaint', function(id, progress)
    local job = manualJobs[id]
    if job then job.progress = math.max(job.progress, progress) end
end)

RegisterNetEvent('bryan_paintjob:client:setGunSpraying', function(id, netProp, state)
    local job = manualJobs[id]
    if not job then return end

    if state and not job.particle and NetworkDoesNetworkIdExist(netProp) then
        job.particle = SprayParticles('core', 'ent_amb_steam', Config.ManualSpray.particleScale, job.color, NetToObj(netProp))
    elseif not state and job.particle then
        StopParticleFxLooped(job.particle, 0)
        job.particle = nil
    end
end)

RegisterNetEvent('bryan_paintjob:client:finishManualPaint', function(id, completed)
    local job = manualJobs[id]
    if not job then return end

    manualJobs[id] = nil

    if job.particle then StopParticleFxLooped(job.particle, 0) end

    if completed then
        if job.paletteIndex then ApplyPalette(job.vehicle, job.target, job.paletteIndex)
        else ApplyFadedColour(job.vehicle, job.start, job.color, job.target == 'primary', 1.0) end

        Citizen.CreateThread(function()
            local smoke = SprayParticles('scr_paintnspray', 'scr_respray_smoke', 0.5, job.color, job.vehicle, vector3(0.0, 0.0, 0.0))
            Citizen.Wait(10 * 1000)
            StopParticleFxLooped(smoke, 0)
        end)
    end

    FreezeEntityPosition(job.vehicle, false)
end)

RegisterNetEvent('bryan_paintjob:client:initalizePaint', function(id, vehicle, color, target, paletteIndex)
    if #(GetEntityCoords(PlayerPedId()) - Config.Locations[id].control) <= 15.0 then
        if paletteIndex then
            PaintPalette(NetToVeh(vehicle), target, paletteIndex)
        else
            PaintVehicle(NetToVeh(vehicle), color, target == 'primary')
        end
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

            if currLocation and not sprayGunProp then
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
    if not Config.Locations[pos].jobs or Bridge.Framework == 'standalone' then return true end

    local jobName = Bridge.GetPlayerJobName()

    for k, v in ipairs(Config.Locations[pos].jobs) do
        if v == jobName then
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

    local palettes = {
        wheels = Config.WheelColours,
        chameleon = Config.ChameleonColours,
    }

    local options = {
        { value = 'primary', label = 'Primary' },
        { value = 'secondary', label = 'Secondary' },
        { value = 'wheels', label = 'Wheels' },
    }

    if Config.ChameleonColours and #Config.ChameleonColours > 0 then
        table.insert(options, { value = 'chameleon', label = 'Chameleon' })
    end

    local fields = {
        { type = 'select', label = 'Option', options = options, default = 'primary', clearable = false },
    }

    if Config.ManualSpray and Config.ManualSpray.enabled then
        table.insert(fields, { type = 'select', label = 'Method', options = {
            { value = 'booth', label = 'Paint Booth' },
            { value = 'gun', label = 'Spray Gun' },
        }, default = 'booth', clearable = false })
    end

    local option = lib.inputDialog('Paint Job', fields)

    if not option then
        TriggerServerEvent('bryan_paintjob:server:setLocationBusy', pos, false)
        return
    end

    local target, method = option[1], option[2] or 'booth'
    local color, paletteIndex

    if palettes[target] then
        local colourOptions = {}

        for k, v in ipairs(palettes[target]) do
            table.insert(colourOptions, { value = tostring(k), label = v.label })
        end

        local input = lib.inputDialog('Paint Job', {
            { type = 'select', label = 'Colour', options = colourOptions, default = '1', clearable = false, searchable = true },
        })

        if not input then
            TriggerServerEvent('bryan_paintjob:server:setLocationBusy', pos, false)
            return
        end

        local colour = palettes[target][tonumber(input[1])]

        color, paletteIndex = Hex2Rgb(colour.hex), colour.index
    else
        local input = lib.inputDialog('Paint Job', {
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

        if target == 'primary' then
            local _, wheelColour = GetVehicleExtraColours(vehicle)

            SetVehicleModColor_1(vehicle, tonumber(input[1]), 0, 0)
            SetVehicleExtraColours(vehicle, 0, wheelColour)
        else
            SetVehicleModColor_2(vehicle, tonumber(input[1]), 0)
        end

        color = Hex2Rgb(input[2])
    end

    if method == 'gun' then
        TriggerServerEvent('bryan_paintjob:server:startManualPaint', pos, VehToNet(vehicle), color, target, paletteIndex)
        Citizen.CreateThread(function() StartSprayGun(pos, vehicle) end)
        return
    end

    TriggerServerEvent('bryan_paintjob:server:initalizePaint', pos, VehToNet(vehicle), color, target, paletteIndex)

    Citizen.CreateThread(function()
        Citizen.Wait(1000)
        while isSpraying do Citizen.Wait(100) end

        TriggerServerEvent('bryan_paintjob:server:setLocationBusy', pos, false)
        TriggerServerEvent('bryan_paintjob:server:stopPaint', pos)
    end)
end

GetVehicleInSprayCoords = function(location)
    return lib.getClosestVehicle(location, 2.0, true)
end

GetVehicleCustomColour = function(vehicle, primary)
    local r, g, b

    if primary then r, g, b = GetVehicleCustomPrimaryColour(vehicle)
    else r, g, b = GetVehicleCustomSecondaryColour(vehicle) end

    return { r = r, g = g, b = b }
end

ApplyFadedColour = function(vehicle, start, color, primary, progress)
    local r = math.floor(start.r + (color.r - start.r) * progress + 0.5)
    local g = math.floor(start.g + (color.g - start.g) * progress + 0.5)
    local b = math.floor(start.b + (color.b - start.b) * progress + 0.5)

    if primary then SetVehicleCustomPrimaryColour(vehicle, r, g, b)
    else SetVehicleCustomSecondaryColour(vehicle, r, g, b) end
end

PaintVehicle = function(vehicle, color, primary)
    local start = GetVehicleCustomColour(vehicle, primary)

    Citizen.CreateThread(function()
        isSpraying = true

        local duration = math.max(Config.SprayDuration, 0.1) * 1000
        local startTime = GetGameTimer()
        local progress = 0.0

        while progress < 1.0 do
            Citizen.Wait(100)

            progress = math.min((GetGameTimer() - startTime) / duration, 1.0)

            ApplyFadedColour(vehicle, start, color, primary, progress)
        end

        isSpraying = false
    end)
end

ApplyPalette = function(vehicle, target, index)
    if target == 'wheels' then
        local pearlescentColour = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, pearlescentColour, index)
    elseif target == 'chameleon' then
        local _, wheelColour = GetVehicleExtraColours(vehicle)

        -- Custom RGB colours would render on top of the chameleon ramp
        ClearVehicleCustomPrimaryColour(vehicle)
        ClearVehicleCustomSecondaryColour(vehicle)
        SetVehicleColours(vehicle, index, index)
        SetVehicleExtraColours(vehicle, 0, wheelColour)
    end
end

-- Palette colours can't fade like custom RGB, so they are applied once the spray finishes
PaintPalette = function(vehicle, target, index)
    Citizen.CreateThread(function()
        isSpraying = true

        Citizen.Wait(math.max(Config.SprayDuration, 0.1) * 1000)

        ApplyPalette(vehicle, target, index)

        isSpraying = false
    end)
end

local sprayZoneLabels = { front = 'Front', back = 'Back', left = 'Left', right = 'Right', roof = 'Roof' }

-- Splits the vehicle into sides by where the hit landed relative to its model bounds
GetSprayZone = function(vehicle, coords, min, max)
    local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, coords.x, coords.y, coords.z)

    if offset.z > max.z - (max.z - min.z) * 0.25 then return 'roof' end

    local x = offset.x / math.max(math.abs(offset.x >= 0 and max.x or min.x), 0.01)
    local y = offset.y / math.max(math.abs(offset.y >= 0 and max.y or min.y), 0.01)

    if math.abs(y) >= math.abs(x) then return y >= 0 and 'front' or 'back' end

    return x >= 0 and 'right' or 'left'
end

-- lib.raycast.cam waits frames for the result, which makes everything drawn in the spray loop flicker
RaycastFromCamera = function(ped, distance)
    local camCoords, camRot = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local pitch, yaw = math.rad(camRot.x), math.rad(camRot.z)
    local direction = vector3(-math.sin(yaw) * math.abs(math.cos(pitch)), math.cos(yaw) * math.abs(math.cos(pitch)), math.sin(pitch))
    local destination = camCoords + direction * distance

    local handle = StartExpensiveSynchronousShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 1 | 2, ped, 4)
    local _, hit, endCoords, _, entity = GetShapeTestResult(handle)

    return hit == 1, entity, endCoords
end

StartAiming = function(ped)
    SetPedConfigFlag(ped, 36, true)
    TaskMoveNetworkByName(ped, 'task_mp_pointing', 0.5, false, 'anim@mp_point', 24)
end

UpdateAiming = function(ped)
    local pitch = math.max(-70.0, math.min(GetGameplayCamRelativePitch(), 42.0))
    local heading = math.max(-180.0, math.min(GetGameplayCamRelativeHeading(), 180.0))

    SetTaskMoveNetworkSignalFloat(ped, 'Pitch', (pitch + 70.0) / 112.0)
    SetTaskMoveNetworkSignalFloat(ped, 'Heading', 1.0 - (heading + 180.0) / 360.0)
    SetTaskMoveNetworkSignalBool(ped, 'isBlocked', false)
    SetTaskMoveNetworkSignalBool(ped, 'isFirstPerson', GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
end

StopAiming = function(ped)
    RequestTaskMoveNetworkStateTransition(ped, 'Stop')
    ClearPedSecondaryTask(ped)
    SetPedConfigFlag(ped, 36, false)
end

StartSprayGun = function(pos, vehicle)
    local cfg = Config.ManualSpray
    local ped = PlayerPedId()

    local timeout = GetGameTimer() + 5000
    while not manualJobs[pos] and GetGameTimer() < timeout do Citizen.Wait(0) end

    local job = manualJobs[pos]

    if not job then
        TriggerServerEvent('bryan_paintjob:server:finishManualPaint', pos, false)
        return
    end

    local hash = GetHashKey(cfg.model)
    lib.requestModel(hash)
    lib.requestAnimDict(cfg.anim.dict)
    lib.requestAnimDict('anim@mp_point')

    local coords = GetEntityCoords(ped)
    sprayGunProp = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    AttachEntityToEntity(sprayGunProp, ped, GetPedBoneIndex(ped, cfg.bone), cfg.offset.x, cfg.offset.y, cfg.offset.z, cfg.rotation.x, cfg.rotation.y, cfg.rotation.z, true, true, false, true, 1, true)

    local netProp = ObjToNet(sprayGunProp)
    SetPedConfigFlag(ped, 122, true)

    local duration = math.max(Config.SprayDuration, 0.1)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))

    local zones
    if cfg.zones then
        zones = job.target == 'wheels' and { 'left', 'right' } or { 'front', 'back', 'left', 'right', 'roof' }
    end

    local coverage = {}
    for _, zone in ipairs(zones or { 'body' }) do coverage[zone] = 0.0 end
    local zoneCount = zones and #zones or 1

    local spraying, aiming, completed, progress, lastSent, animCheckAt, lastText = false, false, false, 0.0, 0.0, 0, nil

    while true do
        Citizen.Wait(0)

        for _, control in ipairs({ 24, 25, 140, 141, 142, 257, 263, 264 }) do DisableControlAction(0, control, true) end
        DisablePlayerFiring(PlayerId(), true)

        if IsDisabledControlJustPressed(0, cfg.cancelKey) or IsEntityDead(ped) or not DoesEntityExist(vehicle)
            or #(GetEntityCoords(ped) - Config.Locations[pos].vehicle) > cfg.maxDistance then
            break
        end

        local hit, entity, endCoords
        local aimPressed = IsDisabledControlPressed(0, 25)

        if aimPressed ~= aiming then
            aiming = aimPressed

            if aiming then
                StopAnimTask(ped, cfg.anim.dict, cfg.anim.clip, 2.0)
                StartAiming(ped)
            else
                StopAiming(ped)
                animCheckAt = 0
            end
        end

        if aiming then
            UpdateAiming(ped)

            hit, entity, endCoords = RaycastFromCamera(ped, cfg.range + 10.0)

            DrawRect(0.5, 0.5, 0.003, 0.005, 255, 255, 255, 200)
        elseif GetGameTimer() > animCheckAt and not IsEntityPlayingAnim(ped, cfg.anim.dict, cfg.anim.clip, 3) then
            -- The anim isn't reported as playing for a few frames after starting, so only recheck it once it had time to blend in
            TaskPlayAnim(ped, cfg.anim.dict, cfg.anim.clip, 4.0, -4.0, -1, 49, 0, false, false, false)
            animCheckAt = GetGameTimer() + 1000
        end

        local pressed = aiming and IsDisabledControlPressed(0, 24)

        if pressed ~= spraying then
            spraying = pressed
            TriggerServerEvent('bryan_paintjob:server:setGunSpraying', pos, netProp, spraying)
        end

        if spraying then
            if hit and entity == vehicle and #(GetEntityCoords(ped) - endCoords) <= cfg.range then
                local zone = zones and GetSprayZone(vehicle, endCoords, min, max) or 'body'

                if coverage[zone] then
                    coverage[zone] = math.min(coverage[zone] + GetFrameTime() * zoneCount / duration, 1.0)

                    local total = 0.0
                    for _, value in pairs(coverage) do total = total + value end
                    progress = total / zoneCount
                    job.progress = math.max(job.progress, progress)

                    if progress >= 1.0 then
                        completed = true
                        break
                    end

                    if progress - lastSent >= 0.05 then
                        lastSent = progress
                        TriggerServerEvent('bryan_paintjob:server:updateManualPaint', pos, progress)
                    end
                end
            end
        end

        local text = ('Painting: %d%%'):format(math.floor(progress * 100))

        if zones then
            for _, zone in ipairs(zones) do
                text = text .. ('  \n%s: %d%%'):format(sprayZoneLabels[zone], math.floor(coverage[zone] * 100))
            end
        end

        text = text .. '  \n[RMB] Aim  \n[LMB] Spray  \n[X] Cancel'

        if text ~= lastText or not lib.isTextUIOpen() then
            lib.showTextUI(text)
            lastText = text
        end
    end

    lib.hideTextUI()
    if aiming then StopAiming(ped) end
    StopAnimTask(ped, cfg.anim.dict, cfg.anim.clip, 1.0)
    RemoveAnimDict(cfg.anim.dict)
    RemoveAnimDict('anim@mp_point')
    SetPedConfigFlag(ped, 122, false)
    DeleteEntity(sprayGunProp)
    sprayGunProp = nil

    TriggerServerEvent('bryan_paintjob:server:finishManualPaint', pos, completed)
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

        if sprayGunProp then
            DeleteEntity(sprayGunProp)
            ClearPedTasks(PlayerPedId())
            SetPedConfigFlag(PlayerPedId(), 122, false)
            SetPedConfigFlag(PlayerPedId(), 36, false)
            lib.hideTextUI()
        end
    end
end)
