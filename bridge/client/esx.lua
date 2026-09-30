if Bridge.Framework ~= 'esx' then return end

local ESX = exports['es_extended']:getSharedObject()

Bridge.GetPlayerJobName = function()
    local playerData = ESX.GetPlayerData()
    return playerData and playerData.job and playerData.job.name
end
