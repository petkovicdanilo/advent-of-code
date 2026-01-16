use std::fs;

use anyhow::{Context, Result, bail};

use crate::Day;

pub(crate) struct Day5;

impl Day for Day5 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = parse_input(input_file)?;
        computer.run()?;
        return Ok(());
    }

    fn part2(&mut self, _input_file: String) -> Result<()> {
        todo!()
    }
}

#[derive(Clone, Debug)]
struct Computer {
    memory: Vec<i32>,
    ip: usize,
}

impl Computer {
    fn run(&mut self) -> Result<()> {
        loop {
            // println!("IP = {}", self.ip);
            let instruction = self.parse_instruction()?;
            // println!("instruction = {instruction:#?}");
            self.ip += instruction.size();
            match instruction {
                Instruction::Add { a, b, res } => {
                    self.memory[res as usize] = a + b;
                }
                Instruction::Mul { a, b, res } => {
                    self.memory[res as usize] = a * b;
                },
                Instruction::Input(param) => {
                    self.memory[param as usize] = 1;
                },
                Instruction::Output(param) => {
                    println!("OUTPUT: {}", self.memory[param as usize]);
                }
                Instruction::Halt => {
                    return Ok(());
                },
            }
        }
    }

    fn parse_instruction(&mut self) -> Result<Instruction> {
        let instruction = self.memory[self.ip];
        // println!("instruction = {instruction}");
        let op = instruction % 100;
        let param_modes = instruction / 100;
        match op {
            1 => {
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory[self.ip + 1], 
                    self.memory[self.ip + 2], 
                    self.memory[self.ip + 3], 
                )?;

                if p3.mode != ParameterMode::Position {
                    bail!("Output parameter of add has to be in position mode.");
                }

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let res = p3.val;

                return Ok(Instruction::Add { a, b, res });
            },
            2 => {
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory[self.ip + 1], 
                    self.memory[self.ip + 2], 
                    self.memory[self.ip + 3], 
                )?;

                if p3.mode != ParameterMode::Position {
                    bail!("Output parameter of mul has to be in position mode.");
                }

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let res = p3.val;

                return Ok(Instruction::Mul { a, b, res });
            },
            3 => {
                let param = self.parse_params1(
                    param_modes, 
                    self.memory[self.ip + 1]
                )?;
                if param.mode != ParameterMode::Position {
                    bail!("Parameter of input has to be in position mode.");
                }
                return Ok(Instruction::Input(param.val));
            },
            4 => {
                let param = self.parse_params1(
                    param_modes, 
                    self.memory[self.ip + 1]
                )?;
                if param.mode != ParameterMode::Position {
                    bail!("Parameter of input has to be in position mode.");
                }
                return Ok(Instruction::Output(param.val));
            }
            99 => {
                return Ok(Instruction::Halt);
            },
            _ => {
                bail!("Invalid op code");
            }
        }
    }

    fn parse_params1(&self, modes: i32, val1: i32) -> Result<Parameter> {
        let p1_mode = ((modes / 100) % 10) as u8;
        let p1_mode: ParameterMode = p1_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;

        let p1 = Parameter {
            mode: p1_mode,
            val: val1,
        };
        return Ok(p1);
    }

    fn parse_params3(&self, modes: i32, val1: i32, val2: i32, val3: i32) -> 
            Result<(Parameter, Parameter, Parameter)> {
        let p3_mode = ((modes / 100) % 10) as u8;
        let p2_mode = ((modes / 10) % 10) as u8;
        let p1_mode = (modes % 10) as u8;

        let p1_mode: ParameterMode = p1_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;
        let p2_mode: ParameterMode = p2_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;
        let p3_mode: ParameterMode = p3_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;

        let p1 = Parameter {
            mode: p1_mode,
            val: val1,
        };
        let p2 = Parameter {
            mode: p2_mode,
            val: val2,
        };
        let p3 = Parameter {
            mode: p3_mode,
            val: val3,
        };

        return Ok((p1, p2, p3));
    }

    fn fetch_param(&self, p: Parameter) -> i32 {
        return match p.mode {
            ParameterMode::Position => self.memory[p.val as usize],
            ParameterMode::Immediate => p.val,
        };
    }
}

#[derive(Debug)]
enum Instruction {
    Add {
        a: i32,
        b: i32,
        res: i32
    },
    Mul {
        a: i32,
        b: i32,
        res: i32
    },
    Input(i32),
    Output(i32),
    Halt
}

impl Instruction {
    fn size(&self) -> usize {
        return match self {
            Instruction::Add { a: _a, b: _b, res: _res } => 4,
            Instruction::Mul { a: _a, b: _b, res: _res } => 4,
            Instruction::Input(_) => 2,
            Instruction::Output(_) => 2,
            Instruction::Halt => 1,
        };
    }
}

struct Parameter {
    mode: ParameterMode,
    val: i32,
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq)]
enum ParameterMode {
    Position = 0,
    Immediate = 1,
}

impl TryFrom<u8> for ParameterMode {
    type Error = ();

    fn try_from(value: u8) -> std::result::Result<Self, Self::Error> {
        return match value {
            0 => Ok(ParameterMode::Position),
            1 => Ok(ParameterMode::Immediate),
            _ => Err(()),
        };
    }
}

fn parse_input(input_file: String) -> Result<Computer> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;
    let contents = contents.split("\n").next()
        .context("Error while parsing the input file")?;

    let memory: Result<Vec<_>, _> = contents.split(",")
        .map(|item| item.parse::<i32>())
        .collect();
    let memory = memory.context("Failed to parse the input file")?;

    return Ok(Computer {
        memory,
        ip: 0,
    });
}
