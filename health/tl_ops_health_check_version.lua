-- tl_ops_health
-- en : health check notify version 
-- zn : 健康检查配置变动版本通知
-- @author iamtsm
-- @email 1905333456@qq.com


local tlog                      = require("utils.tl_ops_utils_log"):new("tl_ops_health_check_version");
local tl_ops_utils_func         = require("utils.tl_ops_utils_func");
local tl_ops_constant_health    = require("constant.tl_ops_constant_health")
local shared                    = ngx.shared.tlopsbalance;

local _M = {
	_VERSION = '0.02'
}


-- 更新当前service的状态版本，用于通知其他worker进程同步最新conf
local tl_ops_health_check_version_incr_service_version = function( service_name )
    if not service_name then
        tlog:err(" service_name nil ")
        return
    end
    local key = tl_ops_utils_func:gen_node_key(tl_ops_constant_health.cache_key.service_version, service_name)
    local service_version, _ = shared:get(key)

    if not service_version then
        service_version, _ = shared:add(key, 1);
        if not service_version then 
            tlog:err(" failed to publish new service_version:" , _)
        end
    else 
        service_version, _ = shared:incr(key, 1);
        if not service_version then 
            tlog:err(" failed to publish new service_version:" , _)
        end
    end
    
    tlog:dbg("service_version key=" , key, ", service_version=",service_version)

    return service_version
end


-- 对service_options_version更新，通知timer检查是否有新增service
local tl_ops_health_check_version_incr_service_option_version = function(  )
    local key = tl_ops_constant_health.cache_key.service_options_version;
    local res, _ = shared:set(key, true)

    tlog:dbg("service_option_version key=" , key, ", service_option_version=",res)

    if not res then
        tlog:err(" set service_options_version err " , _)
    end
end

_M = {
    incr_service_version = tl_ops_health_check_version_incr_service_version,
    incr_service_option_version = tl_ops_health_check_version_incr_service_option_version
}


return _M;