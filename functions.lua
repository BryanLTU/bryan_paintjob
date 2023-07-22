ESX = exports['es_extended']:getSharedObject()

_ShowNotification = function(msg)
    lib.notify({
        title = msg,
    })
end

_ShowHelpNotification = function(msg)
    lib.showTextUI(msg)
end

_GetClosestVehicle = function(location)
    return ESX.Game.GetClosestVehicle(location)
end

_GetPlayerJobName = function()
    return ESX.GetPlayerData().job.name
end