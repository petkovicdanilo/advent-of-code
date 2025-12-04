package main

import (
	"os"
	"strconv"

	"github.com/petkovicdanilo/advent-of-code-2025/day1"
	"github.com/petkovicdanilo/advent-of-code-2025/day2"
	"github.com/petkovicdanilo/advent-of-code-2025/day3"
	"github.com/petkovicdanilo/advent-of-code-2025/day4"
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
			must(day1.SolvePartOne(fileName))
		case 2:
			must(day1.SolvePartTwo(fileName))
		}
	case 2:
		switch part {
		case 1:
			must(day2.SolvePartOne(fileName))
		case 2:
			must(day2.SolvePartTwo(fileName))
		}
	case 3:
		switch part {
		case 1:
			must(day3.SolvePartOne(fileName))
		case 2:
			must(day3.SolvePartTwo(fileName))
		}
	case 4:
		switch part {
		case 1:
			must(day4.SolvePartOne(fileName))
		case 2:
			must(day4.SolvePartTwo(fileName))
		}
	}
}


func must(err error) {
    if err != nil {
        panic(err)
    }
}
