import sys

from z3 import Optimize, Int, sat

def main():
    file_name = sys.argv[1]

    input = []
    with open(file_name, "r") as f:
        for line in f:
            button_list = []
            desired_joltages = []

            parts = line.split(" ")
            for part in parts:
                if part[0] == '[':
                    # no need to parse diagram here
                    pass
                elif part[0] == '(':
                    button = [int(n) for n in part[1:-1].split(',')]
                    button_list.append(button)
                elif part[0] == '{':
                    desired_joltages = [int(n) for n in part[1:-2].split(',')]
                else:
                    print("Invalid input")
                    sys.exit(1)
            input.append((button_list, desired_joltages))

    res = 0
    for button_list, desired_joltages in input:
        opt = Optimize()

        variables = []
        for i, _ in enumerate(button_list):
            xi = Int(f"x{i}")
            opt.add(xi >= 0)
            variables.append(xi)

        equation_left_sides = []
        for _ in desired_joltages:
            equation_left_sides.append(0)

        for i, button in enumerate(button_list):
            for idx in button:
                equation_left_sides[idx] += variables[i]

        # print(equation_left_sides)

        for left_side, joltage in zip(equation_left_sides, desired_joltages):
            opt.add(left_side == joltage)

        sum = 0
        for var in variables:
            sum = sum + var

        opt.minimize(sum)

        result = opt.check()
        if result != sat:
            print("Couldn't solve")
            sys.exit(1)

        model = opt.model()

        for var in variables:
            res += model[var].as_long()

    print(res)

if __name__ == "__main__":
    main()
