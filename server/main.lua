RegisterNetEvent('bryan_paintjob:server:setLocationBusy', function(pos, value)
    TriggerClientEvent('bryan_paintjob:client:setLocationBusy', -1, pos, value)
end)

RegisterNetEvent('bryan_paintjob:server:initalizePaint', function(id, vehicle, color, target, paletteIndex)
    TriggerClientEvent('bryan_paintjob:client:initalizePaint', -1, id, vehicle, color, target, paletteIndex)
end)

RegisterNetEvent('bryan_paintjob:server:stopPaint', function(id)
    TriggerClientEvent('bryan_paintjob:client:stopPaint', -1, id)
end)

local manualSprayers = {}

local FinishManualPaint = function(id, completed)
    manualSprayers[id] = nil
    TriggerClientEvent('bryan_paintjob:client:finishManualPaint', -1, id, completed)
    TriggerClientEvent('bryan_paintjob:client:setLocationBusy', -1, id, false)
end

RegisterNetEvent('bryan_paintjob:server:startManualPaint', function(id, vehicle, color, target, paletteIndex)
    manualSprayers[id] = source
    TriggerClientEvent('bryan_paintjob:client:startManualPaint', -1, id, vehicle, color, target, paletteIndex)
end)

RegisterNetEvent('bryan_paintjob:server:updateManualPaint', function(id, progress)
    if manualSprayers[id] ~= source then return end
    TriggerClientEvent('bryan_paintjob:client:updateManualPaint', -1, id, progress)
end)

RegisterNetEvent('bryan_paintjob:server:setGunSpraying', function(id, prop, state)
    if manualSprayers[id] ~= source then return end
    TriggerClientEvent('bryan_paintjob:client:setGunSpraying', -1, id, prop, state)
end)

RegisterNetEvent('bryan_paintjob:server:finishManualPaint', function(id, completed)
    if manualSprayers[id] ~= source then return end
    FinishManualPaint(id, completed)
end)

AddEventHandler('playerDropped', function()
    for id, src in pairs(manualSprayers) do
        if src == source then FinishManualPaint(id, false) end
    end
end)