
local netutil = {}

netutil.LITTLE_ENDIAN = true
--- Convert given short value to network byte order on little endian hosts
-- @param x Unsigned integer value between 0x0000 and 0xFFFF
-- @return  Byte-swapped value
-- @see	 htonl
-- @see	 ntohs
netutil.htons = function(x)
	if LITTLE_ENDIAN then
		return bit.bor(
			bit.rshift( x, 8 ),
			bit.band( bit.lshift( x, 8 ), 0xFF00 )
		)
	else
		return x
	end
end

--- Convert given long value to network byte order on little endian hosts
-- @param x Unsigned integer value between 0x00000000 and 0xFFFFFFFF
-- @return  Byte-swapped value
-- @see	 htons
-- @see	 ntohl
netutil.htonl = function(x)
	if LITTLE_ENDIAN then
		return bit.bor(
			bit.lshift( htons( bit.band( x, 0xFFFF ) ), 16 ),
			htons( bit.rshift( x, 16 ) )
		)
	else
		return x
	end
end

netutil.ntohs = netutil.htons
netutil.ntohl = netutil.htonl

netutil.packint16 = function(x)
	local ret
	local l = bit.rshift( x,8)
	local h = bit.band( x,0xff)
	if(  0 == l ) then 
		ret = "\0"
	else
		ret = string.format("%c", l )
	end
	if(  0 == h ) then 
		ret = ret .. "\0"
	else
		ret = ret .. string.format("%c", h)
	end
	return ret
end

netutil.unpackint16 = function(x)
	local h = tonumber(string.byte(x, 1, 1));
	local l = tonumber(string.byte(x, 2, 2));
	return h*256+l
end

netutil.packint32 = function(x)
	return netutil.packint16(bit.rshift( x,16)) .. netutil.packint16(bit.band(x,0xffff)) 
end

netutil.unpackint32 = function(x)	
	return 65536 * netutil.unpackint16( string.sub(x, 1, 2) ) + netutil.unpackint16( string.sub(x, 3, 4) )
end

netutil.htod = function(h)
    local n = tonumber(h)
    if nil ~= n then return n end
    
    if h == "a" or h == "A" then return 10 end
    if h == "b" or h == "B" then return 11 end
    if h == "c" or h == "C" then return 12 end
    if h == "d" or h == "D" then return 13 end
    if h == "e" or h == "E" then return 14 end
    if h == "f" or h == "F" then return 15 end
        
    --nlog.dinfo("htod not 16: " .. h)
    return 0
end

-- 检查字符串是否为空
local is_value = function(str)
    if str ~= nil and str ~= "" and str ~= ngx.null then 
        return true 
    else
        return false
    end 
end 

--[[
    @function  : dtoh
    @parameters: dec : 需要转换成十六进制的十进制数字 (0~15)
    @desc : 将单个十进制数字转换成十六进制
]]--
netutil.dtoh = function(dec)
    dec = tonumber(dec)
    if not is_value(dec) or "number" ~= type(dec) or 0 > dec or 15 < dec then
        nlog.error("dec is invalid, dec = " .. (dec or "nil"))
        return "0"
    end
    
    if 0 <= dec and 9 >= dec then
        return tostring(dec)
    else
        if 10 == dec then return "a" end
        if 11 == dec then return "b" end
        if 12 == dec then return "c" end
        if 13 == dec then return "d" end
        if 14 == dec then return "e" end
        if 15 == dec then return "f" end
    end
end

return netutil
