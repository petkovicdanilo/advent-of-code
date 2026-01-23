use anyhow::{Result};

use crate::{Day, computer::Computer};

pub(crate) struct Day5;

impl Day for Day5 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        let inputs = std::iter::repeat_n(1, 1);

        let res = computer.run(inputs)?;
        for output in res.outputs {
            println!("OUTPUT: {output}");
        }

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        let inputs = std::iter::repeat_n(5, 1);

        let res = computer.run(inputs)?;
        for output in res.outputs {
            println!("OUTPUT: {output}");
        }

        return Ok(());
    }
}
