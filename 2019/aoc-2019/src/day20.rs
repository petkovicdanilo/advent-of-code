use std::{cmp::{Ordering, Reverse}, collections::{BinaryHeap, HashMap}, fs};

use anyhow::{Context, Result, bail};

use crate::Day;

pub(crate) struct Day20 {
}

impl Day for Day20 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let input = parse_input(input_file)?;
        // println!("{input:?}");
        // for row in &input.mat {
        //     for field in row {
        //         let el = match field {
        //             Field::Wall => "#",
        //             Field::Empty => ".",
        //             Field::Portal(portal) => &portal,
        //         };
        //         print!("{el:2}");
        //     }
        //     println!();
        // }
        // println!("start = {:?}, end = {:?}", &input.start, &input.end);
        // println!("{:?}", &input.portals);

        let res = dijkstra(&input)?;
        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let input = parse_input(input_file)?;

        let res = dijkstra2(&input)?;
        println!("{res}");

        return Ok(());
    }
}

fn dijkstra(input: &Input) -> Result<usize> {
    let mut priority_queue = BinaryHeap::new();
    let mut dist_map = HashMap::new();

    let rows = input.mat.len();
    let cols = input.mat[0].len();

    priority_queue.push(
        Reverse(
            HeapNode {
                dist: 0, pos: input.start, level: 0,
            }
        )
    );
    dist_map.insert(input.start, 0);

    while priority_queue.len() != 0 {
        let Reverse(HeapNode { dist, pos, level: _ }) = priority_queue.pop().unwrap();
        // println!("checking {pos:?} with dist {dist}");

        if *dist_map.get(&pos).unwrap() < dist {
            continue;
        }

        if let Field::Portal(portal) = &input.mat[pos.0][pos.1] && 
            *portal != String::from("AA") && *portal != String::from("ZZ") {
            // println!("at portal {portal}");
            let next_pos = input.jump_portal(portal, &pos)?;
            let curr_dist = dist_map.entry(next_pos).or_insert(usize::MAX);
            if dist + 1 < *curr_dist {
                *curr_dist = dist + 1;
                priority_queue.push(
                    Reverse(
                        HeapNode {
                            dist: dist + 1, pos: next_pos, level: 0,
                        }
                    )
                );
            }
        };

        for (dr, dc) in STEPS {
            let next_r = pos.0 as isize + dr;
            let next_c = pos.1 as isize + dc;

            if !in_bounds((next_r, next_c), rows, cols) {
                continue;
            }

            let next_r = next_r as usize;
            let next_c = next_c as usize;

            let next_field = &input.mat[next_r][next_c];

            if *next_field == Field::Wall {
                continue;
            }

            let next_pos = (next_r, next_c);
            let curr_dist = dist_map.entry(next_pos).or_insert(usize::MAX);
            if dist + 1 < *curr_dist {
                *curr_dist = dist + 1;
                priority_queue.push(
                    Reverse(
                        HeapNode {
                            dist: dist + 1, pos: next_pos, level: 0,
                        }
                    )
                );
            }
        }
    }

    // println!("{dist_map:?}");

    let res = dist_map.get(&input.end)
        .context("Couldn't find distance to exit")?;

    return Ok(*res);
}

fn dijkstra2(input: &Input) -> Result<usize> {
    let mut priority_queue = BinaryHeap::new();
    let mut dist_map = HashMap::new();

    let rows = input.mat.len();
    let cols = input.mat[0].len();

    priority_queue.push(
        Reverse(
            HeapNode {
                dist: 0, pos: input.start, level: 0,
            }
        )
    );
    dist_map.insert((input.start, 0), 0);

    while priority_queue.len() != 0 {
        let Reverse(HeapNode { dist, pos, level }) = priority_queue.pop().unwrap();
        // println!("checking {pos:?} with dist {dist} on level {level}");

        if *dist_map.get(&(pos, level)).unwrap() < dist {
            continue;
        }

        if pos == input.end && level == 0 {
            break;
        }

        if let Field::Portal(portal) = &input.mat[pos.0][pos.1] && 
            *portal != String::from("AA") && *portal != String::from("ZZ") {
            // println!("at portal {portal}");
            let next_level = if is_outer_portal(pos, rows, cols) {
                // println!("is outer portal");
                if level == 0 {
                    // println!("level is 0 and ");
                    continue;
                }
                level - 1
            } else {
                level + 1
            };

            let next_pos = input.jump_portal(portal, &pos)?;
            let curr_dist = dist_map.entry((next_pos, next_level)).or_insert(usize::MAX);
            if dist + 1 < *curr_dist {
                *curr_dist = dist + 1;
                priority_queue.push(
                    Reverse(
                        HeapNode {
                            dist: dist + 1, pos: next_pos, level: next_level,
                        }
                    )
                );
            }
        };

        for (dr, dc) in STEPS {
            let next_r = pos.0 as isize + dr;
            let next_c = pos.1 as isize + dc;

            if !in_bounds((next_r, next_c), rows, cols) {
                continue;
            }

            let next_r = next_r as usize;
            let next_c = next_c as usize;

            let next_field = &input.mat[next_r][next_c];

            if *next_field == Field::Wall {
                continue;
            }

            if (next_r, next_c) == input.start || (next_r, next_c) == input.end && level != 0 {
                continue
            }

            let next_pos = (next_r, next_c);
            let curr_dist = dist_map.entry((next_pos, level)).or_insert(usize::MAX);
            if dist + 1 < *curr_dist {
                *curr_dist = dist + 1;
                priority_queue.push(
                    Reverse(
                        HeapNode {
                            dist: dist + 1, pos: next_pos, level,
                        }
                    )
                );
            }
        }
    }

    // println!("{dist_map:?}");

    let res = dist_map.get(&(input.end, 0))
        .context("Couldn't find distance to exit")?;

    return Ok(*res);
}

#[derive(Debug, PartialEq, Eq)]
struct HeapNode {
    dist: usize,
    pos: Position,
    level: usize,
}

impl Ord for HeapNode {
    fn cmp(&self, other: &Self) -> Ordering {
        let dist_cmp = self.dist.cmp(&other.dist);
        if let Ordering::Equal = dist_cmp {
            return self.level.cmp(&other.level);
        }
        return dist_cmp;
    }
}

impl PartialOrd for HeapNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        return Some(self.cmp(other));
    }
}

type Position = (usize, usize);

#[derive(Debug)]
struct Input {
    mat: Vec<Vec<Field>>,
    portals: HashMap<String, (Position, Position)>,
    start: Position,
    end: Position,
}

impl Input {
    fn jump_portal(&self, portal: &String, pos: &Position) -> Result<Position> {
        if let Some((pos1, pos2)) = self.portals.get(portal) {
            if pos1 == pos {
                return Ok(*pos2);
            } else if pos2 == pos {
                return Ok(*pos1);
            } else {
                bail!("Invalid pos provided for portal {portal}");
            }
        } 

        bail!("Couldn't find portal {portal}");
    }
}

#[derive(Debug, Eq, PartialEq)]
enum Field {
    Wall,
    Empty,
    Portal(String),
}

const STEPS: [(isize, isize); 4] = [(0, -1), (-1, 0), (0, 1), (1, 0)];

fn parse_input(input_file: String) -> Result<Input> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut input_mat = Vec::new();
    for line in contents.lines() {
        let mut row = Vec::new();
        for ch in line.chars() {
            if ch == ' ' {
                row.push('#');
                continue;
            }

            row.push(ch);
        }
        input_mat.push(row);
    }

    let rows = input_mat.len();
    let cols = input_mat[0].len();

    let mut mat = Vec::with_capacity(rows);
    for _ in 0..rows {
        let mut row = Vec::with_capacity(cols);
        for _ in 0..cols {
            row.push(Field::Empty);
        }
        mat.push(row);
    }

    let mut portals_map: HashMap<String, Vec<Position>> = HashMap::new();
    let mut start = (0, 0);
    let mut end = (0, 0);

    for (r, input_row) in input_mat.iter().enumerate() {
        for (c, field) in input_row.iter().enumerate() {
            if mat[r][c] != Field::Empty {
                continue;
            }

            if *field == '.' {
                mat[r][c] = Field::Empty;
                continue;
            }
            if *field == '#' {
                mat[r][c] = Field::Wall;
                continue;
            }

            let first_letter = field;

            for (dr, dc) in [(0, 1), (1, 0)] {
                let second_letter_r = r as isize + dr;
                let second_letter_c = c as isize + dc;

                if !in_bounds((second_letter_r, second_letter_c), rows, cols) {
                    continue;
                }

                let second_letter_r = second_letter_r as usize;
                let second_letter_c = second_letter_c as usize;

                let second_letter = input_mat[second_letter_r][second_letter_c];

                if !second_letter.is_uppercase() {
                    continue;
                }

                let portal = format!("{first_letter}{second_letter}");

                let mut empty_r = second_letter_r as isize + dr;
                let mut empty_c = second_letter_c as isize + dc;

                let entrance_pos = if in_bounds((empty_r, empty_c), rows, cols) && input_mat[empty_r as usize][empty_c as usize] == '.' {
                    // entry at second letter
                    (empty_r as usize, empty_c as usize)
                } else {
                    // entry at first ltter
                    empty_r = r as isize + (-dr);
                    empty_c = c as isize + (-dc);
                    if !in_bounds((empty_r, empty_c), rows, cols) || input_mat[empty_r as usize][empty_c as usize] != '.' {
                        bail!("Couldn't find entrance to portal {portal}");
                    }
                    (empty_r as usize, empty_c as usize)
                };

                mat[r][c] = Field::Wall;
                mat[second_letter_r][second_letter_c] = Field::Wall;
                
                if portal == String::from("AA") {
                    start = entrance_pos;
                }

                if portal == String::from("ZZ") {
                    end = entrance_pos;
                }

                mat[entrance_pos.0][entrance_pos.1] = Field::Portal(portal.clone());
                if portal == String::from("AA") || portal == String::from("ZZ") {
                    break;
                }

                let entry = portals_map.entry(portal.clone()).or_default();
                if entry.len() == 2 {
                    bail!("Found more than 2 points for portal {portal}");
                }
                entry.push(entrance_pos);

                break;
            }
        }
    }

    let mut portals = HashMap::new();
    for (portal, pos_vec) in portals_map {
        if pos_vec.len() != 2 {
            bail!("Couldn't find both ends for portal {portal}");
        }
        portals.insert(portal, (pos_vec[0], pos_vec[1]));
    }

    return Ok(Input { mat, portals, start, end });
}

fn in_bounds(pos: (isize, isize), rows: usize, cols: usize) -> bool {
    let (r, c) = pos;
    if r < 0 || r >= rows as isize || c < 0 || c >= cols as isize {
        return false;
    }
    return true;
}

fn is_outer_portal(pos: Position, rows: usize, cols: usize) -> bool {
    for (dr, dc) in STEPS {
        let dr = 3*dr;
        let dc = 3*dc;

        if !in_bounds((pos.0 as isize + dr, pos.1 as isize + dc), rows, cols) {
            return true;
        }
    }

    return false;
}
