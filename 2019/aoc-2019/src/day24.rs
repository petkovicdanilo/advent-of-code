use std::{collections::{HashMap, HashSet}, fs};

use anyhow::{Context, Result, bail};

use crate::Day;

pub(crate) struct Day24 {
}

impl Day for Day24 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut layout = parse_input(input_file)?;
        // println!("{layout:#?}");
        let mut states = HashSet::new();
        states.insert(encode(&layout));

        loop {
            layout = next_layout(&layout);
            let state = encode(&layout);
            if states.contains(&state) {
                println!("{state}");
                break;
            }
            states.insert(state);
        }

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let layout = parse_input(input_file)?;

        const ITER: usize = 200;
        // const ITER: usize = 10;

        let mut layout = RecursiveLayout::new(layout);

        for _ in 0..ITER {
            layout.step()?;
        }

        // println!("{layout:#?}");

        let mut res = 0;
        for level_layout in layout.layouts.values() {
            for r in 0..N {
                for c in 0..N {
                    if r == 2 && c == 2 {
                        continue;
                    }
                    if level_layout[r][c] == Tile::Bug {
                        res += 1;
                    }
                }
            }
        }

        println!("{res}");

        // println!("{:?}", neighbours(0, (1, 1)));
        // println!("{:?}", neighbours(0, (0, 3)));
        // println!("{:?}", neighbours(0, (0, 4)));
        // println!("{:?}", neighbours(1, (2, 3)));
        // println!("{:?}", neighbours(0, (2, 3)));

        return Ok(());
    }
}

const N: usize = 5;
type Layout = [[Tile; N]; N];

const STEPS: [(isize, isize); 4] = [(0, -1), (-1, 0), (0, 1), (1, 0)];

fn next_layout(layout: &Layout) -> Layout {
    let mut new_layout: Layout = [[Tile::Empty; N]; N];

    for (r, row) in layout.iter().enumerate() {
        for (c, tile) in row.iter().enumerate() {
            let mut count_bug_neighbours = 0;

            for (dr, dc) in STEPS {
                let next_r = r as isize + dr;
                let next_c = c as isize + dc;

                let next_tile = if next_r < 0 || next_r >= N as isize ||
                    next_c < 0 || next_c >= N as isize {
                    Tile::Empty
                } else {
                    let next_r = next_r as usize;
                    let next_c = next_c as usize;
                    layout[next_r][next_c]
                };

                if next_tile == Tile::Bug {
                    count_bug_neighbours += 1;
                }
            }

            let new_tile = match *tile {
                Tile::Bug => if count_bug_neighbours == 1 {
                    Tile::Bug
                } else {
                    Tile::Empty
                },
                Tile::Empty => if count_bug_neighbours == 1 || count_bug_neighbours == 2 {
                    Tile::Bug
                } else {
                    Tile::Empty
                },
            };

            new_layout[r][c] = new_tile;
        }
    }

    return new_layout;
}

fn encode(layout: &Layout) -> u32 {
    let mut idx = 0;
    let mut res = 0;

    for row in layout {
        for tile in row {
            if *tile == Tile::Bug {
                res |= 1 << idx;
            }
            idx += 1;
        }
    }

    return res;
}

#[derive(Debug)]
struct RecursiveLayout {
    layouts: HashMap<isize, Layout>,
    steps: usize,
}

impl RecursiveLayout {
    fn new(layout: Layout) -> Self {
        let mut layouts = HashMap::new();
        layouts.insert(0, layout);
        return Self { layouts, steps: 0 };
    }

    fn step(&mut self) -> Result<()> {
        self.steps += 1;
        self.layouts.insert(self.steps as isize, [[Tile::Empty; N]; N]);
        self.layouts.insert(-(self.steps as isize), [[Tile::Empty; N]; N]);

        let mut new_layout = HashMap::new();

        let steps = self.steps as isize;
        for level in -steps..=steps {
            let layout = self.layouts.get(&level).unwrap();
            for (r, row) in layout.iter().enumerate() {
                for (c, tile) in row.iter().enumerate() {
                    if r == 2 && c == 2 {
                        continue;
                    }

                    let count_bug_neighbours = neighbours(level, (r, c))?
                        .iter()
                        .filter(|(level, n_r, n_c)| {
                            let layout = self.layouts
                                .get(&level)
                                .unwrap_or(&[[Tile::Empty; N]; N]);
                            return layout[*n_r][*n_c] == Tile::Bug;
                        })
                        .count();

                    let new_tile = match *tile {
                        Tile::Bug => if count_bug_neighbours == 1 {
                            Tile::Bug
                        } else {
                            Tile::Empty
                        },
                        Tile::Empty => if count_bug_neighbours == 1 || count_bug_neighbours == 2 {
                            Tile::Bug
                        } else {
                            Tile::Empty
                        },
                    };

                    let entry = new_layout.entry(level)
                        .or_insert([[Tile::Empty; N]; N]);
                    entry[r][c] = new_tile;
                }
            }
        }

        self.layouts = new_layout;

        return Ok(());
    }

}

fn neighbours(level: isize, pos: (usize, usize)) -> Result<Vec<(isize, usize, usize)>> {
    let (r, c) = pos;
    let mut ret = Vec::new();

    for (dr, dc) in STEPS {
        let next_r = r as isize + dr;
        let next_c = c as isize + dc;

        if next_r < 0 || next_r >= N as isize ||
            next_c < 0 || next_c >= N as isize {

            let next_r = (2 + dr) as usize;
            let next_c = (2 + dc) as usize;

            ret.push((level + 1, next_r, next_c));
            continue;
        }

        let next_r = next_r as usize;
        let next_c = next_c as usize;

        if next_r == 2 && next_c == 2 {
            let (r, c, dr, dc) = match (dr, dc) {
                (0, -1) => (0, 4, 1, 0),
                (-1, 0) => (4, 0, 0, 1),
                (0, 1) => (0, 0, 1, 0),
                (1, 0) => (0, 0, 0, 1),
                _ => unreachable!(),
            };

            for i in 0..N {
                let next_r = r + i*dr;
                let next_c = c + i*dc;
                ret.push((level - 1, next_r, next_c));
            }
        } else {
            ret.push((level, next_r, next_c));
        }
    }

    return Ok(ret);
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum Tile {
    Bug,
    Empty
}

impl Default for Tile {
    fn default() -> Self {
        return Self::Empty;
    }
}

fn parse_input(input_file: String) -> Result<Layout> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut ret = [[Tile::Empty; 5]; 5];
    for (row, line) in contents.lines().enumerate() {
        for (col, ch) in line.chars().enumerate() {
            let t = match ch {
                '#' => Tile::Bug,
                '.' => Tile::Empty,
                ch => bail!("Invalid character {ch} found in the input"),
            };
            ret[row][col] = t;
        }
    }

    return Ok(ret);
}
