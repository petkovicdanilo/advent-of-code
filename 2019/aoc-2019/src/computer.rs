use std::{collections::HashMap, fs};

use anyhow::{Context, Result, anyhow, bail};

#[derive(Clone, Debug)]
pub(crate) struct Computer {
    pub(crate) memory: Memory,
    pub(crate) ip: u64,
    pub(crate) rel_base: i64,
}

impl Computer {
    pub(crate) fn from_file(input_file: &str) -> Result<Self> {
        let contents = fs::read_to_string(input_file)
            .context("Couldn't read from the input file")?;
        let contents = contents.split("\n").next()
            .context("Error while parsing the input file")?;

        let mut memory = Memory::new();
        for (idx, ch) in contents.split(",").enumerate() {
            let val = ch.parse::<i64>()
                .context("Failed to parse input file")?;
            memory.write(idx as u64, val);
        }

        return Ok(Computer {
            memory,
            ip: 0,
            rel_base: 0,
        });
    }

    pub(crate) fn run(&mut self, mut inputs: impl Iterator<Item=i64>)
            -> Result<RunOutput> {
        let mut outputs = Vec::<i64>::new();
        loop {
            // println!("IP = {}", self.ip);
            let instruction = self.parse_instruction()?;
            // println!("instruction = {instruction:#?}");
            match instruction {
                Instruction::Add { a, b, pos } => {
                    self.memory.write(pos as u64, a + b);
                    self.ip += instruction.size();
                }
                Instruction::Mul { a, b, pos } => {
                    self.memory.write(pos as u64, a * b);
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

                    self.memory.write(param as u64, next.unwrap());
                    self.ip += instruction.size();
                },
                Instruction::Output(val) => {
                    outputs.push(val);
                    self.ip += instruction.size();
                }
                Instruction::JumpIfTrue { val, pos } => {
                    if val != 0 {
                        self.ip = pos as u64;
                    } else {
                        self.ip += instruction.size();
                    }
                },
                Instruction::JumpIfFalse { val, pos } => {
                    if val == 0 {
                        self.ip = pos as u64;
                    } else {
                        self.ip += instruction.size();
                    }
                },
                Instruction::LessThan { a, b, pos } => {
                    if a < b {
                        self.memory.write(pos as u64, 1);
                    } else {
                        self.memory.write(pos as u64, 0);
                    }
                    self.ip += instruction.size();
                },
                Instruction::Equals { a, b, pos } => {
                    if a == b {
                        self.memory.write(pos as u64, 1);
                    } else {
                        self.memory.write(pos as u64, 0);
                    }
                    self.ip += instruction.size();
                },
                Instruction::AdjRelBase(val) => {
                    self.rel_base += val;
                    self.ip += instruction.size();
                },
                Instruction::Halt => {
                    return Ok(RunOutput { outputs, status: Status::Halted });
                },
            }
        }
    }

    fn parse_instruction(&mut self) -> Result<Instruction> {
        let instruction = self.memory.read(self.ip);
        // println!("instruction = {instruction}");
        let op = instruction % 100;
        let param_modes = instruction / 100;
        let ret = match op {
            1 => {
                // add
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory.read(self.ip + 1),
                    self.memory.read(self.ip + 2),
                    self.memory.read(self.ip + 3),
                )?;

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let pos = self.fetch_pos_param(p3)
                    .context("Failed to fetch output param of add instruction")?;

                Instruction::Add { a, b, pos }
            },
            2 => {
                // mul
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory.read(self.ip + 1),
                    self.memory.read(self.ip + 2),
                    self.memory.read(self.ip + 3),
                )?;

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let pos = self.fetch_pos_param(p3)
                    .context("Failed to fetch output param of mul instruction")?;


                Instruction::Mul { a, b, pos }
            },
            3 => {
                // input
                let param = self.parse_params1(
                    param_modes,
                    self.memory.read(self.ip + 1)
                )?;

                let pos = self.fetch_pos_param(param)
                    .context("Failed to fetch pos param of input instruction")?;

                Instruction::Input(pos)
            },
            4 => {
                // output
                let param = self.parse_params1(
                    param_modes,
                    self.memory.read(self.ip + 1)
                )?;
                let val = self.fetch_param(param);

                Instruction::Output(val)
            },
            5 => {
                // jump-if-true
                let (p1, p2) = self.parse_params2(
                    param_modes,
                    self.memory.read(self.ip + 1),
                    self.memory.read(self.ip + 2),
                )?;
                let val = self.fetch_param(p1);
                let pos = self.fetch_param(p2) as u64;

                Instruction::JumpIfTrue { val, pos }
            },
            6 => {
                // jump-if-false
                let (p1, p2) = self.parse_params2(
                    param_modes,
                    self.memory.read(self.ip + 1),
                    self.memory.read(self.ip + 2),
                )?;
                let val = self.fetch_param(p1);
                let pos = self.fetch_param(p2) as u64;

                Instruction::JumpIfFalse { val, pos }
            },
            7 => {
                // less than
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory.read(self.ip + 1),
                    self.memory.read(self.ip + 2),
                    self.memory.read(self.ip + 3),
                )?;

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let pos = self.fetch_pos_param(p3)
                    .context("Failed to fetch pos param for less-than instruction")?;

                Instruction::LessThan { a, b, pos }
            },
            8 => {
                // equals
                let (p1, p2, p3) = self.parse_params3(
                    param_modes,
                    self.memory.read(self.ip + 1),
                    self.memory.read(self.ip + 2),
                    self.memory.read(self.ip + 3),
                )?;

                let a = self.fetch_param(p1);
                let b = self.fetch_param(p2);
                let pos = self.fetch_pos_param(p3)
                    .context("Failed to fetch pos param for equals instruction")?;

                Instruction::Equals { a, b, pos }
            },
            9 => {
                // adjust relative base
                let param = self.parse_params1(
                    param_modes,
                    self.memory.read(self.ip + 1),
                )?;

                let val = self.fetch_param(param);

                Instruction::AdjRelBase(val)
            },
            99 => {
                // halt
                Instruction::Halt
            },
            op => {
                bail!("Invalid op code {op}");
            }
        };

        return Ok(ret);
    }

    fn fetch_pos_param(&self, param: Parameter) -> Result<u64> {
        let res = match param.mode {
            ParameterMode::Position => param.val as u64,
            ParameterMode::Relative => (param.val + self.rel_base) as u64,
            m => {
                bail!("Invalid mode `{m:?}` for output param.");
            },
        };
        return Ok(res);
    }

    fn parse_params1(&self, modes: i64, val1: i64) -> Result<Parameter> {
        let p1_mode = (modes % 10) as u8;
        let p1_mode: ParameterMode = p1_mode.try_into()
            .or_else(|_| bail!("Failed to parse parameter mode"))?;

        let p1 = Parameter {
            mode: p1_mode,
            val: val1,
        };
        // println!("p1={p1:#?}");

        return Ok(p1);
    }

    fn parse_params2(&self, modes: i64, val1: i64, val2: i64) ->
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

        // println!("p1={p1:#?}");
        // println!("p2={p2:#?}");

        return Ok((p1, p2));
    }

    fn parse_params3(&self, modes: i64, val1: i64, val2: i64, val3: i64) ->
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

        // println!("p1={p1:#?}");
        // println!("p2={p2:#?}");
        // println!("p3={p3:#?}");

        return Ok((p1, p2, p3));
    }

    fn fetch_param(&self, p: Parameter) -> i64 {
        return match p.mode {
            ParameterMode::Position => self.memory.read(p.val as u64),
            ParameterMode::Immediate => p.val,
            ParameterMode::Relative =>
                self.memory.read((p.val + self.rel_base) as u64),
        };
    }
}

#[derive(Clone, Debug)]
pub(crate) struct Memory {
    inner: HashMap<u64, i64>
}

impl Memory {
    pub fn new() -> Self {
        Self {
            inner: HashMap::new()
        }
    }

    pub fn read(&self, addr: u64) -> i64 {
        return *self.inner.get(&addr).unwrap_or(&0);
    }

    pub fn write(&mut self, addr: u64, val: i64) {
        self.inner.insert(addr, val);
    }
}

#[derive(Debug)]
enum Instruction {
    Add {
        a: i64,
        b: i64,
        pos: u64,
    },
    Mul {
        a: i64,
        b: i64,
        pos: u64,
    },
    Input(u64),
    Output(i64),
    JumpIfTrue {
        val: i64,
        pos: u64,
    },
    JumpIfFalse{
        val: i64,
        pos: u64,
    },
    LessThan {
        a: i64,
        b: i64,
        pos: u64,
    },
    Equals {
        a: i64,
        b: i64,
        pos: u64,
    },
    AdjRelBase(i64),
    Halt
}

impl Instruction {
    fn size(&self) -> u64 {
        return match self {
            Instruction::Add { a: _a, b: _b, pos: _res } => 4,
            Instruction::Mul { a: _a, b: _b, pos: _res } => 4,
            Instruction::Input(_) => 2,
            Instruction::Output(_) => 2,
            Instruction::JumpIfTrue { val: _val, pos: _pos } => 3,
            Instruction::JumpIfFalse { val: _val, pos: _pos } => 3,
            Instruction::LessThan { a: _a, b: _b, pos: _pos } => 4,
            Instruction::Equals { a: _a, b: _b, pos: _pos } => 4,
            Instruction::AdjRelBase(_) => 2,
            Instruction::Halt => 1,
        };
    }
}

#[derive(Debug)]
struct Parameter {
    mode: ParameterMode,
    val: i64,
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq)]
enum ParameterMode {
    Position = 0,
    Immediate = 1,
    Relative = 2,
}

impl TryFrom<u8> for ParameterMode {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> std::result::Result<Self, Self::Error> {
        return match value {
            0 => Ok(ParameterMode::Position),
            1 => Ok(ParameterMode::Immediate),
            2 => Ok(ParameterMode::Relative),
            c => Err(anyhow!("Invalid char `{c}`")),
        };
    }
}

#[derive(Eq, PartialEq)]
pub(crate) enum Status {
    Halted,
    PausedForInput,
}

pub(crate) struct RunOutput {
    pub(crate) outputs: Vec<i64>,
    pub(crate) status: Status,
}

