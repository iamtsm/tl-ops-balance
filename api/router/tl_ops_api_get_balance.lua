-- tl_ops_api 
-- en : get balance config
-- zn : 获取路由配置列表
-- @author iamtsm
-- @email 1905333456@qq.com


local cache                   = require("cache.tl_ops_cache_core"):new("tl-ops-balance")
local tl_ops_constant_balance = require("constant.tl_ops_constant_balance")
local tl_ops_rt               = require("constant.tl_ops_constant_comm").tl_ops_rt
local tl_ops_utils_func       = require("utils.tl_ops_utils_func")
local cjson                   = require("cjson.safe");
cjson.encode_empty_table_as_object(false)


local Handler = function() 
   local service_empty = cache:get(tl_ops_constant_balance.cache_key.service_empty)
   if not service_empty then
      return tl_ops_rt.not_found, "not found service_empty", _
   end

   local mode_empty = cache:get(tl_ops_constant_balance.cache_key.mode_empty)
   if not mode_empty then
      return tl_ops_rt.not_found, "not found mode_empty", _
   end

   local host_empty = cache:get(tl_ops_constant_balance.cache_key.host_empty)
   if not host_empty then
      return tl_ops_rt.not_found, "not found host_empty", _
   end

   local host_pass = cache:get(tl_ops_constant_balance.cache_key.host_pass)
   if not host_pass then
      return tl_ops_rt.not_found, "not found host_pass", _
   end

   local token_limit = cache:get(tl_ops_constant_balance.cache_key.token_limit)
   if not token_limit then
      return tl_ops_rt.not_found, "not found token_limit", _
   end

   local leak_limit = cache:get(tl_ops_constant_balance.cache_key.leak_limit)
   if not leak_limit then
      return tl_ops_rt.not_found, "not found leak_limit", _
   end

   local offline = cache:get(tl_ops_constant_balance.cache_key.offline)
   if not offline then
      return tl_ops_rt.not_found, "not found offline", _
   end

   local res_data = {
      service_empty = cjson.decode(service_empty),
      mode_empty = cjson.decode(mode_empty),
      host_empty = cjson.decode(host_empty),
      host_pass = cjson.decode(host_pass),
      token_limit = cjson.decode(token_limit),
      leak_limit = cjson.decode(leak_limit),
      offline = cjson.decode(offline)
   }

   return tl_ops_rt.ok, "success", res_data
end


local Router = function ()
   tl_ops_utils_func:set_ngx_req_return_ok(Handler())
end

return {
   Handler = Handler,
   Router = Router
}
