--牌型类

local const     = require("poke_constant")

local CardBrand = class()

function CardBrand:ctor( type, cards )
	self.m_type  = type
	self.m_cards = cards
end

function CardBrand:getType()
	return self.m_type
end

function CardBrand:compareOtherBrand( otherBrand )
	if self:getType() == otherBrand:getType() then 
		return self:_compareOtherBrandWithSameType(otherBrand)
	else
		return self:getType() - otherBrand:getType()
	end  
end

local kCmpIndexsMap = {
	[const.CardType.RoyalFlush]    = {},
	[const.CardType.StraightFlush] = {1},
	[const.CardType.FourOfKind]    = {1,5},
	[const.CardType.FullHouse]     = {1,4},
	[const.CardType.Flush]         = {1,2,3,4,5},
	[const.CardType.Straight]      = {1},
	[const.CardType.ThreeOfKind]   = {1,4,5},
	[const.CardType.TwoPairs]      = {1,3,5},
	[const.CardType.OnePairs]      = {1,3,4,5},
	[const.CardType.HighCard]      = {1,2,3,4,5}
}

function CardBrand:_getCompareIndexs()
	--assert("sub class must override this function!")
	local ret = kCmpIndexsMap[self.m_type]
	if ret then 
		return ret
	else 
		print("maybe error! unknown type:", self.m_type)
		return {}
	end 
end

function CardBrand:_getCardByIndex( index )
	assert(index >= 1 and index <= 5)
	return self.m_cards[index]
end

function CardBrand:_compareCardByIndex(index, otherBrand)
	local selfValue  = self:_getCardByIndex(index):packageValue()
	local otherValue = otherBrand:_getCardByIndex(index):packageValue()
	return selfValue - otherValue
end

function CardBrand:_compareOtherBrandWithSameType( otherBrand )
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

function CardBrand:getDesc()
	local str = const.CardTypeCnDesc[self.m_type]..":"
	for _,v in ipairs(self.m_cards or {}) do
		str = str .. v:getDesc().." "
	end
	--print(str)
	return str
end

function CardBrand:dump()
	print(self:getDesc())
end


local export = {}
export.createBrand = function ( type, cards )
	return new(CardBrand, type, cards)
end

return export
