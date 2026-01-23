use std::fs;

use anyhow::{Context, Result, bail};

#[derive(Clone, Debug)]
pub(crate) struct Computer {
    pub(crate) memory: Vec<i32>,
    pub(crate) ip: usize,
}

impl Computer {
    pub(crate) fn from_file(input_file: &str) -> Result<Self> {
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

    pub(crate) fn run(&mut self, mut inputs: impl Iterator<Item=i32>) 
            -> Result<RunOutput> {
        let mut outputs = Vec::<i32>::new();
        loop {
            // println!("IP = {}", self.ip);
            let instruction = self.parse_instruction()?;
            // println!("instruction = {instruction:#?}");
            match instruction {
                Instruction::Add { a, b, pos } => {
                    self.memory[pos as usize] = a + b;
                    self.ip += instruction.size();
                }
                Instruction::Mul { a, b, pos } => {
                    self.memory[pos as usize] = a * b;
                    self.ip += instruction.size();
                },
                Instruction::Input(param) => {
                    let next = inputs.next();
                    if next.is_none() {
                        return Ok(RunOutput {
                            outputs,
                            status: Status::PausedForInput,
                        });
                    }

                    self.memory[param as usize] = next.unwrap();
                    self.ip += instruction.size();
                },
                Instruction::Output(param) => {
                    let val = self.memory[param as usize];
                    outputs.push(val);
                    self.ip += instruction.size();
                }
                Instruction::JumpIfTrue { val, pos } => {
                    if val != 0 {
                        self.ip = pos as usize;
                    } else {
                        self.ip += instruction.size();
                    }
                },
                Instruction::JumpIfFalse { val, pos } => {
                    if val == 0 {
                        self.ip = pos as usize;
                    } else {
                        self.ip += instruction.size();
                    }
                },
                Instruction::LessThan { a, b, pos } => {
                    if a < b {
                        self.memory[pos as usize] = 1;
                    } else {
                        self.memory[pos as usize] = 0;
                    }
                    self.ip += instruction.size();
                },
                Instruction::Equals { a, b, pos } => {
                    if a == b {
                        self.memory[pos as usize] = 1;
                    } else {
                        self.memory[pos as usize] = 0;
                    }
                    self.ip += instruction.size();
                },
                Instruction::Halt => {
                    return Ok(RunOutput { outputs, status: Status::Halted });
                },
            }
        }
    }

    fn parse_instruction(&mut self) -> Result<Instruction> {
        let instruction = self.memory[self.ip];
        // println!("instruction = {instruction}");
        let op = instruction % 100;
        let param_modes = instruction / 100;
        let ret = match op {
            1 => {
                // add
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
                let pos = p3.val;

                Instruction::Add { a, b, pos }
            },
            2 => {
                // mul
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
                let pos = p3.val;

                Instruction::Mul { a, b, pos }
            },
            3 => {
                // input
                let param = self.parse_params1(
                    param_modes, 
                    self.memory[self.ip + 1]
                )?;
                if param.mode != ParameterMode::Position {
                    bail!("Parameter of input has to be in position mode.");
                }
                Instruction::Input(param.val)
            },
            4 => {
                // output
                let param = self.parse_params1(
                    param_modes, 
                    self.memory[self.ip + 1]
                )?;
                if param.mode != ParameterMode::Position {
                    bail!("Parameter of input has to be in position mode.");
                }
                Instruction::Output(param.val)
            },
            5 => {
                // jump-if-true
                let (p1, p2) = self.parse_params2(
                    param_modes,
                    self.memory[self.ip + 1],
                    self.memory[self.ip + 2],
                )?;
                let val = self.fetch_param(p1);
                let pos = self.fetch_param(p2);

                Instruction::JumpIfTrue { val, pos }
            },
            6 => {
                // jump-if-false
                let (p1, p2) = self.parse_params2(
                    param_modes,
                    self.memory[self.ip + 1],
                    self.memory[self.ip + 2],
                )?;
                let val = self.fetch_param(p1);
                let pos = self.fetch_param(p2);

                Instruction::JumpIfFalse { val, pos }
            },
            7 => {
                // less than
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory[self.ip + 1], 
                    self.memory[self.ip + 2], 
                    self.memory[self.ip + 3], 
                )?;

                if p3.mode != ParameterMode::Position {
                    bail!("Output parameter of less than has to be in position mode.");
                }

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let pos = p3.val;

                Instruction::LessThan { a, b, pos }
            },
            8 => {
                // equals
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory[self.ip + 1], 
                    self.memory[self.ip + 2], 
                    self.memory[self.ip + 3], 
                )?;

                if p3.mode != ParameterMode::Position {
                    bail!("Output parameter of equals than has to be in position mode.");
                }

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let pos = p3.val;

                Instruction::Equals { a, b, pos }
            }
            99 => {
                // halt
                Instruction::Halt
            },
            _ => {
                bail!("Invalid op code");
            }
        };

        return Ok(ret);
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

    fn parse_params2(&self, modes: i32, val1: i32, val2: i32) -> 
            Result<(Parameter, Parameter)> {
        let p2_mode = ((modes / 10) % 10) as u8;
        let p1_mode = (modes % 10) as u8;

        let p1_mode: ParameterMode = p1_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;
        let p2_mode: ParameterMode = p2_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;

        let p1 = Parameter {
            mode: p1_mode,
            val: val1,
        };
        let p2 = Parameter {
            mode: p2_mode,
            val: val2,
        };

        return Ok((p1, p2));
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
        pos: i32,
    },
    Mul {
        a: i32,
        b: i32,
        pos: i32,
    },
    Input(i32),
    Output(i32),
    JumpIfTrue {
        val: i32,
        pos: i32,
    },
    JumpIfFalse{
        val: i32,
        pos: i32,
    },
    LessThan {
        a: i32,
        b: i32,
        pos: i32,
    },
    Equals {
        a: i32,
        b: i32,
        pos: i32,
    },
    Halt
}

impl Instruction {
    fn size(&self) -> usize {
        return match self {
            Instruction::Add { a: _a, b: _b, pos: _res } => 4,
            Instruction::Mul { a: _a, b: _b, pos: _res } => 4,
            Instruction::Input(_) => 2,
            Instruction::Output(_) => 2,
            Instruction::JumpIfTrue { val: _val, pos: _pos } => 3,
            Instruction::JumpIfFalse { val: _val, pos: _pos } => 3,
            Instruction::LessThan { a: _a, b: _b, pos: _pos } => 4,
            Instruction::Equals { a: _a, b: _b, pos: _pos } => 4,
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

#[derive(Eq, PartialEq)]
pub(crate) enum Status {
    Halted,
    PausedForInput,
}

pub(crate) struct RunOutput {
    pub(crate) outputs: Vec<i32>,
    pub(crate) status: Status,
}

