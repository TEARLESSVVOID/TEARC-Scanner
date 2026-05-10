-- ============================================================
-- TEARC-Scanner 中文菜单系统
-- NUI-based 菜单，支持键盘和鼠标操作
-- ============================================================

local Menu = {}
local isMenuOpen = false
local currentVolume = 70

local menuItems = {
    {
        id = 'toggle_scanner',
        label = '扫描器开关',
        description = '开启或关闭无线电扫描器',
        type = 'toggle',
        getState = function() return TEARC_Scanner.IsEnabled() end,
        action = function() TEARC_Scanner.Toggle() end,
    },
    {
        id = 'toggle_sync',
        label = '附近玩家同步',
        description = '让附近玩家也能听到你的扫描器音频',
        type = 'toggle',
        getState = function() return TEARC_Sync.IsEnabled() end,
        action = function() TEARC_Sync.Toggle() end,
    },
    {
        id = 'volume',
        label = '音量调节',
        description = '调整扫描器音量大小',
        type = 'slider',
        min = 10,
        max = 100,
        step = 5,
        value = 70,
        action = function(value)
            currentVolume = value
            SendNUIMessage({
                action = 'setVolume',
                data = { volume = value / 100 }
            })
        end,
    },
    {
        id = 'play_test',
        label = '测试播放',
        description = '播放一段测试音频以检查音效',
        type = 'button',
        action = function()
            TEARC_Scanner.PlayChatter()
            TEARC_Notify.Info('测试音频已播放', { duration = 2000 })
        end,
    },
    {
        id = 'stop_all',
        label = '停止所有音频',
        description = '立即停止所有正在播放的音频',
        type = 'button',
        action = function()
            TEARC_Audio.StopAll()
            TEARC_Notify.Info('所有音频已停止', { duration = 2000 })
        end,
    },
    {
        id = 'reset_history',
        label = '重置播放历史',
        description = '清除播放记录，允许重新播放所有音频',
        type = 'button',
        action = function()
            TEARC_Scanner.ResetHistory()
            TEARC_Notify.Success('播放历史已重置', { duration = 2000 })
        end,
    },
}

local function BuildMenuItems()
    local items = {}
    for _, item in ipairs(menuItems) do
        local menuItem = {
            id = item.id,
            label = item.label,
            description = item.description,
            type = item.type,
        }
        if item.type == 'toggle' and item.getState then
            menuItem.state = item.getState()
        end
        if item.type == 'slider' then
            menuItem.min = item.min
            menuItem.max = item.max
            menuItem.step = item.step
            menuItem.value = currentVolume
        end
        table.insert(items, menuItem)
    end
    return items
end

function Menu.Open()
    if isMenuOpen then return end
    isMenuOpen = true

    SendNUIMessage({
        action = 'openMenu',
        data = {
            title = 'TEARC-Scanner 无线电扫描仪',
            subtitle = 'v1.0.0 - 独立插件',
            items = BuildMenuItems(),
        }
    })

    SetNuiFocus(true, true)

    if Config.Debug then
        print('[TEARC-Scanner] 菜单已打开')
    end
end

function Menu.Close()
    if not isMenuOpen then return end
    isMenuOpen = false

    SendNUIMessage({
        action = 'closeMenu',
        data = {}
    })

    SetNuiFocus(false, false)

    if Config.Debug then
        print('[TEARC-Scanner] 菜单已关闭')
    end
end

function Menu.Toggle()
    if isMenuOpen then
        Menu.Close()
    else
        Menu.Open()
    end
end

RegisterNUICallback('menuAction', function(data, cb)
    local itemId = data.id
    local actionType = data.actionType

    for _, item in ipairs(menuItems) do
        if item.id == itemId then
            if item.type == 'toggle' then
                if item.action then item.action() end
            elseif item.type == 'button' then
                if item.action then item.action() end
            elseif item.type == 'slider' then
                if item.action and data.value then item.action(tonumber(data.value)) end
            end
            break
        end
    end

    cb({ items = BuildMenuItems() })
end)

RegisterNUICallback('closeMenu', function(data, cb)
    Menu.Close()
    cb('ok')
end)

Citizen.CreateThread(function()
    RegisterKeyMapping('tearc-menu', 'TEARC-Scanner: 打开菜单', 'keyboard', Config.Keys.openMenu)

    RegisterCommand('tearc-menu', function()
        Menu.Toggle()
    end, false)

    RegisterKeyMapping('tearc-toggle', 'TEARC-Scanner: 开关扫描器', 'keyboard', Config.Keys.toggleScanner)

    RegisterCommand('tearc-toggle', function()
        TEARC_Scanner.Toggle()
    end, false)
end)

TEARC_Menu = Menu
