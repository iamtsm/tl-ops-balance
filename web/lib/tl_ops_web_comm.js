//请求参数封装
const tl_ajax_data = function (data) {
    //全局请求成功处理
    $(document).ajaxSuccess(function (event, xhr, settings) {
        if(xhr.responseText){
            let res = JSON.parse(xhr.responseText);
            if (res && res.code === -10004){
                layer.msg("请先登录")
                return
            }
        }
    });

    let needReloadMsg = (data.needReloadMsg === undefined) ? true : data.needReloadMsg;
    let comm_data = {
        method:'post',
    };
    if(!data.done){
        comm_data.done = needReloadMsg ? tl_ajax_done_data_handler : '';
    }
    if (!data.success){
        comm_data.success = needReloadMsg ? tl_ajax_success_data_handler : '';
    }
    if(!data.failed){
        comm_data.failed = tl_ajax_failed_handler;
    }

    Object.assign(data, comm_data);
    return data;
};

//ajax请求成功
const tl_ajax_success_data_handler = function (data) {
    try {
        data = JSON.parse(data);
    } catch (error) {
        data = data;
    }
    if(data.code === 0){
        layer.msg(data.msg)
    }else{
        layer.msg(data.msg+", code="+data.code)
    }
};

//table请求成功
const tl_ajax_done_data_handler = function (data) {
    if(data.code === 0){
        layer.msg(data.msg)
    }else{
        layer.msg(data.msg+", code="+data.code)
    }
};

//请求出错
const tl_ajax_failed_handler = function (data) {
    layer.msg("请求出错, "+data)
};

//获取参数
const tl_request_get_param = function (variable) {
    let query = decodeURIComponent(window.location.search.substring(1));
    let vars = query.split("&");
    for (let i = 0; i < vars.length; i++) {
        let pair = vars[i].split("=");
        if(pair[0] === variable){return pair[1];}
    }
    return "";
};

//开关开启失败
const tl_switch_open_failed = function (data, text) {
    data.elem.checked = false;
    let em = $(data.othis[0]);
    data.othis[0].classList.remove('layui-form-onswitch');
    em.children('em').text(text);
};

//开关关闭失败
const tl_switch_close_failed = function (data, text) {
    data.elem.checked = true;
    let em = $(data.othis[0]);
    data.othis[0].classList.remove('layui-form-switch');
    em.children('em').text(text);
};

//鼠标hover的tips
const tl_mouse_enter_tips = function (id, text) {
    layer.tips(text, '#'+id, {
        tips: [1,'#50393d']
    });
};

const tl_mose_enter_tips_time = function (id, text) {
    layer.tips(text, '#'+id, {
        tips: [1,'#50393d'],
        time : 2000
    });
};

//鼠标leave
const tl_mouse_leave_tips = function (id, text) {
    layer.closeAll('tips');
};


const tl_validate_ip = function( ip ) {
	const re =
		/^(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|[0-9])\.((1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)\.){2}(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)$/
	return re.test(ip)
}

//防抖
const tl_debounce = function(handler, time, business) {
    return function () {
        if(window['tl_debounce_timeout_id_'+business]){
            window.clearTimeout(window['tl_debounce_timeout_id_'+business]);
        }
        window['tl_debounce_timeout_id_'+business] = setTimeout(handler, time);
    };
};


//字节转换
const tl_byte_to_m = function (size) {
    let sizeStr = (size / 1048576).toString();
    let head = sizeStr.split(".")[0];
    let tail = "";
    if (sizeStr.split(".")[1]) {
        tail = sizeStr.split(".")[1].substring(0, 3);
    }

    if(tail === ''){
        return head + "M";
    }
    
    return head + '.' + tail + "M";
}