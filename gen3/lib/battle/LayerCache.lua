local C={}
function C.same(a,b)
 if type(a)~='table'then return a==b end
 if type(b)~='table'then return false end
 for k,v in pairs(a)do if not C.same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
function C.copy(a,b)
 if type(a)~='table'then return a end
 b=type(b)=='table'and b or{};for k in pairs(b)do if a[k]==nil then b[k]=nil end end
 for k,v in pairs(a)do b[k]=C.copy(v,b[k])end;return b
end
return C
