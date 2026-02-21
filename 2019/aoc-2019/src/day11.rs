use std::collections::HashMap;

use crate::{Day, computer::{Computer, Status}};

use anyhow::{Result, anyhow, bail};

pub(crate) struct Day11 {
}

impl Day for Day11 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let mut dir = Direction::Up;
        let mut panels = HashMap::new();
        let mut x: i32 = 0;
        let mut y: i32 = 0;
        loop {
            let curr_color = panels.get(&(x, y)).unwrap_or(&Color::Black);
            let input = match curr_color {
                Color::Black => vec![0].into_iter(),
                Color::White => vec![1].into_iter(),
            };
            let output = computer.run(input)?;
            match output.status {
                Status::Halted => {
                    break;
                },
                Status::PausedForInput => {
                    if output.outputs.len() == 0 {
                        continue;
                    }

                    if output.outputs.len() != 2 {
                        bail!("Unexpected output '{:?}'", output.outputs);
                    }

                    let color: Color = output.outputs[0].try_into()?;
                    let dir_out = output.outputs[1];
                    if dir_out != 0 && dir_out != 1 {
                        bail!("Invalid rotate direction `{dir_out}`");
                    }
                    let rotate_dir = if dir_out == 0 { 
                        RotateDirection::Left
                    } else {
                        RotateDirection::Right
                    };

                    panels.insert((x, y), color);
                    dir = rotated(&dir, &rotate_dir);
                    move_robot(&mut x, &mut y, &dir);
                },
            }
        }

        println!("{}", panels.len());

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let mut dir = Direction::Up;
        let mut panels = HashMap::new();
        let mut x: i32 = 0;
        let mut y: i32 = 0;
        loop {
            let curr_color = panels.get(&(x, y)).unwrap_or_else(|| {
                if panels.len() == 0 {
                    // first one
                    &Color::White
                } else {
                    &Color::Black
                }
            });
            let input = match curr_color {
                Color::Black => vec![0].into_iter(),
                Color::White => vec![1].into_iter(),
            };
            let output = computer.run(input)?;
            match output.status {
                Status::Halted => {
                    break;
                },
                Status::PausedForInput => {
                    if output.outputs.len() == 0 {
                        continue;
                    }

                    if output.outputs.len() != 2 {
                        bail!("Unexpected output '{:?}'", output.outputs);
                    }

                    let color: Color = output.outputs[0].try_into()?;
                    let dir_out = output.outputs[1];
                    if dir_out != 0 && dir_out != 1 {
                        bail!("Invalid rotate direction `{dir_out}`");
                    }
                    let rotate_dir = if dir_out == 0 { 
                        RotateDirection::Left
                    } else {
                        RotateDirection::Right
                    };

                    panels.insert((x, y), color);
                    dir = rotated(&dir, &rotate_dir);
                    move_robot(&mut x, &mut y, &dir);
                },
            }
        }

        let min_r = panels.iter().min_by(|a, b| a.0.0.cmp(&b.0.0)).unwrap().0.0;
        let max_r = panels.iter().max_by(|a, b| a.0.0.cmp(&b.0.0)).unwrap().0.0;
        let min_c = panels.iter().min_by(|a, b| a.0.1.cmp(&b.0.1)).unwrap().0.1;
        let max_c = panels.iter().max_by(|a, b| a.0.1.cmp(&b.0.1)).unwrap().0.1;

        for r in min_r..=max_r {
            for c in min_c..=max_c {
                let color = if let Some(col) = panels.get(&(r, c)) {
                    col
                } else {
                    if r == 0 && c == 0 {
                        &Color::White
                    } else {
                        &Color::Black
                    }
                };

                match color {
                    Color::Black => print!(" "),
                    Color::White => print!("#"),
                };
            }
            println!();
        }

        return Ok(());
    }
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq)]
enum Color  {
    Black = 0,
    White = 1,
}

impl TryFrom<i64> for Color {
    type Error = anyhow::Error;

    fn try_from(value: i64) -> std::result::Result<Self, Self::Error> {
        return match value {
            0 => Ok(Self::Black),
            1 => Ok(Self::White),
            c => Err(anyhow!("Invalid value `{c}` for color")),
        };
    }
}

enum Direction {
    Up,
    Right,
    Down,
    Left
}

enum RotateDirection {
    Left,
    Right,
}

fn rotated(d: &Direction, r: &RotateDirection) -> Direction {
    match (r, d) {
        (RotateDirection::Left, Direction::Up) => Direction::Left,
        (RotateDirection::Left, Direction::Right) => Direction::Up,
        (RotateDirection::Left, Direction::Down) => Direction::Right,
        (RotateDirection::Left, Direction::Left) => Direction::Down,
        (RotateDirection::Right, Direction::Up) => Direction::Right,
        (RotateDirection::Right, Direction::Right) => Direction::Down,
        (RotateDirection::Right, Direction::Down) => Direction::Left,
        (RotateDirection::Right, Direction::Left) => Direction::Up,
    }
}

fn move_robot(x: &mut i32, y: &mut i32, dir: &Direction) {
    match dir {
        Direction::Up => {
            *x -= 1;
        },
        Direction::Right => {
            *y += 1;
        },
        Direction::Down => {
            *x += 1;
        },
        Direction::Left => {
            *y -= 1;
        },
    }
}
