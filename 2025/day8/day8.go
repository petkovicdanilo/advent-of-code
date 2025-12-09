package day8

import (
	"bufio"
	"errors"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
)

type Input []Position

type Position struct {
	x, y, z int
}

type UnionSet struct {
	parent []int
}

func NewUnionSet(n int) UnionSet {
	parent := make([]int, n)
	for i := range(n) {
		parent[i] = i
	}
	return UnionSet { parent:parent }
}

func (u *UnionSet) Find(i int) int {
	if u.parent[i] == i {
		return i
	}
	return u.Find(u.parent[i])
}

func (u *UnionSet) Union(i, j int) {
	iParent := u.Find(i)
	jParent := u.Find(j)
	u.parent[iParent] = jParent
}

func getInput(fileName string) (Input, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var positions []Position

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Split(line, ",")
		if len(parts) != 3 {
			return nil, errors.New("Invalid input")
		}

		x, err := strconv.ParseInt(parts[0], 10, 32)
		if err != nil {
			return nil, err
		}

		y, err := strconv.ParseInt(parts[1], 10, 32)
		if err != nil {
			return nil, err
		}

		z, err := strconv.ParseInt(parts[2], 10, 32)
		if err != nil {
			return nil, err
		}

		positions = append(positions, Position{x:int(x), y:int(y), z:int(z)})
	}

	return positions, nil
}

func distance(p1, p2 Position) float64 {
	return math.Sqrt(
		float64((p1.x - p2.x)*(p1.x - p2.x) +
			(p1.y - p2.y)*(p1.y - p2.y) +
			(p1.z - p2.z)*(p1.z - p2.z)))
}

func SolvePartOne(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}
	// fmt.Printf("%v\n", input)

	var distMat [][]float64
	n := len(input)
	distMat = make([][]float64, n)
	for i := range(n) {
		distMat[i] = make([]float64, n)
	}

	for i := range(n - 1) {
		for j := i + 1; j < n; j++ {
			p1 := input[i]
			p2 := input[j]
			distMat[i][j] = distance(p1, p2)
		}
	}
	// fmt.Printf("%v\n", distMat)

	unionSet := NewUnionSet(n)

	const ITERATIONS = 1000
	for range(ITERATIONS) {
		minDist := math.MaxFloat64
		minI := 0
		minJ := 0
		for i := range(n) {
			for j := i + 1; j < n; j++ {
				if distMat[i][j] < minDist {
					minDist = distMat[i][j]
					minI = i
					minJ = j
				}
			}
		}
		distMat[minI][minJ] = math.MaxFloat64
		unionSet.Union(minI, minJ)
		// fmt.Printf("%d,%d\n", minI, minJ)
	}

	parentToCount := make(map[int]int)
	for i := range(n) {
		parentToCount[i] = 0
	}

	for i := range(n) {
		parent := unionSet.Find(i)
		parentToCount[parent]++
	}

	const LARGEST_CIRCUITS_ITER = 3

	res := 1
	for range(LARGEST_CIRCUITS_ITER) {
		maxCount := 0
		maxIdx := 0
		for i, count := range parentToCount {
			if count > maxCount {
				maxCount = count
				maxIdx = i
			}
		}

		res *= maxCount
		parentToCount[maxIdx] = 0
	}

	fmt.Printf("%d\n", res)

	return nil
}

func SolvePartTwo(fileName string) error {
	input, err := getInput(fileName)
	if err != nil {
		return err
	}
	// fmt.Printf("%v\n", input)

	var distMat [][]float64
	n := len(input)
	distMat = make([][]float64, n)
	for i := range(n) {
		distMat[i] = make([]float64, n)
	}

	for i := range(n - 1) {
		for j := i + 1; j < n; j++ {
			p1 := input[i]
			p2 := input[j]
			distMat[i][j] = distance(p1, p2)
		}
	}
	// fmt.Printf("%v\n", distMat)

	unionSet := NewUnionSet(n)

	finished := false
	lastX1 := 0
	lastX2 := 0
	for !finished {
		minDist := math.MaxFloat64
		minI := 0
		minJ := 0
		for i := range(n) {
			for j := i + 1; j < n; j++ {
				if distMat[i][j] < minDist {
					minDist = distMat[i][j]
					minI = i
					minJ = j
				}
			}
		}

		// save their x coordinates in case this is last iteration
		lastX1 = input[minI].x
		lastX2 = input[minJ].x

		distMat[minI][minJ] = math.MaxFloat64
		unionSet.Union(minI, minJ)
		// fmt.Printf("%d,%d\n", minI, minJ)

		firstParent := unionSet.Find(0)
		finished = true
		for i := range(n) {
			if unionSet.Find(i) != firstParent {
				finished = false
				break
			}
		}
	}

	res := lastX1 * lastX2
	fmt.Printf("%d\n", res)

	return nil
}
