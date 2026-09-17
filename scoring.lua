-- Save/send real elapsed time. Derive the penalty once when displaying or ranking.
local S={deathPenalty=.05}
function S.penalty(deaths) return math.max(0,deaths or 0)*S.deathPenalty end
function S.total(elapsed,deaths) return (elapsed or 0)+S.penalty(deaths) end
function S.label(deaths) return string.format('+%.2f s',S.penalty(deaths)):gsub('%.',',') end
return S
