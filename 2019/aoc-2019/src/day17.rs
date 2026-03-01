use std::fmt::Display;

use anyhow::{Result, bail};

use crate::{Day, computer::{Computer, Status}};

pub(crate) struct Day17 {
}

impl Day for Day17 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let view = parse_input(&input_file)?;
        // println!("view={view:?}");

        let rows = view.view.len();
        let cols = view.view[0].len();

        let mut res = 0;

        for r in 0..rows {
            for c in 0..cols {
                if view.view[r][c] != Tile::Scaffold {
                    continue;
                }
                
                let mut is_intersection = true;

                for dir in vec![
                    Direction::Up,
                    Direction::Right,
                    Direction::Down,
                    Direction::Left] {

                    match neighbour((r, c), &dir, (rows, cols)) {
                        Some(n) => {
                            if view.view[n.0][n.1] == Tile::Open {
                                is_intersection = false;
                                break;
                            }
                        },
                        None => {
                            is_intersection = false;
                            break;
                        },
                    }
                }

                if is_intersection {
                    // println!("Intersection at ({r}, {c})");
                    res += r * c;
                }
            }
        }

        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let view = parse_input(&input_file)?;

        let rows = view.view.len();
        let cols = view.view[0].len();

        let mut r = view.robot_r;
        let mut c = view.robot_c;
        let mut dir = view.robot_dir;

        loop {
            let mut steps = 0;

            let new_dir = dir.turn_left();
            if let Some(n) = neighbour((r, c), &new_dir, (rows, cols)) &&
                    view.view[n.0][n.1] == Tile::Scaffold {
                r = n.0;
                c = n.1;
                dir = new_dir;
                print!("L,");
            } else {
                let new_dir = dir.turn_right();
                if let Some(n) = neighbour((r, c), &new_dir, (rows, cols)) && 
                        view.view[n.0][n.1] == Tile::Scaffold {
                    r = n.0;
                    c = n.1;
                    dir = new_dir;
                    print!("R,");
                } else {
                    break;
                }
            }
            steps += 1;

            while let Some(n) = neighbour((r, c), &dir, (rows, cols)) &&
                    view.view[n.0][n.1] == Tile::Scaffold {
                r = n.0;
                c = n.1;
                steps += 1;
            }

            print!("{steps},");
        }
        println!();

        // hardcoded this part for my input :(
        let input_str = r#"A,B,A,C,A,B,C,A,B,C
R,12,R,4,R,10,R,12
R,6,L,8,R,10
L,8,R,4,R,4,R,6
n
"#;
        println!("{input_str}");

        let input = input_str
            .chars()
            .map(|ch| ch as i64);

        let mut computer = Computer::from_file(&input_file)?;
        computer.memory.write(0, 2);
        let output = computer.run(input)?;
        println!("{:?}", output.outputs.iter().last().unwrap());

        return Ok(());
    }
}

fn neighbour(pos: (usize, usize), dir: &Direction, dim: (usize, usize)) -> Option<(usize, usize)> {
    let mut r = pos.0 as i32;
    let mut c = pos.1 as i32;

    match dir {
        Direction::Up => r -= 1,
        Direction::Down => r += 1,
        Direction::Right => c += 1,
        Direction::Left => c -= 1,
    };

    if r < 0 || r >= dim.0 as i32 || c < 0 || c >= dim.1 as i32 {
        return None;
    }

    return Some((r as usize, c as usize));
}

fn parse_input(input_file: &String) -> Result<View> {
    let mut computer = Computer::from_file(input_file)?;
    let input = std::iter::empty();

    let output = computer.run(input)?;

    if output.status != Status::Halted {
        bail!("Computer did not shut down properly");
    }

    for o in &output.outputs {
        if *o == 10 {
            println!();
        } else {
            print!("{}", *o as u8 as char);
        }
    }

    let mut view = Vec::new();
    let mut row = Vec::new();

    let mut robot_r = 0;
    let mut robot_c = 0;
    let mut robot_dir = Direction::Up;

    let mut r = 0;
    let mut c = 0;

    for o in output.outputs {
        if o as u8 as char == '\n' {
            if row.len() > 0 {
                view.push(row);
            }
            row = Vec::new();
            r += 1;
            c = 0;
            continue;
        }

        let tile = match o as u8 as char {
            '#' => Tile::Scaffold,
            '.' => Tile::Open,
            '^' => {
                robot_r = r;
                robot_c = c;
                robot_dir = Direction::Up;
                Tile::Open
            },
            'v' => {
                robot_r = r;
                robot_c = c;
                robot_dir = Direction::Down;
                Tile::Open
            },
            '<' => {
                robot_r = r;
                robot_c = c;
                robot_dir = Direction::Left;
                Tile::Open
            },
            '>' => {
                robot_r = r;
                robot_c = c;
                robot_dir = Direction::Right;
                Tile::Open
            },
            c => bail!(format!("Invalid character '{c}' found.")),
        };
        row.push(tile);

        c += 1;
    }

    return Ok(View { view, robot_r, robot_c, robot_dir });
}

#[derive(Debug)]
struct View {
    view: Vec<Vec<Tile>>,
    robot_r: usize,
    robot_c: usize,
    robot_dir: Direction,
}

#[derive(Debug, Eq, PartialEq)]
enum Tile {
    Scaffold,
    Open,
}

#[derive(Debug)]
enum Direction {
    Up,
    Right,
    Down,
    Left,
}

impl Direction {
    fn turn_left(&self) -> Direction {
        return match self {
            Direction::Up => Direction::Left,
            Direction::Right => Direction::Up,
            Direction::Down => Direction::Right,
            Direction::Left => Direction::Down,
        };
    }

    fn turn_right(&mut self) -> Direction {
        return match self {
            Direction::Up => Direction::Right,
            Direction::Right => Direction::Down,
            Direction::Down => Direction::Left,
            Direction::Left => Direction::Up,
        };
    }
}

impl Display for Direction {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let c = match self {
            Direction::Up => "U",
            Direction::Right => "R",
            Direction::Down => "D",
            Direction::Left => "L",
        };
        return write!(f, "{c}");
    }
}
