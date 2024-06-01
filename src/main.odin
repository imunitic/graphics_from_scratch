package main

import "core:fmt"
import "core:math"
import "core:mem"

import rl "vendor:raylib"

// VECTOR
Vector2 :: distinct [2]f32
Vector3 :: distinct [3]f32

Color :: distinct [4]u8

Infinity: f32 = 1_000_000_000.0

vector3_dot :: proc(v1, v2: Vector3) -> f32 {
    return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z)
}

vector3_sub :: proc(v1, v2: Vector3) -> Vector3 {
	return {(v1.x - v2.x), (v1.y - v2.y), (v1.z - v2.z)}
}

// END_VECTOR

// ERROR
Error :: union {
    InvalidCoordinate,
    mem.Allocator_Error,
}

InvalidCoordinate :: struct {}
// END_ERROR

// SCENE, VIEWPORT, FRAME
Viewport :: struct {
    _width:    f32,
    _height:   f32,
    _distance: f32,
}

Sphere :: struct {
    center: Vector3,
    radius: f32,
    color:  Color,
}

viewport_coord :: proc(viewport: Viewport, canvas: $T/Canvas, canvas_coord: Vector2) -> Vector3 {
	viewport_size := viewport._width
	canvas_width := f32(canvas._width)
	canvas_height := f32(canvas._height)
	projection_plane_z := viewport._distance

    vx := canvas_coord.x * viewport_size / canvas_width
    vy := canvas_coord.y * viewport_size / canvas_height
    vz := projection_plane_z

    return Vector3{vx, vy, vz}
}

intersect_ray_sphere :: proc(origin, direction: Vector3, sphere: Sphere) -> Vector2 {
    oc := vector3_sub(origin, sphere.center)

    k1 := vector3_dot(direction, direction)
    k2 := 2 * vector3_dot(oc, direction)
    k3 := vector3_dot(oc, oc) - sphere.radius * sphere.radius

    discriminant := k2 * k2 - 4 * k1 * k3
    if discriminant < 0 {
        return Vector2{Infinity, Infinity}
    }

    t1 := (-k2 + math.sqrt(discriminant)) / (2 * k1)
    t2 := (-k2 - math.sqrt(discriminant)) / (2 * k1)

    return Vector2{t1, t2}
}

trace_ray :: proc(origin, direction: Vector3, min_t, max_t: f32, spheres: []Sphere) -> Color {
    closest_t := Infinity
    closest_sphere: Sphere

    for sphere in spheres {
        ts := intersect_ray_sphere(origin, direction, sphere)

        if ts.x < closest_t && min_t < ts.x && ts.x < max_t {
            closest_t = ts.x
            closest_sphere = sphere
        }

        if ts.y < closest_t && min_t < ts.y && ts.y < max_t {
            closest_t = ts.y
            closest_sphere = sphere
        }
    }

    if closest_sphere == {} {
        return Color{255, 255, 255, 255}
    }

    return closest_sphere.color
}

// END_SCENE

// CANVAS

BytesPerPixel :: 4

Canvas :: struct($W, $H: i32) {
    _width:  f32,
    _height: f32,
    _data:   ^[W * H * BytesPerPixel]u8,
}

init_canvas :: proc($W, $H: i32) -> (canvas: Canvas(W, H), err: Error) {
    data := new([W * H * BytesPerPixel]u8) or_return

    canvas_width := f32(W)
    canvas_height := f32(H)

    canvas = {canvas_width, canvas_height, data}

    return
}

delete_canvas :: proc(canvas: $T/Canvas) {
    free(canvas._data)
}

canvas_data_offset :: proc(canvas: $T/Canvas, screen_coord: Vector2) -> i32 {
    pitch := canvas._width * BytesPerPixel
    return i32((BytesPerPixel * screen_coord.x) + (pitch * screen_coord.y))
}

to_screen_coord :: proc(canvas: $T/Canvas, canvas_coord: Vector2) -> (screen_coord: Vector2, err: Error) {
	canvas_width := f32(canvas._width)
	canvas_height := f32(canvas._height)

    x := canvas_width / 2.0 + canvas_coord.x
    y := canvas_height / 2.0 - canvas_coord.y - 1.0

    if x < 0 || x >= canvas_width || y < 0 || y >= canvas_height {
        return {}, InvalidCoordinate{}
    }

    return Vector2{x, y}, nil
}


get_pixel :: proc(canvas: $T/Canvas, canvas_coord: Vector2) -> (color: Color, err: Error) {
    screen_coord := to_screen_coord(canvas, canvas_coord) or_return

    offset := canvas_data_offset(canvas, screen_coord)
    r := canvas._data[offset + 0]
    g := canvas._data[offset + 1]
    b := canvas._data[offset + 2]
    a := canvas._data[offset + 3]

    color = Color{r, g, b, a}

    return
}


put_pixel :: proc(canvas: ^$T/Canvas, canvas_coord: Vector2, color: Color) -> Error {
    screen_coord := to_screen_coord(canvas^, canvas_coord) or_return

    offset := canvas_data_offset(canvas^, screen_coord)
    canvas^._data[offset + 0] = color.r
    canvas^._data[offset + 1] = color.g
    canvas^._data[offset + 2] = color.b
    canvas^._data[offset + 3] = color.a

    return nil
}

// END_CANVAS

main :: proc() {

    rl.InitWindow(800, 800, "Ray tracer - ch02")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    canvas, err := init_canvas(800, 800)
    if err != nil do return

    defer delete_canvas(canvas)


    viewport := Viewport{1, 1, 1}

    spheres := []Sphere {
        Sphere{{0, -1, 3}, 1, {255, 0, 0, 255}},
        Sphere{{2, 0, 4}, 1, {0, 0, 255, 255}},
        Sphere{{-2, 0, 4}, 1, {0, 255, 0, 255}},
    }

    min_x := -canvas._width / 2
    max_x := canvas._width / 2

    min_y := -canvas._height / 2
    max_y := canvas._height / 2

    camera_position := Vector3{0.0, 0.0, 0.0}

    for x in min_x ..< max_x {
        for y in min_y ..< max_y {
            direction := viewport_coord(viewport, canvas, Vector2{cast(f32)x, cast(f32)y})
            color := trace_ray(camera_position, direction, 1, Infinity, spheres)

            _ = put_pixel(&canvas, Vector2{cast(f32)x, cast(f32)y}, color)
        }
    }


    image := rl.Image {
        data    = canvas._data,
        width   = cast(i32)canvas._width,
        height  = cast(i32)canvas._height,
        format  = rl.PixelFormat.UNCOMPRESSED_R8G8B8A8,
        mipmaps = 1,
    }

    texture := rl.LoadTextureFromImage(image)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.LIGHTGRAY)

        rl.DrawTexture(texture, 0, 0, rl.WHITE)
    }
}
