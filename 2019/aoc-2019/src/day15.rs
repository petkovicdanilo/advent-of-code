use std::collections::{HashMap, HashSet, VecDeque};

use crate::{Day, computer::{self, Computer}};

use anyhow::{Context, Result, anyhow, bail};

pub(crate) struct Day15 {
}

impl Day for Day15 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let mut field_map = HashMap::new();

        let (oxygen_r, oxygen_c) = traverse_map(&mut computer, &mut field_map)?;
        // println!("Oxygen at ({oxygen_r}, {oxygen_c})");
        // print_map(&mut field_map, oxygen_r, oxygen_c);

        let res = find_shortest_path(&field_map, (0, 0), (oxygen_r, oxygen_c))?;
        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut computer = Computer::from_file(&input_file)?;

        let mut field_map = HashMap::new();

        let (oxygen_r, oxygen_c) = traverse_map(&mut computer, &mut field_map)?;

        let res = flood_map(&field_map, (oxygen_r, oxygen_c))?;
        println!("{res}");

        return Ok(());
    }
}

fn traverse_map(computer: &mut Computer, field_map: &mut HashMap<(i32, i32), bool>) -> Result<(i32, i32)> {
    let mut movement = Movement::North;

    // let mut min_r = i32::MAX;
    // let mut min_c = i32::MAX;
    // let mut max_r = i32::MIN;
    // let mut max_c = i32::MIN;

    let mut r = 0;
    let mut c = 0;

    let mut oxygen_pos = None;

    loop {
        // println!("({r}, {c})");

        // if r < min_r {
        //     min_r = r;
        // }
        // if r > max_r {
        //     max_r = r;
        // }
        //
        // if c < min_c {
        //     min_c = c;
        // }
        // if c > max_c {
        //     max_c = c;
        // }

        let new_pos = move_position((r, c), &movement);
        let mut new_r = new_pos.0;
        let mut new_c = new_pos.1;

        while let Some(val) = field_map.get(&(new_r, new_c)) && !val {
            movement = movement.turn_right();
            let new_pos = move_position((r, c), &movement);
            new_r = new_pos.0;
            new_c = new_pos.1;
        }

        let movement_input: u8 = (&movement).into();
        // println!("Input movement {movement:?}");
        let input = vec![movement_input as i64].into_iter();

        let output = computer.run(input)?;

        if output.status == computer::Status::Halted {
            bail!("Computer program terminated unexpectedly.");
        }

        let movement_status = (output.outputs[0] as u8).try_into()?;
        // println!("got output {movement_status:?}");
        match movement_status {
            Status::Moved => {
                field_map.insert((new_r, new_c), true);
                r = new_r;
                c = new_c;
                movement = movement.turn_left();
            },
            Status::HitWall => {
                field_map.insert((new_r, new_c), false);
                movement = movement.turn_right();
            },
            Status::FoundOxygenSystem => {
                field_map.insert((new_r, new_c), true);
                oxygen_pos = Some((new_r, new_c));
                r = new_r;
                c = new_c;
                movement = movement.turn_left();
            },
        };

        if r == 0 && c == 0 && oxygen_pos.is_some() {
            break;
        }
    };

    if oxygen_pos.is_none() {
        bail!("Couldn't find oxygen system");
    }

    // println!("min_r={min_r}, max_r={max_r}");
    // println!("min_c={min_c}, max_c={max_c}");

    return Ok(oxygen_pos.unwrap())
}

// fn print_map(field_map: &mut HashMap<(i32, i32), bool>, oxygen_r: i32, oxygen_c: i32) {
//     const DIM: usize = 40;
//     let mut mat = [[false; DIM]; DIM];
//     for i in 0..DIM {
//         let map_i = i as i32 - 20;
//         for j in 0..DIM {
//             let map_j = j as i32 - 20;
//             if let Some(val) = field_map.get(&(map_i, map_j)) && *val {
//                 mat[i][j] = true;
//             }
//         }
//     }
//
//     for i in 0..DIM {
//         let map_i = i as i32 - 20;
//         for j in 0..DIM {
//             let map_j = j as i32 - 20;
//             if map_i == 0 && map_j == 0 {
//                 print!("s");
//             } else if map_i == oxygen_r && map_j == oxygen_c {
//                 print!("e");
//             } else if mat[i][j] {
//                 print!(".");
//             } else {
//                 print!("#");
//             }
//         }
//         println!();
//     }
// }

fn find_shortest_path(
    field_map: &HashMap<(i32, i32), bool>,
    start: (i32, i32),
    end: (i32, i32)) -> Result<u32> {

    let mut queue = VecDeque::new();
    queue.push_back((start, 0));

    let mut visited = HashSet::new();
    visited.insert((0, 0));

    let mut res = None;

    while queue.len() > 0 {
        let (pos, dist) = queue.pop_front().unwrap();

        if pos == end {
            res = Some(dist);
            break;
        }

        for i in 1..=4 {
            let movement = i.try_into()?;
            let new_pos = move_position(pos, &movement);

            let field = field_map.get(&new_pos);
            if field.is_none() || !*field.unwrap() {
                continue;
            }

            if visited.contains(&new_pos) {
                continue;
            }

            visited.insert(new_pos);
            queue.push_back((new_pos, dist + 1));
        }

    }

    let res = res.context("Couldn't find shortest path to oxygen system")?;
    return Ok(res);
}

fn flood_map(field_map: &HashMap<(i32, i32), bool>, start: (i32, i32)) -> Result<u32> {
    let mut queue = VecDeque::new();
    queue.push_back((start, 0));

    let mut visited = HashSet::new();
    visited.insert((0, 0));

    let mut res = 0;

    while queue.len() > 0 {
        let (pos, dist) = queue.pop_front().unwrap();
        if dist > res {
            res = dist;
        }

        for i in 1..=4 {
            let movement = i.try_into()?;
            let new_pos = move_position(pos, &movement);

            let field = field_map.get(&new_pos);
            if field.is_none() || !*field.unwrap() {
                continue;
            }

            if visited.contains(&new_pos) {
                continue;
            }

            visited.insert(new_pos);
            queue.push_back((new_pos, dist + 1));
        }

    }

    return Ok(res);
}

fn move_position(pos: (i32, i32), m: &Movement) -> (i32, i32) {
    return match m {
        Movement::North => (pos.0 - 1, pos.1),
        Movement::South => (pos.0 + 1, pos.1),
        Movement::West => (pos.0, pos.1 - 1),
        Movement::East => (pos.0, pos.1 + 1),
    };
}

#[repr(u8)]
#[derive(Clone, Debug, Eq, PartialEq)]
enum Movement {
    North = 1,
    South = 2,
    West = 3,
    East = 4,
}

impl Movement {
    fn turn_left(&self) -> Movement {
        return match self {
            Movement::North => Movement::West,
            Movement::South => Movement::East,
            Movement::West => Movement::South,
            Movement::East => Movement::North,
        };
    }

    fn turn_right(&self) -> Movement {
        return match self {
            Movement::North => Movement::East,
            Movement::South => Movement::West,
            Movement::West => Movement::North,
            Movement::East => Movement::South,
        };
    }
}

impl TryFrom<u8> for Movement {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> std::result::Result<Self, Self::Error> {
        return match value {
            1 => Ok(Movement::North),
            2 => Ok(Movement::South),
            3 => Ok(Movement::West),
            4 => Ok(Movement::East),
            m => Err(anyhow!("Invalid movement `{m}`")),
        };
    }
}

impl From<&Movement> for u8 {
    fn from(value: &Movement) -> Self {
        return match value {
            Movement::North => 1,
            Movement::South => 2,
            Movement::West => 3,
            Movement::East => 4,
        };
    }
}

#[repr(u8)]
#[derive(Debug, Eq, PartialEq)]
enum Status {
    HitWall = 0,
    Moved = 1,
    FoundOxygenSystem = 2,
}

impl TryFrom<u8> for Status {
    type Error = anyhow::Error;

    fn try_from(value: u8) -> std::result::Result<Self, Self::Error> {
        return match value {
            0 => Ok(Status::HitWall),
            1 => Ok(Status::Moved),
            2 => Ok(Status::FoundOxygenSystem),
            s => Err(anyhow!("Invalid status `{s}`")),
        };
    }
}
