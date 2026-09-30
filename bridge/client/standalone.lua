if Bridge.Framework ~= 'standalone' then return end

-- No framework means no jobs, so job restrictions in the config are ignored
Bridge.GetPlayerJobName = function()
    return nil
end
