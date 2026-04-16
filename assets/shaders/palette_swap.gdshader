// palette_swap.gdshader —— 调色盘替换 Shader：灰度 Sprite × target_color 正片叠底，用于 SHADOW/CHASSIS/BODY 三层
shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// 灰度图的 R 通道作为明度值
	float gray = tex.r;
	// 正片叠底：灰度值 × 目标颜色，保留原纹理 alpha
	COLOR = vec4(target_color.rgb * gray, tex.a);
}
