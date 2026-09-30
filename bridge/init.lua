Bridge = {}

local frameworks = {
    { name = 'qbx', resource = 'qbx_core' },
    { name = 'qb', resource = 'qb-core' },
    { name = 'esx', resource = 'es_extended' },
}

local function IsResourceRunning(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

local function DetectFramework()
    if Config.Framework and Config.Framework ~= 'auto' then
        return Config.Framework
    end

    for _, framework in ipairs(frameworks) do
        if IsResourceRunning(framework.resource) then
            return framework.name
        end
    end

    return 'standalone'
end

Bridge.Framework = DetectFramework()
