use std::{collections::{HashMap, HashSet}, fs};

use crate::Day;

use anyhow::{anyhow, Context, Result};

pub(crate) struct Day10 {
}

impl Day for Day10 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let input = parse_input(input_file)?;
        // println!("{input:#?}");
        
        let mut asteroids = Vec::new();

        for (r, row) in input.iter().enumerate() {
            for (c, pos) in row.iter().enumerate() {
                if *pos == Position::Asteriod {
                    asteroids.push((c, r));
                }
            }
        }
        // println!("{asteroids:?}");

        let mut asteroids_visible = HashMap::<(usize, usize), u32>::new();

        for i in 0..asteroids.len() - 1 {
            for j in (i+1)..asteroids.len() {
                let first = &asteroids[i];
                let second = &asteroids[j];
                if has_line_of_sight(&input, first, second) {
                    asteroids_visible.entry(first.clone())
                        .and_modify(|e| *e += 1)
                        .or_insert(1);
                    asteroids_visible.entry(second.clone())
                        .and_modify(|e| *e += 1)
                        .or_insert(1);
                }
            }
        }

        // println!("{asteroids_visible:?}");
        let res = asteroids_visible
            .values()
            .max()
            .ok_or(anyhow!("Failed to find asteroid with most visible other asteroids"))?;

        println!("{res}");
        
        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut input = parse_input(input_file)?;
        // println!("{input:#?}");
        
        let mut asteroids = Vec::new();

        for (r, row) in input.iter().enumerate() {
            for (c, pos) in row.iter().enumerate() {
                if *pos == Position::Asteriod {
                    asteroids.push((c, r));
                }
            }
        }
        // println!("{asteroids:?}");

        let mut asteroids_visible = HashMap::<(usize, usize), u32>::new();

        for i in 0..asteroids.len() - 1 {
            for j in (i+1)..asteroids.len() {
                let first = &asteroids[i];
                let second = &asteroids[j];
                if has_line_of_sight(&input, first, second) {
                    asteroids_visible.entry(first.clone())
                        .and_modify(|e| *e += 1)
                        .or_insert(1);
                    asteroids_visible.entry(second.clone())
                        .and_modify(|e| *e += 1)
                        .or_insert(1);
                }
            }
        }

        // println!("{asteroids_visible:?}");
        let vis_max = asteroids_visible
            .values()
            .max()
            .ok_or(anyhow!("Failed to find asteroid with most visible other asteroids"))?;

        let laser = asteroids_visible.iter()
            .filter(|(_, v)| *v == vis_max )
            .next().unwrap().0.clone();
        // println!("laser = {laser:?}");

        let mut asteroids: HashSet<_> = asteroids.into_iter().collect();
        asteroids.remove(&laser);
        let mut counter = 0;
        let res = 
            'outer:
            loop {
                let mut other_visible = Vec::new();
                for a in &asteroids {
                    if has_line_of_sight(&input, &laser, &a) {
                        let theta = (a.0 as f32 - laser.0 as f32).atan2(a.1 as f32 - laser.1 as f32);
                        other_visible.push((a.clone(), theta));
                    }
                }

                for (a, _) in &other_visible {
                    input[a.1][a.0] = Position::Empty;
                    asteroids.remove(&a);
                }

                other_visible.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap().reverse());
                for (a, _) in &other_visible {
                    counter += 1;
                    // println!("{counter}: {a:?}");
                    if counter == 200 {
                        break 'outer a.clone();
                    }
                }
            };

        println!("{}", res.0 * 100 + res.1);

        return Ok(());
    }
} 

#[derive(Debug, Eq, PartialEq)]
enum Position {
    Empty,
    Asteriod,
}

impl TryFrom<char> for Position {
    type Error = anyhow::Error;

    fn try_from(value: char) -> std::result::Result<Self, Self::Error> {
        return match value {
            '.' => Ok(Position::Empty),
            '#' => Ok(Position::Asteriod),
            c => Err(anyhow!("Invalid char `{c}`")),
        };
    }
}

fn has_line_of_sight(mat: &Vec<Vec<Position>>, p1: &(usize, usize), p2: &(usize, usize)) -> bool {
    let (c1, r1) = p1;
    let (c2, r2) = p2;

    let dc = *c2 as i32 - *c1 as i32;
    let dr = *r2 as i32 - *r1 as i32;

    let g = if dc == 0 {
        dr.abs() as u32
    } else if dr == 0 {
        dc.abs() as u32
    } else {
        gcd(dc.abs() as u32, dr.abs() as u32)
    };

    if g == 1 {
        return true;
    }

    // println!("gcd = {g}");

    let dc = dc / g as i32;
    let dr = dr / g as i32;
    // println!("dc={dc}, dr={dr}");

    let mut c = *c1;
    let mut r = *r1;
    // println!("c={c}, r={r}");
    for _ in 1..g {
        c = (c as i32 + dc) as usize;
        r = (r as i32 + dr) as usize;
        // println!("c={c}, r={r}");
        if mat[r][c] == Position::Asteriod {
            return false;
        }
    }

    return true;
}

fn gcd(a: u32, b: u32) -> u32 {
    let mut a = a;
    let mut b = b;
    while b > 0 {
        let r = a % b;
        a = b;
        b = r;
    }
    return a;
}

fn parse_input(input_file: String) -> Result<Vec<Vec<Position>>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut res = Vec::new();

    for line in contents.lines() {
        let mut row = Vec::new();

        for c in line.chars() {
            let pos: Position = c.try_into()?;
            row.push(pos);
        }

        res.push(row);
    }

    return Ok(res);
}
