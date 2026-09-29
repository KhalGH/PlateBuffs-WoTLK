import math

#====================================================#
#==================== PARAMETERS ====================#
#====================================================#

#============ Spritesheet ============# 
GRID_SIZE = 16
CELL_SIZE = 64
WIDTH = GRID_SIZE * CELL_SIZE
HEIGHT = GRID_SIZE * CELL_SIZE
TOTAL_FRAMES = GRID_SIZE * GRID_SIZE

#=============== Swipe ===============# 
SWIPE_ALPHA = 191
SUPERSAMPLE = 4

#=============== Edge ===============#
EDGE_ALPHA = 191
EDGE_WIDTH = 0.07
EDGE_CORE = 0.003
EDGE_FADE_POWER = 1.6
EDGE_COLORS = [
    (255, 225,   5),
    (255, 225,   5),
    (255, 225,   5),
    (230, 205,   5),
    (195, 170,   5),
    (150, 130,   5),
    ( 95,  82,   5),
    ( 35,  32,   3),
]
EDGE_RADIAL_ALPHA = [
    0.14,
    0.22,
    0.35,
    0.49,
    0.65,
    0.79,
    0.92,
    1.00,
]

#===================================================#
#====================== SWIPE ======================#
#===================================================#

def pixel_progress(sub_x, sub_y):
    dx = sub_x - CELL_SIZE / 2.0
    dy = sub_y - CELL_SIZE / 2.0
    ang = math.atan2(dx, -dy)
    if ang < 0:
        ang += 2 * math.pi
    return ang / (2 * math.pi)

def alpha_for_pixel(x, y, progress, ss=SUPERSAMPLE):
    covered = 0
    step = 1.0 / ss
    for sy in range(ss):
        for sx in range(ss):
            sub_x = x + (sx + 0.5) * step
            sub_y = y + (sy + 0.5) * step
            if pixel_progress(sub_x, sub_y) > progress:
                covered += 1
    frac = covered / (ss * ss)
    return round(frac * SWIPE_ALPHA)

def generate_tga(filename):
    pixels = bytearray(WIDTH * HEIGHT * 4)
    for frame_idx in range(TOTAL_FRAMES):
        progress = frame_idx / TOTAL_FRAMES
        if frame_idx == 0:
            progress = -0.001
        row = frame_idx // GRID_SIZE
        col = frame_idx % GRID_SIZE
        base_x = col * CELL_SIZE
        base_y = row * CELL_SIZE
        for y in range(CELL_SIZE):
            for x in range(CELL_SIZE):
                a = alpha_for_pixel(x, y, progress)
                idx = ((base_y + y) * WIDTH + (base_x + x)) * 4
                pixels[idx + 0] = 0
                pixels[idx + 1] = 0
                pixels[idx + 2] = 0
                pixels[idx + 3] = a
    with open(filename, 'wb') as f:
        header = bytes([
            0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            WIDTH & 0xFF, WIDTH >> 8,
            HEIGHT & 0xFF, HEIGHT >> 8,
            32, 0x28
        ])
        f.write(header)
        f.write(pixels)
    print(f"Generated: {filename}")

if __name__ == "__main__":
    generate_tga("Swipe.tga")


#======================================================#
#==================== SWIPE + EDGE ====================#
#======================================================#

def angular_distance_edge(a, b):
    d = abs(a - b)
    return min(d, 1.0 - d)

def edge_alpha(progress_value, progress):
    distance = angular_distance_edge(
        progress_value,
        progress
    )
    if distance >= EDGE_WIDTH:
        return 0.0
    if distance <= EDGE_CORE:
        return 1.0
    t = (
        (distance - EDGE_CORE) /
        (EDGE_WIDTH - EDGE_CORE)
    )
    return (1.0 - t) ** EDGE_FADE_POWER

def edge_radial_alpha(sub_x, sub_y):
    center = CELL_SIZE / 2.0
    dx = sub_x - center
    dy = sub_y - center
    radius = math.sqrt(
        dx * dx +
        dy * dy
    )
    outer_radius = CELL_SIZE / 2.0
    radial = radius / outer_radius
    if radial <= 0:
        return EDGE_RADIAL_ALPHA[0]
    if radial >= 1:
        return EDGE_RADIAL_ALPHA[-1]
    position = radial * (len(EDGE_RADIAL_ALPHA) - 1)
    index = int(position)
    if index >= len(EDGE_RADIAL_ALPHA) - 1:
        return EDGE_RADIAL_ALPHA[-1]
    fraction = position - index
    a1 = EDGE_RADIAL_ALPHA[index]
    a2 = EDGE_RADIAL_ALPHA[index + 1]
    return a1 + (a2 - a1) * fraction

def edge_color(edge):
    if edge <= 0:
        return EDGE_COLORS[-1]
    if edge >= 1:
        return EDGE_COLORS[0]
    position = (
        (1.0 - edge) *
        (len(EDGE_COLORS) - 1)
    )
    index = int(position)
    if index >= len(EDGE_COLORS) - 1:
        return EDGE_COLORS[-1]
    fraction = position - index
    r1, g1, b1 = EDGE_COLORS[index]
    r2, g2, b2 = EDGE_COLORS[index + 1]
    r = r1 + (r2 - r1) * fraction
    g = g1 + (g2 - g1) * fraction
    b = b1 + (b2 - b1) * fraction
    return r, g, b

def pixel_rgba(x, y, progress, ss=SUPERSAMPLE):
    step = 1.0 / ss
    total_r = 0.0
    total_g = 0.0
    total_b = 0.0
    total_a = 0.0
    for sy in range(ss):
        for sx in range(ss):
            sub_x = x + (sx + 0.5) * step
            sub_y = y + (sy + 0.5) * step
            current_progress = pixel_progress(
                sub_x,
                sub_y
            )
            if current_progress > progress:
                base_r = 0.0
                base_g = 0.0
                base_b = 0.0
                base_a = float(SWIPE_ALPHA)
            else:
                base_r = 0.0
                base_g = 0.0
                base_b = 0.0
                base_a = 0.0
            angular_alpha = edge_alpha(
                current_progress,
                progress
            )
            if angular_alpha > 0:
                radial_alpha = edge_radial_alpha(
                    sub_x,
                    sub_y
                )
                edge_a = (
                    EDGE_ALPHA *
                    angular_alpha *
                    radial_alpha
                )
                edge_r, edge_g, edge_b = edge_color(
                    angular_alpha
                )
                edge_factor = edge_a / 255.0
                base_factor = 1.0 - edge_factor
                out_r = (
                    base_r * base_factor +
                    edge_r * edge_factor
                )
                out_g = (
                    base_g * base_factor +
                    edge_g * edge_factor
                )
                out_b = (
                    base_b * base_factor +
                    edge_b * edge_factor
                )
                out_a = (
                    base_a +
                    edge_a *
                    (1.0 - base_a / 255.0)
                )
            else:
                out_r = base_r
                out_g = base_g
                out_b = base_b
                out_a = base_a
            total_r += out_r
            total_g += out_g
            total_b += out_b
            total_a += out_a
    samples = ss * ss
    return (
        round(total_r / samples),
        round(total_g / samples),
        round(total_b / samples),
        round(total_a / samples)
    )

def generate_tga_edge(filename):
    pixels = bytearray(
        WIDTH * HEIGHT * 4
    )
    for frame_idx in range(TOTAL_FRAMES):
        progress = frame_idx / TOTAL_FRAMES
        if frame_idx == 0:
            progress = -0.001
        row = frame_idx // GRID_SIZE
        col = frame_idx % GRID_SIZE
        base_x = col * CELL_SIZE
        base_y = row * CELL_SIZE
        for y in range(CELL_SIZE):
            for x in range(CELL_SIZE):
                r, g, b, a = pixel_rgba(x, y, progress)
                idx = ((base_y + y) * WIDTH + (base_x + x)) * 4
                pixels[idx + 0] = b
                pixels[idx + 1] = g
                pixels[idx + 2] = r
                pixels[idx + 3] = a
    with open(filename, 'wb') as f:
        header = bytes([
            0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            WIDTH & 0xFF,
            WIDTH >> 8,
            HEIGHT & 0xFF,
            HEIGHT >> 8,
            32,
            0x28
        ])
        f.write(header)
        f.write(pixels)
    print(f"Generated: {filename}")

if __name__ == "__main__":
    generate_tga_edge("SwipeEdge.tga")