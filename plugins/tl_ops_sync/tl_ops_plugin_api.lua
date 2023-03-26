-- tl_ops_plugin_sync_api
-- en : sync api
-- zn : 插件api接口
-- @author iamtsm
-- @email 1905333456@qq.com

local constant                  = require("plugins.tl_ops_sync.tl_ops_plugin_constant")
local export_get_router         = require("plugins.tl_ops_sync.export_get_router")
local export_set_router         = require("plugins.tl_ops_sync.export_set_router")

-- 插件管理对外管理接口
return function(ctx)

    -- 插件管理对外管理接口
    ctx.tlops_api[constant.export.tlops_api.get] = export_get_router

    ctx.tlops_api[constant.export.tlops_api.set] = export_set_router

end
