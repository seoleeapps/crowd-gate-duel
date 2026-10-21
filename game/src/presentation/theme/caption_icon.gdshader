shader_type canvas_item;

varying vec4 icon_tint;

void vertex() {
    icon_tint = COLOR;
}

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    COLOR = vec4(vec3(1.0), source.a) * icon_tint;
}
