local G={active=false}
function G.reset()
 G.active=Campaign.world==7 and player.level==9 and not App.sessionLayout and not Secret.duel
 G.age=0;G.closing=false;G.ready=false;G.fade=0;G.ambient=nil
 if not G.active then return end
 mobs={};Bosses.reset();Abyss.active=true;Abyss.boss=false;Abyss.giant=false;Abyss.head=nil;Abyss.bones={};Abyss.lightSites={};Abyss.threads={};AbyssTerrain.reset()
 Hazards.lava={};Realms.vents={};Realms.holes={};Realms.tornadoes={};Realms.current={};Realms.rainSites={}
 player.x=Arena.width*.18-15;player.y=288;objet.larme.taken=true
 G.x=Arena.width-105;G.y=300;G.width=math.min(540,Arena.width*.58)
 G.tx=G.x-G.width*.18;G.ty=350
 G.ambient={bones={},width=Arena.width};require('mobs.bosses.abyss.tooth_wake').setup(G.ambient)
 for i=#G.ambient.lumenParticles,161,-1 do table.remove(G.ambient.lumenParticles,i) end
end
function G.resize()
 if not G.active then return end
 if G.ambient then local ratio=Arena.width/(G.ambient.width or Arena.width);for _,p in ipairs(G.ambient.lumenParticles) do p.x=p.x*ratio;if p.starHomeX then p.starHomeX=p.starHomeX*ratio end end;G.ambient.width=Arena.width end
 G.x=Arena.width-105;G.width=math.min(540,Arena.width*.58);G.tx=G.x-G.width*.18
end
function G.update(dt)
 if not G.active then return end
 require('mobs.bosses.abyss.tooth_wake').update(G.ambient,dt,{})
 if not G.closing and require('collision_shapes').touchRect('abyss_gate_tear',G.tx-15,G.ty-20,30,40) then G.closing=true;G.age=0 end
 if G.closing then
  G.age=G.age+dt;G.fade=math.max(0,math.min(1,(G.age-.35)/.45))
  if G.age>=1.25 then G.ready=true end
 end
end
function G.draw()
 if not G.active then return end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 require('mobs.bosses.abyss.tooth_wake').draw(G.ambient)
 local key=G.closing and G.age>.22 and 'skeleton_head' or 'skeleton_open'
 local sprite=Art.images[key];local spot=sprite.glow or {u=.5,v=.5}
 local x,y,w,h=sprite.quad:getViewport();local iw,ih=sprite.image:getDimensions()
 G.shader=G.shader or g.newShader([[
 extern vec2 eye;extern vec2 span;extern vec2 origin;
 float patch(vec2 p,vec2 at,vec2 width){vec2 d=(p-at)/width;return exp(-dot(d,d));}
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
  vec4 p=Texel(tex,uv);vec2 q=(uv-origin)/span;
  float eyeDistance=length((uv-eye)/span);
  float mask=1.-smoothstep(.06,.15,eyeDistance);
  float cyan=smoothstep(.025,.12,min(p.g-p.r,p.b-p.r));
  p.rgb=mix(p.rgb,vec3(.005,.008,.012),max(mask*cyan,1.-smoothstep(.035,.075,eyeDistance)));
  float teeth=patch(q,vec2(.82,.43),vec2(.22,.14))+patch(q,vec2(.76,.82),vec2(.25,.13));
  float fragments=patch(q,vec2(.48,.16),vec2(.18,.055))*.20+patch(q,vec2(.28,.65),vec2(.08,.19))*.13;
  float bone=smoothstep(.18,.55,max(p.r,max(p.g,p.b)));
  float light=.045+min(1.,teeth)*.57*bone+fragments;
  return vec4(p.rgb*light,p.a)*color;
 }]])
 G.shader:send('eye',{(x+spot.u*w)/iw,(y+spot.v*h)/ih});G.shader:send('span',{w/iw,h/ih});G.shader:send('origin',{x/iw,y/ih})
 local openSpot=Art.images.skeleton_open.glow or {u=.5,v=.5}
 local cx=G.x-G.width*(openSpot.u-spot.u);local cy=G.y+G.width*1.2*(openSpot.v-spot.v)
 g.setShader(G.shader);g.setColor(.75,.85,.95);Art.draw(key,cx,cy,-G.width,0,G.width*1.2);g.setShader()
 if not G.closing then
  local tint=Worlds.color(7).tear
  require('tear_fx').draw(G.tx,G.ty,tint,UI.clock)
  G.tearShader=G.tearShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
   vec4 p=Texel(tex,uv);float light=max(p.r,max(p.g,p.b));
   vec3 base=color.rgb*(.42+.58*light);
   float highlight=smoothstep(.88,1.,min(p.r,min(p.g,p.b)))*.45;
   return vec4(mix(base,vec3(1.),highlight),p.a*color.a);
  }]])
  g.setShader(G.tearShader);g.setColor(tint);g.draw(objet.larme.img,G.tx-15,G.ty-20,0,objet.larme.size)
 end
 g.pop()
end
function G.shake()
 if not G.active or not G.closing or not Graphics.effects then return 0,0 end
 local t=G.age-.22
 if t<0 or t>.32 then return 0,0 end
 local strength=8*(1-t/.32)^2
 return math.cos(t*105)*strength,math.sin(t*137+1)*strength*.65
end
function G.blackout()
 if not G.active or G.fade<=0 then return end
 local g=love.graphics;g.push('all');g.origin();g.setShader();g.setColor(0,0,0,G.fade);g.rectangle('fill',0,0,g.getWidth(),g.getHeight());g.pop()
end
return G
