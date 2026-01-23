use anyhow::{Result, bail};

use crate::{Day, computer::Computer};

pub(crate) struct Day2;

impl Day for Day2 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        computer.memory[1] = 12;
        computer.memory[2] = 2;

        let inputs = std::iter::empty();
        let _ = computer.run(inputs)?;

        println!("{}", computer.memory[0]);

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        for i in 0..=99 {
            for j in 0..=99 {
                let mut c = computer.clone();
                c.memory[1] = i;
                c.memory[2] = j;
                let inputs = std::iter::empty();
                let _ = c.run(inputs)?;

                if c.memory[0] == 19690720 {
                    let res = 100 * i + j;
                    println!("{res}");
                    return Ok(());
                }
            }
        }

        bail!("Result not found.");
    }
}
