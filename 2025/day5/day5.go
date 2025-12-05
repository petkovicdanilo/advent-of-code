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

// r1 and r2 are sorted
func overlap(r1, r2 Range) bool {
	return !(r2.start > r1.end)
}

func merge(r1, r2 Range) Range {
	start := min(r1.start, r2.start)
	end := max(r1.end, r2.end)
	return Range {
		start: start,
		end: end,
	}
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	slices.SortFunc(input.ranges, func(a, b Range) int {
		if a.start == b.start {
			return cmp.Compare(a.end, b.end)
		}
		return cmp.Compare(a.start, b.start)
	})
	
	s := int64(0)
	runningRange := input.ranges[0]
	for i := 1; i < len(input.ranges); i++ {
		r := input.ranges[i]
		if overlap(runningRange, r) {
			// fmt.Printf("%v and %v overlap\n", runningRange, r)
			runningRange = merge(runningRange, r)
			// fmt.Printf("merged to %v\n", runningRange)
		} else {
			s += runningRange.end - runningRange.start + 1
			// fmt.Printf("%v and %v don't overlap\n", runningRange, r)
			runningRange = r
		}
	}
	// fmt.Printf("%v\n", runningRange)
	s += runningRange.end - runningRange.start + 1

	fmt.Printf("%d\n", s)

	return nil
}
