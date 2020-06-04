require 'luaservice'
require 'stringext'
local json = require 'dkjson'

local root_node_font = 27
local node_font = 18
local node_padding = 10
local node_min_width = 140
local node_max_width = 480

local DefaultTheme = {}
luaservice.register('Theme', DefaultTheme)

function DefaultTheme:handle(request, response)
    local action = request.jsonparams['action']
    if action == 'getStyle' then
        -- 返回样式
        local node = request.jsonparams['node']
        local layouterName = request.jsonparams['layouterName']
        response.sendfeedback(get_node_style(node, 0, layouterName), nil)
    elseif action == 'layouterNames' then
        -- 获取布局方式列表
        response.sendfeedback(get_layout_names())
    elseif action == 'layout' then
        -- 返回布局
        local node = request.jsonparams['node']
        local layout_name = request.jsonparams['name']

        if layout_name == '树形' then
            response.sendfeedback(layout_as_tree(node))
        elseif layout_name == '阅读模式' then
            response.sendfeedback(layout_as_readable(node))
        else
            response.sendfeedback(layout_as_tree(node))
        end
    elseif action == 'drawConnection' then
        -- 绘制连接线
        local from_node = request.jsonparams['from']
        local to_node = request.jsonparams['to']
        local type = request.jsonparams['type']
        local layouterName = request.jsonparams['layouterName']
        if layouterName == '阅读模式' or layouterName == '树形' then
            type = 'rect'
        end
        if type == 'curve' then
            response.sendfeedback(draw_connection_curve(from_node, to_node), nil)
        elseif type == 'rect' then
            response.sendfeedback(draw_connection_rect(layouterName, from_node, to_node), nil)
        elseif type == 'direct' then
            response.sendfeedback(draw_connection_direct(from_node, to_node), nil)
        end
    end

end

-- 返回支持的布局方式
function get_layout_names()
    return '树形' .. ',' .. '阅读模式'
end

-- 阅读模式布局
function layout_as_readable(node)
    local layout_results = {}

    layout_calculate_size(layout_results, node, true)
    local result = layout_results[1]
    local max = {}
    local centerX = node.layoutWidth / 2
    max.right = centerX
    layout_readable_set_position(result, centerX, 400, max)
    result.allWidth = max.right - centerX

    return layout_results
end

function layout_readable_set_position(result, x, y, max)
    result.x = x
    result.y = y
    result.displayX = 0
    result.displayY = 0
    result.connPointX = x
    result.connPointY = y + result.displayHeight / 2
    result.plugPointX = result.connPointX
    result.plugPointY = result.connPointY

    local v_spacing = 20
    local startY = y + result.height + v_spacing
    if result.subnodes ~= nil then
        local startX = x + 20
        for _, subResult in ipairs(result.subnodes) do
            local h = layout_readable_set_position(subResult, startX, startY, max)
            startY = startY + h
        end
    end
    result.height = startY - y
    if result.x + result.width > max.right then
        max.right = result.x + result.width
    end
    return startY - y
end

-- 树形布局
function layout_as_tree(node)
    local layout_results = {}

    layout_calculate_size(layout_results, node, true)
    local result = layout_results[1]
    layout_as_tree_set_position(result, (node.layoutWidth - result.allWidth) / 2, (result.allWidth - result.width) / 2, (node.layoutHeight - result.subHeight) / 2)

    return layout_results
end

function layout_as_tree_set_position(result, offsetx, x, y)
    result.x = offsetx + x
    result.y = y
    result.displayX = 0
    result.displayY = 0
    result.connPointX = result.x + result.width / 2
    result.connPointY = y + result.displayHeight / 2
    result.plugPointX = result.connPointX
    result.plugPointY = y

    if result.subnodes ~= nil then
        local startX = x - (result.allWidth - result.width) / 2
        local v_spacing = 50
        local h_spacing = 20
        local subY = y + result.height + v_spacing
        for _, sub_result in ipairs(result.subnodes) do
            layout_as_tree_set_position(sub_result, offsetx, startX + (sub_result.allWidth - sub_result.width) / 2, subY)
            startX = startX + sub_result.allWidth + h_spacing
        end
    end
end

-- 布局：计算每个节点宽度和高度
function layout_calculate_size(tb, node, root)
    local result = {}
    local font_size = node_font
    if root then
        font_size = root_node_font
    end
    local max_width = node_max_width
    if node.preferedStyle ~= nil and node.preferedStyle.maxWidth ~= nil then
        max_width = node.preferedStyle.maxWidth
    end
    local min_width = node_min_width
    if node.preferedStyle ~= nil and node.preferedStyle.minWidth ~= nil then
        min_width = node.preferedStyle.minWidth
    end
    local subnodesCount = 0
    if node.subnodes ~= nil then
        subnodesCount = table.getn(node.subnodes)
    end
    local text_size = node.title:size(font_size, max_width)
    local titleX = node_padding
    local titleWidth = text_size.width
    if text_size.width < min_width then
        if subnodesCount > 0 then
            titleX = node_padding + (min_width - text_size.width) / 2
            text_size.width = min_width
        else
            titleWidth = min_width
        end
    end
    result.width = text_size.width + node_padding * 2
    result.height = text_size.height + node_padding * 2
    result.displayWidth = result.width
    result.displayHeight = result.height
    result.titleX = titleX
    result.titleY = node_padding
    result.titleWidth = titleWidth
    result.titleHeight = text_size.height
    result.subnodes = {}

    local maxHeight = result.height
    local totalWidth = result.width
    local subHeight = 0
    local subWidth = 0
    local x = 0
    local y = 0
    if subnodesCount > 0 then
        local l_h_spacing = 0
        local l_v_spacing = 0
        for _, v in ipairs(node.subnodes) do
            local h_spacing = 40
            local v_spacing = 50
            local size = layout_calculate_size(result.subnodes, v, false)
            x = x + size.allWidth + h_spacing
            subWidth = subWidth + size.width + h_spacing
            subHeight = subHeight + size.height + v_spacing
            l_h_spacing = h_spacing
            l_v_spacing = v_spacing
            if size.height > maxHeight then
                maxHeight = size.height
            end
        end
        totalWidth = x - l_h_spacing
        subWidth = subWidth - l_h_spacing
        subHeight = subHeight - l_v_spacing
    end
    result.allWidth = totalWidth
    result.subHeight = subHeight
    result.subWidth = subWidth
    
    table.insert(tb, result)

    return result
end

-- 绘制连接线：直接连接
function draw_connection_direct(from_node, to_node)
    local draw = {}
    local shapes = {}
    draw.shapes = shapes

    local shape = {}
    shape.type = 'moveTo'
    shape.x = from_node.x
    shape.y = from_node.y
    table.insert(shapes, shape)

    shape = {}
    shape.type = 'lineTo'
    shape.x = to_node.x
    shape.y = to_node.y
    table.insert(shapes, shape)

    return draw
end

-- 绘制连接线：直角
function draw_connection_rect(layouterName, from_node, to_node)
    local draw = {}
    local shapes = {}
    draw.shapes = shapes

    local shape = {}
    shape.type = 'moveTo'
    shape.x = from_node.x
    shape.y = from_node.y
    table.insert(shapes, shape)

    if layouterName == '阅读模式' then
        shape = {}
        shape.type = 'lineTo'
        shape.x = from_node.x - 20
        shape.y = from_node.y
        table.insert(shapes, shape)

        shape = {}
        shape.type = 'lineTo'
        shape.x = from_node.x - 20
        shape.y = to_node.y
        table.insert(shapes, shape)
    else
        shape = {}
        shape.type = 'lineTo'
        shape.x = from_node.x
        shape.y = to_node.y - (to_node.y - from_node.y - from_node.height / 2) / 2
        table.insert(shapes, shape)

        shape = {}
        shape.type = 'lineTo'
        shape.x = to_node.x
        shape.y = to_node.y - (to_node.y - from_node.y - from_node.height / 2) / 2
        table.insert(shapes, shape)
    end

    shape = {}
    shape.type = 'lineTo'
    shape.x = to_node.x
    shape.y = to_node.y
    table.insert(shapes, shape)

    return draw
end

-- 绘制连接线：曲线
function draw_connection_curve(from_node, to_node)
    local draw = {}
    local shapes = {}
    draw.shapes = shapes

    local shape = {}
    shape.type = 'moveTo'
    shape.x = from_node.x
    shape.y = from_node.y
    table.insert(shapes, shape)

    shape = {}
    shape.type = 'quadCurveTo'
    shape.x = to_node.x
    shape.y = to_node.y
    if to_node.x < from_node.x then
        shape.controlPoint1X = to_node.x + (from_node.x - to_node.x)
    else
        shape.controlPoint1X = to_node.x - (to_node.x - from_node.x)
    end
    shape.controlPoint1Y = to_node.y
    table.insert(shapes, shape)

    return draw
end

-- 返回节点样式
function get_node_style(node, display_level, layouterName)
    local theme = {}
    theme.background_color = '135,206,250'
    theme.text_color = '0,0,0'
    theme.font_size = node_font
    theme.border_width = 1
    theme.corner_radius = 15
    if node.preferedStyle == nil or node.preferedStyle.maxWidth == nil then
        theme.max_width = node_max_width
    end
    if node.preferedStyle == nil or node.preferedStyle.minWidth == nil then
        theme.min_width = node_min_width
    end
    theme.connection_view_class_name = 'TSScriptConnectionView'
    theme.padding = node_padding
    theme.alignment = 'center'
    local attrs = {}
    theme.connection_view_attrs = attrs
    attrs.engineId = __runner_id -- 使用当前引擎执行绘制连接线
    attrs.type = 'curve' -- 设置连接线类型
    if layouterName == '阅读模式' then
        attrs.lineDash = '5, 5'
        attrs.lineColor = '125,125,125'
    end

    local subnodesCount = 0
    if node.subnodes ~= nil then
        subnodesCount = table.getn(node.subnodes)
    end
    if display_level == 0 then
        -- root
        theme.border_width = 2
        theme.max_width = node_max_width
        theme.min_width = node_min_width
        theme.font_size = root_node_font
        theme.background_color = '255,0,0'
        theme.text_color = '255,255,255'
    elseif node.title == '关于' then
        theme.background_color = '255,0,0'
        theme.text_color = '255,255,255'
    elseif display_level == 1 then
        theme.background_color = '255,255,0,100'
        theme.text_color = '0,0,0'
    elseif subnodesCount > 3 then
        theme.text_color = '0,0,0'
    elseif subnodesCount == 0 then
        theme.background_color = '255,255,255'
        theme.corner_radius = 0
        theme.view_class_name = 'TSSimpleNodeView'
    end
    
    local subnodes = {}
    if subnodesCount > 0 then
        for _, subnode in ipairs(node.subnodes) do
            table.insert(subnodes, get_node_style(subnode, display_level + 1, layouterName))
        end
    end
    theme.subnodes = subnodes

    return theme
end

function supportStyle()
    return 1
end
