package main

import (
	"os"
	"strconv"

	"github.com/petkovicdanilo/advent-of-code-2025/day1"
	"github.com/petkovicdanilo/advent-of-code-2025/day2"
	"github.com/petkovicdanilo/advent-of-code-2025/day3"
)

func main() {
	day, err := strconv.ParseUint(os.Args[1], 10, 8)
	if err != nil {
		panic(err)
	}

	part, err := strconv.ParseUint(os.Args[2], 10, 8)
	if err != nil {
		panic(err)
	}

	fileName := os.Args[3]


	switch day {
	case 1:
		switch part {
		case 1:
			err := day1.SolvePartOne(fileName)
			if err != nil {
				panic(err)
			}
		case 2:
			err := day1.SolvePartTwo(fileName)
			if err != nil {
				panic(err)
			}
		}
	case 2:
		switch part {
		case 1:
			err := day2.SolvePartOne(fileName)
			if err != nil {
				panic(err)
			}
		case 2:
			err := day2.SolvePartTwo(fileName)
			if err != nil {
				panic(err)
			}
		}
	case 3:
		switch part {
		case 1:
			err := day3.SolvePartOne(fileName)
			if err != nil {
				panic(err)
			}
		case 2:
			err := day3.SolvePartTwo(fileName)
			if err != nil {
				panic(err)
			}
		}
	}
}
