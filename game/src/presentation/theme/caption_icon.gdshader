shader_type canvas_item;

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    COLOR = vec4(vec3(1.0), source.a) * COLOR;
}
