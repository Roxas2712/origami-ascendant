-- Instanced rain uses seven native float32 components per placement.
-- Cached surface columns can reach the same mesh through a byte copy.
local U={}

function U.write(mesh,vertices,count,columns)
 if count==0 then return 0 end
 if not columns then
  mesh:setVertices(vertices,1,count)
  return count
 end

 local bytes=table.concat(columns)
 local ok,data=pcall(love.data.newByteData,bytes)
 if not ok then return nil end
 local written=pcall(mesh.setVertices,mesh,data,1,count)
 data:release()
 return written and count or nil
end

return U
