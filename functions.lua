ESX = exports['es_extended']:getSharedObject()

_ShowHelpNotification = function(msg)
    ESX.ShowHelpNotification(msg)
end

_GetClosestVehicle = function(location)
    return ESX.Game.GetClosestVehicle(location)
end

_GetPlayerJobName = function()
    return ESX.GetPlayerData().job.name
end