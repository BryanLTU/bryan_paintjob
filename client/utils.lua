_ShowNotification = function(msg)
    lib.notify({
        title = msg,
    })
end

_ShowHelpNotification = function(msg)
    lib.showTextUI(msg)
end

Hex2Rgb = function(hex)
    hex = hex:gsub('#', '')
    return { r = tonumber('0x' .. hex:sub(1, 2)), g = tonumber('0x' .. hex:sub(3, 4)), b = tonumber('0x' .. hex:sub(5, 6)) }
end
