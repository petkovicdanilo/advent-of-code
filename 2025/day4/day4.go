package day4

import (
	"bufio"
	"fmt"
	"os"
)

const (
	EMPTY = iota
	ROLL
)

type Input struct {
	mat [][]byte

}

var (
	dRow = [8]int {-1, -1, -1,  0, 0,  1, 1, 1}
	dCol = [8]int {-1,  0,  1, -1, 1, -1, 0, 1}
)

func getInput(fileName string) ([][]int, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	rows := 0
	cols := 0

	var mat [][]int
	
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()

		rows += 1
		if cols == 0 {
			cols = len(line)
		}

		var row []int

		for _, b := range line {
			if b == '.' {
				row = append(row, EMPTY)
			} else {
				row = append(row, ROLL)
			}
		}

		mat = append(mat, row)
	}

	return mat, nil
}

func inBounds(r, c, rows, cols int) bool {
	if r < 0 || r >= rows {
		return false
	}

	if c < 0 || c >= cols {
		return false
	}

	return true
}

func canAccess(mat [][]int, r, c, rows, cols int) bool {
	adjRolls := 0
	for i := range 8 {
		dr := dRow[i]
		dc := dCol[i]
		newR := r + dr
		newC := c + dc

		if !inBounds(newR, newC, rows, cols) {
			continue
		}

		if mat[newR][newC] == ROLL {
			adjRolls += 1
		}
	}

	return adjRolls < 4
}

func SolvePartOne(fileName string) error {
	mat, err := getInput(fileName)
	if err != nil {
		return err
	}

	rows := len(mat)
	cols := len(mat[0])

	n := 0
	for r := range rows {
		for c := range cols {
			if mat[r][c] == ROLL && canAccess(mat, r, c, rows, cols) {
				n += 1
			}
		}
	}

	fmt.Printf("%d\n", n)

	return nil
}

func SolvePartTwo(fileName string) error {
	mat, err := getInput(fileName)
	if err != nil {
		return err
	}

	rows := len(mat)
	cols := len(mat[0])

	total := 0
	n := 1 // dummy just to enter loop
	for n > 0 {
		n = 0
		var toRemoveR []int
		var toRemoveC []int

		for r := range rows {
			for c := range cols {
				if mat[r][c] == ROLL && canAccess(mat, r, c, rows, cols) {
					n += 1
					toRemoveR = append(toRemoveR, r)
					toRemoveC = append(toRemoveC, c)
				}
			}
		}

		for i, r := range toRemoveR {
			c := toRemoveC[i]
			mat[r][c] = EMPTY
		}
		total += n
	}

	fmt.Printf("%d\n", total)

	return nil
}
