-- ============================================================
-- TEARC-Scanner 客户端主入口
-- 初始化所有模块，处理事件
-- ============================================================

local isInitialized = false

local function Initialize()
    if isInitialized then return end
    isInitialized = true

    if Config.VersionCheck.enabled then
        TEARC_Version.Check(function(hasUpdate, latestVer, latestUrl)
            if hasUpdate then
                if Config.Debug then
                    print('[TEARC-Scanner] ========================================')
                    print('[TEARC-Scanner] 发现新版本!')
                    print(string.format('[TEARC-Scanner] 当前版本: %s', TEARC_Version.GetCurrent()))
                    print(string.format('[TEARC-Scanner] 最新版本: %s', latestVer))
                    print(string.format('[TEARC-Scanner] 下载地址: %s', latestUrl))
                    print('[TEARC-Scanner] ========================================')
                end

                if Config.VersionCheck.notifyPlayer then
                    TEARC_Notify.Warning(string.format(
                        '发现新版本 ~y~%s~s~! 当前: ~r~%s~s~\n请前往GitHub下载更新',
                        latestVer, TEARC_Version.GetCurrent()
                    ), {
                        title = 'TEARC-Scanner 更新',
                        duration = 10000,
                    })
                end
            end
        end)
    end

    Citizen.Wait(1000)
    TEARC_Notify.Success('TEARC-Scanner 无线电扫描仪已加载', {
        title = 'TEARC-Scanner',
        duration = 4000,
    })

    if Config.Scanner.enabled then
        Citizen.Wait(2000)
        TEARC_Scanner.Enable()
    end

    if Config.PlayerSync.enabled then
        TEARC_Sync.Enable()
    end

    if Config.Debug then
        print('========================================')
        print('[TEARC-Scanner] 插件初始化完成')
        print('[TEARC-Scanner] 版本: 1.0.0')
        print('[TEARC-Scanner] 3D音效: ' .. tostring(Config.SpatialAudio.enabled))
        print('[TEARC-Scanner] 扫描器: ' .. tostring(Config.Scanner.enabled))
        print('[TEARC-Scanner] 玩家同步: ' .. tostring(Config.PlayerSync.enabled))
        print('========================================')
    end
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Initialize()
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TEARC_Audio.StopAll()
        TEARC_Menu.Close()
        if Config.Debug then
            print('[TEARC-Scanner] 插件已卸载')
        end
    end
end)

local wasDead = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local ped = PlayerPedId()
        if IsPedDeadOrDying(ped, true) then
            if not wasDead and TEARC_Scanner.IsEnabled() then
                TEARC_Audio.StopAll()
                if Config.Debug then
                    print('[TEARC-Scanner] 玩家死亡，暂停扫描器')
                end
            end
            wasDead = true
        else
            wasDead = false
        end
    end
end)

RegisterCommand('tearc-dispatch', function()
    if TEARC_Scanner.IsEnabled() then
        TEARC_Scanner.PlayFunEvent()
    else
        TEARC_Notify.Warning('请先开启扫描器 (F9)', { duration = 3000 })
    end
end, false)

RegisterCommand('tearc-status', function()
    local scannerStatus = TEARC_Scanner.IsEnabled() and '~g~开启' or '~r~关闭'
    local syncStatus = TEARC_Sync.IsEnabled() and '~g~开启' or '~r~关闭'
    local spatialStatus = Config.SpatialAudio.enabled and '~g~3D音效' or '~y~2D音效'

    TEARC_Notify.Info(string.format(
        '扫描器: %s | 同步: %s | %s',
        scannerStatus, syncStatus, spatialStatus
    ), { title = 'TEARC-Scanner 状态', duration = 5000 })
end, false)

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    if isInitialized then
        TEARC_Notify.Info('按 ~y~F9~s~ 开关扫描器 | 按 ~y~F10~s~ 打开菜单', {
            title = 'TEARC-Scanner',
            duration = 8000,
        })
    end
end)

RegisterCommand('tearc-version', function()
    TEARC_Notify.Info('正在检查版本更新...', { duration = 2000 })

    TEARC_Version.Check(function(hasUpdate, latestVer, latestUrl)
        if hasUpdate then
            TEARC_Notify.Warning(string.format(
                '发现新版本 ~y~%s~s~!\n当前版本: ~r~%s~s~\n下载: ~b~%s~s~',
                latestVer, TEARC_Version.GetCurrent(), latestUrl
            ), {
                title = 'TEARC-Scanner 更新',
                duration = 12000,
            })
        else
            TEARC_Notify.Success(string.format(
                '已是最新版本: ~g~%s~s~', TEARC_Version.GetCurrent()
            ), {
                title = 'TEARC-Scanner',
                duration = 4000,
            })
        end
    end)
end, false)
