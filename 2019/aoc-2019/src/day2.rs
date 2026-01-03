use std::fs;

use anyhow::{Context, Result, bail};

use crate::Day;

pub(crate) struct Day2;

impl Day for Day2 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = parse_input(input_file)?;
        computer.program[1] = 12;
        computer.program[2] = 2;

        computer.run();

        println!("{}", computer.program[0]);

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let computer = parse_input(input_file)?;

        for i in 0..=99 {
            for j in 0..=99 {
                let mut c = computer.clone();
                c.program[1] = i;
                c.program[2] = j;
                c.run();

                if c.program[0] == 19690720 {
                    let res = 100 * i + j;
                    println!("{res}");
                    return Ok(());
                }
            }
        }

        bail!("Result not found.");
    }
}

#[derive(Clone, Debug)]
struct Computer {
    program: Vec<i32>,
    instruction_pointer: usize,
}

impl Computer {
    fn run(&mut self) {
        loop {
            let ip = self.instruction_pointer;
            let op = self.program[ip];
            match op {
                1 => {
                    self.add_op(
                        self.program[ip + 1],
                        self.program[ip + 2],
                        self.program[ip + 3],
                    );
                },
                2 => {
                    self.mul_op(
                        self.program[ip + 1],
                        self.program[ip + 2],
                        self.program[ip + 3],
                    );
                },
                99 => {
                    return;
                },
                x => {
                    panic!("Invalid op {x}");
                }
            }
            self.instruction_pointer += 4;
        }
    }

    fn add_op(&mut self, pos1: i32, pos2: i32, pos3: i32) {
        let arg1 = self.program[pos1 as usize];
        let arg2 = self.program[pos2 as usize];

        let res = arg1 + arg2;
        self.program[pos3 as usize] = res;
    }

    fn mul_op(&mut self, pos1: i32, pos2: i32, pos3: i32) {
        let arg1 = self.program[pos1 as usize];
        let arg2 = self.program[pos2 as usize];

        let res = arg1 * arg2;
        self.program[pos3 as usize] = res;
    }
}

fn parse_input(input_file: String) -> Result<Computer> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;
    let contents = contents.split("\n").next()
        .context("Error while parsing the input file")?;

    let program: Result<Vec<_>, _> = contents.split(",")
        .map(|item| item.parse::<i32>())
        .collect();
    let program = program.context("Failed to parse the input file")?;

    return Ok(Computer {
        program,
        instruction_pointer: 0,
    });
}
