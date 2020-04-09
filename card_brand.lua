--牌型类

local const         = require("poke_constant")

local AbstractBrand = class()

function AbstractBrand:ctor( type, cards )
	self.m_type  = type
	self.m_cards = cards
end

function AbstractBrand:getType()
	return self.m_type
end

function AbstractBrand:compareOtherBrand( otherBrand )
	if self:getType() == otherBrand:getType() then 
		return self:_compareOtherBrandWithSameType(otherBrand)
	else
		return self:getType() - otherBrand:getType()
	end  
end

function AbstractBrand:_getCompareIndexs()
	assert("sub class must override this function!")
end

function AbstractBrand:_getCardByIndex( index )
	assert(index >= 1 and index <= 5)
	return self.m_cards[index]
end

function AbstractBrand:_compareCardByIndex(index, otherBrand)
	local selfValue  = self:_getCardByIndex(index):packageValue()
	local otherValue = otherBrand:_getCardByIndex(index):packageValue()
	return selfValue - otherValue
end

function AbstractBrand:_compareOtherBrandWithSameType( otherBrand )
	local cmpIndexs = self:_getCompareIndexs()
	local cmp = 0
	for i=1,#cmpIndexs do
		cmp = self:_compareCardByIndex(cmpIndexs[i], otherBrand)
		if cmp ~= 0 then 
			return cmp
		end 
	end
	return cmp
end

function AbstractBrand:getDesc()
	local str = const.CardTypeCnDesc[self.m_type]..":"
	for _,v in ipairs(self.m_cards or {}) do
		str = str .. v:getDesc().." "
	end
	--print(str)
	return str
end

function AbstractBrand:dump()
	print(self:getDesc())
end

---------------------------------------------------------皇家同花顺------------------------------------------------------
local RoyalFlushBrand = class(AbstractBrand)
--皇家同花顺 一定是相等的
function RoyalFlushBrand:_getCompareIndexs()
	return {}
end

---------------------------------------------------------同花顺------------------------------------------------------

--同花顺
local StraightFlushBrand = class(AbstractBrand)

function StraightFlushBrand:_getCompareIndexs()
	return {1}
end

local FourOfKindBrand = class(AbstractBrand)

function FourOfKindBrand:_getCompareIndexs()
	return {1,5}
end

local FullHouseBrand = class(AbstractBrand)

function FullHouseBrand:_getCompareIndexs()
	return {1,4}
end

local FlushBrand = class(AbstractBrand)

function FlushBrand:_getCompareIndexs()
	return {1,2,3,4,5}
end 

local StraightBrand = class(AbstractBrand)

function StraightBrand:_getCompareIndexs()
	return {1}
end

local ThreeOfKindBrand = class(AbstractBrand)

function ThreeOfKindBrand:_getCompareIndexs()
	return {1,4,5}
end

local TwoPairsBrand = class(AbstractBrand)

function TwoPairsBrand:_getCompareIndexs()
	return {1,3,5}
end

local OnePairsBrand = class(AbstractBrand)

function OnePairsBrand:_getCompareIndexs()
	return {1,3,4,5}
end

local HighCardBrand = class(AbstractBrand)

function HighCardBrand:_getCompareIndexs()
	return {1,2,3,4,5}
end
--------------------------------------------------------------------------------------------
local kCreateClassMap = {
	[const.CardType.RoyalFlush]    = RoyalFlushBrand,
	[const.CardType.StraightFlush] = StraightFlushBrand,
	[const.CardType.FourOfKind]    = FourOfKindBrand,
	[const.CardType.FullHouse]     = FullHouseBrand,
	[const.CardType.Flush]         = FlushBrand,
	[const.CardType.Straight]      = StraightBrand,
	[const.CardType.ThreeOfKind]   = ThreeOfKindBrand,
	[const.CardType.TwoPairs]      = TwoPairsBrand,
	[const.CardType.OnePairs]      = OnePairsBrand,
	[const.CardType.HighCard]      = HighCardBrand
}

local export = {}

export.createBrand = function ( type, cards )
	local clsname = kCreateClassMap[type]
	if clsname then 
		return new(clsname, type, cards)
	else
		print("may be error! unknown type:", type)
	end 
	return nil
end

return export