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

	NUM_DIGITS := 12

	sum := uint64(0)
	for _, bank := range banks {
		pickedIdxMap := make(map[uint8]struct{})

		joltage := uint64(0)

		for range(NUM_DIGITS) {
			maxJoltage := uint64(0)
			maxIdx := uint8(0)
			for idx := range bank {
				if _, found := pickedIdxMap[uint8(idx)]; found {
					continue
				}

				// This can be prettier (and more efficient)
				// with something like binary search tree

				// temporarily add idx to picked
				pickedIdxMap[uint8(idx)] = struct{}{}

				joltage := calculateJoltage(bank, pickedIdxMap)
				if joltage > maxJoltage {
					maxIdx = uint8(idx)
					maxJoltage = joltage
				}

				// cleanup
				delete(pickedIdxMap, uint8(idx))
			}

			pickedIdxMap[maxIdx] = struct{}{}
			joltage = maxJoltage
		}

		var pickedIdxList []uint8
		for idx := range pickedIdxMap {
			pickedIdxList = append(pickedIdxList, idx)
		}
		slices.Sort(pickedIdxList)

		sum += joltage
	}

	fmt.Printf("%d\n", sum)

	return nil
}
