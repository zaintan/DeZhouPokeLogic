
----------------------------------------------------------------------------------------------
require("global_expand")
--
local judagementModule = require("judagement")
local const            = require("poke_constant")
local Card      = require("card")


local function testlogic(req, judagement, cards)	
	print("==============================test start==============================")
	req:setCardsArr(cards)
	req:dump()
	judagement:handlerRequest(req):dump()
	print("==============================test  end==============================")
end

--
local req           = new(judagementModule.BrandJudgementRequest)
local judageHandler = judagementModule.createJudgementHandler()

--testlogic(req, judageHandler, { 0x01, 0x0D, 0x0C, 0x0A, 0x11, 0x0B, 0x21})--皇家同花顺
--testlogic(req, judageHandler, { 0x09, 0x0D, 0x0C, 0x0A, 0x11, 0x0B, 0x21})--同花顺
--testlogic(req, judageHandler, { 0x01, 0x02, 0x03, 0x04, 0x05, 0x0B, 0x21})--特殊同花顺  A2345 应该也是同花顺
--testlogic(req, judageHandler, { 0x09, 0x19, 0x29, 0x0A, 0x1A, 0x01, 0x39})--四条
--testlogic(req, judageHandler, { 0x09, 0x19, 0x29, 0x0A, 0x1A, 0x01, 0x2A})--葫芦
--testlogic(req, judageHandler, { 0x09, 0x19, 0x29, 0x0A, 0x02, 0x01, 0x04})--同花
--testlogic(req, judageHandler, { 0x09, 0x08, 0x17, 0x06, 0x15, 0x21, 0x34})--顺子
--testlogic(req, judageHandler, { 0x01, 0x21, 0x02, 0x13, 0x15, 0x2A, 0x34})--顺子  特殊顺子
--testlogic(req, judageHandler, { 0x01, 0x11, 0x21, 0x1D, 0x1C, 0x23, 0x24})--三条
--testlogic(req, judageHandler, { 0x01, 0x11, 0x05, 0x32, 0x28, 0x24, 0x12})--两对
--testlogic(req, judageHandler, { 0x01, 0x17, 0x05, 0x33, 0x28, 0x22, 0x12})--一对
--testlogic(req, judageHandler, { 0x31, 0x13, 0x04, 0x32, 0x28, 0x2D, 0x1A})--高牌
--方片J 红桃A 梅花2 红桃J 方片K 梅花J 红桃8 
--testlogic(req, judageHandler, { 0x0b, 0x21, 0x12, 0x2b, 0x0d, 0x1b, 0x28})

local function dump_cards_arr( arr )
	local str = ""
	for _,v in ipairs(arr or {}) do
		if type(v) == "number" then 
			local tmp_card = new(Card, v)
			str = str .. tmp_card:getDesc() .." "--string.format("0x%02x", v)
		else
			str = str .. v:getDesc().." "
		end 
	end
	return str
end


local function create_cards()
	local cards = {}
	for i=0,3 do
		for j=1,13 do 
			table.insert(cards, i*16 + j)
		end 
	end
	return cards
end

local function shulff( cards )
	math.randomseed(os.time())
	for i = #cards,1,-1 do
		local index         = math.random(i)--[1,i]
		local temp          = cards[i]
		cards[i]            = cards[index]
		cards[index]       = temp
	end	
	return cards
end

local function make_test(personNum)
	local cards = create_cards()
	shulff(cards)

	local hand_cards = {}
	local index = 1
	for i=1,personNum do 
		table.insert(hand_cards, {cards[index], cards[index+1]})
		index = index + 2
	end 

	local common_cards = {cards[index], cards[index+1], cards[index+2],cards[index+3],cards[index+4]}

	local result = {}
	for i=1,personNum do
		local name  = "p"..i
		local cards = {}
		for _,v in ipairs(hand_cards[i]) do
			table.insert(cards,  v)
		end
		for _,v in ipairs(common_cards) do
			table.insert(cards,  v)
		end
		req:setCardsArr(cards)
		local brand = judageHandler:handlerRequest(req)
		if not brand then 
			print("maybe error! generate brand nil! error cards data:")
			print(dump_cards_arr(cards))
		end 
		local item  = {name = name, brand = brand, hand = hand_cards[i], common = common_cards}
		table.insert(result, item)
	end

	table.sort(result, function ( a, b )
		return a.brand:compareOtherBrand(b.brand) > 0
	end)

	return result
end

local function dump_result( result )
	print("==========test begin==========")

	for i,v in ipairs(result or {}) do
		print("公牌:"..dump_cards_arr(v.common))
		print("玩家 "..v.name .. " 手牌:"..dump_cards_arr(v.hand))
		print("成牌:".. v.brand:getDesc())
		print("")
	end
	print("==========test begin==========")
end

dump_result(make_test(6))
