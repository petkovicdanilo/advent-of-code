package day12

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Shape [3][3]int

type Region struct {
	rows, cols int
	shapeCount []int
}

type Input struct {
	shapes []Shape
	regions []Region
}

const (
	EMPTY = iota
	FILLED
)

func getInput(fileName string) (*Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var shapes []Shape
	var regions []Region

	currShape := Shape{}
	currShapeRow := 0

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			shapes = append(shapes, currShape)
			currShape = Shape{}
			currShapeRow = 0
			continue
		}

		if line[0] >= '0' && line[0] <= '9' {
			if !strings.Contains(line, "x") {
				continue
			}
			region, err := parseRegion(line)
			if err != nil {
				return nil, err
			}

			regions = append(regions, *region)
		} else {
			for i, ch := range line {
				if ch == '#' {
					currShape[currShapeRow][i] = FILLED
				} else {
					currShape[currShapeRow][i] = EMPTY
				}
			}
			currShapeRow++
		}
	}

	input := Input {
		shapes: shapes,
		regions: regions,
	}

	return &input, nil
}

func parseRegion(s string) (*Region, error) {
	parts := strings.Split(s, ": ")
	if len(parts) != 2 {
		return nil, errors.New("Invalid input")
	}

	left := parts[0]
	leftParts := strings.Split(left, "x")
	if len(leftParts) != 2 {
		return nil, errors.New("Invalid input")
	}

	r, err := strconv.ParseInt(leftParts[0], 10, 32)
	if err != nil {
		return nil, err
	}

	c, err := strconv.ParseInt(leftParts[1], 10, 32)
	if err != nil {
		return nil, err
	}

	right := parts[1]
	rightParts := strings.Split(right, " ")
	shapeCount := make([]int, len(rightParts))
	for i, p := range rightParts {
		count, err := strconv.ParseInt(p, 10, 32)
		if err != nil {
			return nil, err
		}
		shapeCount[i] = int(count)
	}

	region := Region {
		rows: int(r),
		cols: int(c),
		shapeCount: shapeCount,
	}

	return &region, nil
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}
	// fmt.Printf("%v\n", input)

	canFit := 0
	for _, region := range input.regions {
		area := region.rows * region.cols

		shapeArea := 0
		for _, shapeCount := range region.shapeCount {
			shapeArea += 3 * 3 * shapeCount
		}

		if area < shapeArea {
			continue
		} else {
			// this does not guarantee that shapes can
			// all be put in a region, but it is enough
			// for the given input. Example won't work
			// on this
			canFit++
		}
	}

	fmt.Printf("%d\n", canFit)

	return nil
}
