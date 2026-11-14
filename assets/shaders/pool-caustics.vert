#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float phase;
    float strength;
    vec2 itemSize;
    vec2 designOrigin;
    float designScale;
    float designRotation;
    float cornerRadius;
} ubuf;

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = ubuf.qt_Matrix * qt_Vertex;
}
