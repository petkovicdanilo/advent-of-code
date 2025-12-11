package day10

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Input []Machine

type Machine struct {
	diagram Diagram
	buttons []Button
	joltages []int
}

type Diagram []rune

type Button struct {
	indices []int
}

func getInput(fileName string) (Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var input Input

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitSeq(line, " ")

		var diagram Diagram
		var buttons []Button
		var joltages []int

		for part := range parts {
			switch part[0] {
			case '[':
				diagram = Diagram(part[1:len(part)-1])
			case '(':
				button, err := parseButton(part)
				if err != nil {
					return nil, err
				}
				buttons = append(buttons, *button)
			case '{':
				joltages, err = parseJoltages(part)
				if err != nil {
					return nil, err
				}
			default:
				return nil, errors.New("Invalid input")
			}
		}
		machine := Machine {
			diagram: diagram,
			buttons: buttons,
			joltages: joltages,
		}
		input = append(input, machine)
	}

	return input, nil
}

func parseButton(s string) (*Button, error) {
	indices, err := parseIntArray(s[1:len(s)-1])
	if err != nil {
		return nil, err
	}

	b := Button {
		indices: indices,
	}
	return &b, nil
}

func parseIntArray(s string) ([]int, error) {
	parts := strings.Split(s, ",")

	array := make([]int, len(parts))
	for i, part := range parts {
		n, err := strconv.ParseInt(part, 10, 32)
		if err != nil {
			return nil, err
		}
		array[i] = int(n)
	}

	return array, nil
}

func parseJoltages(s string) ([]int, error) {
	joltages, err := parseIntArray(s[1:len(s)-1])
	if err != nil {
		return nil, err
	}
	return joltages, nil
}

func generateStartDiagramStr(n int) string {
	slice := make([]rune, n)
	for i := range n {
		slice[i] = '.'
	}
	return string(slice)
}

func flip(b rune) rune {
	if b == '.' {
		return '#'
	}
	return '.'
}

func partOne(machine Machine) int {
	countMap := make(map[string]int)
	n := len(machine.diagram)

	startDiagram := generateStartDiagramStr(n)
	countMap[string(startDiagram)] = 0

	for _, button := range machine.buttons {
		for diagram, count := range countMap {
			newDiagram := Diagram(diagram)
			for _, idx := range button.indices {
				newDiagram[idx] = flip(newDiagram[idx])
			}
			newDiagramStr := string(newDiagram)

			val, found := countMap[newDiagramStr]
			newDiagramCount := count + 1
			if !found || newDiagramCount < val {
				// fmt.Printf("Inserting %v => %d\n", newDiagramStr, newDiagramCount)
				countMap[newDiagramStr] = newDiagramCount
			}
		}
	}

	// fmt.Printf("%v\n", countMap)

	return countMap[string(machine.diagram)]
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}
	// fmt.Printf("%v\n", input)

	res := 0
	for _, machine := range input {
		r := partOne(machine)
		// fmt.Printf("res = %d\n", r)
		res += r
	}

	fmt.Printf("%d\n", res)

	return nil
}

func SolvePartTwo(fileName string) error {
	_, err := getInput(fileName)
	if err != nil {
		return err
	}

	return nil
}
