use std::fs;

use crate::Day;

use anyhow::{Context, Result};

const COLS: i32 = 25;
const ROWS: i32 = 6;

pub(crate) struct Day8 {
}

impl Day for Day8 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let layers = parse_input(input_file)?;

        let mut min_idx = 0;
        let mut min_val = u32::MAX;
        for (idx, layer) in layers.iter().enumerate() {
            let zero_count = layer
                .iter()
                .filter(|el| **el == 0)
                .count() as u32;
            if zero_count < min_val {
                min_val = zero_count;
                min_idx = idx;
            }
        }

        let layer = &layers[min_idx];
        let one_count: u32 = layer
            .iter()
            .filter(|el| **el == 1)
            .count() as u32;
        let two_count: u32 = layer
            .iter()
            .filter(|el| **el == 2)
            .count() as u32;

        let res = one_count * two_count;
        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let layers = parse_input(input_file)?;
        let n = (ROWS * COLS) as usize;

        let mut res = Vec::with_capacity(n);
        for i in 0..n {
            let mut layer_idx = 0;
            let mut color = 2; // transparent

            while layer_idx < layers.len() {
                let layer = &layers[layer_idx];
                if layer[i] != 2 {
                    color = layer[i];
                    break;
                }
                layer_idx += 1;
            }

            res.push(color);
        }

        for i in 0..n {
            if i != 0 && i % (COLS as usize) == 0 {
                print!("\n");
            }

            if res[i] == 1 {
                print!("#");
            } else {
                print!(" ");
            }
        }
        print!("\n");

        return Ok(());
    }
}

fn parse_input(input_file: String) -> Result<Vec<Vec<u8>>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;
    let contents = &contents[..contents.len() - 1];

    let mut ret = Vec::new();
    let mut curr_layer = Vec::new();

    for (i, c) in contents.chars().enumerate() {
        let num = c.to_digit(10)
            .context(format!("Invalid character `{c}` in the input"))?;
        let num = num as u8;
        if i != 0 && (i as i32) % (ROWS * COLS) == 0 {
            ret.push(curr_layer);
            curr_layer = Vec::new();
        }
        curr_layer.push(num);
    }
    ret.push(curr_layer);

    return Ok(ret);
}
