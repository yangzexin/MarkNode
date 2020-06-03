## Intro
<!-- !ATTRIBUTE: style=conn-view-attr: lineWidth=2; -->
### 功能列表
<!-- !ATTRIBUTE: style=conn-view-class: TSSimpleConnectionView; conn-view-attr: fillColor=255,95,0; conn-view-attr: fillWidth=4; conn-view-attr: lineWidth=0; -->
#### 思维导图
##### 新增、删除、拖动节点
##### 文本编辑
#### 皮肤系统
<!-- !ATTRIBUTE: style=conn-view-class: TSLineConnectionView; sub-alignment: top; conn-view-attr: lineWidth=2; conn-view-attr: lineColor=75,75,75; -->
##### 样式可配置
##### 脚本布局
##### 脚本绘图
### 类设计
#### TSLayouter
##### TSStandardLayouter
###### 标准脑图布局，左右两边分布
##### TSScriptLayouter
###### lua脚本布局支持，将布局逻辑提交给脚本引擎执行
#### TSNode
##### 节点类，节点标题，属性等信息
#### TSMindView
##### 根据布局产生的数据，管理TSNodeView和TSConnectionView的展示
#### TSNodeView
##### 展示单个节点的View，绘制单个节点
#### TSConnectionView
##### 连接线View，负责绘制连接线
#### TSScriptConnectionView
##### 提供通过lua脚本绘制连接线的支持
#### TSNodeStyle
##### 样式支持
#### TSScriptMindViewStyle
##### 提供lua脚本动态生成样式的功能
#### TSUIRegistry
##### 布局器和样式资源管理
#### TSLuaEngine
##### 脚本引擎，提供与lua交互相关
### 实现逻辑
<!-- !ATTRIBUTE: style=conn-view-class: TSLineConnectionView;  conn-view-attr: lineWidth=5; conn-view-attr: lineColor=255,0,0,50;sub-alignment: top; -->
1. TSLayouter根据样式等信息计算出布局数据TSLayoutResult
<!-- !ATTRIBUTE: style=max-width: 400; alignment: left; -->
2. <br/>TSMindView根据布局数据TSLayoutResult, <br/>创建TSNodeView和TSConnectionView绘制界面元素, <br/>提供编辑和拖动功能, <br/>提供动画支持
<!-- !ATTRIBUTE: style=max-width: 400 -->
3. TSMindView通过TSMindViewDelegate回调通知UI事件
<!-- !ATTRIBUTE: style=max-width: 400 -->
### 其他
<!-- !ATTRIBUTE: style=conn-view-attr: lineDash=5, 5; -->
#### 关于
<!-- 
!ATTRIBUTE: link-node=http://chemagui.com:8000/about.md
!ATTRIBUTE: style=bg-color: 255,0,0; text-color: 255,255,255; corner-radius: 15; border-width: 2; view-class: TSNodeView; font-size: 18; alignment: center; 
-->
