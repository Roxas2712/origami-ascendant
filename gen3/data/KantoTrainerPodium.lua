-- Source pixels measured on the upper white tread, not the atlas cell edge.
local P={texture='kanto-structure.png',rect={782,826,1131,975},
 width=1.15,height=18,y=-1.35,contactPixel={956.5,845},contactZ=.65}
P.contactY=P.y+(P.rect[4]-P.contactPixel[2])*P.height/(P.rect[4]-P.rect[2])
return P
