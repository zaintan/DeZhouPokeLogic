local M = {}

M.CardType = {
	RoyalFlush    = 10, --皇家同花顺
	StraightFlush = 9,  --同花顺
	FourOfKind    = 8,  --四条
	FullHouse     = 7,  --葫芦
	Flush         = 6,  --同花
	Straight      = 5,  --顺子
	ThreeOfKind   = 4,  --三条
	TwoPairs      = 3,  --两对
	OnePairs      = 2,  --一对
	HighCard      = 1,  --高牌
}

M.CardColor = {
	Diamond = 0,--0x01,0x0D  方片A - 方片K
	Club    = 1,--0x11,0x1D  梅花
	Heart   = 2,--0x21,0x2D  红桃
	Spade   = 3,--0x31,0x3D  黑桃
}

local CardColorDescEn = {
	[0] = "d",
	[1] = "c",
	[2] = "h",
	[3] = "s",		
}

local CardColorDescCn = {
	[0] = "方",
	[1] = "梅",
	[2] = "红",
	[3] = "黑",		
}

M.CardValueDesc = {
	[1] = "A",
	[2] = "2",
	[3] = "3",
	[4] = "4",
	[5] = "5",
	[6] = "6",
	[7] = "7",
	[8] = "8",
	[9] = "9",
	[10] = "10",
	[11] = "J",
	[12] = "Q",
	[13] = "K",				
}

local CardTypeDescEn = {
	[1] = "HighCard",
	[2] = "OnePairs",
	[3] = "TwoPairs",
	[4] = "ThreeOfKind",
	[5] = "Straight",
	[6] = "Flush",
	[7] = "FullHouse",
	[8] = "FourOfKind",
	[9] = "StraightFlush",
	[10] = "RoyalFlush",		
}

local CardTypeDescCn = {
	[1] = "高牌",
	[2] = "一对",
	[3] = "两对",
	[4] = "三条",
	[5] = "顺子",
	[6] = "同花",
	[7] = "葫芦",
	[8] = "四条",
	[9] = "同花顺",
	[10] = "皇家同花顺",		
}

if global_language and global_language == "En" then 
	M.CardColorDesc = CardColorDescEn
	M.CardTypeDesc  = CardTypeDescEn
else 
	M.CardColorDesc = CardColorDescCn
	M.CardTypeDesc  = CardTypeDescCn
end 

return M