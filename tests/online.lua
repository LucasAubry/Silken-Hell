local T={}
function T.run()
    local elapsed,nextLevel,lastSent,started,done=0,1,0,false,false
    love.update=function(dt)
        elapsed=elapsed+dt; UI.clock=UI.clock+dt; Online.update(dt)
        assert(elapsed<60,'HTTPS native : délai dépassé / '..Online.scoreStatus)
        if not started and Online.country~='ZZ' and Online.boards[1] and Online.boards[1].global then
            started=true; Profile.name='SilkenGameQA'; Profile.country=Online.country
            Online.start(1,Profile.name); App.state='menu'
            App.capture='menu-online-qa.png'
        end
        if started and Online.current.id and nextLevel<=10 and elapsed-lastSent>=1 then
            Online.checkpoint(nextLevel,nextLevel,0); nextLevel=nextLevel+1; lastSent=elapsed
            love.filesystem.write('qa-run-id.txt',Online.current.id)
        end
        if Online.scoreStatus=='Score publié dans les classements' and not done then
            done=true; Online.refresh(1); lastSent=elapsed
        end
        if done and elapsed-lastSent>2 and Online.boards[1].global then
            local found=false
            for _,s in ipairs(Online.boards[1].global) do if s.name=='SilkenGameQA' then found=true end end
            assert(found,'Score natif visible dans le classement')
            print('PASS NATIVE HTTPS: détection '..Online.country..', identité, dix checkpoints, score et classement en ligne')
            love.event.quit(0)
        end
    end
end
return T
