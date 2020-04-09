
local const = require("poke_constant")
local Card  = class()

function Card:ctor( value )
	assert(value and type(value) == "number")
	--assert(value > 0 and value < )
	self.m_originValue = value

	self:getColor()
	self:getValue()
end

function Card:getOriginValue()
	return self.m_originValue
end

function Card:getColor()
	if not self.m_color then 
		self.m_color = bit.rshift(bit.band(self.m_originValue, 0xF0), 4)
	end 
	return self.m_color
end

function Card:getValue()
	if not self.m_value then 
		self.m_value = bit.band(self.m_originValue, 0x0F)
	end 
	return self.m_value
end

function Card:packageValue()
	return self:getValue() == 1 and self.m_value + 13 or self.m_value--A特殊处理  A(1) > K(13) > Q(12) > J(11) > ...
end
--

--先比颜色 再比大小-- A = K + 1
function Card:compareByColorValue(otherCard)
	if self:getColor() == otherCard:getColor() then 
		return self:packageValue() > otherCard:packageValue()
	end 
	return self:getColor() > otherCard:getColor()
end

--先比大小 再比颜色-- A = K + 1
function Card:compareByValueColor(otherCard)
	if self:packageValue() == otherCard:packageValue() then 
		return self:getColor() > otherCard:getColor()
	end 
	return self:packageValue() > otherCard:packageValue()
end


--先比颜色 再比大小-- A = 1
function Card:compareByColorValueSpecial(otherCard)
	if self:getColor() == otherCard:getColor() then 
		return self:getValue() > otherCard:getValue()
	end 
	return self:getColor() > otherCard:getColor()
end

--先比大小 再比颜色-- A = 1
function Card:compareByValueColorSpecial(otherCard)
	if self:getValue() == otherCard:getValue() then 
		return self:getColor() > otherCard:getColor()
	end 
	return self:getValue() > otherCard:getValue()
end

function Card:getDesc(en)
	local valueDesc = const.CardValueDesc[self:getValue()]
	if not valueDesc then 
		return "unknown value"
	end 
	--
	if en then 
		local desc = const.CardColorDescEn[self:getColor()]
		if not desc then 
			return "unknown color"
		end 
		return valueDesc..desc
	else
		local desc = const.CardColorDescCn[self:getColor()]
		if not desc then 
			return "unknown color"
		end 
		return desc..valueDesc
	end 
end

--function Card:equalColor( otherCard )
--	return self:getColor() == otherCard:getColor()
--end--

--function Card:equalValue( otherCard )
--	return self:getValue() == otherCard:getValue()
--end

return Card
