use crate::{Day, computer::Computer};

use anyhow::Result;

pub(crate) struct Day9 {
}

impl Day for Day9 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let input = vec![1].into_iter();
        let output = computer.run(input)?;

        println!("{}", output.outputs[0]);

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let input = vec![2].into_iter();
        let output = computer.run(input)?;

        println!("{}", output.outputs[0]);

        return Ok(());
    }
}
