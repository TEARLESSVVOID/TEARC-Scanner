-- ============================================================
-- TEARC-Scanner 3D音效引擎
-- 使用NUI HTML5 Audio播放, Lua端计算3D距离衰减
-- ============================================================

local Audio = {}
local activeSounds = {}
local soundIdCounter = 0

local audioPaths = {
    scanner = 'audio/scanner/',
    alerts = 'audio/alerts/',
    backup_transport = 'audio/backup/transport/',
    backup_coroner = 'audio/backup/coroner/',
    backup_animal = 'audio/backup/animal/',
    backup_supervisor = 'audio/backup/supervisor/',
}

local function CalculateAttenuation(distance)
    if not Config.SpatialAudio.enabled then
        return 1.0
    end

    local maxDist = Config.SpatialAudio.maxDistance
    local refDist = Config.SpatialAudio.refDistance
    local rolloff = Config.SpatialAudio.rolloffFactor

    if distance <= refDist then
        return 1.0
    elseif distance >= maxDist then
        return 0.0
    end

    local normalized = (distance - refDist) / (maxDist - refDist)
    local volume = 1.0 - (normalized ^ rolloff)
    return math.max(0.0, math.min(1.0, volume))
end

function Audio.Play3D(category, fileName, coords, options)
    options = options or {}
    local volume = options.volume or 1.0
    local loop = options.loop or false

    if not coords then
        coords = GetEntityCoords(PlayerPedId())
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(coords - playerCoords)

    local spatialVolume = CalculateAttenuation(distance)
    if spatialVolume <= 0.0 then
        return -1
    end

    local finalVolume = volume * spatialVolume

    soundIdCounter = soundIdCounter + 1
    local soundId = soundIdCounter

    local soundData = {
        id = soundId,
        category = category,
        fileName = fileName,
        coords = coords,
        volume = finalVolume,
        baseVolume = volume,
        loop = loop,
        startTime = GetGameTimer(),
        is3D = Config.SpatialAudio.enabled,
    }

    activeSounds[soundId] = soundData

    SendNUIMessage({
        action = 'playAudio',
        data = {
            id = soundId,
            category = category,
            file = fileName,
            volume = finalVolume,
            loop = loop,
            is3D = Config.SpatialAudio.enabled,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            playerCoords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z },
        }
    })

    return soundId
end

function Audio.Play2D(category, fileName, options)
    options = options or {}
    local volume = options.volume or 1.0
    local loop = options.loop or false

    soundIdCounter = soundIdCounter + 1
    local soundId = soundIdCounter

    activeSounds[soundId] = {
        id = soundId,
        category = category,
        fileName = fileName,
        volume = volume,
        baseVolume = volume,
        loop = loop,
        startTime = GetGameTimer(),
        is3D = false,
    }

    SendNUIMessage({
        action = 'playAudio',
        data = {
            id = soundId,
            category = category,
            file = fileName,
            volume = volume,
            loop = loop,
            is3D = false,
        }
    })

    return soundId
end

function Audio.Stop(soundId)
    SendNUIMessage({
        action = 'stopAudio',
        data = { id = soundId }
    })
    activeSounds[soundId] = nil
end

function Audio.StopCategory(category)
    SendNUIMessage({
        action = 'stopCategory',
        data = { category = category }
    })
    for id, data in pairs(activeSounds) do
        if data.category == category then
            activeSounds[id] = nil
        end
    end
end

function Audio.StopAll()
    SendNUIMessage({
        action = 'stopAll',
        data = {}
    })
    activeSounds = {}
end

function Audio.UpdatePosition(soundId, newCoords)
    if not activeSounds[soundId] then return end
    activeSounds[soundId].coords = newCoords

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(newCoords - playerCoords)
    local spatialVolume = CalculateAttenuation(distance)
    local finalVolume = activeSounds[soundId].baseVolume * spatialVolume

    activeSounds[soundId].volume = finalVolume

    SendNUIMessage({
        action = 'updateVolume',
        data = {
            id = soundId,
            volume = finalVolume,
        }
    })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)

        if Config.SpatialAudio.enabled then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local hasActive3D = false

            for id, data in pairs(activeSounds) do
                if data.is3D and data.coords then
                    hasActive3D = true
                    local distance = #(data.coords - playerCoords)
                    local spatialVolume = CalculateAttenuation(distance)
                    local finalVolume = data.baseVolume * spatialVolume

                    local diff = math.abs(data.volume - finalVolume)
                    if diff > 0.02 then
                        data.volume = finalVolume
                        SendNUIMessage({
                            action = 'updateVolume',
                            data = {
                                id = id,
                                volume = finalVolume,
                            }
                        })
                    end
                end
            end

            if not hasActive3D then
                Citizen.Wait(1000)
            end
        else
            Citizen.Wait(2000)
        end
    end
end)

TEARC_Audio = Audio
