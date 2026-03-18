use std::collections::VecDeque;

use anyhow::{Result, bail};

use crate::{Day, computer::{Computer, Status}};

pub(crate) struct Day25 {
}

impl Day for Day25 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let output = computer.run(std::iter::empty())?;

        if output.status == Status::Halted {
            bail!("Computer halted unexpectedly");
        }

        let out: String = output.outputs.iter().map(|o| *o as u8 as char).collect();
        println!("{out}");

        let traverse_input = r#"east
take whirled peas
east
north
take prime number
south
east
east
east
take dark matter
west
west
west
west
north
take coin
west
south
take antenna
north
north
west
take astrolabe
east
south
east
south
west
north
take fixed point
north
take weather machine
east
drop dark matter
drop coin
drop whirled peas
drop fixed point
drop astrolabe
drop prime number
drop antenna
drop weather machine"#;

        let items = vec![
            "coin",
            "whirled peas",
            "fixed point",
            "astrolabe",
            "prime number",
            "antenna",
            "weather machine",
        ];

        let mut input_queue = VecDeque::new();

        for command in traverse_input.lines() {
            input_queue.push_back(command.to_string());
        }

        let interactive = false;

        let mut curr_bitmap = Bitmap::new(0);
        let mut i = 0;

        let stdin = std::io::stdin();
        loop {
            let mut input_buff = String::new();

            let input = if let Some(command) = input_queue.pop_front() {
                command.to_string()
            } else {
                if interactive {
                    stdin.read_line(&mut input_buff)?;
                    if input_buff == "q\n" {
                        break;
                    }
                    input_buff[0..input_buff.len() - 1].to_string()
                } else {
                    for item in &items {
                        if curr_bitmap.contains_item(item)? {
                            input_queue.push_back(format!("drop {item}"));
                        }
                    }

                    i += 1;
                    if i >= (1 << items.len()) {
                        bail!("Couldn't find result");
                    }

                    let new_bitmap = Bitmap::new(i);
                    for item in &items {
                        if new_bitmap.contains_item(item)? {
                            input_queue.push_back(format!("take {item}"));
                        }
                    }
                    curr_bitmap = new_bitmap;
                    input_queue.push_back("south".to_string());
                    continue;
                }
            };

            println!("{input}");

            let output = computer.run(
                input
                    .chars()
                    .map(|ch| ch as i64)
                    .chain(['\n' as i64])
            )?;

            let out: String = output.outputs
                .iter()
                .map(|o| *o as u8 as char)
                .collect();

            println!("{out}");

            if output.status == Status::Halted {
                println!("Computer halted");
                break;
            }

        }

        return Ok(());
    }

    fn part2(&mut self, _input_file: String) -> Result<()> {
        println!("Nothing to do here");
        return Ok(());
    }
}

#[derive(Copy, Clone, Debug, Hash, Eq, PartialEq)]
struct Bitmap(u32);

impl Bitmap {
    fn new(val: u32) -> Self {
        return Self(val);
    }

    fn contains_item(&self, item: &str) -> Result<bool> {
        let idx = Bitmap::item_to_idx(item)?;
        let res = self.0 & (1 << idx) != 0;
        return Ok(res);
    }

    fn item_to_idx(item: &str) -> Result<usize> {
        let idx = match item {
            "coin" => 0,
            "whirled peas" => 1,
            "fixed point" => 2,
            "astrolabe" => 3,
            "prime number" => 4,
            "antenna" => 5,
            "weather machine" => 6,
            i => bail!("Invalid item {i}"),
        };
        return Ok(idx);
    }
}
