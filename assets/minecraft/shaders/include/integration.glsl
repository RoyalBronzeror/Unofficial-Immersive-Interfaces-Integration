//==========Globals==========

vec2 g_atlasSize;
vec2 g_corner;
vec2 g_texCoord;

//==========Utils==========

bool posInRectX(vec3 position, vec2 screen, float offset, float size) {
    float rectMin = screen.x * 0.5 + offset;
    float rectMax = rectMin + size;
    return position.x >= rectMin && position.x <= rectMax;
}

bool posInRectY(vec3 position, vec2 screen, float offset, float size) {
    float rectMin = screen.y * 0.5 + offset;
    float rectMax = rectMin + size;
    return position.y >= rectMin && position.y <= rectMax;
}

bool posCheckY(vec3 position,vec2 screen, float offset,float size) {
    return ( abs( (round(screen.y/2)+offset+(size*corners[gl_VertexID % 4].y)) - position.y )<= margin );
}

//==========

float sliceX(float texCoordX, float cornerX, float atlasW, float spriteW, float a, float b) {
    float spriteUV = spriteW / atlasW;
    float baseX = texCoordX - cornerX * spriteUV;
    return baseX + (a + cornerX * (b - a)) * spriteUV;
}

float sliceY(float texCoordY, float cornerY, float atlasH, float spriteH, float a, float b) {
    float spriteUV = spriteH / atlasH; // The UV height corresponding to the texture height in the atlas
    float baseY = texCoordY - cornerY * spriteUV; // Derive the top UV of the texture in the atlas
    return baseY + (a + cornerY * (b - a)) * spriteUV; // Map to the corresponding row
}

vec2 sliceUV(vec2 texCoord, vec2 corner, vec2 atlasSize, vec2 spriteSize, vec2 a, vec2 b) {
    return vec2(
        sliceX(texCoord.x, corner.x, atlasSize.x, spriteSize.x, a.x, b.x),
        sliceY(texCoord.y, corner.y, atlasSize.y, spriteSize.y, a.y, b.y)
    );
}

//==========

void remap(inout vec2 texCoord, vec4 pointer) { // Only for versions prior to 1.21.2
    
    vec2 uvMin = pointer.xy / g_atlasSize;
    vec2 uvMax = pointer.zw / g_atlasSize;
    texCoord = mix(uvMin, uvMax, g_corner);
    
}

//==========

bool colorMatches(int colorCode, int target, float texelInset, sampler2D Sampler) {

    vec2 pixelSize = 1.0 / g_atlasSize;
    vec2 inwardOffset = pixelSize * (1.0 - 2.0 * g_corner) * (0.5 + texelInset);
    ivec4 color = ivec4(round(texture(Sampler, g_texCoord + inwardOffset) * 255.0));
    return color[colorCode] == target;

}

//==========Main==========

Data integration(mat4 ProjMat, float GameTime, sampler2D Sampler0, vec3 Position, vec2 texCoord0) {
    
    vec3 pos = Position;
    vec2 texCoord = texCoord0;
    g_texCoord = texCoord0;
    
    int vertID = gl_VertexID % 4;
    vec2 corner = corners[vertID];
    g_corner = corner;
    
    vec2 atlasSize = textureSize(Sampler0, 0);
    g_atlasSize = atlasSize;
    
    
    ivec2 bottomRight = ivec2(g_atlasSize) - ivec2(1, 1);
    ivec4 cornerPixel = ivec4(round(texelFetch(Sampler0, bottomRight, 0) * 255.0));
    // Handles texCoord scaling for older versions of the entire GUI texture
    
    if (cornerPixel == ivec4(255, 0, 0, 255)) g_texCoord = g_texCoord * 0.6;
    
    
    vec2 pixelSize = 1.0 / atlasSize; // One Pixel Size
    vec2 offsetBias = pixelSize * 0.5 * corner;
    vec4 color = round(texture(Sampler0, texCoord - offsetBias) * 255.0);
    
    vec2 inwardOffset = pixelSize * (1.0 - 2.0 * corner) * 1.5; 
    ivec4 cmdColor = ivec4(round(texture(Sampler0, texCoord + inwardOffset) * 255.0));
    
    
    
    vec2 screen = 2 / vec2(ProjMat[0][0], -ProjMat[1][1]);
    
    vec2 signs = (corner - 0.5) * 2;
        
    if (color.a == 1) { // Panels
    
        if (color.r == 255) { // Nomal Large
        
            pos.xy += (signs * vec2(176, 166));
                    
        }
        
        if (color.r == 254) { // Enchanting Infuser Size
        
            pos.xy += (signs * vec2(220, 185));
                    
        }
    
    }
    
    if (cmdColor.a == 1 && !(color.a == 1 && color.r == 254)) { // Old Version Atlas Sprites Pointing
    
        if (cmdColor.r == 254) { // Enchanting Infuser 1.21.2
        
            switch (cmdColor.g) {
            
                case 0: // Infuser Button
                    
                    if (cmdColor.b == 0) remap(g_texCoord, vec4(0.0, 753.0, 160.0, 879.0));
                    if (cmdColor.b == 1) remap(g_texCoord, vec4(160.0, 753.0, 320.0, 879.0));
                    if (cmdColor.b == 2) remap(g_texCoord, vec4(320.0, 753.0, 480.0, 879.0));
                    
                    break;
                case 1: // Infuser Scroller
                    
                    pos.xy -= (signs * vec2(3.0, 1.5)); // 18*18 --> 12*15
                    if (cmdColor.b == 0) remap(g_texCoord, vec4(660.0, 270.0, 700.0, 370.0));
                    if (cmdColor.b == 1) remap(g_texCoord, vec4(700.0, 270.0, 988.0, 760.0));
                    
                    break;
                case 2: // Infuser Add/Remove Button
                    
                    if (cmdColor.b == 0) remap(g_texCoord, vec4(0.0, 717.0, 36.0, 753.0));
                    if (cmdColor.b == 1) remap(g_texCoord, vec4(36.0, 717.0, 72.0, 753.0));
                    if (cmdColor.b == 2) remap(g_texCoord, vec4(72.0, 717.0, 108.0, 753.0));
                    if (cmdColor.b == 3) remap(g_texCoord, vec4(108.0, 717.0, 144.0, 753.0));
                    if (cmdColor.b == 4) remap(g_texCoord, vec4(144.0, 717.0, 180.0, 753.0));
                    if (cmdColor.b == 5) remap(g_texCoord, vec4(180.0, 717.0, 216.0, 753.0));

                    break;
                case 4: // Enchant Button
                    
                    if (cmdColor.b == 0) remap(g_texCoord, vec4(0.0, 879.0, 316.0, 1037.0));
                    if (cmdColor.b == 1) remap(g_texCoord, vec4(316.0, 879.0, 632.0, 1037.0));
                    if (cmdColor.b == 2) remap(g_texCoord, vec4(0.0, 1037.0, 316.0, 1159.0));
                    
                    break;
                case 5: // Repair Button
                    
                    if (cmdColor.b == 0) remap(g_texCoord, vec4(216.0, 717.0, 242.0, 743.0));
                    if (cmdColor.b == 1) remap(g_texCoord, vec4(216.0, 717.0, 242.0, 743.0));
                    if (cmdColor.b == 2) remap(g_texCoord, vec4(242.0, 717.0, 268.0, 743.0));
                    
                    break;
            }
        
        }
    
    }
    
    if (colorMatches(3, 2, 0.0, Sampler0)) { // Sprites
    
        if (colorMatches(0, 254, 0.0, Sampler0)) { // Enchanting Infuser
        
            if (colorMatches(1, 0, 0.0, Sampler0)) { // Infuser Button
    
                // Align all four vertices to the top of the row (relative to screen center)
                float rowTopY = Position.y - corner.y * 18.0 - screen.y * 0.5;
            
                float rowIndex = 0.0;
                if      (rowTopY >= -84.0 && rowTopY < -67.0) rowIndex = 0.0;
                else if (rowTopY >= -67.0 && rowTopY < -58.0) rowIndex = 1.0;
                else if (rowTopY >= -58.0 && rowTopY < -49.0) rowIndex = 2.0;
                else if (rowTopY >= -49.0 && rowTopY < -40.0) rowIndex = 3.0;
                else if (rowTopY >= -40.0 && rowTopY < -31.0) rowIndex = 4.0;
                else if (rowTopY >= -31.0 && rowTopY < -22.0) rowIndex = 5.0;
                else if (rowTopY >= -22.0)                       rowIndex = 6.0;
    
                g_texCoord.y = sliceY(g_texCoord.y, corner.y, atlasSize.y, 126.0, rowIndex / 7.0, (rowIndex + 1.0) / 7.0);
            
            }
            
            if (colorMatches(1, 1, 0.0, Sampler0)) { // Infuser Scroller
                
                //=====Infuser Scroller=====
                
                if (posCheckX(Position, screen, 88, 12)) {
                
                    if (colorMatches(2, 255, 0.0, Sampler0)) { // Disabled
                    
                        pos.xy += signs * vec2(14, 35);
                        g_texCoord = sliceUV(g_texCoord, corner, atlasSize, vec2(40.0, 100.0), vec2(0.0, 15.0 / 100.0), vec2(1.0));
                    
                    }
                    
                    else if (colorMatches(2, 254, 0.0, Sampler0)) { // Enabled
                    
                        pos.xy += signs * vec2(12, 27.5);
                        
                        float topY = Position.y - corner.y * 15.0 - screen.y * 0.5;
                        
                        float index = floor(topY - (-75.0));
                        index = clamp(index, 0.0, 55.0);
                        
                        float cols = mod(index, 8.0);
                        float rows = floor(index / 8.0);
                        
                        float frameColStart = (cols * 36.0) / 288.0;
                        float frameRowStart = (rows * 70.0) / 490.0;
                        float frameColEnd = ((cols + 1.0) * 36.0) / 288.0;
                        float frameRowEnd = ((rows + 1.0) * 70.0) / 490.0;
                        
                        if (index == 0.0) {
                        
                            g_texCoord = sliceUV(g_texCoord, corner, atlasSize, vec2(288.0, 490.0), vec2(0.0), vec2(26.0 / 288.0, 50.0 / 490.0));
                            pos.xy -= signs * vec2(5, 10);
                            pos.x -= 5.0;
                            pos.y -= 10.0;
                        
                        }
                        else g_texCoord = sliceUV(g_texCoord, corner, atlasSize, vec2(288.0, 490.0), vec2(frameColStart, frameRowStart), vec2(frameColEnd, frameRowEnd));
                        
                        pos.y += 27.5 - index;
                        
                    }
                
                }
                
                //=====Vanilla Scroller=====
                
                // Disabled
                else if (colorMatches(2, 255, 0.0, Sampler0)) g_texCoord = sliceUV(g_texCoord, corner, atlasSize, vec2(40.0, 100.0), vec2(14.0 / 40.0, 0.0), vec2(26.0 / 40.0, 15.0 / 100.0));
                
                // Enabled
                else if (colorMatches(2, 254, 0.0, Sampler0)) g_texCoord = sliceUV(g_texCoord, corner, atlasSize, vec2(288.0, 490.0), vec2(24.0 / 288.0, 55.0 / 490.0), vec2(36.0 / 288.0, 70.0 / 490.0));
               
            
            }
            
            if (colorMatches(1, 2, 0.0, Sampler0)) { // Infuser Add/Remove Button
                
                float rowTopY = Position.y - corner.y * 18.0 - screen.y * 0.5;
                if (rowTopY >= -31.0) g_texCoord.x = sliceX(g_texCoord.x, corner.x, atlasSize.x, 36.0, 0.5, 1.0);
                else g_texCoord.x = sliceX(g_texCoord.x, corner.x, atlasSize.x, 36.0, 0.0, 0.5);
                
                // ==========
                
                if (posCheckX(Position, screen, 62, 18) || posCheckX(Position, screen, -80, 18)) { // Without shift
                
                    g_texCoord.y = sliceY(g_texCoord.y, corner.y, atlasSize.y, 36.0, 0.5, 1.0);
                
                }
                
                else if (posCheckX(Position, screen, 59, 18)) {  // With shift Right Button
                
                    g_texCoord.y = sliceY(g_texCoord.y, corner.y, atlasSize.y, 36.0, 0.0, 0.5);
                    pos.x += 3.0;
                
                }
                
                else if (posCheckX(Position, screen, -77, 18)) {  // With shift Left Button
                
                    g_texCoord.y = sliceY(g_texCoord.y, corner.y, atlasSize.y, 36.0, 0.0, 0.5);
                    pos.x -= 3.0;
                
                }
                
                else return null;
            
            }
            
            if (colorMatches(1, 4, 0.0, Sampler0)) { // Enchant Button
            
                // The Advanced
                if (posCheckY(Position, screen, -49, 18)) g_texCoord.x = sliceX(g_texCoord.x, corner.x, atlasSize.x, 316.0, 0.5, 1.0);
                
                // The Basic
                if (posCheckY(Position, screen, -38, 18)) g_texCoord.x = sliceX(g_texCoord.x, corner.x, atlasSize.x, 316.0, 0.0, 0.5);
                
                pos.xy += signs * vec2(70);
            
            }
            
            if (colorMatches(1, 5, 0.0, Sampler0)) pos.xy += signs * vec2(4); // Repair Button
        
        }
    
    }
    
    return Data(pos,g_texCoord,vec4(0));
}