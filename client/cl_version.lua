-- ============================================================
-- TEARC-Scanner GitHub API 版本检查模块
-- 启动时自动查询GitHub Releases检测新版本
-- ============================================================

local Version = {}
local currentVersion = '1.0.0'
local repoOwner = 'TEARLESSVVOID'
local repoName = 'TEARC-Scanner'
local apiUrl = string.format('https://api.github.com/repos/%s/%s/releases/latest', repoOwner, repoName)
local checkComplete = false
local updateAvailable = false
local latestVersion = nil
local latestUrl = nil

-- 解析语义化版本号 (x.y.z)
local function ParseVersion(versionStr)
    if not versionStr then return nil end
    -- 去除 'v' 前缀
    local cleaned = versionStr:gsub('^v', '')
    local major, minor, patch = cleaned:match('^(%d+)%.(%d+)%.(%d+)$')
    if major then
        return {
            major = tonumber(major),
            minor = tonumber(minor),
            patch = tonumber(patch),
            raw = versionStr,
        }
    end
    return nil
end

-- 比较两个版本号，返回: 1 (a > b), -1 (a < b), 0 (相等)
local function CompareVersions(a, b)
    if not a or not b then return 0 end
    if a.major ~= b.major then
        return a.major > b.major and 1 or -1
    end
    if a.minor ~= b.minor then
        return a.minor > b.minor and 1 or -1
    end
    if a.patch ~= b.patch then
        return a.patch > b.patch and 1 or -1
    end
    return 0
end

-- 执行版本检查
function Version.Check(callback)
    if checkComplete then
        if callback then
            callback(updateAvailable, latestVersion, latestUrl)
        end
        return
    end

    PerformHttpRequest(apiUrl, function(statusCode, responseBody, responseHeaders)
        if statusCode == 200 and responseBody then
            local success, data = pcall(function()
                return json.decode(responseBody)
            end)

            if success and data and data.tag_name then
                local remoteVer = ParseVersion(data.tag_name)
                local localVer = ParseVersion(currentVersion)

                if remoteVer and localVer then
                    local cmp = CompareVersions(remoteVer, localVer)
                    if cmp > 0 then
                        updateAvailable = true
                        latestVersion = data.tag_name
                        latestUrl = data.html_url or string.format(
                            'https://github.com/%s/%s/releases/tag/%s',
                            repoOwner, repoName, data.tag_name
                        )

                        if Config.Debug then
                            print(string.format('[TEARC-Scanner] 发现新版本: %s (当前: %s)', latestVersion, currentVersion))
                            print(string.format('[TEARC-Scanner] 下载地址: %s', latestUrl))
                        end
                    else
                        if Config.Debug then
                            print(string.format('[TEARC-Scanner] 已是最新版本: %s', currentVersion))
                        end
                    end
                end
            else
                if Config.Debug then
                    print('[TEARC-Scanner] 版本检查: GitHub API返回数据解析失败')
                end
            end
        else
            if Config.Debug then
                print(string.format('[TEARC-Scanner] 版本检查: HTTP请求失败 (状态码: %s)', tostring(statusCode)))
            end
        end

        checkComplete = true

        if callback then
            callback(updateAvailable, latestVersion, latestUrl)
        end
    end, 'GET', '', {
        ['User-Agent'] = 'TEARC-Scanner/' .. currentVersion,
        ['Accept'] = 'application/vnd.github.v3+json',
    })
end

-- 获取当前版本
function Version.GetCurrent()
    return currentVersion
end

-- 是否有更新
function Version.IsUpdateAvailable()
    return updateAvailable
end

-- 获取最新版本号
function Version.GetLatest()
    return latestVersion
end

-- 获取最新版本URL
function Version.GetLatestUrl()
    return latestUrl
end

-- 检查是否已完成
function Version.IsCheckComplete()
    return checkComplete
end

-- 导出
TEARC_Version = Version