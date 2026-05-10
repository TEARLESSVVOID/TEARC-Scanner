-- ============================================================
-- TEARC-Scanner 玩家音频同步模块
-- 将当前播放的音频同步给附近玩家
-- ============================================================

local Sync = {}
local isSyncEnabled = false

local function GetNearbyPlayerIds()
    local nearby = {}
    local myCoords = GetEntityCoords(PlayerPedId())
    local players = GetActivePlayers()

    for _, player in ipairs(players) do
        local serverId = GetPlayerServerId(player)
        if serverId ~= GetPlayerServerId(PlayerId()) then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local distance = #(myCoords - coords)
                if distance <= Config.PlayerSync.syncRange then
                    table.insert(nearby, serverId)
                end
            end
        end
    end

    return nearby
end

function Sync.BroadcastAudio(category, fileName, coords)
    if not isSyncEnabled then return end

    local nearbyPlayers = GetNearbyPlayerIds()
    if #nearbyPlayers == 0 then return end

    TriggerServerEvent('tearc-scanner:syncAudio', {
        category = category,
        fileName = fileName,
        coords = coords,
        senderId = GetPlayerServerId(PlayerId()),
        targetPlayers = nearbyPlayers,
    })
end

RegisterNetEvent('tearc-scanner:receiveAudio', function(data)
    if not isSyncEnabled then return end

    local senderPlayer = GetPlayerFromServerId(data.senderId)
    if not senderPlayer or senderPlayer == -1 then return end

    local senderPed = GetPlayerPed(senderPlayer)
    if not DoesEntityExist(senderPed) then return end

    local senderCoords = GetEntityCoords(senderPed)
    local myCoords = GetEntityCoords(PlayerPedId())
    local distance = #(senderCoords - myCoords)

    if distance <= Config.PlayerSync.syncRange then
        SendNUIMessage({
            action = 'playAudio',
            data = {
                category = data.category,
                file = data.fileName,
                is3D = Config.SpatialAudio.enabled,
                coords = {
                    x = senderCoords.x,
                    y = senderCoords.y,
                    z = senderCoords.z,
                },
                volume = 0.6,
            }
        })
    end
end)

function Sync.Enable()
    if isSyncEnabled then return end
    isSyncEnabled = true
    TEARC_Notify.Info('玩家音频同步已开启', { duration = 2000 })
end

function Sync.Disable()
    if not isSyncEnabled then return end
    isSyncEnabled = false
    TEARC_Notify.Info('玩家音频同步已关闭', { duration = 2000 })
end

function Sync.Toggle()
    if isSyncEnabled then
        Sync.Disable()
    else
        Sync.Enable()
    end
end

function Sync.IsEnabled()
    return isSyncEnabled
end

TEARC_Sync = Sync
