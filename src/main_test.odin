package main

import "core:testing"
import "core:fmt"

@(test)
test_put_pixel :: proc(t: ^testing.T) {
	//GIVEN
	canvas, err := init_canvas(10, 10)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}
	defer delete_canvas(canvas)

	color := Color{255, 155, 55, 255}
	canvas_coord_1 := Vector2{0, 0}
	canvas_coord_2 := Vector2{1, 0}
	canvas_coord_3 := Vector2{2, 0}

	//WHEN
	err = put_pixel(&canvas, canvas_coord_1, color)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}
	err = put_pixel(&canvas, canvas_coord_2, color)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}
		err = put_pixel(&canvas, canvas_coord_3, color)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}


	//THEN
	got: Color
	got, err = get_pixel(canvas, canvas_coord_1)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}

	testing.expect_value(t, got, color)

	got, err = get_pixel(canvas, canvas_coord_2)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}

	testing.expect_value(t, got, color)

	got, err = get_pixel(canvas, canvas_coord_3)
	if err != nil {
		testing.logf(t, "%v", err)
		testing.fail(t)
	}

	testing.expect_value(t, got, color)
}