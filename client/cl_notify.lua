-- ============================================================
-- TEARC-Scanner 自研通知插件系统
-- 独立实现，不依赖任何第三方通知库
-- ============================================================

local Notify = {}
local activeNotifications = {}

local positions = {
    ['top-left'] = { x = 0.015, y = 0.02, align = 'left' },
    ['top-right'] = { x = 0.985, y = 0.02, align = 'right' },
    ['bottom-left'] = { x = 0.015, y = 0.90, align = 'left' },
    ['bottom-right'] = { x = 0.985, y = 0.90, align = 'right' },
    ['center'] = { x = 0.5, y = 0.15, align = 'center' },
}

local function GetPosition()
    return positions[Config.Notify.position] or positions['top-right']
end

function Notify.Show(message, options)
    options = options or {}
    local duration = options.duration or Config.Notify.duration
    local title = options.title or 'TEARC-Scanner'
    local type = options.type or 'info'

    local colors = {
        info = { 59, 130, 246 },
        success = { 34, 197, 94 },
        error = { 239, 68, 68 },
        warning = { 234, 179, 8 },
    }
    local color = colors[type] or colors.info

    while #activeNotifications >= Config.Notify.maxVisible do
        table.remove(activeNotifications, 1)
    end

    local id = GetGameTimer() + math.random(1000, 9999)
    local notification = {
        id = id,
        title = title,
        message = message,
        color = color,
        startTime = GetGameTimer(),
        duration = duration,
        opacity = 255,
    }
    table.insert(activeNotifications, notification)

    PlaySoundFrontend(-1, 'FocusIn', 'HintCamSounds', false)

    return id
end

function Notify.Info(message, options)
    options = options or {}
    options.type = 'info'
    return Notify.Show(message, options)
end

function Notify.Success(message, options)
    options = options or {}
    options.type = 'success'
    return Notify.Show(message, options)
end

function Notify.Error(message, options)
    options = options or {}
    options.type = 'error'
    return Notify.Show(message, options)
end

function Notify.Warning(message, options)
    options = options or {}
    options.type = 'warning'
    return Notify.Show(message, options)
end

Citizen.CreateThread(function()
    while true do
        if #activeNotifications == 0 then
            Citizen.Wait(500)
            goto continue
        end

        Citizen.Wait(0)

        local pos = GetPosition()
        local currentTime = GetGameTimer()
        local yBase = pos.y

        for i = #activeNotifications, 1, -1 do
            local n = activeNotifications[i]
            if currentTime - n.startTime > n.duration then
                table.remove(activeNotifications, i)
            end
        end

        if #activeNotifications == 0 then
            goto continue
        end

        for i, n in ipairs(activeNotifications) do
            local elapsed = currentTime - n.startTime
            local progress = elapsed / n.duration

            local alpha = 255
            if progress < 0.1 then
                alpha = math.floor(255 * (progress / 0.1))
            elseif progress > 0.85 then
                alpha = math.floor(255 * ((1.0 - progress) / 0.15))
            end

            local yPos = yBase + (i - 1) * 0.065

            DrawRect(pos.x, yPos + 0.028, 0.28, 0.055, 15, 17, 22, math.floor(alpha * 0.92))
            DrawRect(pos.x - 0.137, yPos + 0.028, 0.006, 0.055, n.color[1], n.color[2], n.color[3], alpha)

            SetTextFont(4)
            SetTextScale(0.38, 0.38)
            SetTextColour(n.color[1], n.color[2], n.color[3], alpha)
            SetTextEntry('STRING')
            AddTextComponentString(n.title)
            if pos.align == 'right' then
                SetTextRightJustify(true)
                SetTextWrap(0, pos.x - 0.01)
            elseif pos.align == 'center' then
                SetTextCentre(true)
            end
            DrawText(pos.x - 0.12, yPos + 0.012)

            SetTextFont(4)
            SetTextScale(0.32, 0.32)
            SetTextColour(200, 200, 200, alpha)
            SetTextEntry('STRING')
            AddTextComponentString(n.message)
            if pos.align == 'right' then
                SetTextRightJustify(true)
                SetTextWrap(0, pos.x - 0.01)
            elseif pos.align == 'center' then
                SetTextCentre(true)
            end
            DrawText(pos.x - 0.12, yPos + 0.035)
        end

        ::continue::
    end
end)

TEARC_Notify = Notify
