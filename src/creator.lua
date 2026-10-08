local C={status=''}
function C.open()
    local ok=require('platform').launch('--editor')
    C.status=ok and 'Le concepteur de niveaux s’ouvre.' or 'Impossible d’ouvrir le concepteur.'
    return ok
end
return C
