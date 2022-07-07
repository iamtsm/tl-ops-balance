-- tl_ops_cookie 
-- en : set cookie config list
-- zn : 更新waf cookie配置列表
-- @author iamtsm
-- @email 1905333456@qq.com


local snowflake                     = require("lib.snowflake");
local cache                         = require("cache.tl_ops_cache_core"):new("tl-ops-waf-cookie");
local tl_ops_constant_waf_cookie    = require("constant.tl_ops_constant_waf_cookie");
local tl_ops_rt                     = require("constant.tl_ops_constant_comm").tl_ops_rt;
local tl_ops_utils_func             = require("utils.tl_ops_utils_func");
local cjson                         = require("cjson.safe");
cjson.encode_empty_table_as_object(false)


local Router = function() 

    local scope, _ = tl_ops_utils_func:get_req_post_args_by_name(tl_ops_constant_waf_cookie.cache_key.scope, 1);
    if not scope or scope == nil then
        tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.args_error ,"wc args err1", _);
        return;
    end

    local open, _ = tl_ops_utils_func:get_req_post_args_by_name(tl_ops_constant_waf_cookie.cache_key.open, 1);
    if open == nil then
        tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.args_error ,"wc args err2", _);
        return;
    end
    
    local list, _ = tl_ops_utils_func:get_req_post_args_by_name(tl_ops_constant_waf_cookie.cache_key.list, 1);
    if not list or list == nil then
        tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.args_error ,"wc args err3", _);
        return;
    end
    
    -- 更新生成id
    for _, cookie in ipairs(list) do
        if not cookie.id or cookie.id == nil or cookie.id == '' then
            cookie.id = snowflake.generate_id( 100 )
        end
        if not cookie.updatetime or cookie.updatetime == nil or cookie.updatetime == '' then
            cookie.updatetime = ngx.localtime()
        end
        if cookie.change and cookie.change == true then
            cookie.updatetime = ngx.localtime()
            cookie.change = nil
        end
    end
    
    local cache_list, _ = cache:set(tl_ops_constant_waf_cookie.cache_key.list, cjson.encode(list));
    if not cache_list then
        tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.error, "set list err ", _)
        return;
    end
    
    local cache_scope, _ = cache:set(tl_ops_constant_waf_cookie.cache_key.scope, scope);
    if not cache_scope then
        tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.error, "set scope err ", _)
        return;
    end

    local cache_open, _ = cache:set(tl_ops_constant_waf_cookie.cache_key.open, open);
    if not cache_open then
        tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.error, "set open err ", _)
        return;
    end
    
    local res_data = {}
    res_data[tl_ops_constant_waf_cookie.cache_key.scope] = scope
    res_data[tl_ops_constant_waf_cookie.cache_key.open] = open
    res_data[tl_ops_constant_waf_cookie.cache_key.list] = list
    
    
    tl_ops_utils_func:set_ngx_req_return_ok(tl_ops_rt.ok, "ok", res_data)
 end
 
return Router
