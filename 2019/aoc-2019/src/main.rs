use std::env;
use anyhow::{Context, Result, bail};

mod day1;
mod day2;
mod day3;
mod day4;

use crate::day1::Day1;
use crate::day2::Day2;
use crate::day3::Day3;
use crate::day4::Day4;

trait Day {
    fn part1(&mut self, input_file: String) -> Result<()>;
    fn part2(&mut self, input_file: String) -> Result<()>;
}

fn get_day(n: i32) -> Result<Box<dyn Day>> {
    match n {
        1 => {
            return Ok(Box::new(Day1{}));
        },
        2 => {
            return Ok(Box::new(Day2{}));
        },
        3 => {
            return Ok(Box::new(Day3{}));
        },
        4 => {
            return Ok(Box::new(Day4{}));
        },
        _ => {
            bail!("Unsupported day number")
        },
    }
}

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 4 {
        bail!("Not enough arguments");
    }

    let n = args[1].parse::<i32>().context("Day argument is not a number.")?;
    let part = args[2].parse::<i32>().context("Part argument is not a number.")?;
    let input_file = args[3].clone();

    let mut day = get_day(n)?;

    if part != 1 && part != 2 {
        bail!("Invalid argument for part");
    }

    if part == 1 {
        day.part1(input_file)?;
        return Ok(());
    } else {
        day.part2(input_file)?;
        return Ok(());
    }
}
