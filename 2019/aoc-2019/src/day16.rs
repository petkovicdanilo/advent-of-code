use std::fs;

use anyhow::{Context, Result};

use crate::Day;

pub(crate) struct Day16 {
}

impl Day for Day16 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut signal = parse_input(input_file)?;
        // println!("{signal:?}");
        let n = signal.len();

        const NUM_PHASES: u32 = 100;
        for _ in 0..NUM_PHASES {
            let mut output = Vec::with_capacity(n);
            for i in 0..n {
                output.push(calc_output_n(&signal, i));
            }
            signal = output;
            // println!("{signal:?}");
        }

        for i in 0..8 {
            print!("{}", signal[i]);
        }
        println!();
        
        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let signal = parse_input(input_file)?;

        let mut offset: usize = 0;
        for el in signal.iter().take(7) {
            offset = offset * 10 + (*el as usize);
        }
        // println!("offset={offset}");

        // from mid till the end, in phase N at index idx
        // new_signal[idx] = signal[idx] + signal[idx + 1] + ... + signal[n - 1]
        // and offset is in the second half. Looks like the same property
        // holds for all inputs.
        let n = signal.len() * 10000;
        let mut signal: Vec<_> = signal
            .into_iter()
            .cycle()
            .take(n)
            .skip(offset)
            .collect();

        let n = signal.len();

        for _ in 0..100 {
            let mut new_signal = Vec::with_capacity(n);
            for _ in 0..n {
                new_signal.push(0);
            }

            new_signal[n - 1] = signal[n - 1];
            for i in (0..n-1).rev() {
                new_signal[i] = (new_signal[i + 1] + signal[i]) % 10;
            }

            signal = new_signal;
        }

        for i in 0..8 {
            print!("{}", signal[i]);
        }
        println!();

        return Ok(());
    }
}

const PATTERN: [i8; 4] = [0, 1, 0, -1];

fn calc_output_n(input: &Vec<u8>, pos: usize) -> u8 {
    let mut pattern_iter = PATTERN
        .into_iter()
        .flat_map(move |n| std::iter::repeat(n).take(pos + 1))
        .cycle()
        .skip(1);

    let mut res: i64 = 0;
    for el in input {
        let pattern_val = pattern_iter.next().unwrap();
        res += *el as i64 * (pattern_val as i64);
    }

    if res < 0 {
        res = -res;
    }

    return (res % 10) as u8;
}

fn parse_input(input_file: String) -> Result<Vec<u8>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut res = Vec::new();
    // skip newline in the end
    for ch in contents.chars().take(contents.len() - 1) {
        let num = ch.to_digit(10)
            .context(format!("Couldn't transform char '{ch}' to digit"))? as u8;
        res.push(num);
    }

    return Ok(res);
}
