-- tl_ops_api 
-- en : set service node config list
-- zn : 更新路由服务节点配置列表
-- @author iamtsm
-- @email 1905333456@qq.com


local cjson                             = require("cjson.safe");
local snowflake                         = require("lib.snowflake");
local cache_service                     = require("cache.tl_ops_cache_core"):new("tl-ops-service");
local tl_ops_constant_service           = require("constant.tl_ops_constant_service");
local tl_ops_constant_health            = require("constant.tl_ops_constant_health");
local tl_ops_constant_limit             = require("constant.tl_ops_constant_limit");
local tl_ops_rt                         = require("constant.tl_ops_constant_comm").tl_ops_rt;
local tl_ops_utils_func                 = require("utils.tl_ops_utils_func");
local tl_ops_health_check_version       = require("health.tl_ops_health_check_version")
local tl_ops_limit_fuse_check_version   = require("limit.fuse.tl_ops_limit_fuse_check_version")


local Handler = function()

    local tl_ops_service_rule,_ = tl_ops_utils_func:get_req_post_args_by_name(tl_ops_constant_service.cache_key.service_rule, 1);
    if not tl_ops_service_rule or tl_ops_service_rule == nil then
        return tl_ops_rt.args_error ,"s args err1", _
    end

    local tl_ops_service_list,_ = tl_ops_utils_func:get_req_post_args_by_name(tl_ops_constant_service.cache_key.service_list, 1);
    if not tl_ops_service_list or tl_ops_service_list == nil then
        return tl_ops_rt.args_error ,"s args err2", _
    end

    local has_new_service_name ,_ = tl_ops_utils_func:get_req_post_args_by_name('has_new_service_name', 1);
    if has_new_service_name == nil then
        return tl_ops_rt.args_error ,"s args err3", _
    end

    local new_service_name ,_ = tl_ops_utils_func:get_req_post_args_by_name('new_service_name', 1);
    if has_new_service_name == true and new_service_name == nil then
        return tl_ops_rt.args_error ,"s args err4", _
    end

    -- 是否存在service name
    if has_new_service_name == true then
        for key,_ in pairs(tl_ops_service_list) do
            if key == new_service_name then
                return tl_ops_rt.args_error ,"service exsit"
            end
        end
        tl_ops_service_list[new_service_name] = {}
    end

    -- 更新生成id
    for key,_ in pairs(tl_ops_service_list) do
        for _, node in ipairs(tl_ops_service_list[key]) do
            if not node.id or node.id == nil or node.id == '' then
                node.id = snowflake.generate_id( 100 )
            end
            if not node.updatetime or node.updatetime == nil or node.updatetime == '' then
                node.updatetime = ngx.localtime()
            end
            if node.change and node.change == true then
                node.updatetime = ngx.localtime()
                node.change = nil
            end
        end
    end

    local cache_list, _ = cache_service:set(tl_ops_constant_service.cache_key.service_list, cjson.encode(tl_ops_service_list));
    if not cache_list then
        return tl_ops_rt.error, "set list err", _
    end

    local cache_rule, _ = cache_service:set(tl_ops_constant_service.cache_key.service_rule, tl_ops_service_rule);
    if not cache_rule then
        return tl_ops_rt.error, "set rule err ", _
    end

    if has_new_service_name and has_new_service_name == true then
        -- 对service_options_version更新，通知timer检查是否有新增service
        tl_ops_health_check_version.incr_service_option_version();
        tl_ops_limit_fuse_check_version.incr_service_option_version();
    end

    -- 对service version更新，通知worker更新所有conf
    for service_name , _ in pairs(tl_ops_service_list) do
        tl_ops_health_check_version.incr_service_version(service_name);
        tl_ops_limit_fuse_check_version.incr_service_version(service_name);
    end

    -- 新增service逻辑分支
    if has_new_service_name == true and new_service_name ~= '' then
        -- 同步健康检查配置
        local cache_health = require("cache.tl_ops_cache_core"):new("tl-ops-health");
        local health_list_str, _ = cache_health:get(tl_ops_constant_health.cache_key.options_list);
        if not health_list_str or health_list_str == nil then
            return tl_ops_rt.not_found, "not found health list", _
        end
        local health_list_table = cjson.decode(health_list_str);
        tl_ops_constant_health.demo.check_service_name = new_service_name
        table.insert(health_list_table, tl_ops_constant_health.demo)

        local health_res, _ = cache_health:set(tl_ops_constant_health.cache_key.options_list, cjson.encode(health_list_table));
        if not health_res then
            return tl_ops_rt.error, "init health conf err ", _
        end

        -- 同步熔断配置
        local cache_limit = require("cache.tl_ops_cache_core"):new("tl-ops-limit");
        local limit_list_str, _ = cache_limit:get(tl_ops_constant_limit.fuse.cache_key.options_list);
        if not limit_list_str or limit_list_str == nil then
            return tl_ops_rt.not_found, "not found limit fuse list", _
        end
        local limit_list_table = cjson.decode(limit_list_str);
        tl_ops_constant_limit.fuse.demo.service_name = new_service_name
        table.insert(limit_list_table, tl_ops_constant_limit.fuse.demo)

        local limit_res, _ = cache_limit:set(tl_ops_constant_limit.fuse.cache_key.options_list, cjson.encode(limit_list_table));
        if not limit_res then
            return tl_ops_rt.error, "init limit fuse conf err ", _
        end

        -- 同步令牌桶配置
        local token_limit_list_str, _ = cache_limit:get(tl_ops_constant_limit.token.cache_key.options_list);
        if not token_limit_list_str or token_limit_list_str == nil then
            return tl_ops_rt.not_found, "not found limit token list", _
        end
        local token_limit_list_table = cjson.decode(token_limit_list_str);
        tl_ops_constant_limit.token.demo.service_name = new_service_name
        table.insert(token_limit_list_table, tl_ops_constant_limit.token.demo)

        local limit_res, _ = cache_limit:set(tl_ops_constant_limit.token.cache_key.options_list, cjson.encode(token_limit_list_table));
        if not limit_res then
            return tl_ops_rt.error, "init limit token conf err ", _
        end

        -- 同步漏桶配置
        local leak_limit_list_str, _ = cache_limit:get(tl_ops_constant_limit.leak.cache_key.options_list);
        if not leak_limit_list_str or leak_limit_list_str == nil then
            return tl_ops_rt.not_found, "not found limit leak list", _
        end
        local leak_limit_list_table = cjson.decode(leak_limit_list_str);
        tl_ops_constant_limit.leak.demo.service_name = new_service_name
        table.insert(leak_limit_list_table, tl_ops_constant_limit.leak.demo)

        local limit_res, _ = cache_limit:set(tl_ops_constant_limit.leak.cache_key.options_list, cjson.encode(leak_limit_list_table));
        if not limit_res then
            return tl_ops_rt.error, "init limit leak conf err ", _
        end
    end

    local res_data = {}
    res_data[tl_ops_constant_service.cache_key.service_rule] = tl_ops_service_rule
    res_data[tl_ops_constant_service.cache_key.service_list] = tl_ops_service_list

    return tl_ops_rt.ok, "success", res_data
end


local Router = function ()
    tl_ops_utils_func:set_ngx_req_return_ok(Handler())
end

return {
    Handler = Handler,
    Router = Router
}
