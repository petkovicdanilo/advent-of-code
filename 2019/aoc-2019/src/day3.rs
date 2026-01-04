use std::{collections::{HashMap, HashSet}, fs};

use crate::Day;
use anyhow::{Context, Result, bail};

pub(crate) struct Day3;

const PANEL_SIZE: usize = 25000;

impl Day for Day3 {
    fn part1(&mut self, input_file: String) -> anyhow::Result<()> {
        let (l1, l2) = parse_input(input_file)?;

        let mut panel: HashSet<(usize, usize)> = HashSet::new();

        let central_port = (PANEL_SIZE / 2, PANEL_SIZE / 2);

        let mut r = central_port.0;
        let mut c = central_port.1;

        for component in &l1.path {
            let (dr, dc) = direction_to_rc_change(&component.direction);
            for _ in 0..component.amount {
                r = (r as i32 + dr) as usize;
                c = (c as i32 + dc) as usize;
                panel.insert((r, c));
            }
        }

        r = central_port.0;
        c = central_port.1;

        let mut min_dist = u32::MAX;
        for component in &l2.path {
            let (dr, dc) = direction_to_rc_change(&component.direction);
            for _ in 0..component.amount {
                r = (r as i32 + dr) as usize;
                c = (c as i32 + dc) as usize;

                if !panel.contains(&(r, c)) {
                    continue;
                }
                let dist = manhattan_distance((r, c), central_port);
                min_dist = std::cmp::min(min_dist, dist);
            }
        }

        println!("{min_dist}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> anyhow::Result<()> {
        let (l1, l2) = parse_input(input_file)?;

        let mut panel: HashMap<(usize, usize), u32> = HashMap::new();

        let central_port = (PANEL_SIZE / 2, PANEL_SIZE / 2);

        let mut r = central_port.0;
        let mut c = central_port.1;

        let mut steps = 0;
        for component in &l1.path {
            let (dr, dc) = direction_to_rc_change(&component.direction);
            for _ in 0..component.amount {
                r = (r as i32 + dr) as usize;
                c = (c as i32 + dc) as usize;
                steps += 1;
                if !panel.contains_key(&(r, c)) {
                    panel.insert((r, c), steps);
                }
            }
        }

        let mut l2_steps = 0;
        r = central_port.0;
        c = central_port.1;

        let mut min_delay = u32::MAX;
        for component in &l2.path {
            let (dr, dc) = direction_to_rc_change(&component.direction);
            for _ in 0..component.amount {
                r = (r as i32 + dr) as usize;
                c = (c as i32 + dc) as usize;

                l2_steps += 1;

                if let Some(l1_steps) = panel.get(&(r, c)) {
                    let delay = l1_steps + l2_steps;
                    min_delay = std::cmp::min(min_delay, delay);
                }
            }
        }

        println!("{min_delay}");

        return Ok(());
    }
}

#[derive(Debug)]
struct Line {
    path: Vec<PathComponent>,
}

#[derive(Debug)]
struct PathComponent {
    amount: u32,
    direction: Direction
}

#[derive(Debug)]
enum Direction {
    LEFT,
    RIGHT,
    DOWN,
    UP,
}

fn direction_to_rc_change(d: &Direction) -> (i32, i32) {
    return match d {
        Direction::LEFT => (0, -1),
        Direction::RIGHT => (0, 1),
        Direction::DOWN => (1, 0),
        Direction::UP => (-1, 0),
    };
}

fn manhattan_distance(p1: (usize, usize), p2: (usize, usize)) -> u32 {
    let dist_r = (p1.0 as i32 - p2.0 as i32).abs() as u32; 
    let dist_c = (p1.1 as i32 - p2.1 as i32).abs() as u32; 
    return dist_r + dist_c;
}

fn parse_input(input_file: String) -> Result<(Line, Line)> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut content_lines = contents.lines();
    let line1 = parse_line(content_lines.next().unwrap())?;
    let line2 = parse_line(content_lines.next().unwrap())?;
    return Ok((line1, line2));
}

fn parse_line(s: &str) -> Result<Line> {
    let mut path: Vec<PathComponent> = Vec::new();
    for part in s.split(",") {
        let component = parse_path_component(part)?;
        path.push(component);
    }

    return Ok(Line {
        path
    });
}

fn parse_path_component(s: &str) -> Result<PathComponent> {
    let (first, rest) = s.split_at(1);

    let first_char = first.chars().next().context("Invalid input")?;
    let direction = match first_char {
        'L' => {
            Direction::LEFT
        },
        'R' => {
            Direction::RIGHT
        },
        'U' => {
            Direction::UP
        },
        'D' => {
            Direction::DOWN
        },
        x => {
            bail!("Invalid direction {x}");
        }
    };

    let amount = rest.parse::<u32>()?;

    return Ok(PathComponent {
        amount,
        direction
    });
}
