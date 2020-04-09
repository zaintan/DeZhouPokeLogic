--从7张牌  提取5张组成最大牌型
local export = {}

local const     = require("poke_constant")
local Card      = require("card")
local CardBrand = require("card_brand")

--获取最大牌型
local BrandJudgementRequest = class()

function BrandJudgementRequest:ctor( cardDataArr )
	if cardDataArr then 
		self:setCardsArr(cardDataArr)
	end 
end

function BrandJudgementRequest:setCardsArr( cardDataArr )
	assert( cardDataArr and type(cardDataArr) == "table")
	assert(#cardDataArr >= 5)

	self.m_originData = cardDataArr

	self.m_sortedCardsByColor = {}
	self.m_sortedCardsByValue = {}
	for _,v in ipairs(cardDataArr) do
		local c = new(Card, v)
		table.insert(self.m_sortedCardsByColor, c)
		table.insert(self.m_sortedCardsByValue, c)
	end
	--按先颜色 再大小
	table.sort(self.m_sortedCardsByColor, function ( a, b )
		return a:compareByColorValue(b)
	end)
	--按先大小 再颜色
	table.sort(self.m_sortedCardsByValue, function ( a, b )
		return a:compareByValueColor(b)
	end)
end

function BrandJudgementRequest:getSortedCardsByColor()
	return self.m_sortedCardsByColor
end

function BrandJudgementRequest:getSortedCardsByValue()
	return self.m_sortedCardsByValue
end

function BrandJudgementRequest:dump()
	originDataStr = ""
	for _,v in ipairs(self.m_originData) do
		originDataStr = originDataStr .. string.format("0x%02X  ", v)
	end
	print("origin:",originDataStr)

	str = ""
	for _,v in ipairs(self.m_sortedCardsByColor) do
		str = str .. v:getDesc().." "
	end
	print("colors:",str)	

	str = ""
	for _,v in ipairs(self.m_sortedCardsByValue) do
		str = str .. v:getDesc().." "
	end
	print("values:",str)		
end

---------------------------------------------------------req------------------------------------------------------
local AbstractBrandJudgement = class()

function AbstractBrandJudgement:handlerRequest( req )
	local ret,result = self:handlerRequestImp(req)
	if ret then 
		return result
	else 
		if self.m_nextHandler then 
			return self.m_nextHandler:handlerRequest(req)
		end 
		return nil
	end 
end

function AbstractBrandJudgement:setNextHandler( handler )
	self.m_nextHandler = handler
	return self.m_nextHandler
end

function AbstractBrandJudgement:handlerRequestImp( req )
	-- body
end

--基于baseIndex 找连续num个相同value的
function AbstractBrandJudgement:_findContinueValue(data, baseIndex, num)
	local findStartCard = data[baseIndex]
	for i = 1,num-1 do 
		local targetCard = data[baseIndex + i]
		if not targetCard or targetCard:getValue() ~= findStartCard:getValue() then 
			return nil
		end 
	end 
	return baseIndex
end

--
function AbstractBrandJudgement:generateResult(cards )
	return CardBrand.createBrand(self.m_type, cards)--return { type = self.m_type,  data = cards}
end

---------------------------------------------------------同花顺------------------------------------------------------

--同花顺
local StraightFlushJudagement = class(AbstractBrandJudgement)

function StraightFlushJudagement:ctor()
	self.m_type = const.CardType.StraightFlush
end

--基于baseIndex 找同花顺
function StraightFlushJudagement:_findStraightFlush(data, baseIndex)
	local findStartCard = data[baseIndex]
	for i = 1,4 do 
		local targetCard = data[baseIndex + i]
		if not targetCard
			 or findStartCard:getColor() ~= targetCard:getColor()
			 or findStartCard:packageValue() ~= targetCard:packageValue() + i then 
			return nil
		end 
	end 
	return baseIndex
end

function StraightFlushJudagement:_getResultData(cards, index)
	return self:generateResult({cards[index],cards[index+1],cards[index+2],cards[index+3],cards[index+4]})
end

function StraightFlushJudagement:_findSpecialA2345(req)
	local cards = req:getSortedCardsByColor()
	--A2345特殊处理
	local specialSortedCards = {}
	for _,v in ipairs(cards) do
		table.insert(specialSortedCards, v)
	end
	--按先颜色 再大小
	table.sort(specialSortedCards, function ( a, b )
		return a:compareByColorValueSpecial(b)
	end)

	for i=1,#cards-5+1 do--找54321
		local findStartCard = specialSortedCards[i]
		local found = true
		for j = 1,4 do 
			local targetCard = specialSortedCards[j + i]
			if not targetCard
				 or findStartCard:getColor() ~= targetCard:getColor()
				 or findStartCard:getValue() ~= targetCard:getValue() + j then 
				found = false
				break
			end 
		end 
		if found then 
			return true, self:_getResultData(specialSortedCards, i)
		end 
	end	
	return false
end

function StraightFlushJudagement:handlerRequestImp( req )
	local cards = req:getSortedCardsByColor()
	--找到 连续5张 同花色的
	-----------------------
	local findList = {}
	--
	local maxNum = #cards
	for i=1,maxNum-5+1 do--按颜色排序的  第一个找到的不一定是最大,所以要找出所有的按packageValue值排序
		local index = self:_findStraightFlush(cards, i)		
		if index then 
			--print("find..",cards[index]:getDesc())
			table.insert(findList, i)
		end 
	end
	if #findList > 0 then 
		table.sort(findList, function ( a, b )
			return cards[a]:packageValue() > cards[b]:packageValue()
		end)
	end 
	if #findList > 0 then 
		return true, self:_getResultData(cards, findList[1])
	end 
	-------------------------------------
	return self:_findSpecialA2345(req)
end

---------------------------------------------------------皇家同花顺------------------------------------------------------
--
local RoyalFlushJudagement = class(StraightFlushJudagement)

function RoyalFlushJudagement:ctor()
	self.m_type = const.CardType.RoyalFlush
end

function RoyalFlushJudagement:handlerRequestImp( req )
	local cards = req:getSortedCardsByColor()
	local maxNum = #cards
	for i=1,maxNum-5+1 do
		if cards[i]:getValue() == 1 then --A
			local index = self:_findStraightFlush(cards, i)		
			if index then 
				--print("find..",cards[index]:getDesc())
				return true,self:_getResultData(cards, index)
			end 
		end 
	end
	return false
end

---------------------------------------------------------四条------------------------------------------------------
local FourOfKindJudagement = class(AbstractBrandJudgement)

function FourOfKindJudagement:ctor()
	self.m_type = const.CardType.FourOfKind
end

function FourOfKindJudagement:handlerRequestImp( req )
	local cards  = req:getSortedCardsByValue()
	local maxNum = #cards

	for i=1,maxNum-4+1 do
		--
		local index = self:_findContinueValue(cards, i, 4)
		if index then --第一个肯定是最大的
			--取剩下的最大的单张
			local findIndex = nil
			for j=1,maxNum do
				if j < index or j > index+3 then --[index,index+1,index+2,index+3]
					findIndex = j 
					break
				end  
			end
			if not findIndex then 
				return false
			end 

			return true,self:generateResult({cards[index],cards[index+1],cards[index+2],cards[index+3], cards[findIndex]})
		end 
	end
	return false
end


---------------------------------------------------------葫芦------------------------------------------------------
local FullHouseJudagement = class(AbstractBrandJudgement)

function FullHouseJudagement:ctor()
	self.m_type = const.CardType.FullHouse
end


--基于指定indexs 找连续num个相同value的
function FullHouseJudagement:_findContinueValueFromValidIndexs(data, indexs, num)
	for i=1,#indexs-num+1 do 
		local baseCard = data[indexs[i]]
		local found = true
		for j=1,num-1 do 
			local targetCard = data[indexs[i + j]]
			if not targetCard or targetCard:getValue() ~= baseCard:getValue() then 
				found = false
				break
			end 
		end 
		--
		if found then 
			return i
		end 
	end
	return nil
end

function FullHouseJudagement:handlerRequestImp( req )
	local cards  = req:getSortedCardsByValue()
	local maxNum = #cards

	for i=1,maxNum-3+1 do
		local index = self:_findContinueValue(cards, i, 3)
		if index then --第一个肯定是最大的

			--取剩下的最大的一对子
			local remainIndexs = {}
			for i=1,maxNum do 
				if i < index or i > index+2 then
					table.insert(remainIndexs, i)
				end  
			end 

			local findPair = self:_findContinueValueFromValidIndexs(cards, remainIndexs, 2)
			--没找到对子  肯定不是葫芦
			if not findPair then 
				return false
			end 
			local pairIndex1 = remainIndexs[findPair]
			local pairIndex2 = remainIndexs[findPair+1]

			return true,self:generateResult({cards[index],cards[index+1],cards[index+2],cards[pairIndex1], cards[pairIndex2]})
		end 
	end
	return false
end

---------------------------------------------------------同花------------------------------------------------------

local FlushJudagement = class(AbstractBrandJudgement)

function FlushJudagement:ctor()
	self.m_type = const.CardType.Flush
end

--基于baseIndex 找同花顺
function FlushJudagement:_findFlush(data, baseIndex)
	local findStartCard = data[baseIndex]
	for i = 1,4 do 
		local targetCard = data[baseIndex + i]
		if not targetCard
			 or findStartCard:getColor() ~= targetCard:getColor() then 
			return nil
		end 
	end 
	return baseIndex
end

function FlushJudagement:handlerRequestImp( req )
	local cards = req:getSortedCardsByColor()
	--找到 连续5张 同花色的
	-----------------------
	local findList = {}
	--
	local maxNum = #cards
	for i=1,maxNum-5+1 do--按颜色排序的  第一个找到的不一定是最大,所以要找出所有的按packageValue值排序
		local index = self:_findFlush(cards, i)		
		if index then 
			table.insert(findList, i)
		end 
	end
	if #findList > 0 then 
		table.sort(findList, function ( a, b )
			return cards[a]:packageValue() > cards[b]:packageValue()
		end)
	end 
	if #findList > 0 then 
		local index = findList[1]
		return true, self:generateResult({cards[index],cards[index+1],cards[index+2],cards[index+3],cards[index+4]})
	end 

	return false
end


---------------------------------------------------------顺子------------------------------------------------------

local StraightJudagement = class(AbstractBrandJudgement)

function StraightJudagement:ctor()
	self.m_type = const.CardType.Straight
end


function StraightJudagement:_findStraightIndexs(data, baseIndex, getCardValueFuncName)

	local funcName       = getCardValueFuncName and getCardValueFuncName or "packageValue"
	local findStartCard  = data[baseIndex]
	local baseValue      = findStartCard[funcName](findStartCard)
	--findStartCard:packageValue()
	local foundNum    = 1
	local foundTarget = 5
	local retIndexs   = { baseIndex }

	--data 已经是按 Card[funcName](Card)排好序的了  ex:As Ac Qc Qd 10c 9c 8c
	for i = baseIndex+1,#data do 
		local targetCard = data[i]
		if not targetCard then --取到空值了  未完成
			return nil
		end 

		local curValue = targetCard[funcName](targetCard) 
		if curValue > baseValue then 
			--一定是出错了  排序 不可能后面比前面大
			print("maybe error! ")
			return nil
		elseif curValue < baseValue then -- targetCard < findStartCard 
			--
			if curValue + foundNum ~= baseValue then
				return nil
			else--find one 
				table.insert(retIndexs, i)
				foundNum = foundNum + 1
			end  
		end ----相等忽略 continue

		--检查已经满足要求了
		if foundNum == foundTarget then 
			return retIndexs
		end 
	end 
	return nil
end

function StraightJudagement:handlerRequestImp( req )

	local cards = req:getSortedCardsByValue()
	--找到 连续5张
	-----------------------
	--
	local maxNum = #cards
	for i=1,maxNum-5+1 do--第一个找到的一定是最大的
		local indexs = self:_findStraightIndexs(cards, i)	
		if indexs then 
			return true, self:generateResult({cards[indexs[1]],cards[indexs[2]],cards[indexs[3]],cards[indexs[4]],cards[indexs[5]]})
		end 	
	end

	return self:_findSpecialA2345(req)
end

function StraightJudagement:_findSpecialA2345( req )
	local cards = req:getSortedCardsByValue()
	--A2345特殊处理
	local specialSortedCards = {}
	for _,v in ipairs(cards) do
		table.insert(specialSortedCards, v)
	end
	--先按大小
	table.sort(specialSortedCards, function ( a, b )
		return a:compareByValueColorSpecial(b)
	end)

	cards = specialSortedCards
	local maxNum = #cards
	for i=1,maxNum-5+1 do--只找A2345 找到一定够了
		local indexs = self:_findStraightIndexs(cards, i, "getValue")	
		if indexs then 
			return true, self:generateResult({cards[indexs[1]],cards[indexs[2]],cards[indexs[3]],cards[indexs[4]],cards[indexs[5]]})
		end 	
	end
	return false
end

---------------------------------------------------------三张------------------------------------------------------
local ThreeOfKindJudagement = class(AbstractBrandJudgement)
--
function ThreeOfKindJudagement:ctor()
	self.m_type = const.CardType.ThreeOfKind
end
--
function ThreeOfKindJudagement:handlerRequestImp( req )
	--print("ThreeOfKindJudagement handle req")
	--req:dump()
	--三张
	local cards  = req:getSortedCardsByValue()
	local maxNum = #cards
	--
	for i=1,maxNum-3+1 do
		--
		local index = self:_findContinueValue(cards, i, 3)
		if index then --第一个肯定是最大的
			local result = {cards[index],cards[index+1],cards[index+2]}
			--取剩下的最大的两个单张
			local numLimit = 2
			for j=1,index-1 do
				table.insert(result, cards[j])
				numLimit = numLimit - 1
				if numLimit <= 0 then 
					return true,self:generateResult(result)
				end 
			end
			--
			for j=index+3,maxNum do 
				table.insert(result, cards[j])
				numLimit = numLimit - 1
				if numLimit <= 0 then 
					return true,self:generateResult(result)
				end 
			end 

			return false
		end 
	end
	return false
end

---------------------------------------------------------两对------------------------------------------------------

local TwoPairsJudagement = class(AbstractBrandJudgement)
--
function TwoPairsJudagement:ctor()
	self.m_type = const.CardType.TwoPairs
end

function TwoPairsJudagement:handlerRequestImp( req )
	--
	local cards  = req:getSortedCardsByValue()
	local maxNum = #cards
	for i=1,maxNum-4+1 do
		local index = self:_findContinueValue(cards, i, 2)--取第一对
		if index then --第一对肯定是最大的
			--print(cards[index]:getDesc(),cards[index+1]:getDesc())
			local result = nil
			for k = index+2,maxNum-2+1 do 
				local secondPairIndex = self:_findContinueValue(cards,k,2)--取第二对
				if secondPairIndex then 
					--print(cards[secondPairIndex]:getDesc(),cards[secondPairIndex+1]:getDesc())
					result = {cards[index],cards[index+1], cards[secondPairIndex],cards[secondPairIndex+1]}
					for j=1,maxNum do 
						if j ~= index and j ~= index+1 and j ~= secondPairIndex and j ~= secondPairIndex+1 then 
							table.insert(result, cards[j])--取最大的单张
							return true,self:generateResult(result)
						end 
					end 
				end 
			end
			--
			return false 
		end 
	end
	return false
end


---------------------------------------------------------一对------------------------------------------------------

local OnePairsJudagement = class(AbstractBrandJudgement)
--
function OnePairsJudagement:ctor()
	self.m_type = const.CardType.OnePairs
end

function OnePairsJudagement:handlerRequestImp( req )
	--
	local cards  = req:getSortedCardsByValue()
	local maxNum = #cards
	for i=1,maxNum-2+1 do
		local index = self:_findContinueValue(cards, i, 2)--取第一对
		if index then --第一对肯定是最大的
			local result = {cards[index],cards[index+1]}
			--取剩下的最大的三个单张
			local numLimit = 3
			for j=1,index-1 do
				table.insert(result, cards[j])
				numLimit = numLimit - 1
				if numLimit <= 0 then 
					return true,self:generateResult(result)
				end 
			end
			--
			for j=index+2,maxNum do 
				table.insert(result, cards[j])
				numLimit = numLimit - 1
				if numLimit <= 0 then 
					return true,self:generateResult(result)
				end 
			end 
			--
			return false
		end 
	end
	return false
end

---------------------------------------------------------高牌------------------------------------------------------

local HighCardJudagement = class(AbstractBrandJudgement)
--
function HighCardJudagement:ctor()
	self.m_type = const.CardType.HighCard
end

function HighCardJudagement:handlerRequestImp( req )
	local cards  = req:getSortedCardsByValue()
	return true, self:generateResult({cards[1], cards[2], cards[3], cards[4], cards[5]})
end
--export.BrandJudgementRequest   = BrandJudgementRequest
--export.RoyalFlushJudagement    = RoyalFlushJudagement
--export.StraightFlushJudagement = StraightFlushJudagement

export.createJudgementHandler = function ()
	local t = {
		RoyalFlushJudagement,
		StraightFlushJudagement,
		FourOfKindJudagement,
		FullHouseJudagement,
		FlushJudagement,
		StraightJudagement,
		ThreeOfKindJudagement,
		TwoPairsJudagement,
		OnePairsJudagement,
		HighCardJudagement
	}-------
	local beginHandler = nil
	local curHandler   = nil
	for _,v in ipairs(t) do
		local handler = new(v)
		if not beginHandler then 
			beginHandler = handler
		end 

		if curHandler then 
			curHandler:setNextHandler(handler)
		end 
		curHandler = handler
	end
	return beginHandler
end

export.BrandJudgementRequest = BrandJudgementRequest

return export