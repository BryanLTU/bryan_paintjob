RegisterNetEvent('bryan_paintjob:server:setLocationBusy', function(pos, value)
    TriggerClientEvent('bryan_paintjob:client:setLocationBusy', -1, pos, value)
end)

RegisterNetEvent('bryan_paintjob:server:initalizePaint', function(id, vehicle, color, isPrimary)
    TriggerClientEvent('bryan_paintjob:client:initalizePaint', -1, id, vehicle, color, isPrimary)
end)

RegisterNetEvent('bryan_paintjob:server:stopPaint', function(id)
    TriggerClientEvent('bryan_paintjob:client:stopPaint', -1, id)
end)