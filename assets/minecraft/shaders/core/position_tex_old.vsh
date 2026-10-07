#version 150

#moj_import <interfaces.glsl>
#moj_import <integration.glsl>
in vec3 Position;
in vec2 UV0;
in vec4 Color;

uniform sampler2D Sampler0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec2 ScreenSize;
uniform float GameTime;


out vec2 texCoord0;

void main() {

    Data data = interfaces(ProjMat, GameTime, Sampler0, Position, UV0);
    Data neodata = integration(ProjMat, GameTime, Sampler0, data.position, data.uv0);
    texCoord0 = neodata.uv0;    
    gl_Position = ProjMat * ModelViewMat * vec4(neodata.position, 1.0);
}