package day3

import (
	"bufio"
	"fmt"
	"os"
	"slices"
	"strconv"
)

type Bank []uint8

func getInput(fileName string) ([]Bank, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var banks []Bank

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		var bank []uint8
		line := scanner.Text()
		for i := 0; i < len(line); i++ {
			joltage, err := strconv.ParseUint(line[i:i+1], 10, 8)
			if err != nil {
				return nil, err
			}
			bank = append(bank, uint8(joltage))
		}
		banks = append(banks, bank)
	}

	return banks, nil
}

func findMaxJoltage(bank []uint8) (uint8, uint8) {
	maxIdx := uint8(0)
	maxJoltage := uint8(0)
	for idx, joltage := range bank {
		if joltage > maxJoltage {
			maxJoltage = joltage
			maxIdx = uint8(idx)
		}
	}
	return maxIdx, maxJoltage
}

func SolvePartOne(fileName string) error {
	banks, err := getInput(fileName)
	if err != nil {
		return err
	}

	sum := 0

	for _, bank := range banks {
		l := uint8(len(bank))
		var j1, j2 uint8
		idx, joltage := findMaxJoltage(bank)
		if idx == l - 1 {
			// we've found right digit
			j2 = joltage
			_, j1 = findMaxJoltage(bank[:l-1])
		} else {
			j1 = joltage
			_, j2 = findMaxJoltage(bank[idx+1:])
		}

		sum += int(j1*10 + j2)
	}

	fmt.Printf("%d\n", sum)

	return nil
}

func calculateJoltage(bank Bank, idxMap map[uint8]struct{}) uint64 {
	var idxList []uint8
	for idx := range idxMap {
		idxList = append(idxList, idx)
	}
	slices.Sort(idxList)

	joltage := uint64(0)
	for _, idx := range idxList {
		joltage = joltage * 10 + uint64(bank[idx])
	}

	return joltage
}

func SolvePartTwo(fileName string) error {
	banks, err := getInput(fileName)
	if err != nil {
		return err
	}

	const NUM_DIGITS = 12

	sum := uint64(0)
	for _, bank := range banks {
		pickedIdx := [NUM_DIGITS]uint8{}
		for i := range(NUM_DIGITS) {
			left := 0
			if i != 0 {
				left = int(pickedIdx[i - 1]) + 1
			}
			right := len(bank) - 12 + i
			maxVal := uint8(0)
			maxIdx := uint8(0)
			// fmt.Printf("[%d,%d]\n", left, right)
			for j := left; j <= right; j++ {
				if bank[j] > maxVal {
					maxVal = bank[j]
					maxIdx = uint8(j)
				}
			}

			pickedIdx[i] = maxIdx
		}

		joltage := uint64(0)
		for _, idx := range(pickedIdx) {
			joltage = joltage * 10 + uint64(bank[idx])
		}
		sum += joltage
	}

	fmt.Printf("%d\n", sum)

	return nil
}
