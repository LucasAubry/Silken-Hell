-- Reuse the real cinematic's final two seconds, including scenery, equipment and gait.
local B={duration=2}
local modules={[6]='sky_arrival',[5]='earth_arrival',[4]='ocean_arrival',[7]='abyss_arrival',[2]='hell_arrival',[3]='renaissance_arrival'}
function B.begin(world)
 B.world=world;B.age=0;B.scene=require(assert(modules[world]))
 local duration=B.scene.begin(world==6)
 B.offset=duration-B.duration
 -- Reconstruct presentation state with the same bounded steps as the full scene.
 local age=0
 while age<B.offset do age=math.min(B.offset,age+.05);B.scene.advance(age) end
 return B.duration
end
function B.captureEnvironment(canvas)if B.scene.captureEnvironment then B.scene.captureEnvironment(canvas) end end
function B.advance(age)B.age=age;B.scene.advance(B.offset+age)end
function B.draw(canvas,w,h)B.scene.draw(canvas,w,h)end
return B
