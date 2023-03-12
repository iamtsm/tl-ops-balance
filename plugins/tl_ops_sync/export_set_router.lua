-- tl_ops_set_sync_export
-- en : set export sync config
-- zn : 更新sync插件配置管理
-- @author iamtsm
-- @email 1905333456@qq.com`

local cache                     = require("cache.tl_ops_cache_core"):new("tl-ops-sync");
local constant                  = require("plugins.tl_ops_sync.tl_ops_plugin_constant");
local tl_ops_rt                 = tlops.constant.comm.tl_ops_rt;
local tl_ops_utils_func         = tlops.utils
local cjson                     = require("cjson.safe");
cjson.encode_empty_table_as_object(false)


local Router = function() 

    local sync, _ = tl_ops_utils_func:get_req_post_args_by_name(constant.export.cache_key.sync, 1);
    if sync then
        local res, _ = cache:set(constant.export.cache_key.sync, cjson.encode(sync));
        if not res then
            tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.error, "set sync err ", _)
            return;
        end
    end
    
    local res_data = {}
    res_data[constant.export.cache_key.sync] = sync

    tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.ok, "success", res_data)
 end
 
return Router