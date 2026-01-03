use std::{env, error::Error};

use crate::day1::Day1;

mod day1;

trait Day {
    fn part1(&mut self, input_file: String) -> Result<(), String>;
    fn part2(&mut self, input_file: String) -> Result<(), String>;
}

fn get_day(n: i32) -> Result<Box<dyn Day>, String> {
    match n {
        1 => {
            return Ok(Box::new(Day1{}));
        },
        _ => {
            Err(String::from("Unsupported day number"))
        },
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 4 {
        return Err(Box::from("Not enough arguments"));
    }

    let n = args[1].parse::<i32>().map_err(|_| String::from("Day argument is not a number."))?;
    let part = args[2].parse::<i32>().map_err(|_| String::from("Part argument is not a number."))?;
    let input_file = args[3].clone();

    let mut day = get_day(n)?;

    if part != 1 && part != 2 {
        return Err(Box::from("Invalid argument for part"));
    }

    if part == 1 {
        day.part1(input_file)?;
        return Ok(());
    } else {
        day.part2(input_file)?;
        return Ok(());
    }
}
