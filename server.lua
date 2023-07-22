RegisterNetEvent('bryan_paintjob:server:setLocationBusy', function(pos, value)
    TriggerClientEvent('bryan_paintjob:client:setLocationBusy', -1, pos, value)
end)