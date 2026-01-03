use std::fs;

use crate::Day;

pub(crate) struct Day1;

impl Day for Day1 {
    fn part1(&mut self, input_file: String) -> Result<(), String> {
        load_input(input_file)?;
        todo!()
    }

    fn part2(&mut self, _input_file: String) -> Result<(), String> {
        todo!()
    }
}

fn load_input(input_file: String) -> Result<(), String> {
    println!("Loading from file {input_file}");
    let contents = fs::read_to_string(input_file)
        .map_err(|e| format!("Couldn't read from file: {e}"))?;
    println!("Contents: {contents}");

    return Ok(());
}
