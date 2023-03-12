-- tl_ops_balance_core_cookie
-- en : balance core cookie impl
-- zn : 根据cookie匹配路由的具体实现
-- @author iamtsm
-- @email 1905333456@qq.com

local cjson                             = require("cjson.safe");
local cache_cookie                      = require("cache.tl_ops_cache_core"):new("tl-ops-balance-cookie");
local tl_ops_utils_func                 = require("utils.tl_ops_utils_func");
local tl_ops_constant_balance_cookie    = require("constant.tl_ops_constant_balance_cookie");
local tl_ops_constant_health            = require("constant.tl_ops_constant_health")
local balance_count_cookie              = require("balance.count.tl_ops_balance_count_cookie")
local shared                            = ngx.shared.tlopsbalance


-- 获取命中的cookie路由项
local tl_ops_balance_cookie_get_matcher_cookie = function(cookie_list_table, rule, rule_match_mode)
    local cookie_utils = require("lib.cookie"):new();
    
    local matcher_list = cookie_list_table[rule]

    if not matcher_list then
        return nil
    end

    -- 获取当前host
    local cur_host = ngx.var.host;
    
    for _, obj in pairs(matcher_list) do
        repeat
            if rule_match_mode == tl_ops_constant_balance_cookie.mode.host then
                -- 如果是优先host规则匹配，先剔除不属于当前host的规则
                if obj.host == nil or obj.host == '' then
                    break
                end
                if obj.host ~= "*" and obj.host ~= cur_host then
                    break
                end
            end
            if not obj or not obj.key then
                break
            end
            local req_cookie_value, _ = cookie_utils:get(obj.key);
            if not req_cookie_value then
                break
            end
            for _, value in pairs(obj.value) do
                if req_cookie_value == value then
                    return obj
                end
            end

            break
        until true
    end

    return nil
end


local tl_ops_balance_cookie_service_matcher = function(service_list_table)
    local matcher = nil
    local node = nil

    -- 规则匹配模式
    local rule_match_mode, _ = cache_cookie:get(tl_ops_constant_balance_cookie.cache_key.rule_match_mode);
    if not rule_match_mode then
        -- 默认以host优先匹配
        rule_match_mode = tl_ops_constant_balance_cookie.mode.host;
    end
    
    -- cookie路由策略
    local cookie_rule, _ = cache_cookie:get(tl_ops_constant_balance_cookie.cache_key.rule);
    if not cookie_rule then
        return nil, nil, nil, nil, rule_match_mode
    end
    
    -- cookie配置列表
    local cookie_list, _ = cache_cookie:get(tl_ops_constant_balance_cookie.cache_key.list);
    if not cookie_list then
        return nil, nil, nil, nil, rule_match_mode
    end

    local cookie_list_table = cjson.decode(cookie_list);
    if not cookie_list_table then
        return nil, nil, nil, nil, rule_match_mode
    end
    
    -- 根据路由当前策略进行路由, 返回正则命中的cookie
    if cookie_rule == tl_ops_constant_balance_cookie.rule.point then
        matcher = tl_ops_balance_cookie_get_matcher_cookie(
            cookie_list_table, tl_ops_constant_balance_cookie.rule.point, rule_match_mode
        );
    elseif cookie_rule == tl_ops_constant_balance_cookie.rule.random then
        matcher = tl_ops_balance_cookie_get_matcher_cookie(
            cookie_list_table, tl_ops_constant_balance_cookie.rule.random, rule_match_mode
        );
    end

    if not matcher or type(matcher) ~= 'table' then
        return nil, nil, nil, nil, rule_match_mode
    end

    local service_list = service_list_table[matcher.service]
    local node_id = matcher.node  -- lua index start 1

    local host = matcher.host
    if not host or host == nil then
        host = ""
    end

    -- 指定节点
    if cookie_rule == tl_ops_constant_balance_cookie.rule.point then
        if node_id ~= nil then
            node = service_list[tonumber(node_id) + 1]            
        else
            return nil, nil, nil, host, rule_match_mode
        end
    -- 服务内随机
    elseif cookie_rule == tl_ops_constant_balance_cookie.rule.random then
        local request_uri = tl_ops_utils_func:get_req_uri();
        math.randomseed(#request_uri)
        node_id = tonumber(math.random(0,1) % #service_list_table[matcher.service]) + 1
        node = service_list[node_id]
    end

    -- 命中统计
    balance_count_cookie.tl_ops_balance_count_incr_cookie_succ(matcher.service,node_id, matcher.id);

    -- 获取当前节点健康状态
    local key = tl_ops_utils_func:gen_node_key(tl_ops_constant_health.cache_key.state, matcher.service, node_id)
    local node_state , _ = shared:get(key)

    return node, node_state, node_id, host, rule_match_mode
end


return {
    tl_ops_balance_cookie_service_matcher = tl_ops_balance_cookie_service_matcher
}