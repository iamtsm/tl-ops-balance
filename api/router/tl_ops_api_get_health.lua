-- tl_ops_api 
-- en : get health options
-- zn : 获取健康检查配置信息
-- @author iamtsm
-- @email 1905333456@qq.com

local cache                     = require("cache.tl_ops_cache_core"):new("tl-ops-health");
local tl_ops_constant_health    = require("constant.tl_ops_constant_health")
local tl_ops_rt                 = require("constant.tl_ops_constant_comm").tl_ops_rt;
local tl_ops_utils_func         = require("utils.tl_ops_utils_func");
local cjson                     = require("cjson.safe");
cjson.encode_empty_table_as_object(false)


local Handler = function() 
    local list_str, _ = cache:get(tl_ops_constant_health.cache_key.options_list);
    if not list_str or list_str == nil then
        return tl_ops_rt.not_found, "not found list", _
    end

    local res_data = {}
    res_data[tl_ops_constant_health.cache_key.options_list] = cjson.decode(list_str)

    return tl_ops_rt.ok, "success", res_data
 end


local Router = function ()
    tl_ops_utils_func:set_ngx_req_return_ok(Handler())
end

return {
    Handler = Handler,
    Router = Router
}