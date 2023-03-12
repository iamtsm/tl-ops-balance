local snowflake     = require("lib.snowflake");
local scope         = require("constant.tl_ops_constant_comm").tl_ops_waf_scope;

-- api waf默认列表
local tl_ops_constant_waf_api = {
    cache_key = {
        -- 持久化字段
        list = "tl_ops_waf_api_list",
        open = "tl_ops_waf_api_open",
        scope = "tl_ops_waf_api_scope"
    },
    list = {

    },
    open = true,
    scope = scope.global,
    demo = {
        id = 1,
        host = "tlops.com",                 -- 当前生效的域名
        value = ".git",                     -- 当前匹配的规则
        service = "tlops-demo",             -- 当前生效的service
        node = 0,                           -- 当前生效的service下的node的索引
        balck = false,                      -- 是否为黑名单
        white = true,                       -- 是否为白名单
    },
}

return tl_ops_constant_waf_api