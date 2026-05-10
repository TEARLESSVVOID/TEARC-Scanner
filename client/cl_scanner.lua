-- ============================================================
-- TEARC-Scanner 扫描器播放逻辑
-- 主音频: scanner背景chatter
-- 趣味补充: alerts/backup/dispatch 偶尔穿插播放
-- ============================================================

local Scanner = {}
local isEnabled = false
local isPlaying = false
local lastPlayedCategory = nil
local consecutiveSameType = 0
local recentPlayedFiles = {}
local recentMaxSize = 30
local dispatchCooldownUntil = 0
local chatterTimer = 0
local dispatchTimer = 0

local audioIndex = {
    scanner = {
        'Scanner_01.wav', 'Scanner_02.wav', 'Scanner_03.wav', 'Scanner_04.wav',
        'Scanner_05.wav', 'Scanner_06.wav', 'Scanner_07.wav', 'Scanner_08.wav',
        'Scanner_09.wav', 'Scanner_10.wav', 'Scanner_11.wav', 'Scanner_12.wav',
        'Scanner_13.wav', 'Scanner_14.wav', 'Scanner_15.wav', 'Scanner_16.wav',
        'Scanner_17.wav', 'Scanner_18.wav', 'Scanner_19.wav', 'Scanner_20.wav',
        'Scanner_21.wav', 'Scanner_22.wav', 'Scanner_23.wav', 'Scanner_24.wav',
        'Scanner_25.wav', 'Scanner_26.wav', 'Scanner_27.wav', 'Scanner_28.wav',
        'Scanner_29.wav', 'Scanner_30.wav', 'Scanner_31.wav', 'Scanner_32.wav',
        'Scanner_33.wav', 'Scanner_34.wav', 'Scanner_35.wav', 'Scanner_36.wav',
        'Scanner_37.wav', 'Scanner_38.wav', 'Scanner_39.wav', 'Scanner_40.wav',
    },
    alerts = {
        'Driver.wav', 'Felonystop.wav', 'Handsup.wav', 'Liftair.wav',
        'Passenger.wav', 'Passenger2.wav', 'Passenger3.wav',
        'PR_Passenger.wav', 'PR_Passenger2.wav', 'PR_Passenger3.wav',
    },
    backup_transport = {
        'transport.wav', 'transport_01.wav', 'transport_02.wav',
    },
    backup_coroner = {
        'coroner.wav', 'coroner_01.wav', 'coroner_02.wav',
    },
    backup_animal = {
        'animal.wav', 'animal_01.wav',
    },
    backup_supervisor = {
        'supervisor.wav', 'supervisor_01.wav',
    },
}

local funCategories = {
    'alerts',
    'backup_transport',
    'backup_coroner',
    'backup_animal',
    'backup_supervisor',
}

local function WasRecentlyPlayed(fileName)
    for _, recent in ipairs(recentPlayedFiles) do
        if recent == fileName then
            return true
        end
    end
    return false
end

local function RecordPlayback(category, fileName)
    table.insert(recentPlayedFiles, 1, fileName)
    if #recentPlayedFiles > recentMaxSize then
        table.remove(recentPlayedFiles)
    end

    if lastPlayedCategory == category then
        consecutiveSameType = consecutiveSameType + 1
    else
        consecutiveSameType = 1
    end
    lastPlayedCategory = category
end

local function PickRandomFromIndex(category)
    local files = audioIndex[category]
    if not files or #files == 0 then return nil end

    local candidates = {}
    for _, file in ipairs(files) do
        if not WasRecentlyPlayed(file) then
            table.insert(candidates, file)
        end
    end

    if #candidates == 0 then
        candidates = files
    end

    return candidates[math.random(1, #candidates)]
end

local function PlayAudioFile(category, fileName)
    local playerCoords = GetEntityCoords(PlayerPedId())

    SendNUIMessage({
        action = 'playAudio',
        data = {
            category = category,
            file = fileName,
            is3D = Config.SpatialAudio.enabled,
            coords = {
                x = playerCoords.x,
                y = playerCoords.y,
                z = playerCoords.z,
            },
        }
    })

    RecordPlayback(category, fileName)
    isPlaying = true

    if Config.PlayerSync.enabled and TEARC_Sync.IsEnabled() then
        TEARC_Sync.BroadcastAudio(category, fileName, playerCoords)
    end

    if Config.Debug then
        print(string.format('[TEARC-Scanner] 播放: [%s] %s', category, fileName))
    end
end

function Scanner.PlayChatter()
    local file = PickRandomFromIndex('scanner')
    if file then
        PlayAudioFile('scanner', file)
    end
end

function Scanner.PlayFunEvent()
    if GetGameTimer() < dispatchCooldownUntil then
        return false
    end

    local category = funCategories[math.random(1, #funCategories)]

    if category == lastPlayedCategory and consecutiveSameType >= Config.Scanner.maxConsecutiveSameType then
        local others = {}
        for _, cat in ipairs(funCategories) do
            if cat ~= category then
                table.insert(others, cat)
            end
        end
        if #others > 0 then
            category = others[math.random(1, #others)]
        end
    end

    local file = PickRandomFromIndex(category)
    if not file then return false end

    PlayAudioFile(category, file)

    dispatchCooldownUntil = GetGameTimer() + (Config.Scanner.cooldownAfterDispatch * 1000)

    return true
end

function Scanner.Enable()
    if isEnabled then return end
    isEnabled = true
    TEARC_Notify.Success('无线电扫描器已开启', { duration = 2500 })

    if Config.Debug then
        print('[TEARC-Scanner] 扫描器已启用')
    end
end

function Scanner.Disable()
    if not isEnabled then return end
    isEnabled = false
    isPlaying = false

    SendNUIMessage({ action = 'stopAll', data = {} })

    TEARC_Notify.Info('无线电扫描器已关闭', { duration = 2500 })

    if Config.Debug then
        print('[TEARC-Scanner] 扫描器已禁用')
    end
end

function Scanner.Toggle()
    if isEnabled then
        Scanner.Disable()
    else
        Scanner.Enable()
    end
end

function Scanner.IsEnabled()
    return isEnabled
end

function Scanner.IsPlaying()
    return isPlaying
end

function Scanner.ResetHistory()
    recentPlayedFiles = {}
    lastPlayedCategory = nil
    consecutiveSameType = 0
    dispatchCooldownUntil = 0

    if Config.Debug then
        print('[TEARC-Scanner] 播放历史已重置')
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        if not isEnabled then
            Citizen.Wait(1000)
            goto continue
        end

        local currentTime = GetGameTimer()

        if currentTime >= chatterTimer then
            Scanner.PlayChatter()
            local interval = math.random(
                Config.Scanner.chatterInterval.min * 1000,
                Config.Scanner.chatterInterval.max * 1000
            )
            chatterTimer = currentTime + interval
        end

        if currentTime >= dispatchTimer and currentTime >= dispatchCooldownUntil then
            Scanner.PlayFunEvent()
            local interval = math.random(
                Config.Scanner.dispatchInterval.min * 1000,
                Config.Scanner.dispatchInterval.max * 1000
            )
            dispatchTimer = currentTime + interval
        end

        ::continue::
    end
end)

RegisterNUICallback('audioEnded', function(data, cb)
    isPlaying = false

    if Config.Debug then
        print(string.format('[TEARC-Scanner] 音频播放完成: [%s] %s', data.category or 'unknown', data.file or 'unknown'))
    end

    cb({ ok = true })
end)

TEARC_Scanner = Scanner
