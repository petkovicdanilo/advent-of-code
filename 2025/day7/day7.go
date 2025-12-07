package day7

import (
	"bufio"
	"errors"
	"fmt"
	"os"
)

const (
	START = iota
	EMPTY
	SPLITTER
)

type Input struct {
	mat [][]int
	startRow int
	startCol int
}

func getInput(fileName string) (*Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	startRow := 0
	startCol := 0
	var mat [][]int

	row := 0
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		var runningRow []int
		for col, ch := range line {
			switch ch {
			case 'S':
				startRow = row
				startCol = col
				runningRow = append(runningRow, START)
			case '.':
				runningRow = append(runningRow, EMPTY)
			case '^':
				runningRow = append(runningRow, SPLITTER)
			default:
				return nil, errors.New("Invalid character found")
			}
		}
		mat = append(mat, runningRow)
		row++
	}

	input := Input {
		mat: mat,
		startRow: startRow,
		startCol: startCol,
	}

	return &input, nil
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	// fmt.Printf("%v\n", input)
	nRows := len(input.mat)
	nCols := len(input.mat[0])

	splits := 0

	row := input.startRow + 1
	currBeams := make(map[int]struct{})
	currBeams[input.startCol] = struct{}{}

	for row < nRows {
		newBeams := make(map[int]struct{})
		for beam := range currBeams {
			if input.mat[row][beam] == EMPTY {
				newBeams[beam] = struct{}{}
				continue
			}

			left := beam - 1
			if left >= 0 {
				newBeams[left] = struct{}{}
			}

			right := beam + 1
			if right < nCols {
				newBeams[right] = struct{}{}
			}
			splits++
		}
		// fmt.Printf("New beams at row %d: %v\n", row, newBeams)
		currBeams = newBeams
		row++
	}

	fmt.Printf("%d\n", splits)

	return nil
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}

	// fmt.Printf("%v\n", input)
	nRows := len(input.mat)
	nCols := len(input.mat[0])

	var countMat [][]int
	for range nRows {
		var row []int
		for range nCols {
			row = append(row, 0)
		}
		countMat = append(countMat, row)
	}

	countMat[input.startRow][input.startCol] = 1

	row := input.startRow + 1
	for row < nRows {
		for col := range nCols {
			if input.mat[row][col] == EMPTY {
				if input.mat[row - 1][col] != SPLITTER {
					countMat[row][col] += countMat[row - 1][col]
				}
				continue
			}

			countMat[row][col] += countMat[row - 1][col]

			left := col - 1
			if left >= 0 {
				countMat[row][left] += countMat[row][col]
			}

			right := col + 1
			if right < nCols {
				countMat[row][right] += countMat[row][col]
			}
		}
		row++
	}

	// fmt.Printf("%v\n", countMat)

	res := 0
	row = nRows - 1
	for col := range nCols {
		res += countMat[row][col]
	}

	fmt.Printf("%d\n", res)

	return nil
}
