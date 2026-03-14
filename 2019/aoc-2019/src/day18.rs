use std::{collections::{HashMap, HashSet, VecDeque}, fs};

use anyhow::{Context, Result};

use crate::Day;

pub(crate) struct Day18 {
}

impl Day for Day18 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let input = parse_input(input_file)?;
        // println!("{input:?}");
        // for row in &input.mat {
        //     for ch in row {
        //         print!("{ch:2}");
        //     }
        //     println!();
        // }

        let mut dist_map = DistanceMap::new();
        let distances = calc_min_dist_from(&input, input.start.clone());
        dist_map.insert(input.start.clone(), distances);

        for key_pos in input.keys.values() {
            let distances = calc_min_dist_from(&input, key_pos.to_owned());
            dist_map.insert(key_pos.to_owned(), distances);
        }
        
        let res = calc_min_dist(&input, &dist_map)?;
        println!("{res}");
        
        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut input = parse_input(input_file)?;

        let start = input.start;
        let mut curr_idx = 0;
        let mut starts = [(0, 0); 4];

        for dr in [1, 0, -1] {
            for dc in [1, 0, -1] {
                let r = (start.0 as isize + dr) as usize;
                let c = (start.1 as isize + dc) as usize;

                if dr.abs() == 1 && dc.abs() == 1 {
                    starts[curr_idx] = (r, c);
                    curr_idx += 1;
                    input.mat[r][c] = '.';
                } else {
                    input.mat[r][c] = '#';
                }
            }
        }

        // for row in &input.mat {
        //     for ch in row {
        //         print!("{ch:2}");
        //     }
        //     println!();
        // }

        // println!("{starts:?}");

        let mut dist_map = DistanceMap::new();
        for start in starts {
            let distances = calc_min_dist_from(&input, start);
            dist_map.insert(start, distances);
        }

        for key_pos in input.keys.values() {
            let distances = calc_min_dist_from(&input, key_pos.to_owned());
            dist_map.insert(key_pos.to_owned(), distances);
        }

        // println!("{dist_map:?}");

        let res = calc_min_dist2(&input, starts, &dist_map)?;
        println!("{res}");

        return Ok(());
    }
}

const STEPS: [(isize, isize); 4] = [(0, -1), (-1, 0), (0, 1), (1, 0)];

fn calc_min_dist(input: &Input, dist_map: &DistanceMap) -> Result<usize> {
    let mut queue = VecDeque::new();
    let mut memo = HashMap::new();

    let rows = input.mat.len();
    let cols = input.mat[0].len();

    queue.push_back((input.start, Bitmap::new(), 0 as usize));
    memo.insert((input.start, Bitmap::new()), 0 as usize);

    while queue.len() > 0 {
        let (pos, acquired_keys, dist) = queue.pop_front().unwrap();
        let distances = dist_map.get(&pos)
            .context(format!("Couldn't find dist_map entry for {pos:?}"))?;

        for (next_key, next_key_pos) in &input.keys {
            if acquired_keys.contains_key(*next_key) {
                continue;
            }

            let d = distances.get(&next_key_pos);
            if d.is_none() {
                continue;
            }
            let (key_dist, doors) = d.unwrap();

            let mut ok = true;
            for door in 'a'..'z' {
                if !doors.contains_key(door) {
                    continue;
                }

                if !acquired_keys.contains_key(door) {
                    ok = false;
                    break;
                }
            }

            if !ok {
                continue;
            }

            let mut next_acquired_keys = acquired_keys;
            next_acquired_keys.add_key(*next_key);

            let min_dist = memo.entry((*next_key_pos, next_acquired_keys))
                .or_insert(usize::MAX);
            let next_dist = dist + key_dist;

            if *min_dist > next_dist {
                *min_dist = next_dist;
                queue.push_back((*next_key_pos, next_acquired_keys, next_dist));
            }
        }
    }

    // println!("{memo:?}");

    let mut all_keys = Bitmap::new();
    for key in input.keys.keys() {
        all_keys.add_key(*key);
    }
    // println!("{all_keys:?}");

    let mut min_dist = usize::MAX;
    for r in 0..rows {
        for c in 0..cols {
            if let Some(dist) = memo.get(&((r, c), all_keys)) && min_dist > *dist {
                min_dist = *dist;
            }
        }
    }

    return Ok(min_dist);
}

#[derive(Clone)]
struct State {
    positions: [(usize, usize); 4],
    acquired_keys: Bitmap,
    dist: usize,
}

#[derive(Eq, PartialEq, Hash)]
struct MemoKey {
    positions: [(usize, usize); 4],
    acquired_keys: Bitmap,
}

type Position = (usize, usize);

type Distances = HashMap<Position, (usize, Bitmap)>;
type DistanceMap = HashMap<Position, Distances>;

fn calc_min_dist2(
    input: &Input,
    starts: [Position; 4],
    dist_map: &DistanceMap,
) -> Result<usize> {
    let mut queue = VecDeque::new();
    let mut memo = HashMap::new();

    queue.push_back(State {
        positions: starts.clone(),
        acquired_keys: Bitmap::new(),
        dist: 0,
    });
    memo.insert(MemoKey {
        positions: starts.clone(),
        acquired_keys: Bitmap::new(),
    }, 0 as usize);

    while queue.len() > 0 {
        let state = queue.pop_front().unwrap();

        for (i, pos) in state.positions.iter().enumerate() {
            let distances = dist_map.get(pos)
                .context(format!("Couldn't find dist_map entry for {pos:?}"))?;

            for (next_key, next_key_pos) in &input.keys {
                if state.acquired_keys.contains_key(*next_key) {
                    continue;
                }
                
                let d = distances.get(&next_key_pos);
                if d.is_none() {
                    continue;
                }
                let (dist, doors) = d.unwrap();

                let mut ok = true;
                for door in 'a'..'z' {
                    if !doors.contains_key(door) {
                        continue;
                    }

                    if !state.acquired_keys.contains_key(door) {
                        ok = false;
                        break;
                    }
                }

                if !ok {
                    continue;
                }

                let mut next_state = state.clone();
                next_state.positions[i] = *next_key_pos;
                next_state.acquired_keys.add_key(*next_key);

                let min_dist = memo.entry(MemoKey {
                    positions: next_state.positions.clone(),
                    acquired_keys: next_state.acquired_keys,
                }).or_insert(usize::MAX);
                let next_dist = state.dist + dist;

                if *min_dist > next_dist {
                    *min_dist = next_dist;
                    next_state.dist = next_dist;
                    queue.push_back(next_state);
                }
            }
        }
    }

    // println!("{memo:?}");

    let mut all_keys = Bitmap::new();
    for key in input.keys.keys() {
        all_keys.add_key(*key);
    }
    // println!("{all_keys:?}");

    let mut min_dist = usize::MAX;
    for (k, dist) in memo {
        if k.acquired_keys != all_keys {
            continue;
        }
        if min_dist > dist {
            min_dist = dist;
        }
    }

    return Ok(min_dist);
}

#[derive(Copy, Clone, Debug, Hash, Eq, PartialEq)]
struct Bitmap(u32);

impl Bitmap {
    fn new() -> Self {
        return Self(0);
    }

    fn contains_key(&self, key: char) -> bool {
        let idx = key as usize - 'a' as usize;
        return (self.0 & (1 << idx)) != 0;
    }

    fn add_key(&mut self, key: char) {
        let idx = key as usize - 'a' as usize;
        return self.0 |= 1 << idx;
    }
}

fn calc_min_dist_from(input: &Input, start: Position) -> Distances {
    let mut queue = VecDeque::new();
    let mut visited = HashSet::new();
    let mut res = Distances::new();

    let rows = input.mat.len();
    let cols = input.mat[0].len();

    queue.push_back((start, Bitmap::new(), 0 as usize));
    visited.insert(start);

    while queue.len() > 0 {
        let (pos, doors_seen, dist) = queue.pop_front().unwrap();

        let field = input.mat[pos.0][pos.1];
        if field.is_lowercase() && pos != start {
            res.insert(pos, (dist, doors_seen));
        }

        for (dr, dc) in STEPS {
            let next_r = pos.0 as isize + dr;
            let next_c = pos.1 as isize + dc;

            if next_r < 0 || next_r >= rows as isize ||
                next_c < 0 || next_c >= cols as isize {
                continue;
            }

            let next_pos = (next_r as usize, next_c as usize);
            if visited.contains(&next_pos) {
                continue;
            }

            let next_field = input.mat[next_pos.0][next_pos.1];

            if next_field == '#' {
                continue;
            }

            let mut next_doors_seen = doors_seen;

            // door
            if next_field.is_uppercase() {
                let d = next_field.to_ascii_lowercase();
                next_doors_seen.add_key(d);
            }

            visited.insert(next_pos);
            queue.push_back((next_pos, next_doors_seen, dist + 1));
        }
    }

    return res;
}

#[derive(Debug)]
struct Input {
    mat: Vec<Vec<char>>,
    start: (usize, usize),
    keys: HashMap<char, (usize, usize)>,
}

fn parse_input(input_file: String) -> Result<Input> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut mat = Vec::new();
    let mut keys = HashMap::new();
    let mut start = (0, 0);

    let mut r = 0;
    for line in contents.lines() {
        let mut row = Vec::new();
        for (c, ch) in line.chars().enumerate() {
            if ch == '@' {
                start = (r, c);
                row.push('.');
            }
            else if ch.is_lowercase() {
                keys.insert(ch, (r, c));
                row.push(ch);
            } else {
                row.push(ch);
            }
        }
        mat.push(row);
        r += 1;
    }

    return Ok(Input { mat, start, keys });
}
