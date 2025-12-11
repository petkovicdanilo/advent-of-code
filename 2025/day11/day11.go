package day11

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"
)

type Input map[string][]string

func getInput(fileName string) (Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	input := make(map[string][]string)

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Split(line, ": ")
		if len(parts) != 2 {
			return nil, errors.New("Invalid input")
		}

		name := parts[0]
		outputs := strings.Split(parts[1], " ")
		input[name] = outputs
	}

	return input, nil
}

func dfs(input Input, start string, end string) int {
	distMap := make(map[string]int)
	return dfsInner(input, start, end, distMap)
}

func dfsInner(input Input, curr string, end string, distMap map[string]int) int {
	if curr == end {
		return 1
	}

	if res, found := distMap[curr]; found {
		return res
	}

	res := 0
	for _, neighbour := range input[curr] {
		res += dfsInner(input, neighbour, end, distMap)
	}

	distMap[curr] = res
	return res
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}
	// fmt.Printf("%v\n", input)

	res := dfs(input, "you", "out")
	fmt.Printf("%d\n", res)
	
	return nil
}

func findDist(input Input, devices []string) int {
	res := 1
	for i := 0; i < len(devices) - 1; i++ {
		start := devices[i]
		end := devices[i + 1]
		dist := dfs(input, start, end)
		res *= dist
	}

	return res
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	res := 0

	path1 := []string{"svr", "dac", "fft", "out"}
	res += findDist(input, path1)

	path2 := []string{"svr", "fft", "dac", "out"}
	res += findDist(input, path2)

	fmt.Printf("%d\n", res)

	return nil
}
