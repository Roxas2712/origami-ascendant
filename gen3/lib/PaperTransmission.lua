-- Thin paper catches backlight; opaque walls and character cards do not.
local V=...
local P={settings={0,3},tint={1,1,1}}
P.uniforms=[[
uniform vec2 paperTransmission;
uniform vec3 transmissionTint;
]]
P.functions=[[
vec3 paperBacklight(vec3 albedo,vec3 normal,vec3 viewDir,vec3 sunDir,
 float thin,float irradiance,float direct,float visibility){
 // Camera elevation is a presentation choice. Backlit upright paper should
 // keep catching the same sun bearing when the view tilts toward the ground.
 float bearings=length(viewDir.xz)*length(sunDir.xz);
 float back=max(0.0,bearings>.0001?dot(-viewDir.xz,sunDir.xz)/bearings:dot(-viewDir,sunDir));
 float grazing=1.0-abs(dot(normal,viewDir));
 float transmit=pow(back,paperTransmission.y)*thin*irradiance*direct*visibility;
 return albedo*albedo*transmissionTint*transmit*paperTransmission.x*(.6+.4*grazing);
}
]]
P.fragment=[[
  if(paperTransmission.x>0.0 && daylightDirect>0.0 && caveMode<.5){
    float thin=max(max(plantFace,grassFace),max(stationaryFoliage,cutTreeFoliage));
    // Use the actual pane mask, never the whole facade/skylight frame.
    if(max(glassFace,roofPaneFace)>.5 && windowEligible>.5)
      thin=max(thin,Texel(glassMask,uv).r*mix(.35,.6,roofPaneFace));
    // Cut-tree props share the actor material range; they are foliage, not
    // trainers/Pokemon. All real character cards remain strictly excluded.
    thin*=1.0-actorFace*(1.0-cutTreeFoliage);
    thin*=1.0-snowCover*.85;
    if(thin>0.0){
      lit+=paperBacklight(pixel.rgb,normal,normalize(cameraEye-worldPosition),normalize(sunDirection),
        thin,sunStrength,daylightDirect,(1.0-shadow*shadowStrength)*cloudDirectTransmission);
    }
  }
]]
function P.prepare(atmosphere,outdoors)
 local c=V.require('DioramaConfig').lighting.transmission
 local solar=atmosphere.solar
 P.settings[1]=c.enabled and outdoors and c.strength*(solar and solar.transmission or 1)or 0
 P.settings[2]=math.max(.1,c.power)
 local color=solar and solar.sunColor
 P.tint[1]=(color and color[1]or 1)*1.05
 P.tint[2]=color and color[2]or 1
 P.tint[3]=(color and color[3]or 1)*.9
end
function P.bind(shader)
 local U=V.require('UniformState')
 U.send(shader,'paperTransmission',P.settings);U.send(shader,'transmissionTint',P.tint)
end
return P
