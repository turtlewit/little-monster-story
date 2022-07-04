// Copyright (c) 2014-2015, NVIDIA CORPORATION. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//  * Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//notice, this list of conditions and the following disclaimer in the
//documentation and/or other materials provided with the distribution.
//  * Neither the name of NVIDIA CORPORATION nor the names of its
//contributors may be used to endorse or promote products derived
//from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
// OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//----------------------------------------------------------------------------------
/*============================================================================


NVIDIA FXAA 3.11 by TIMOTHY LOTTES

------------------------------------------------------------------------------*/
// preset 12
shader_type canvas_item;

const int FXAA_GREEN_AS_LUMA = 1;
const int FXAA_DISCARD = 0;
const int FXAA_FAST_PIXEL_OFFSET = 0;

const int FXAA_QUALITY__PS = 5;
const float FXAA_QUALITY__P0 = 1.0;
const float FXAA_QUALITY__P1 = 1.5;
const float FXAA_QUALITY__P2 = 2.0;
const float FXAA_QUALITY__P3 = 4.0;
const float FXAA_QUALITY__P4 = 12.0;

float FxaaLuma(vec4 rgba) 
{
	return rgba.y;
}

float FxaaSat(float x)
{
	return clamp(x, 0.0, 1.0);
}

vec4 sampler2DOff(sampler2D t, vec2 p, vec2 o, vec2 r)
{
	return textureLod(t, p + (o * r), 0.0);
}

vec4 sampler2DTop(sampler2D t, vec2 o)
{
	return textureLod(t, o, 0.0);
}

bool FxaaPixelShader(
	vec2 pos,
	sampler2D tex,
	vec2 fxaaQualityRcpFrame,
	float fxaaQualitySubpix,
	float fxaaQualityEdgeThreshold,
	float fxaaQualityEdgeThresholdMin,
	out vec4 output
)
{
	vec2 posM;
	posM.x = pos.x;
	posM.y = pos.y;


	vec4 rgbyM = textureLod(tex, posM, 0.0);
	float lumaM = rgbyM.y;
	float lumaS = FxaaLuma(sampler2DOff(tex, posM, vec2( 0, 1), fxaaQualityRcpFrame.xy));
	float lumaE = FxaaLuma(sampler2DOff(tex, posM, vec2( 1, 0), fxaaQualityRcpFrame.xy));
	float lumaN = FxaaLuma(sampler2DOff(tex, posM, vec2( 0,-1), fxaaQualityRcpFrame.xy));
	float lumaW = FxaaLuma(sampler2DOff(tex, posM, vec2(-1, 0), fxaaQualityRcpFrame.xy));

/*--------------------------------------------------------------------------*/
	float maxSM = max(lumaS, lumaM);
	float minSM = min(lumaS, lumaM);
	float maxESM = max(lumaE, maxSM);
	float minESM = min(lumaE, minSM);
	float maxWN = max(lumaN, lumaW);
	float minWN = min(lumaN, lumaW);
	float rangeMax = max(maxWN, maxESM);
	float rangeMin = min(minWN, minESM);
	float rangeMaxScaled = rangeMax * fxaaQualityEdgeThreshold;
	float range = rangeMax - rangeMin;
	float rangeMaxClamped = max(fxaaQualityEdgeThresholdMin, rangeMaxScaled);
	bool earlyExit = range < rangeMaxClamped;
/*--------------------------------------------------------------------------*/
	if(earlyExit) {
		output = rgbyM;
		return false;
	}

/*--------------------------------------------------------------------------*/

	float lumaNW = FxaaLuma(sampler2DOff(tex, posM, vec2(-1,-1), fxaaQualityRcpFrame.xy));
	float lumaSE = FxaaLuma(sampler2DOff(tex, posM, vec2( 1, 1), fxaaQualityRcpFrame.xy));
	float lumaNE = FxaaLuma(sampler2DOff(tex, posM, vec2( 1,-1), fxaaQualityRcpFrame.xy));
	float lumaSW = FxaaLuma(sampler2DOff(tex, posM, vec2(-1, 1), fxaaQualityRcpFrame.xy));

/*--------------------------------------------------------------------------*/
	float lumaNS = lumaN + lumaS;
	float lumaWE = lumaW + lumaE;
	float subpixRcpRange = 1.0/range;
	float subpixNSWE = lumaNS + lumaWE;
	float edgeHorz1 = (-2.0 * lumaM) + lumaNS;
	float edgeVert1 = (-2.0 * lumaM) + lumaWE;
/*--------------------------------------------------------------------------*/
	float lumaNESE = lumaNE + lumaSE;
	float lumaNWNE = lumaNW + lumaNE;
	float edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
	float edgeVert2 = (-2.0 * lumaN) + lumaNWNE;
/*--------------------------------------------------------------------------*/
	float lumaNWSW = lumaNW + lumaSW;
	float lumaSWSE = lumaSW + lumaSE;
	float edgeHorz4 = (abs(edgeHorz1) * 2.0) + abs(edgeHorz2);
	float edgeVert4 = (abs(edgeVert1) * 2.0) + abs(edgeVert2);
	float edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
	float edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
	float edgeHorz = abs(edgeHorz3) + edgeHorz4;
	float edgeVert = abs(edgeVert3) + edgeVert4;
/*--------------------------------------------------------------------------*/
	float subpixNWSWNESE = lumaNWSW + lumaNESE;
	float lengthSign = fxaaQualityRcpFrame.x;
	bool horzSpan = edgeHorz >= edgeVert;
	float subpixA = subpixNSWE * 2.0 + subpixNWSWNESE;
/*--------------------------------------------------------------------------*/
	if(!horzSpan) lumaN = lumaW;
	if(!horzSpan) lumaS = lumaE;
	if(horzSpan) lengthSign = fxaaQualityRcpFrame.y;
	float subpixB = (subpixA * (1.0/12.0)) - lumaM;
/*--------------------------------------------------------------------------*/
	float gradientN = lumaN - lumaM;
	float gradientS = lumaS - lumaM;
	float lumaNN = lumaN + lumaM;
	float lumaSS = lumaS + lumaM;
	bool pairN = abs(gradientN) >= abs(gradientS);
	float gradient = max(abs(gradientN), abs(gradientS));
	if(pairN) lengthSign = -lengthSign;
	float subpixC = FxaaSat(abs(subpixB) * subpixRcpRange);
/*--------------------------------------------------------------------------*/
	vec2 posB;
	posB.x = posM.x;
	posB.y = posM.y;
	vec2 offNP;
	offNP.x = (!horzSpan) ? 0.0 : fxaaQualityRcpFrame.x;
	offNP.y = ( horzSpan) ? 0.0 : fxaaQualityRcpFrame.y;
	if(!horzSpan) posB.x += lengthSign * 0.5;
	if( horzSpan) posB.y += lengthSign * 0.5;
/*--------------------------------------------------------------------------*/
	vec2 posN;
	posN.x = posB.x - offNP.x * FXAA_QUALITY__P0;
	posN.y = posB.y - offNP.y * FXAA_QUALITY__P0;
	vec2 posP;
	posP.x = posB.x + offNP.x * FXAA_QUALITY__P0;
	posP.y = posB.y + offNP.y * FXAA_QUALITY__P0;
	float subpixD = ((-2.0)*subpixC) + 3.0;
	float lumaEndN = FxaaLuma(textureLod(tex, posN, 0.0));
	float subpixE = subpixC * subpixC;
	float lumaEndP = FxaaLuma(textureLod(tex, posP, 0.0));
/*--------------------------------------------------------------------------*/
	if(!pairN) lumaNN = lumaSS;
	float gradientScaled = gradient * 1.0/4.0;
	float lumaMM = lumaM - lumaNN * 0.5;
	float subpixF = subpixD * subpixE;
	bool lumaMLTZero = lumaMM < 0.0;
/*--------------------------------------------------------------------------*/
	lumaEndN -= lumaNN * 0.5;
	lumaEndP -= lumaNN * 0.5;
	bool doneN = abs(lumaEndN) >= gradientScaled;
	bool doneP = abs(lumaEndP) >= gradientScaled;
	if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P1;
	if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P1;
	bool doneNP = (!doneN) || (!doneP);
	if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P1;
	if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P1;
/*--------------------------------------------------------------------------*/
	if(doneNP) {
	if(!doneN) lumaEndN = FxaaLuma(sampler2DTop(tex, posN.xy));
	if(!doneP) lumaEndP = FxaaLuma(sampler2DTop(tex, posP.xy));
	if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
	if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
	doneN = abs(lumaEndN) >= gradientScaled;
	doneP = abs(lumaEndP) >= gradientScaled;
	if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P2;
	if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P2;
	doneNP = (!doneN) || (!doneP);
	if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P2;
	if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P2;
/*--------------------------------------------------------------------------*/
	if(doneNP) {
	if(!doneN) lumaEndN = FxaaLuma(sampler2DTop(tex, posN.xy));
	if(!doneP) lumaEndP = FxaaLuma(sampler2DTop(tex, posP.xy));
	if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
	if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
	doneN = abs(lumaEndN) >= gradientScaled;
	doneP = abs(lumaEndP) >= gradientScaled;
	if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P3;
	if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P3;
	doneNP = (!doneN) || (!doneP);
	if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P3;
	if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P3;
/*--------------------------------------------------------------------------*/
	if(doneNP) {
	if(!doneN) lumaEndN = FxaaLuma(sampler2DTop(tex, posN.xy));
	if(!doneP) lumaEndP = FxaaLuma(sampler2DTop(tex, posP.xy));
	if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
	if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
	doneN = abs(lumaEndN) >= gradientScaled;
	doneP = abs(lumaEndP) >= gradientScaled;
	if(!doneN) posN.x -= offNP.x * FXAA_QUALITY__P4;
	if(!doneN) posN.y -= offNP.y * FXAA_QUALITY__P4;
	doneNP = (!doneN) || (!doneP);
	if(!doneP) posP.x += offNP.x * FXAA_QUALITY__P4;
	if(!doneP) posP.y += offNP.y * FXAA_QUALITY__P4;
/*--------------------------------------------------------------------------*/
	}}}
/*--------------------------------------------------------------------------*/
	float dstN = posM.x - posN.x;
	float dstP = posP.x - posM.x;
	if(!horzSpan) dstN = posM.y - posN.y;
	if(!horzSpan) dstP = posP.y - posM.y;
/*--------------------------------------------------------------------------*/
	bool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
	float spanLength = (dstP + dstN);
	bool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
	float spanLengthRcp = 1.0/spanLength;
/*--------------------------------------------------------------------------*/
	bool directionN = dstN < dstP;
	float dst = min(dstN, dstP);
	bool goodSpan = directionN ? goodSpanN : goodSpanP;
	float subpixG = subpixF * subpixF;
	float pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
	float subpixH = subpixG * fxaaQualitySubpix;
/*--------------------------------------------------------------------------*/
	float pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
	float pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
	if(!horzSpan) posM.x += pixelOffsetSubpix * lengthSign;
	if( horzSpan) posM.y += pixelOffsetSubpix * lengthSign;
	
	if (FXAA_DISCARD == 1) {
		output = sampler2DTop(tex, posM);
		return false;
	} else {
		output = vec4(sampler2DTop(tex, posM).xyz, lumaM);
		return false;
	}
}

void fragment() {
	vec4 result;
	FxaaPixelShader(SCREEN_UV, SCREEN_TEXTURE, SCREEN_PIXEL_SIZE, 0.75, 0.166, 0.0833, result);
	result.w = 1.;
	COLOR = result;
}