package day2

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"slices"
	"strconv"
	"strings"
)


type Input struct {
	ranges []Range
}

type Range struct {
	start, end uint64
}

func getDigits(n uint64) []uint8 {
	var digits []uint8
	for (n > 0) {
		d := uint8(n % 10)
		digits = append(digits, d)
		n = n / 10
	}

	slices.Reverse(digits)
	return digits
}

func isInvalid(n uint64) bool {
	digits := getDigits(n)
	digitsLen := len(digits)
	if digitsLen % 2 != 0 {
		return false
	}

	for i := 0; i < digitsLen / 2; i++ {
		l := i
		r := i + (digitsLen / 2)
		if digits[l] != digits[r] {
			return false
		}
	}

	return true
}

// k is length of period
func isInvalidPartTwoHelper(digits []uint8, k uint8) bool {
	digitsLen := uint8(len(digits))
	if digitsLen % k != 0 {
		return false
	}

	if digitsLen <= k {
		return false
	}

	digitsToCheck := digits
	for uint8(len(digitsToCheck)) > k {
		for i := range k {
			l := i
			r := i + k
			if digitsToCheck[l] != digitsToCheck[r] {
				return false
			}
		}
		digitsToCheck = digitsToCheck[k:]
	}

	return true
}

func isInvalidPartTwo(n uint64) bool {
	digits := getDigits(n)
	l := uint8(len(digits))
	for i := uint8(1); i <= l / 2; i++ {
		if isInvalidPartTwoHelper(digits, i) {
			// fmt.Printf("%d is invalid with period %d\n", n, i)
			return true
		}
	}

	return false
}

func SolvePartOne(fileName string ) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	var sum uint64 = 0
	for _, r := range(input.ranges) {
		for i := r.start; i <= r.end; i++ {
			if isInvalid(i) {
				sum += i
			}
		}
	}

	fmt.Printf("%d\n", sum)

	return nil
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	var sum uint64 = 0
	for _, r := range(input.ranges) {
		for i := r.start; i <= r.end; i++ {
			if isInvalidPartTwo(i) {
				sum += i
			}
		}
	}

	fmt.Printf("%d\n", sum)

	return nil
}

func getInput(fileName string) (*Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var ranges []Range

	scanner := bufio.NewScanner(f)
	scanner.Scan()
	line := scanner.Text()
	rangeParts := strings.SplitSeq(line, ",")
	for r := range rangeParts {
		parts := strings.Split(r, "-")
		if len(parts) != 2 {
			return nil, errors.New("Unexpected input format")
		}

		start, err := strconv.ParseUint(parts[0], 10, 64)
		if err != nil {
			return nil, err
		}
		end, err := strconv.ParseUint(parts[1], 10, 64)
		if err != nil {
			return nil, err
		}
		ranges = append(ranges, Range {start: start, end: end})
	}

	input := Input {ranges: ranges}
	return &input, nil
}
