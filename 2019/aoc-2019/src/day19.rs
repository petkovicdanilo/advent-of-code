use std::{collections::HashMap, fs};

use anyhow::{Context, Result};

use crate::{Day, computer::Computer};

pub(crate) struct Day19 {
}

impl Day for Day19 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let computer = Computer::from_file(&input_file)?;
        let mut memo = HashMap::new();

        let mut res = 0;
        for y in 0..50 {
            for x in 0..50 {
                if check(computer.clone(), (y, x), &mut memo)? {
                    res += 1;
                }
            }
        }
        println!("{res}");
        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let computer = Computer::from_file(&input_file)?;
        let mut memo = HashMap::new();
        // let test_input = parse_test_input(input_file)?;

        const DIM: usize = 100;
        // const DIM: usize = 10;

        let mut y: usize = DIM - 1;
        let mut x: usize = y - 1;

        loop {
            while !check(computer.clone(), (y, x), &mut memo)? {
            // while !test_check(&test_input, (y, x)) {
                x += 1;
            }

            let y2 = y;
            let x1 = x;

            let x2 = x + DIM - 1;
            // bottom right
            if !check(computer.clone(), (y2, x2), &mut memo)? {
            // if !test_check(&test_input, (y2, x2)) {
                y += 1;
                continue;
            }

            let y1 = y as isize - DIM as isize + 1;
            if y1 < 0 {
                y += 1;
                continue;
            }
            let y1 = y1 as usize;

            // top left
            if !check(computer.clone(), (y1, x1), &mut memo)? {
            // if !test_check(&test_input, (y1, x1)) {
                y += 1;
                continue;
            }

            // top right
            if !check(computer.clone(), (y1, x2), &mut memo)? {
            // if !test_check(&test_input, (y1, x2)) {
                y += 1;
                continue;
            }

            y = y1;
            x = x1;
            break;
        }

        // println!("{y} {x}");
        let res = y * 10000 + x;
        println!("{res}");

        return Ok(());
    }
}

type Position = (usize, usize);

fn check(
    mut computer: Computer,
    pos: Position,
    memo: &mut HashMap<(usize, usize), bool>
) -> Result<bool> {
    if let Some(val) = memo.get(&pos) {
        return Ok(*val);
    }

    let input = [pos.0 as i64, pos.1 as i64].into_iter();
    let out = computer.run(input)?;

    if out.outputs[0] == 0 {
        memo.insert(pos, false);
        return Ok(false);
    }

    memo.insert(pos, true);
    return Ok(true);
}

fn _parse_test_input(input_file: String) -> Result<Vec<Vec<char>>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut res = Vec::new();
    for line in contents.lines() {
        let mut row = Vec::new();
        for ch in line.chars() {
            row.push(ch);
        }
        res.push(row);
    }

    return Ok(res);
}

fn _test_check(input: &Vec<Vec<char>>, pos: Position) -> bool {
    let el = input[pos.0][pos.1];
    if el == '#' {
        return true;
    }

    return false;
}
