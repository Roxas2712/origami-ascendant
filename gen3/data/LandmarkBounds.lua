-- Native footprints for large/touching landmarks whose collision components
-- also include adjacent row houses. Coordinates are native metatile cells.
local dewfordHousePanes={{34,45,38,50},{41,45,45,50}}
local mossdeepHousePanes={{43,43,50,43},{41,44,52,44},{40,45,53,50},{41,51,52,51}}
local mossdeepClubPanes={{45,59,50,59},{44,60,51,60},{43,61,52,61},{42,62,53,66},{43,67,52,67},
 {61,59,66,59},{60,60,67,60},{59,61,68,61},{58,62,69,66},{59,67,68,67}}
return {
 -- Ferry terminals are entered from the north. A facade-door flood cannot
 -- recognize their south-facing shell; keep the approach pier outside it.
 FR_FIVE_ISLAND={{x0=10,x1=14,y0=16,y1=19,ground=0x276,wallRows=2,renderOnly=true}},
 FR_BIRTH_ISLAND_EXTERIOR={{x0=13,x1=17,y0=26,y1=29,ground=0x276,wallRows=2,renderOnly=true}},
 FR_NAVEL_ROCK_EXTERIOR={{x0=7,x1=11,y0=18,y1=21,ground=0x276,wallRows=2,renderOnly=true}},
 FR_TWO_ISLAND={{x0=8,x1=12,y0=10,y1=13,ground=0x276,wallRows=2,renderOnly=true}},
 FR_THREE_ISLAND_PORT={{x0=10,x1=14,y0=15,y1=18,ground=0x276,wallRows=2,renderOnly=true}},
 FR_FOUR_ISLAND={{x0=8,x1=12,y0=30,y1=33,ground=0x276,wallRows=2,renderOnly=true}},
 FR_SIX_ISLAND={{x0=9,x1=13,y0=25,y1=28,ground=0x276,wallRows=2,renderOnly=true}},
 FR_SEVEN_ISLAND={{x0=14,x1=18,y0=15,y1=18,ground=0x276,wallRows=2,renderOnly=true}},
 -- The small stair room on the accessible condominium roof has a separate
 -- roof and facade. The surrounding deck and lower building remain intact.
 FR_CELADON_CITY_CONDOMINIUMS_ROOF={{x0=1,x1=4,y0=7,y1=12,doorX=2,doorY=12,ground=0x306,wallRows=2}},
 -- The Safari fence is a secondary solid tile too, but is not part of the
 -- gate's roof. The six-column native gate reaches the north map boundary.
 FR_FUCHSIA_CITY={{x0=22,x1=27,y0=0,y1=5,doorX=24,doorY=5,ground=1,wallRows=2}},
 -- Bill's cottage starts at x49. The neighboring 0x2fa is a tree base,
 -- and 0x169 is its freestanding sign; neither belongs in the roof/facade.
 FR_ROUTE_25={{x0=49,x1=53,y0=2,y1=4,doorX=51,doorY=4,wallRows=2,billCottage=true}},
 -- Native route houses whose non-solid window bands split the automatic
 -- collision flood. y0-1 is the first roof row; fences/signs stay outside.
 EM_ROUTE109={{x0=10,x1=14,y0=3,y1=5,doorX=12,doorY=5,eaveRow=38,hoennLocalArchitecture=true,panes={}}},
 EM_ROUTE110={
  {x0=14,x1=19,y0=13,y1=16,doorX=15,doorY=16,eaveRow=38,hoennLocalArchitecture=true,panes={}},
  {x0=15,x1=20,y0=85,y1=88,doorX=16,doorY=88,eaveRow=38,hoennLocalArchitecture=true,panes={}},
 },
 EM_ROUTE111={{x0=11,x1=15,y0=110,y1=113,doorX=13,doorY=113,eaveRow=38,hoennLocalArchitecture=true,panes={}}},
 EM_ROUTE112={{x0=27,x1=32,y0=24,y1=27,doorX=28,doorY=27,eaveRow=54,hoennLocalArchitecture=true,panes={}}},
 EM_MT_CHIMNEY={{x0=14,x1=19,y0=33,y1=36,doorX=17,doorY=36,eaveRow=54,hoennLocalArchitecture=true,panes={}}},
 EM_ROUTE113={{x0=32,x1=35,y0=3,y1=5,doorX=33,doorY=5,eaveRow=38,hoennLocalArchitecture=true,panes={}}},
 EM_ROUTE114={{x0=28,x1=31,y0=3,y1=5,doorX=29,doorY=5,eaveRow=38,hoennLocalArchitecture=true,panes={}}},
 EM_ROUTE121={{x0=35,x1=39,y0=1,y1=5,doorX=37,doorY=5,eaveRow=64,hoennLocalArchitecture=true,panes={}}},
 EM_SAFARI_ZONE_SOUTH={{x0=30,x1=39,y0=30,y1=33,doorX=32,doorY=33,eaveRow=48,hoennLocalArchitecture=true,panes={}}},
 EM_VERDANTURF_TOWN={
  {x0=1,x1=5,y0=4,y1=7,doorX=3,doorY=7,eaveRow=0,hoennLocalArchitecture=true,paperValues={wallScale=.85,roofScale=.60},panes={}},
  {x0=0,x1=3,y0=12,y1=14,doorX=1,doorY=14,eaveRow=38,hoennLocalArchitecture=true,panes={}},
  {x0=8,x1=12,y0=12,y1=14,doorX=10,doorY=14,eaveRow=38,hoennLocalArchitecture=true,panes={}},
  {x0=16,x1=19,y0=13,y1=15,doorX=17,doorY=15,eaveRow=38,hoennLocalArchitecture=true,panes={}},
 },
 -- Native Emerald city footprints. The first roof course is y0-1, as in
 -- BuildingMesh.sprite. Explicit bounds keep adjacent fences, cliffs and
 -- paving out of the folded artwork; common Centers/Marts stay automatic.
 EM_DEWFORD_TOWN={
  {x0=1,x1=5,y0=1,y1=3,doorX=3,doorY=3,eaveRow=38,hoennLocalArchitecture=true,panes={{50,45,54,50},{57,45,61,50}}},
  {x0=7,x1=10,y0=6,y1=8,doorX=8,doorY=8,eaveRow=38,hoennLocalArchitecture=true,panes=dewfordHousePanes},
  {x0=16,x1=19,y0=12,y1=14,doorX=17,doorY=14,eaveRow=38,hoennLocalArchitecture=true,panes=dewfordHousePanes},
 },
 EM_MAUVILLE_CITY={
  {x0=34,x1=38,y0=3,y1=5,doorX=35,doorY=5,eaveRow=38,hoennLocalArchitecture=true,panes={{53,43,54,44},{57,43,58,44},{52,45,54,48},{57,45,59,48},{52,50,54,52},{57,50,59,52}}},
  {x0=5,x1=11,y0=11,y1=13,doorX=8,doorY=13,eaveRow=32,hoennLocalArchitecture=true,panes={{16,42,39,52},{16,55,39,59},{72,42,95,52},{72,55,95,59}}},
  {x0=18,x1=21,y0=12,y1=14,doorX=19,doorY=14,eaveRow=38,hoennLocalArchitecture=true,panes={{37,43,38,44},{41,43,42,44},{36,45,38,48},{41,45,43,48},{36,50,38,52},{41,50,43,52}}},
  {x0=31,x1=35,y0=12,y1=14,doorX=32,doorY=14,eaveRow=38,hoennLocalArchitecture=true,panes={{49,44,54,49},{57,44,62,49}}},
  {x0=36,x1=39,y0=12,y1=15,doorX=37,doorY=15,eaveRow=42,ground=1,renderOnly=true,hoennLocalArchitecture=true,panes={}},
 },
 EM_MOSSDEEP_CITY={
  {x0=27,x1=30,y0=7,y1=9,doorX=28,doorY=9,eaveRow=38,hoennLocalArchitecture=true,panes=mossdeepHousePanes},
  {x0=66,x1=69,y0=23,y1=25,doorX=67,doorY=25,eaveRow=38,hoennLocalArchitecture=true,panes=mossdeepHousePanes},
  {x0=48,x1=51,y0=4,y1=6,doorX=49,doorY=6,eaveRow=38,hoennLocalArchitecture=true,panes=mossdeepHousePanes},
  {x0=18,x1=21,y0=8,y1=10,doorX=19,doorY=10,eaveRow=38,hoennLocalArchitecture=true,panes=mossdeepHousePanes},
  {x0=17,x1=20,y0=14,y1=16,doorX=18,doorY=16,eaveRow=38,hoennLocalArchitecture=true,panes=mossdeepHousePanes},
  {x0=35,x1=39,y0=21,y1=24,doorX=36,doorY=24,eaveRow=54,hoennLocalArchitecture=true,panes=mossdeepClubPanes},
 },
 EM_RUSTBORO_CITY={
  {x0=9,x1=17,y0=26,y1=30,doorX=13,doorY=30,wallRows=3,exteriorPaper=true},
  {x0=24,x1=30,y0=31,y1=34,doorX=27,doorY=34,wallRows=2,exteriorPaper=true},
  {x0=7,x1=11,y0=35,y1=38,doorX=9,doorY=38,wallRows=2,exteriorPaper=true},
  {x0=24,x1=29,y0=43,y1=46,doorX=26,doorY=46,wallRows=2,exteriorPaper=true},
  {x0=28,x1=32,y0=25,y1=28,doorX=30,doorY=28,wallRows=2,exteriorPaper=true},
  {x0=31,x1=35,y0=16,y1=19,doorX=33,doorY=19,wallRows=2,exteriorPaper=true},
  {x0=3,x1=9,y0=44,y1=51,doorX=5,doorY=51,wallRows=6,exteriorPaper=true},
  {x0=31,x1=34,y0=40,y1=46,doorX=32,doorY=46,wallRows=5,renderOnly=true,exteriorPaper=true},
 },
 EM_LILYCOVE_CITY={
  {x0=35,x1=38,y0=4,y1=6,doorX=36,doorY=6,wallRows=2,exteriorPaper=true},
  {x0=41,x1=44,y0=4,y1=6,doorX=42,doorY=6,wallRows=2,exteriorPaper=true},
  {x0=37,x1=41,y0=12,y1=14,doorX=39,doorY=14,wallRows=2,exteriorPaper=true},
  {x0=11,x1=14,y0=12,y1=14,doorX=12,doorY=14,wallRows=2,exteriorPaper=true},
  {x0=10,x1=13,y0=20,y1=22,doorX=11,doorY=22,wallRows=2,exteriorPaper=true},
  {x0=54,x1=57,y0=13,y1=15,doorX=55,doorY=15,wallRows=2,exteriorPaper=true},
  {x0=36,x1=41,y0=21,y1=24,doorX=37,doorY=24,wallRows=2,exteriorPaper=true},
 },
 EM_FORTREE_CITY={
  {x0=19,x1=24,y0=8,y1=11,doorX=22,doorY=11,ground=1,wallRows=2},
  {x0=8,x1=12,y0=2,y1=3,doorX=10,doorY=3,ground=0xc7,wallRows=1},
  {x0=15,x1=19,y0=2,y1=3,doorX=17,doorY=3,ground=0xc7,wallRows=1},
  {x0=23,x1=27,y0=2,y1=3,doorX=25,doorY=3,ground=0xc7,wallRows=1},
  {x0=30,x1=34,y0=1,y1=2,doorX=32,doorY=2,ground=0xc7,wallRows=1},
  {x0=10,x1=14,y0=12,y1=13,doorX=12,doorY=13,ground=0xc7,wallRows=1},
  {x0=35,x1=39,y0=12,y1=13,doorX=37,doorY=13,ground=0xc7,wallRows=1},
 },
 -- The forest's wide north gate uses primary architecture tiles. Its
 -- roof is cropped at the map edge; y7 is the native glass/facade course.
 FR_VIRIDIAN_FOREST={
  {x0=0,x1=10,y0=0,y1=9,ground=1,wallRows=3,renderOnly=true,forestGate=true},
  -- South gate is seen from behind; only its roof is in the native layout.
  -- Keep the northern approach and all three warp cells in row62 on the floor.
  {x0=24,x1=34,y0=64,y1=68,ground=1,wallRows=0,renderOnly=true,forestRearGate=true},
 },
 FR_ROUTE_2={
  {x0=2,x1=9,y0=15,y1=19,doorX=5,doorY=13,ground=1,wallRows=2},
  {x0=14,x1=18,y0=21,y1=22,doorX=17,doorY=22,wallRows=1},
  {x0=16,x1=21,y0=43,y1=46,doorX=18,doorY=46,wallRows=2},
  {x0=2,x1=9,y0=46,y1=51,doorX=5,doorY=51,wallRows=3},
 },
 -- Route-side gate footprints include the primary roof/front tiles. The
 -- southern approach tile remains on the ground, outside each facade.
 FR_ROUTE_5={{x0=22,x1=27,y0=34,y1=38,ground=1,wallRows=3,renderOnly=true,routeGate=true}},
 FR_ROUTE_6={{x0=10,x1=15,y0=1,y1=5,ground=1,wallRows=3,renderOnly=true,routeGate=true}},
 FR_ROUTE_7={{x0=16,x1=21,y0=8,y1=11,ground=1,wallRows=2,renderOnly=true,routeGate=true}},
 FR_ROUTE_8={{x0=1,x1=6,y0=8,y1=11,ground=1,wallRows=2,renderOnly=true,routeGate=true}},
 FR_ROUTE_11={{x0=59,x1=64,y0=8,y1=11,ground=1,wallRows=2,renderOnly=true,routeGate=true}},
 -- The pier gate's primary window course (1B5–1B7) splits the automatic
 -- architecture flood. Include the whole native elevation, keeping both
 -- north warps on the pier outside its roof footprint.
 FR_ROUTE_12={{x0=12,x1=16,y0=17,y1=21,ground=0x12b,wallRows=3,
  doorX=14,doorY=21,pierGate=true},
  {x0=11,x1=15,y0=85,y1=86,doorX=12,doorY=86,ground=1,wallRows=1.375}},
 FR_ROUTE_15={{x0=10,x1=15,y0=9,y1=12,ground=1,wallRows=2,renderOnly=true,routeGate=true}},
 FR_ROUTE_16={{x0=9,x1=13,y0=4,y1=5,doorX=10,doorY=5,ground=1,wallRows=1.375},
  {x0=21,x1=26,y0=4,y1=14,ground=1,wallRows=3,renderOnly=true,routeGate=true,gatePaneTop=147}},
 FR_ROUTE_18={{x0=42,x1=47,y0=7,y1=10,ground=1,wallRows=2,renderOnly=true,routeGate=true}},
 FR_THREE_ISLAND={
  {x0=3,x1=7,y0=4,y1=6,doorX=4,doorY=6,ground=1,wallRows=1.375},
  {x0=11,x1=15,y0=4,y1=6,doorX=12,doorY=6,ground=1,wallRows=1.375},
 },
 FR_SAFARI_ZONE_WEST={{x0=10,x1=15,y0=3,y1=7,doorX=12,doorY=7,ground=1,wallRows=2}},
 -- Three adjoining decorative houses west of the Celadon row houses.
 -- Collision components are L-shaped and fail the rectangular density test.
 -- Native source coordinates keep each roof separate, including trim row.
 FR_CELADON_CITY={
  -- Game Corner and prize room share touching wall tiles but have different
  -- roof lengths and native door rows. Keep their measured volumes separate.
  {x0=31,x1=37,y0=17,y1=21,doorX=34,doorY=21,ground=1,wallRows=1.625,celadonGameCorner=true},
  {x0=38,x1=40,y0=17,y1=20,doorX=39,doorY=20,ground=1,wallRows=1.625,celadonGameCorner=true},
  -- Mansion and lower neighbours touch in native collision data. Each has
  -- its own eave; folding their union raises the paving and tree strip too.
  {x0=27,x1=33,y0=4,y1=11,doorX=30,doorY=11,ground=1,wallRows=4.375,celadonHighRise=true},
  {x0=34,x1=37,y0=8,y1=11,ground=1,wallRows=2.375,renderOnly=true,celadonHighRise=true},
  {x0=38,x1=41,y0=8,y1=11,ground=1,wallRows=2.375,renderOnly=true,celadonHighRise=true},
  {x0=42,x1=45,y0=8,y1=11,ground=1,wallRows=2.375,renderOnly=true,celadonHighRise=true},
  {x0=4,x1=8,y0=5,y1=11,ground=1,wallRows=4.375,renderOnly=true,celadonHighRise=true},
  {x0=18,x1=24,y0=5,y1=11,ground=1,wallRows=4.375,renderOnly=true,celadonHighRise=true},
  {x0=16,x1=19,y0=26,y1=29,ground=1,wallRows=2,renderOnly=true},
  {x0=20,x1=23,y0=27,y1=29,ground=1,wallRows=1,renderOnly=true},
  {x0=20,x1=23,y0=31,y1=34,ground=1,wallRows=3.375,renderOnly=true,celadonHighRise=true},
 },
 -- Native Saffron connection view (48x40), distinct from the walk-in city.
 -- Every source rectangle matches an existing city facade tile-for-tile.
 FR_SAFFRON_CITY_CONNECTION={
  {x0=27,x1=32,y0=2,y1=5,ground=0x2e9,wallRows=2,renderOnly=true},
  {x0=40,x1=43,y0=1,y1=4,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=33,x1=39,y0=2,y1=5,ground=0x2e9,wallRows=2,renderOnly=true},
  {x0=7,x1=18,y0=4,y1=7,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=19,x1=27,y0=10,y1=23,ground=0x2e9,wallRows=10,renderOnly=true,saffronSilph=true},
  {x0=8,x1=11,y0=11,y1=14,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=12,x1=15,y0=12,y1=14,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=16,x1=18,y0=11,y1=14,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=32,x1=35,y0=12,y1=14,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=36,x1=39,y0=11,y1=14,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=28,x1=31,y0=12,y1=14,ground=0x2e9,wallRows=2,renderOnly=true},
  {x0=9,x1=13,y0=19,y1=23,ground=0x2e9,wallRows=3.25,renderOnly=true,saffronHighRise=true,lightScaleKey='saffronHighRiseLightScale'},
  {x0=14,x1=18,y0=19,y1=23,ground=0x2e9,wallRows=3.25,renderOnly=true,saffronHighRise=true,lightScaleKey='saffronHighRiseLightScale'},
  {x0=28,x1=32,y0=19,y1=23,ground=0x2e9,wallRows=3.25,renderOnly=true,saffronHighRise=true,lightScaleKey='saffronHighRiseLightScale'},
  {x0=33,x1=37,y0=19,y1=23,ground=0x2e9,wallRows=3.25,renderOnly=true,saffronHighRise=true,lightScaleKey='saffronHighRiseLightScale'},
  {x0=8,x1=11,y0=28,y1=31,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=12,x1=16,y0=28,y1=31,ground=0x2e9,wallRows=2,renderOnly=true},
  {x0=17,x1=20,y0=29,y1=31,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=21,x1=24,y0=28,y1=31,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=25,x1=28,y0=28,y1=31,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=31,x1=39,y0=28,y1=31,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=9,x1=20,y0=35,y1=37,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=29,x1=40,y0=35,y1=37,ground=0x2e9,wallRows=1.125,renderOnly=true},
 },
 FR_SAFFRON_CITY={
  -- Gate fronts use primary metatiles 1B5..1B7, which the architectural
  -- collision flood does not join to the roof. Include every native course.
  -- y0-1 is the first roof row, never adjacent grass/flowers or fence tiles.
  {x0=32,x1=37,y0=1,y1=5,ground=1,wallRows=3,renderOnly=true,saffronGate=true},
  {x0=32,x1=37,y0=48,y1=52,ground=1,wallRows=3,renderOnly=true,saffronGate=true},
  {x0=2,x1=7,y0=25,y1=28,ground=1,wallRows=2,renderOnly=true,saffronGate=true},
  {x0=59,x1=64,y0=25,y1=28,ground=1,wallRows=2,renderOnly=true,saffronGate=true},
  {x0=29,x1=37,y0=17,y1=30,doorX=33,doorY=30,wallRows=10},
  -- Different-height houses share collision components, not a roof plane.
  {x0=18,x1=21,y0=18,y1=21,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=22,x1=25,y0=19,y1=21,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=26,x1=28,y0=18,y1=21,doorX=27,doorY=21,ground=0x2e9,wallRows=2.125},
  {x0=42,x1=45,y0=19,y1=21,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=46,x1=49,y0=18,y1=21,doorX=47,doorY=21,ground=0x2e9,wallRows=2.125},
  {x0=27,x1=30,y0=36,y1=38,ground=0x2e9,wallRows=1.125,renderOnly=true},
  {x0=31,x1=34,y0=35,y1=38,ground=0x2e9,wallRows=2.125,renderOnly=true},
  {x0=35,x1=38,y0=35,y1=38,ground=0x2e9,wallRows=2.125,renderOnly=true},
  -- The dojo's component previously included the gym's left roof column.
  {x0=37,x1=42,y0=9,y1=12,doorX=40,doorY=12,ground=0x2e9,wallRows=2},
  {x0=43,x1=49,y0=9,y1=12,doorX=46,doorY=12,ground=0x2e9,wallRows=2},
  -- Four native decorative high-rises: source y25..30, eave at pixel44.
  -- The builder includes y0-1. Keep the railings in y31 on the ground;
  -- paved donor2E9 removes the old footprint without inventing any doors.
  -- Nine native panes per facade share a restrained local spill budget.
  {x0=19,x1=23,y0=26,y1=30,ground=0x2e9,wallRows=3.25,renderOnly=true,lightScaleKey='saffronHighRiseLightScale',saffronHighRise=true},
  {x0=24,x1=28,y0=26,y1=30,ground=0x2e9,wallRows=3.25,renderOnly=true,lightScaleKey='saffronHighRiseLightScale',saffronHighRise=true},
  {x0=38,x1=42,y0=26,y1=30,ground=0x2e9,wallRows=3.25,renderOnly=true,lightScaleKey='saffronHighRiseLightScale',saffronHighRise=true},
  {x0=43,x1=47,y0=26,y1=30,ground=0x2e9,wallRows=3.25,renderOnly=true,lightScaleKey='saffronHighRiseLightScale',saffronHighRise=true},
 },
}
