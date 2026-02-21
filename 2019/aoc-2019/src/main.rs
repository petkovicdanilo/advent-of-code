use std::env;
use anyhow::{Context, Result, bail};

mod computer;
mod day1;
mod day2;
mod day3;
mod day4;
mod day5;
mod day6;
mod day7;
mod day8;
mod day9;
mod day10;

use crate::day1::Day1;
use crate::day2::Day2;
use crate::day3::Day3;
use crate::day4::Day4;
use crate::day5::Day5;
use crate::day6::Day6;
use crate::day7::Day7;
use crate::day8::Day8;
use crate::day9::Day9;
use crate::day10::Day10;

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
        5 => {
            return Ok(Box::new(Day5{}));
        },
        6 => {
            return Ok(Box::new(Day6{}));
        },
        7 => {
            return Ok(Box::new(Day7{}));
        },
        8 => {
            return Ok(Box::new(Day8{}));
        },
        9 => {
            return Ok(Box::new(Day9{}));
        },
        10 => {
            return Ok(Box::new(Day10{}));
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
