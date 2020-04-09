
global_language = 'En'-- 'En: English  Cn: Chinese'

function class(super, autoConstructSuper)
    local classType = {};
    classType.autoConstructSuper = autoConstructSuper or (autoConstructSuper == nil);
    if super then
        classType.super = super;
        local mt = getmetatable(super);
        setmetatable(classType, { __index = super; __newindex = mt and mt.__newindex;});
    else
        classType.setDelegate = function(self,delegate)
            self.m_delegate = delegate;
        end
    end
    return classType;
end
--
function new(classType, ...)
    local obj = {};
    local mt = getmetatable(classType);
    setmetatable(obj, { __index = classType; __newindex = mt and mt.__newindex;});
    do
        local create;
        create =
            function(c, ...)
            if c.super and c.autoConstructSuper then
                create(c.super, ...);
            end
            if rawget(c,"ctor") then
                obj.currentSuper = c.super;
                c.ctor(obj, ...);
            end
        end
        create(classType, ...);
    end
    obj.currentSuper = nil;
    return obj;
end


--function table.clone( tbl )
--    local lookup_table = {}  
--    local function _copy(target)  
--        if type(target) ~= "table" then  
--            return target   
--        end  
--        if lookup_table[target] then 
--            return lookup_table[target]
--        end 
--        local new_table = {}  
--        lookup_table[target] = new_table  
--        for index, value in pairs(target) do  
--            new_table[_copy(index)] = _copy(value)  
--        end     
--        return setmetatable(new_table, getmetatable(target))      
--    end     
--    return _copy(tbl) 
--end

-- bit operation
bit = bit or {}
bit.data32 = {}

for i=1,32 do
    bit.data32[i]=2^(32-i)
end

function bit._b2d(arg)
    local nr=0
    for i=1,32 do
        if arg[i] ==1 then
            nr=nr+bit.data32[i]
        end
    end
    return  nr
end

function bit._d2b(arg)
    arg = arg >= 0 and arg or (0xFFFFFFFF + arg + 1)
    local tr={}
    for i=1,32 do
        if arg >= bit.data32[i] then
            tr[i]=1
            arg=arg-bit.data32[i]
        else
            tr[i]=0
        end
    end
    return   tr
end

function    bit._and(a,b)
    local op1=bit._d2b(a)
    local op2=bit._d2b(b)
    local r={}

    for i=1,32 do
        if op1[i]==1 and op2[i]==1  then
            r[i]=1
        else
            r[i]=0
        end
    end
    return  bit._b2d(r)

end

function    bit._rshift(a,n)
    local op1=bit._d2b(a)
    n = n <= 32 and n or 32
    n = n >= 0 and n or 0

    for i=32, n+1, -1 do
        op1[i] = op1[i-n]
    end
    for i=1, n do
        op1[i] = 0
    end

    return  bit._b2d(op1)
end

function    bit._lshift(a,n)
    local op1=bit._d2b(a)
    n = n <= 32 and n or 32
    n = n >= 0 and n or 0

    for i=n+1, 32, 1 do
        op1[i-n] = op1[i]
    end

    for i=32-n + 1, 32, 1 do
        op1[i] = 0
    end

    return  bit._b2d(op1)
end

function bit._not(a)
    local op1=bit._d2b(a)
    local r={}

    for i=1,32 do
        if  op1[i]==1   then
            r[i]=0
        else
            r[i]=1
        end
    end
    return bit._b2d(r)
end

function bit._or(a,b)
    local op1=bit._d2b(a)
    local op2=bit._d2b(b)
    local r={}

    for i=1,32 do
        if op1[i]==1 or op2[i]==1  then
            r[i]=1
        else
            r[i]=0
        end
    end
    return bit._b2d(r)
end

bit.band   = bit.band or bit._and
bit.rshift = bit.rshift or bit._rshift
bit.lshift = bit.lshift or bit._lshift
bit.bnot   = bit.bnot or bit._not
bit.bor    = bit.bor or bit._or

-- bit operation end
