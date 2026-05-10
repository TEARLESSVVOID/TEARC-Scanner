-- ============================================================
-- TEARC-Scanner 服务端
-- 处理音频同步事件转发 (定向广播 + 安全验证)
-- ============================================================

local isDebug = Config.Debug
local playerLastSync = {}
local SYNC_COOLDOWN = 2000

local validCategories = {
    scanner = true,
    alerts = true,
    backup_transport = true,
    backup_coroner = true,
    backup_animal = true,
    backup_supervisor = true,
}

RegisterNetEvent('tearc-scanner:syncAudio', function(data)
    local src = source

    if type(data) ~= 'table' then return end
    if type(data.category) ~= 'string' or not validCategories[data.category] then return end
    if type(data.fileName) ~= 'string' or #data.fileName > 64 then return end
    if type(data.coords) ~= 'table' or not data.coords.x or not data.coords.y then return end
    if type(data.senderId) ~= 'number' then return end

    local currentTime = GetGameTimer()
    local lastSync = playerLastSync[src] or 0
    if currentTime - lastSync < SYNC_COOLDOWN then
        return
    end
    playerLastSync[src] = currentTime

    if isDebug then
        print(string.format('[TEARC-Scanner] 同步事件: 玩家%d -> [%s] %s', src, data.category, data.fileName))
    end

    local targetPlayers = data.targetPlayers
    if type(targetPlayers) == 'table' and #targetPlayers > 0 then
        for _, playerId in ipairs(targetPlayers) do
            if type(playerId) == 'number' and playerId ~= src then
                TriggerClientEvent('tearc-scanner:receiveAudio', playerId, {
                    category = data.category,
                    fileName = data.fileName,
                    coords = data.coords,
                    senderId = data.senderId,
                })
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    playerLastSync[source] = nil
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('========================================')
        print('[TEARC-Scanner] 服务端已启动')
        print('[TEARC-Scanner] 版本: 1.0.0')
        print('========================================')
    end
end)
