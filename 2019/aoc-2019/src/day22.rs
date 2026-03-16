use std::fs;

use anyhow::{Context, Result, bail};

use crate::Day;

pub(crate) struct Day22 {
}

impl Day for Day22 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let instructions = parse_input(input_file)?;
        // println!("{instructions:?}");
        
        // const N: i128 = 10;
        const N: i128 = 10007;

        let mut idx = 2019;
        for instruction in &instructions {
            let (a, b) = coeff(&instruction, N);
            idx = (a * idx + b) % N;
            if idx < 0 {
                idx += N;
            }
        }

        println!("{idx}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let instructions = parse_input(input_file)?;

        let mut a = 1;
        let mut b = 0;

        const N: i128 = 119315717514047;
        const CYCLES: i128 = 101741582076661;

        for instruction in &instructions {
            let (new_a, new_b) = coeff(instruction, N);
            a = (new_a * a) % N;
            b = (new_a * b + new_b) % N;
        }

        // we now have F(i) = a * i + b for one cycle
        // calculate for desired number of cycles
        (a, b) = power(a, b, CYCLES, N);

        // F(i) = a * i + b  / mod N
        // new_idx = a * orig_idx + b  / mod N
        // orig_idx = (new_idx - b) * inv_a / mod N
        let inv_a = mod_inverse(a, N)?;
        let new_idx = 2020;

        let mut orig_idx = ((new_idx - b) * inv_a) % N;
        if orig_idx < 0 {
            orig_idx += N;
        }

        println!("{orig_idx}");

        return Ok(());
    }
}

// can be interpreted as linear function with modulo arithmetic
// f(i) = a*i + b  / mod N
// 1. deal into new stack -> f(i) = N - 1 - i => a = -1, b = N - 1
// 2. cut k -> f(i) = N - k + i => a = 1, b = N - k
// 3. deal with increment n -> f(i) = n*i => a = n, b = 0
fn coeff(instruction: &Instruction, n: i128) -> (i128, i128) {
    return match instruction {
        Instruction::DealIntoNewStack => (-1, n - 1),
        Instruction::Cut(val) => {
            (1, (n - val) % n)
        },
        Instruction::DealWithIncrement(val) => (*val as i128, 0),
    };
}

// f(i) = a * i + b
// f^2(i) = f(f(i)) = a(a * i + b) + b = a^2 * i + (a * b + b)
// find f^pow(i)
fn power(mut a: i128, mut b: i128, mut pow: i128, n: i128) -> (i128, i128) {
    let mut ret_a = 1;
    let mut ret_b = 0;

    while pow > 0 {
        if pow % 2 == 1 {
            ret_b = (a * ret_b + b) % n;
            ret_a = (a * ret_a) % n;
        }
        // Square the operation: f(f(x)) = a(ax + b) + b = a^2x + (ab + b)
        b = (a * b + b) % n;
        a = (a * a) % n;
        pow /= 2;
    }

    return (ret_a, ret_b);
}

// returns (d, x, y) so that
// ax + by = gcd(a, b)
// where d = gcd(a, b)
fn extended_gcd(a: i128, b: i128) -> (i128, i128, i128) {
    if a == 0 {
        return (b, 0, 1);
    }

    let (d, x1, y1) = extended_gcd(b % a, a);
    return (d, y1 - (b / a) * x1, x1)
}

fn mod_inverse(val: i128, n: i128) -> Result<i128> {
    let (d, x, _) = extended_gcd(val, n);
    if d != 1 {
        bail!("Modular inverse of {val} modulo {n} does not exist");
    }

    return Ok(x % n);
}

#[derive(Debug)]
enum Instruction {
    DealIntoNewStack,
    Cut(i128),
    DealWithIncrement(u128),
}

fn parse_input(input_file: String) -> Result<Vec<Instruction>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut instructions = Vec::new();
    for line in contents.lines() {
        let instruction = if line.starts_with("deal into new stack") {
            Instruction::DealIntoNewStack
        } else if line.starts_with("cut ") {
            let (_, num) = line.split_once("cut ").unwrap();
            let num = num.parse::<i128>()?;
            Instruction::Cut(num)
        } else if line.starts_with("deal with increment ") {
            let (_, num) = line.split_once("deal with increment ").unwrap();
            let num = num.parse::<u128>()?;
            Instruction::DealWithIncrement(num)
        } else {
            bail!("Invalid command in input '{line}'");
        };

        instructions.push(instruction);
    }

    return Ok(instructions);
}
