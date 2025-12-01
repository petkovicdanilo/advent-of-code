package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

type Direction int

const (
	LEFT Direction = -1
	RIGHT Direction = 1
)

const (
	MAX = 100
	START_POS = 50
)

type Rotation struct {
	Direction Direction
	N int
}

func circle(a, b int) int {
	r := a % b
	if r < 0 {
		r += b
	}
	return r
}

func abs(a int) int {
	if a < 0 {
		return -a
	}
	return a
}

func circle2(pos, step, size int) (int, int) {
	res := 0
	if abs(step) > size {
		res = abs(step) / size
		step = step % size
	}
	newPos := (pos + step)
	if pos != 0 && (newPos < 0 || newPos >= size) {
		res += 1
	}
	if newPos < 0 {
		newPos += size
	} else if newPos >= size {
		newPos -= size
	} else if newPos == 0 {
		res += 1
	}

	return res, newPos
}


func part1(rotations []Rotation) {
	pos := START_POS
	counter := 0
	for _, rotation := range rotations {
		pos = circle(pos + int(rotation.Direction) * rotation.N, MAX)
		if pos == 0 {
			counter += 1
		}
	}
	fmt.Printf("%d\n", counter)
}

func part2(rotations []Rotation) {
	pos := START_POS
	counter := 0
	for _, rotation := range rotations {
		res, newPos := circle2(pos, int(rotation.Direction) * rotation.N, MAX)
		pos = newPos
		counter += res
	}
	fmt.Printf("%d\n", counter)
}

func main() {
	fileName := os.Args[1]
	f, err := os.Open(fileName)
	if err != nil {
		panic(err)
	}

	rotations := make([]Rotation, 0, 0)

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		d := LEFT
		if line[0] == 'L' {
			d = LEFT
		} else {
			d = RIGHT
		}
		n, err := strconv.ParseInt(line[1:], 0, 32)
		if err != nil {
			panic(err)
		}

		r := Rotation {
			Direction: d,
			N: int(n),
		}
		rotations = append(rotations, r)
	}

	f.Close()

	// part1(rotations)
	part2(rotations)
}
