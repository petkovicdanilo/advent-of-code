use std::collections::HashSet;

use crate::{Day, computer::Computer};

use anyhow::{Result, anyhow};

pub(crate) struct Day13 {
}

impl Day for Day13 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        let inputs = std::iter::empty();
        let output = computer.run(inputs)?;

        let mut res = 0;

        for chunk in output.outputs.chunks(3) {
            let _x = chunk[0];
            let _y = chunk[1];
            let tile_id: TileId = (chunk[2] as u8).try_into()?;

            if tile_id == TileId::Block {
                res += 1;
            }
        }

        println!("{res}");
        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;
        computer.memory.write(0, 2);

        let inputs = std::iter::empty();
        let output = computer.run(inputs)?;
        // println!("{:?}\n", output.outputs);

        let mut score = 0;
        let mut block_positions = HashSet::new();
        let mut paddle = (0, 0);
        let mut ball = (0, 0);

        for chunk in output.outputs.chunks(3) {
            // println!("{chunk:?}");
            let x = chunk[0];
            let y = chunk[1];
            if x == -1 && y == 0 {
                score = chunk[2];
            }
            else {
                let tile_id: TileId = (chunk[2] as u8).try_into()?;
                match tile_id {
                    TileId::Block => {
                        block_positions.insert((x, y));
                    },
                    TileId::HorizontalPaddle => {
                        paddle = (x, y);
                    },
                    TileId::Ball => {
                        ball = (x, y);
                    },
                    TileId::Empty | TileId::Wall => {},
                };
            }

        }

        while !block_positions.is_empty() {
            let joystik = if paddle.0 < ball.0 {
                Joystick::Right
            } else if paddle.0 > ball.0 {
                Joystick::Left
            } else {
                Joystick::Neutral
            };
            let joystick_val: i8 = joystik.into();

            let inputs = vec![joystick_val as i64].into_iter();
            let output = computer.run(inputs)?;
            // println!("{:?}\n", output.outputs);

            for chunk in output.outputs.chunks(3) {
                // println!("{chunk:?}");
                let x = chunk[0];
                let y = chunk[1];
                if x == -1 && y == 0 {
                    score = chunk[2];
                }
                else {
                    let tile_id: TileId = (chunk[2] as u8).try_into()?;

                    // if block has dissapeared.
                    if tile_id != TileId::Block {
                        if block_positions.contains(&(x, y)) {
                            block_positions.remove(&(x, y));
                        }
                    }

                    match tile_id {
                        TileId::HorizontalPaddle => {
                            paddle = (x, y);
                        },
                        TileId::Ball => {
                            ball = (x, y);
                        },
                        TileId::Empty | TileId::Wall | TileId::Block => {},
                    };
                }
            }
        }

        println!("{score}");

        return Ok(());
    }
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq)]
enum TileId {
    Empty = 0,
    Wall = 1,
    Block = 2,
    HorizontalPaddle = 3,
    Ball = 4,
}

impl TryFrom<u8> for TileId {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> std::result::Result<Self, Self::Error> {
        return match value {
            0 => Ok(TileId::Empty),
            1 => Ok(TileId::Wall),
            2 => Ok(TileId::Block),
            3 => Ok(TileId::HorizontalPaddle),
            4 => Ok(TileId::Ball),
            v => Err(anyhow!("Invalid tile id `{v}`")),
        };
    }
}

enum Joystick {
    Neutral,
    Left,
    Right,
}

impl From<Joystick> for i8 {
    fn from(value: Joystick) -> Self {
        return match value {
            Joystick::Neutral => 0,
            Joystick::Left => -1,
            Joystick::Right => 1,
        };
    }
}
