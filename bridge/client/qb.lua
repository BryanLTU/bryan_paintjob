if Bridge.Framework ~= 'qb' then return end

local QBCore = exports['qb-core']:GetCoreObject()

Bridge.GetPlayerJobName = function()
    local playerData = QBCore.Functions.GetPlayerData()
    return playerData and playerData.job and playerData.job.name
end
