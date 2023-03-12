-- tl_ops_grpc_sync
-- en : sync grpc config
-- zn : 同步、预热插件模板相关数据
-- @corsor iamtsm
-- @email 1905333456@qq.com

local tlog              = require("utils.tl_ops_utils_log"):new("tl_ops_plugin_grpc")
local cache             = require("cache.tl_ops_cache_core"):new("tl-ops-grpc")
local constant          = require("plugins.tl_ops_grpc.tl_ops_plugin_constant")
local tl_ops_rt         = tlops.constant.comm.tl_ops_rt
local cjson             = require("cjson.safe")
cjson.encode_empty_table_as_object(false)


-- 同步静态数据
local sync_data = function()

    return tl_ops_rt.ok
end


-- 同步插件对外数据
local sync_fields_export = function ()
    local cache_key = constant.export.cache_key.grpc
    local constant_data = constant.export.grpc
    local demo = constant.export.demo

    local data_str, _ = cache:get(cache_key);
    if not data_str then
        local res, _ = cache:set(cache_key, cjson.encode(constant_data))
        if not res then
            tlog:err("grpc sync_fields_export new store err, cache_key=",cache_key,",res=",res)
            return tl_ops_rt.error
        end

        data_str, _ = cache:get(cache_key);

        tlog:dbg("grpc sync_fields_export new store,  cache_key=",cache_key,",res=",res)
    end

    local data = cjson.decode(data_str);
    if not data and type(data) ~= 'table' then
        tlog:err("grpc sync_fields_export err,  cache_key=",cache_key,",old=",data)
        return tl_ops_rt.error
    end

    tlog:dbg("grpc sync_fields_export start,  cache_key=",cache_key,",old=",data)

    local add_keys = {}

    -- demo fileds check
    for key , _ in pairs(demo) do
        -- data fileds check
         -- add keys
         if data[key] == nil then
            data[key] = demo[key]
            table.insert(add_keys , key)
        end
    end

    local res = cache:set(cache_key, cjson.encode(data))
    if not res then
        tlog:err("grpc sync_fields_export err,  cache_key=",cache_key,",res=",res,",new=",data)
        return tl_ops_rt.error
    end

    tlog:dbg("grpc sync_fields_export done,  cache_key=",cache_key,",new=",data,",add_keys=",add_keys)
    
    return tl_ops_rt.ok
end



-- 字段数据同步
local sync_fields = function ()

    -- 对外配置  数据
    sync_fields_export()

    return tl_ops_rt.ok
end



return {
    sync_data = sync_data,
    sync_fields = sync_fields
}