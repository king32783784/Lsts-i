#I 后台运行，兼容Lart_i
##1 测试需求xml、测试项参数xml、测试设置xml
##2 damon检查测试需求xml更新
##3 存在更新，解析xml
##4 下载测试工具
##5 检查系统环境（安装依赖包）
##6 安装测试工具
##7 运行测试
###7.1 按照需求启动测试
###7.2 测试过程监控
####7.2.1 定时侦测测试机状态，如CPU、MEM、NET、io等
####7.2.2 按照一定格式记录测试机状态
####7.2.3 按照设定以邮件形式定时反馈测试机状态
##8 测试结果处理
###8.1 按照一定格式处理测试结果
###8.2 按照设定以邮件形式反馈测试结果
##9 清理测试环境

#####说明：该框架后续可能会以B/S框架实现

#II 单机执行，带GUI控制界面，不兼容Lart_i
##1 GUI控制界面
###1.1 设定测试项目
###1.2 设定测试参数
###1.3 设定监控参数
####1.3.1 设定监控时长
####1.3.2 设定监控项目
####1.3.3 设定反馈周期
##2 解析设定参数
##3 按照指定参数启动测试
##4 安装指定参数实现监控
##5 测试结果处理
##6 反馈测试结果
##7 清理测试环境
