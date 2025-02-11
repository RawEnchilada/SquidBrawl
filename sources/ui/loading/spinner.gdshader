shader_type canvas_item;
render_mode unshaded;

uniform float speed = 1.0; // Speed of the spinning (radians per second)

void fragment() {
    // Get the UV coordinates centered around (0.5, 0.5)
    vec2 uv = UV;
    uv -= vec2(0.5);

    // Calculate the rotation angle based on time and speed
    float angle = TIME * speed;

    // Create the rotation matrix
    mat2 rotation = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));

    // Apply the rotation to the UV coordinates
    vec2 rotated_uv = rotation * uv;

    // Recenter the UV coordinates
    rotated_uv += vec2(0.5);

    // Sample the texture using the rotated UV coordinates
    COLOR = texture(TEXTURE, rotated_uv);
}
