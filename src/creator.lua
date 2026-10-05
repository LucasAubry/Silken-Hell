local C={status=''}
local function quote(s) return "'"..s:gsub("'","'\\''").."'" end
function C.open()
    local base=os.getenv('HOME')..'/Library/Application Support/Silken Hell/'
    local f=io.open(base..'project-path.txt','rb'); local project=f and f:read('*a'); if f then f:close() end
    project=project and project:gsub('[\r\n]+$','') or os.getenv('SILKEN_PROJECT')
    if not project then
        local source=love.filesystem.getSource()
        if love.filesystem.getInfo('designer/main.lua') and not source:match('%.love$') then project=source end
    end
    if not project then C.status='Lance le jeu depuis le bouton du dossier du projet pour ouvrir l’éditeur.'; return false end
    local command='open -n '..quote(project..'/Concepteur Silken Hell.app')
    local ok=os.execute(command)
    C.status=(ok==true or ok==0) and 'Le concepteur de niveaux s’ouvre.' or 'Impossible d’ouvrir le concepteur.'
    return ok==true or ok==0
end
return C
