#include "globals.h"

struct Appdata
{
    float4 Position	    : POSITION;
    float2 Uv	        : TEXCOORD0;
    float4 Color        : COLOR0;
};

struct VertexOutput
{
    float4 HPosition    : POSITION;
    float PSize         : PSIZE;

    float2 Uv           : TEXCOORD0;
    float4 Color        : COLOR0;
};

uniform float4x4 WorldMatrix;

uniform float4 Color;
uniform float4 Color2;

VertexOutput SkyVS(Appdata IN)
{
    VertexOutput OUT = (VertexOutput)0;

    float4 wpos = mul(WorldMatrix, IN.Position);

    OUT.HPosition = mul(G.ViewProjection, wpos);

    // snap to far plane to prevent scene-sky intersections
    // small offset is needed to prevent 0/0 division in case w=0, which causes rasterization issues
    OUT.HPosition.z = OUT.HPosition.w - 1.f / 16;

    OUT.PSize = 2.0; // star size

    OUT.Uv = IN.Uv;
    OUT.Color = IN.Color * lerp(Color2,Color,wpos.y/1700);
    //OUT.Color = IN.Color * Color;

    return OUT;
}

sampler2D DiffuseMap: register(s0);

float4 SkyPS(VertexOutput IN): COLOR0
{
    return tex2D(DiffuseMap, IN.Uv) * IN.Color;
}
