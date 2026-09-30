if Bridge.Framework ~= 'qbx' then return end

Bridge.GetPlayerJobName = function()
    local playerData = exports.qbx_core:GetPlayerData()
    return playerData and playerData.job and playerData.job.name
end
