// A ring that runs out from a blast through what is behind the game —the
// desktop, its windows— and bends it as it goes, splitting its colours at the
// crest, with a rim of light. `a.x` is how far it has gone (0 to 1), `a.y` how
// hard it pushes (negative pulls in: something going elsewhere), `a.z` how
// much its rim shines, in `color`.
fn shade(s: Shader) -> vec4<f32> {
    let c = s.size * 0.5;
    let d = s.pos - c;
    let r = length(d);
    let age = clamp(s.a.x, 0.0, 1.0);
    let reach = min(c.x, c.y);
    // Fast at first, slowing as it spreads; a pull runs inwards instead.
    var grown = 1.0 - pow(1.0 - age, 3.0);
    if (s.a.y < 0.0) { grown = 1.0 - grown; }
    let crest = reach * (0.08 + 0.88 * grown);
    let width = reach * 0.1 + 5.0;
    let band = exp(-pow((r - crest) / width, 2.0));
    let fade = (1.0 - age) * (1.0 - age);
    let strength = s.a.y * fade;
    if (band * abs(strength) < 0.3 || r > reach) {
        return vec4<f32>(0.0);
    }
    let dir = d / max(r, 1.0);
    let push = dir * band * strength;
    let red = behind(s, s.pos - push * 1.25);
    let green = behind(s, s.pos - push);
    let blue = behind(s, s.pos - push * 0.75);
    let known = min(red.a, min(green.a, blue.a));
    var col = vec3<f32>(red.r, green.g, blue.b);
    col = col + s.color.rgb * band * fade * s.a.z;
    return vec4<f32>(col, 0.88 * smoothstep(0.03, 0.25, band) * known);
}
