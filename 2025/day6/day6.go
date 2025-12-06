package day6

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Input struct {
	problems []Problem
}

type Problem struct {
	numbers []int
	op Op
}

type Op int
const (
	ADD Op = iota
	MUL
)

type Input2 struct {
	lines []string
}

func getInput(fileName string) (*Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var problems []Problem

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if line[0] == '*' || line[0] == '+' {
			ops, err := parseOps(line)
			if err != nil {
				return nil, err
			}

			for i, op := range ops {
				p := &problems[i]
				p.op = op
			}
		} else {
			row, err := parseNumbers(line)
			if err != nil {
				return nil, err
			}

			if len(problems) == 0 {
				problems = make([]Problem, len(row))
			}

			for i, item := range row {
				p := &problems[i]
				p.numbers = append(p.numbers, item)
			}
		}
	}

	input := Input {
		problems: problems,
	}

	return &input, nil
}

func getInput2(fileName string) (*Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var problems []Problem
	var lines []string

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if line[0] == '*' || line[0] == '+' {
			ops, err := parseOps(line)
			if err != nil {
				return nil, err
			}

			for _, op := range ops {
				p := Problem {
					op: op,
				}
				problems = append(problems, p)
			}
		} else {
			lines = append(lines, line)
		}
	}

	rows := len(lines)
	cols := len(lines[0])

	currProblemIdx := 0
	for col := range cols {
		num := 0
		for row := range rows {
			if lines[row][col] == ' ' {
				continue
			}
			digit, err := strconv.ParseInt(string(lines[row][col]), 10, 8)
			if err != nil {
				return nil, err
			}
			num = num * 10 + int(digit)
		}

		if num == 0 {
			currProblemIdx++
		} else {
			p := &problems[currProblemIdx]
			p.numbers = append(p.numbers, num)
		}
	}

	input := Input {
		problems: problems,
	}

	return &input, nil
}

func parseNumbers(line string) ([]int, error) {
	parts := strings.Fields(line)

	numbers := make([]int, len(parts))
	for i, part := range parts {
		num, err := strconv.ParseInt(part, 10, 32)
		if err != nil {
			return nil, err
		}
		numbers[i] = int(num)
	}

	return numbers, nil
}

func parseOps(line string) ([]Op, error) {
	parts := strings.Fields(line)

	ops := make([]Op, len(parts))
	for i, part := range parts {
		if part == "+" {
			ops[i] = ADD
		}
		if part == "*" {
			ops[i] = MUL
		}
	}

	return ops, nil
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	sum := int64(0)
	for _, problem := range input.problems {
		res := int64(0)
		if problem.op == MUL {
			res = int64(1)
		}

		for _, num := range problem.numbers {
			if problem.op == ADD {
				res += int64(num)
			} else {
				res *= int64(num)
			}
		}

		sum += res
	}

	fmt.Printf("%d\n", sum)

	return nil
}

func SolvePartTwo(fileName string) error {
	input, err := getInput2(fileName)
	if err != nil {
		return err
	}

	sum := int64(0)
	for _, problem := range input.problems {
		res := int64(0)
		if problem.op == MUL {
			res = int64(1)
		}

		for _, num := range problem.numbers {
			if problem.op == ADD {
				res += int64(num)
			} else {
				res *= int64(num)
			}
		}

		sum += res
	}

	fmt.Printf("%d\n", sum)

	return nil
}
