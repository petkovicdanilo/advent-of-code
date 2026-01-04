use std::{collections::VecDeque, fs};

use crate::Day;

use anyhow::{Context, Result};

pub(crate) struct Day4;

impl Day for Day4 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let (lower, upper) = parse_input(input_file)?;

        let mut res = 0;
        for n in lower..=upper {
            if is_valid(n) {
                res += 1;
            }
        }

        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let (lower, upper) = parse_input(input_file)?;

        let mut res = 0;
        for n in lower..=upper {
            if is_valid2(n) {
                res += 1;
            }
        }

        println!("{res}");

        return Ok(());
    }
}

fn is_valid(n: u32) -> bool {
    let digits = get_digits(n);

    if digits.len() != 6 {
        return false;
    }

    let mut has_two_same = false;
    for window in digits.windows(2) {
        let l = window[0];
        let r = window[1];

        if r < l {
            return false
        }

        if l == r {
            has_two_same = true;
        }
    }

    if !has_two_same {
        return false;
    }

    return true;
}

fn is_valid2(n: u32) -> bool {
    let digits = get_digits(n);

    let mut digits: VecDeque<usize> = digits.into();

    if digits.len() != 6 {
        return false;
    }

    let mut found_double = false;

    while digits.len() > 0 {
        let curr = digits.pop_front().unwrap();

        let mut count = 1;
        while let Some(next) = digits.front() && curr == *next {
            count += 1;
            digits.pop_front();
        }

        if count == 2 {
            found_double = true;
        }

        if let Some(next) = digits.front() {
            if curr > *next {
                return false;
            }
        }
    }

    if found_double {
        return true;
    }

    return false;
}

fn get_digits(n: u32) -> Vec<usize> {
    if n == 0 {
        return vec![0];
    }

    let mut num = n;
    let mut digits = Vec::new();
    while num > 0 {
        let digit = (num % 10) as usize;
        digits.push(digit);
        num = num / 10;
    }

    digits.reverse();
    return digits;
}

fn parse_input(input_file: String) -> Result<(u32, u32)> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;
    let contents = contents.split("\n").next()
        .context("Error while parsing the input file")?;

    let mut split = contents.split("-");
    let lower_str = split.next().context("Couldn't get lower bound.")?;
    let upper_str = split.next().context("Couldn't get upper bound.")?;

    let lower = lower_str.parse::<u32>()?;
    let upper = upper_str.parse::<u32>()?;

    return Ok((lower, upper));
}
