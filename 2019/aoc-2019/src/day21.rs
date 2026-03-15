use anyhow::{Result, bail};

use crate::{Day, computer::{Computer, Status}};

pub(crate) struct Day21 {
}

impl Day for Day21 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        let input = std::iter::empty();
        let out = computer.run(input)?;

        // prompt
        for code in out.outputs {
            print!("{}", code as u8 as char);
        }
        println!();

        if out.status == Status::Halted {
            bail!("Computer halted unexpectedly.");
        }

        let input_str = r#"NOT C J
AND D J
NOT A T
OR T J
WALK
"#;
        println!("{input_str}");
        let input = input_str
            .chars()
            .map(|ch| ch as i64);
        let out = computer.run(input)?;

        for code in out.outputs.iter().take(out.outputs.len() - 1) {
            print!("{}", *code as u8 as char);
        }

        println!("{}", *out.outputs.iter().last().unwrap() as i64);

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        let input = std::iter::empty();
        let out = computer.run(input)?;

        // prompt
        for code in out.outputs {
            print!("{}", code as u8 as char);
        }
        println!();

        if out.status == Status::Halted {
            bail!("Computer halted unexpectedly.");
        }

        let input_str = r#"NOT C J
AND D J
AND H J
NOT B T
AND D T
OR T J
NOT A T
OR T J
RUN
"#;
        println!("{input_str}");
        let input = input_str
            .chars()
            .map(|ch| ch as i64);
        let out = computer.run(input)?;

        for code in out.outputs.iter().take(out.outputs.len() - 1) {
            print!("{}", *code as u8 as char);
        }

        println!("{}", *out.outputs.iter().last().unwrap() as i64);

        return Ok(());
    }
}
