local B={cache={}}
function B.path(w,h)
 local key=w..':'..h;if B.cache[key] then return B.cache[key] end
 local points={};local r=5
 for _,c in ipairs({{w-r,r,-math.pi/2},{w-r,h-r,0},{r,h-r,math.pi/2},{r,r,math.pi}}) do
  for i=0,8 do local a=c[3]+i*math.pi/16;points[#points+1]={c[1]+math.cos(a)*r,c[2]+math.sin(a)*r} end
 end
 local path={length=0}
 for i,p in ipairs(points) do local q=points[i%#points+1];local length=math.sqrt((q[1]-p[1])^2+(q[2]-p[2])^2)
  path[#path+1]={p=p,q=q,start=path.length,length=length};path.length=path.length+length
 end
 B.cache[key]=path;return path
end
function B.draw(x,y,w,h,clock,color)
 local g=love.graphics;local path=B.path(w,h);local start=(clock*65)%path.length
 g.push('all');g.translate(x,y)
 for _,offset in ipairs({0,path.length/2}) do
  for layer=1,2 do
   g.setLineWidth(layer==1 and 6 or 2);g.setColor(color[1],color[2],color[3],layer==1 and .10 or .95)
   local a=(start+offset)%path.length;local b=a+56
   for _,shift in ipairs({0,-path.length}) do for _,edge in ipairs(path) do
    local lo=math.max(edge.start,a+shift);local hi=math.min(edge.start+edge.length,b+shift)
    if hi>lo then
     local u,v=(lo-edge.start)/edge.length,(hi-edge.start)/edge.length;local p,q=edge.p,edge.q
     g.line(p[1]+(q[1]-p[1])*u,p[2]+(q[2]-p[2])*u,p[1]+(q[1]-p[1])*v,p[2]+(q[2]-p[2])*v)
    end
   end end
  end
 end
 g.pop()
end
return B
