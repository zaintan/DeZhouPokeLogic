# 德州牌型判断逻辑

main.lua : 入口, 提供测试用例,示范

global_expand.lua : 基础类依赖  模拟面向对象class， new方法,  位运算库bit

poke_constant.lua : 常量定义 牌型,描述

card.lua : 牌数据类, 拆分颜色 牌值, 提供颜色比较  大小比较方法

judagement.lua : 判断牌型，从一个牌数组(>=5)内中提取出最大的组合牌型

card_brand.lua : 牌型大小比较
