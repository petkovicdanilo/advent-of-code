use std::fs;
use anyhow::{Context, Result};

use crate::Day;

pub(crate) struct Day1;

impl Day for Day1 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let numbers = parse_input(input_file)?;

        let mut res = 0;
        for number in numbers.iter() {
            res += get_fuel(*number);
        }

        println!("{res}");
        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let numbers = parse_input(input_file)?;

        let mut res = 0;
        for number in numbers.iter() {
            let mut n = *number;
            loop {
                let fuel = get_fuel(n);
                if fuel < 0 {
                    break;
                }
                res += fuel;
                n = fuel;
            }
        }

        println!("{res}");
        return Ok(());
    }
}

fn parse_input(input_file: String) -> Result<Vec<i32>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let numbers: Result<Vec<_>, _> = contents.lines()
        .map(|line| line.parse::<i32>())
        .collect();
    let numbers = numbers.context("Failed to parse the input file")?;

    return Ok(numbers);
}

fn get_fuel(n: i32) -> i32 {
    return (n as f32 / 3.0).floor() as i32 - 2;
}
