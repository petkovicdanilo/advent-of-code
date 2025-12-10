package day9

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Input []Point

type Polygon struct {
	vertices []Point
}

type Point struct {
	row, col int
}

func getInput(fileName string) (Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var positions []Point

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Split(line, ",")
		if len(parts) != 2 {
			return nil, errors.New("Invalid input")
		}

		y, err := strconv.ParseInt(parts[0], 10, 32)
		if err != nil {
			return nil, err
		}

		x, err := strconv.ParseInt(parts[1], 10, 32)
		if err != nil {
			return nil, err
		}

		positions = append(positions, Point{row:int(x), col:int(y)})
	}

	return positions, nil
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

func area(p1, p2 Point) int {
	return (abs(p1.row - p2.row) + 1) * (abs(p1.col - p2.col) + 1)
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	maxArea := 0
	for i, corner1 := range input {
		for j := i + 1; j < len(input); j++ {
			corner2 := input[j]
		 	a := area(corner1, corner2)
			if a > maxArea {
				maxArea = a
			}
		}
	}

	fmt.Printf("%d\n", maxArea)

	return nil
}

func between(p, a, b int) bool {
	first := min(a, b)
	second := max(a, b)
	return p >= first && p <= second
}

func (polygon *Polygon) IsInside(pos Point) bool {
	inside := false

	n := len(polygon.vertices)
	for i := range n {
		j := (i + 1) % n
		r1, c1 := polygon.vertices[i].row, polygon.vertices[i].col
		r2, c2 := polygon.vertices[j].row, polygon.vertices[j].col

		if r1 == r2 {
			// horizontal
			if pos.row == r1 && between(pos.col, c1, c2) {
				return true
			}
		} else if c1 == c2{
			// vertical
			if pos.col == c1 && between(pos.row, r1, r2) {
				return true
			}
		}
	}

	for i := range n {
		j := (i + 1) % n
		r1, c1 := polygon.vertices[i].row, polygon.vertices[i].col
		r2, _ := polygon.vertices[j].row, polygon.vertices[j].col

		if r1 == r2 {
			// skip horizontal edges
			continue
		}

		if (pos.row > r1) == (pos.row > r2) {
			continue
		}
		if pos.col < c1 {
			inside = !inside
		}
	}

	return inside
}

func (p *Polygon) IsRectangleValid(pos1, pos2 Point) bool {
	// fmt.Printf("check %v %v\n", pos1, pos2)
	other1 := Point {
		row: pos1.row,
		col: pos2.col,
	}
	other2 := Point {
		row: pos2.row,
		col: pos1.col,
	}
	// fmt.Printf("other %v %v\n", other1, other2)

	if !p.IsInside(other1) || !p.IsInside(other2) {
		// fmt.Printf("not inside\n")
		return false
	}

	minRow := min(pos1.row, pos2.row)
	maxRow := max(pos1.row, pos2.row)
	minCol := min(pos1.col, pos2.col)
	maxCol := max(pos1.col, pos2.col)

	topLeft := Point {
		row: minRow,
		col: minCol,
	}
	topRight := Point {
		row: minRow,
		col: maxCol,
	}
	bottomLeft := Point {
		row: maxRow,
		col: minCol,
	}
	bottomRight := Point {
		row: maxRow,
		col: maxCol,
	}
	
	rectangle := Polygon {
		vertices: []Point{topLeft, topRight, bottomRight, bottomLeft},
	}

	n := len(p.vertices)
	for rectI := range 4 {
		rectJ := (rectI + 1) % 4
		r1, c1 := rectangle.vertices[rectI].row, rectangle.vertices[rectI].col
		r2, c2 := rectangle.vertices[rectJ].row, rectangle.vertices[rectJ].col

		for i := range n {
			j := (i + 1) % n
			edgeR1, edgeC1 := p.vertices[i].row, p.vertices[i].col
			edgeR2, edgeC2 := p.vertices[j].row, p.vertices[j].col

			if r1 == r2 {
				if edgeR1 == edgeR2 {
					continue
				}
				// (r1, c1) - (r2, c2) - horizontal
				// (edgeR1, edgeC1) - (edgeR2, edgeC2) - vertical

				if (r1 > edgeR1) == (r1 > edgeR2) {
					continue
				}

				r := r1
				c := edgeC1

				if c > max(c1, c2) {
					continue
				}

				if between(r, edgeR1, edgeR2) && between(c, c1, c2) &&
					r != edgeR1 && r != edgeR2 &&
					c != edgeC1 && c != edgeC2 {
					// fmt.Printf("Intersection (%d, %d) (%d, %d) (%d, %d) (%d, %d)\n",
					// 	r1, c1, r2, c2, edgeR1, edgeC1, edgeR2, edgeC2)
					return false
				}
			} else {
				if edgeC1 == edgeC2 {
					continue
				}
				// (r1, c1) - (r2, c2) - vertical
				// (edgeR1, edgeC1) - (edgeR2, edgeC2) - horizontal

				if (c1 > edgeC1) == (c1 > edgeC2) {
					continue
				}

				r := edgeR1
				c := c1

				if r > max(r1, r2) {
					continue
				}

				if between(c, edgeC1, edgeC2) && between(r, r1, r2) &&
					c != edgeC1 && c != edgeC2 &&
					r != r1 && r != r2 {
					// fmt.Printf("Intersection (%d, %d) (%d, %d) (%d, %d) (%d, %d)\n",
					// 	r1, c1, r2, c2, edgeR1, edgeC1, edgeR2, edgeC2)
					return false
				}
			}
		}
	}

	// fmt.Printf("okay %v %v\n", pos1, pos2)
	return true
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}
	// fmt.Printf("%v\n", input)

	p := Polygon {
		vertices: input,
	}

	// pos1 := Position {x:1, y:2}
	// fmt.Printf("%v\n", p.IsInside(pos1))
	// pos2 := Position {x:1, y:7}
	// fmt.Printf("%v\n", p.IsInside(pos2))
	// pos3 := Position {x:5, y:2}
	// fmt.Printf("%v\n", p.IsInside(pos3))
	// pos4 := Point {x:0, y:2}
	// fmt.Printf("%v\n", p.IsInside(pos4))

	// p1 := Point {row:3, col:1}
	// p2 := Point {row:3, col:6}
	// q1 := Point {row:2, col:5}
	// q2 := Point {row:8, col:5}
	// fmt.Printf("%v\n", intersection(p1, p2, q1, q2))

	// for i := range 9 {
	// 	for j := range 14 {
	// 		pos := Point {x:i, y:j}
	// 		isInside := p.IsInside(pos)
	// 		if isInside {
	// 			fmt.Printf("T")
	// 		} else {
	// 			fmt.Printf(".")
	// 		}
	// 	}
	// 	fmt.Println()
	// }

	maxArea := 0
	for i, corner1 := range input {
		for j := i + 1; j < len(input); j++ {
			corner2 := input[j]
			if !p.IsRectangleValid(corner1, corner2) {
				// fmt.Printf("%v %v is invalid\n", corner1, corner2)
				continue
			}

		 	a := area(corner1, corner2)
			if a > maxArea {
				maxArea = a
			}
		}
	}

	fmt.Printf("%d\n", maxArea)

	return nil
}
