Config = {}

-- ============================================================
-- TEARC-Scanner 配置文件
-- 所有设置都在此处修改，重启插件后生效
-- ============================================================

-- [[ 3D音效设置 ]] --
Config.SpatialAudio = {
    enabled = true,             -- 是否启用3D音效 (true=3D空间音效, false=全服2D)
    maxDistance = 50.0,         -- 3D音效最大传播距离(米)
    refDistance = 5.0,          -- 参考距离(米)，此距离内音量最大
    rolloffFactor = 2.0,        -- 衰减系数，越大衰减越快
}

-- [[ 扫描器播放设置 ]] --
Config.Scanner = {
    enabled = true,             -- 默认是否启用扫描器
    chatterInterval = {         -- 背景无线电chatter间隔(秒)
        min = 4,
        max = 10,
    },
    dispatchInterval = {        -- 趣味调度事件间隔(秒)
        min = 30,
        max = 90,
    },
    cooldownAfterDispatch = 10, -- 调度事件后冷却时间(秒)
    maxConsecutiveSameType = 2, -- 同类型事件最大连续播放次数
}

-- [[ 附近玩家同步设置 ]] --
Config.PlayerSync = {
    enabled = false,            -- 默认是否启用附近玩家音频同步
    syncRange = 80.0,           -- 同步范围(米)
}

-- [[ 通知设置 ]] --
Config.Notify = {
    position = 'top-right',     -- 通知位置: 'top-left', 'top-right', 'bottom-left', 'bottom-right', 'center'
    duration = 4000,            -- 通知显示时长(毫秒)
    maxVisible = 3,             -- 同时最多显示几条通知
}

-- [[ 按键设置 ]] --
Config.Keys = {
    toggleScanner = 'F9',       -- 开关扫描器
    openMenu = 'F10',           -- 打开菜单
}

-- [[ 音频音量归一化 ]] --
-- 自动将不同音量的音频统一到目标响度
Config.AudioNormalization = {
    enabled = true,             -- 是否启用音量归一化
    targetLUFS = -16,           -- 目标响度 (LUFS, 广播标准为-16)
    maxGain = 2.5,              -- 最大增益倍数 (防止静音文件被过度放大)
    minGain = 0.3,              -- 最小增益倍数 (防止过响文件失真)
}

-- [[ GitHub版本检查 ]] --
-- 插件启动时自动查询GitHub Releases检测新版本
Config.VersionCheck = {
    enabled = true,             -- 是否启用版本检查
    notifyPlayer = true,        -- 发现新版本时是否通知玩家
}

-- [[ 调试设置 ]] --
Config.Debug = false            -- 调试模式，开启后会在控制台输出日志