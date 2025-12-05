package day5

import (
	"bufio"
	"cmp"
	"errors"
	"fmt"
	"os"
	"slices"
	"strconv"
	"strings"
)

type Input struct {
	ranges []Range
	ingredients []int64
}

type Range struct {
	start int64
	end int64
}

const (
	OPEN = iota
	CLOSE
)

type RangePoint struct {
	n int64
	ty int
	count int
}

func getInput(fileName string) (*Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	input := Input {}

	readRanges := true

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			readRanges = false
			continue
		}

		if readRanges {
			parts := strings.Split(line, "-")
			if len(parts) != 2 {
				return nil, errors.New("Invalid input")
			}

			start, err := strconv.ParseInt(parts[0], 10, 64)
			if err != nil {
				return nil, err
			}


			end, err := strconv.ParseInt(parts[1], 10, 64)
			if err != nil {
				return nil, err
			}

			r := Range {
				start: start,
				end: end,
			}

			input.ranges = append(input.ranges, r)
		} else {
			n, err := strconv.ParseInt(line, 10, 64)
			if err != nil {
				return nil, err
			}
			input.ingredients = append(input.ingredients, n)
		}
	}

	return &input, nil
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	n := 0
	for _, ingredient := range input.ingredients {
		fresh := false
		for _, r := range input.ranges {
			if ingredient >= r.start && ingredient <= r.end {
				fresh = true
				break
			}
		}
		if fresh {
			n += 1
			continue
		}
	}

	fmt.Printf("%d\n", n)

	return nil
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}


	openPoints := make(map[int64]*RangePoint)
	closePoints := make(map[int64]*RangePoint)
	for _, r := range input.ranges {
		if _, found := openPoints[r.start]; !found {
			openPoints[r.start] = &RangePoint {
				n: r.start,
				count: 0,
				ty: OPEN,
			}
		}
		p := openPoints[r.start]
		p.count += 1

		if _, found := closePoints[r.end]; !found {
			closePoints[r.end] = &RangePoint {
				n: r.end,
				count: 0,
				ty: CLOSE,
			}
		}
		p = closePoints[r.end]
		p.count += 1
	}

	var rangePoints []RangePoint
	for _, p := range openPoints {
		rangePoints = append(rangePoints, *p)
	}
	for _, p := range closePoints {
		rangePoints = append(rangePoints, *p)
	}

	slices.SortFunc(rangePoints, func(a, b RangePoint) int {
		if a.n == b.n {
			// make open brackets appear first
			return cmp.Compare(a.ty, b.ty)
		}
		return cmp.Compare(a.n, b.n)
	})
	// fmt.Printf("rangePoints = %v\n", rangePoints)

	s := int64(0)
	left := rangePoints[0]
	numOpen := left.count
	leftIncluded := false
	for i := 1; i < len(rangePoints); i++ {
		right := rangePoints[i]
		if numOpen > 0 {
			if !leftIncluded {
				// fmt.Printf("including [%d,%d]\n", left.n, right.n)
				s += right.n - left.n + 1
			} else {
				// fmt.Printf("including (%d,%d]\n", left.n, right.n)
				s += right.n - left.n
			}
			leftIncluded = true
		} else {
			// we didn't include our current range
			// so next iteration has to know that it can include its
			// left point
			leftIncluded = false
		}

		if right.ty == OPEN {
			numOpen += right.count
		} else {
			numOpen -= right.count
		}
		left = right
	}

	fmt.Printf("%d\n", s)

	return nil
}
