-- Presentation-only remap of the native 25-frame player send-out arc.
-- Native spin supplies progress, so pausing/switching never creates a new clock.
local B={}
local hands={emerald={{46,31},{12,30}},kanto={{46,33},{16,35}}}
function B.anchor(edition,gender)
 return hands[edition=='emerald' and 'emerald' or 'kanto'][gender==1 and 2 or 1]
end
function B.hand(edition,gender,x,y,scale,bottom,portrait)
 -- Steven's extended hand is on the other side of his native 64px portrait.
 -- The left-side portrait is mirrored, just like the player's front sprite.
 local p=edition=='emerald'and(portrait=='steven'and{14,35}or portrait=='wally'and{23,27})or B.anchor(edition,gender)
 return {x-(p[1]-32)*scale,y+(p[2]-bottom)*scale,scale}
end
function B.position(ball,hand,target)
 if not hand or not target or ball.side~='player'then return end
 local u=(ball.frame or 0)>0 and 1 or math.max(0,math.min(1,(ball.rot or 0)/(25*25/256*math.pi*2)))
 local x=hand[1]+(target[1]-hand[1])*u+(ball.ox or 0)
 local y=hand[2]+(target[2]-hand[2])*u-40*u*(1-u)+(ball.oy or 0)
 return x,y,math.max(.3,math.min(.65,hand[3]*.8))
end
function B.returnPosition(age,hand,target)
 if not age or age<12/60 or age>=37/60 or not hand then return end
 local u=math.max(0,math.min(1,(age-12/60)/(25/60)))
 return target[1]+(hand[1]-target[1])*u,target[2]+(hand[2]-target[2])*u-32*u*(1-u),
  math.max(.3,math.min(.65,hand[3]*.8)),u*math.pi*2
end
return B
