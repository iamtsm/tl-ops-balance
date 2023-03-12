-- tl_ops_grpc_open
-- en : get export grpc open config
-- zn : 获取插件是否开启
-- @author iamtsm
-- @email 1905333456@qq.com

local cache         = require("cache.tl_ops_cache_core"):new("tl-ops-grpc");
local constant      = require("plugins.tl_ops_grpc.tl_ops_plugin_constant");
local cjson         = require("cjson.safe");
cjson.encode_empty_table_as_object(false)


local Func = function()
    
    local str, _ = cache:get101(constant.export.cache_key.grpc);
    if not str or str == nil then
        return false;
    end

    local data = cjson.decode(str);
    if not data then
        return false
    end
    
    return data.open
end

return Func