use std::{collections::HashMap, fs};

use anyhow::{Context, Result};

use crate::Day;

pub(crate) struct Day6;

impl Day for Day6 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let orbit_map = parse_input(input_file)?;
        // println!("{orbit_map:#?}");

        let com = String::from("COM");
        let orbit_count_map = calculate_orbits(&com, &orbit_map)?;
        // println!("{orbit_count_map:#?}");

        let mut res = 0;
        for count in orbit_count_map.values() {
            res += count;
        }

        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let orbit_map = parse_input(input_file)?;

        let mut parent_map = HashMap::<String, String>::new();

        for (parent, children) in orbit_map {
            for child in children {
                parent_map.insert(child, parent.clone());
            }
        }

        let you = String::from("YOU");
        let san = String::from("SAN");

        let you_path = find_path(&you, &parent_map);
        let san_path = find_path(&san, &parent_map);

        // println!("{you_path:#?}");
        // println!("{san_path:#?}");

        let mut idx = 0;
        while you_path[idx] == san_path[idx] {
            idx += 1;
        }

        // println!("idx={idx}");

        let res = (you_path[idx..].len() - 1) + (san_path[idx..].len() - 1);
        println!("{res}");

        return Ok(());
    }
}

type OrbitMap = HashMap<String, Vec<String>>;

fn calculate_orbits(start: &String, orbit_map: &OrbitMap) -> Result<HashMap<String, u32>> {
    let mut count_map = HashMap::new();
    calculate_orbits_inner(&start, 0, orbit_map, &mut count_map)?;
    return Ok(count_map);
}

fn calculate_orbits_inner(
    start: &String, count: u32, orbit_map: &OrbitMap, count_map: &mut HashMap<String, u32>
    ) -> Result<()> {

    count_map.insert(start.clone(), count);
    if let Some(children) = orbit_map.get(start) {
        for child in children {
            calculate_orbits_inner(&child, count + 1, orbit_map, count_map)?;
        }
    }

    return Ok(());
}

fn find_path(start: &str, parent_map: &HashMap<String, String>) -> Vec<String> {
    let mut ret = Vec::new();

    let mut curr = start;
    while let Some(parent) = parent_map.get(curr) {
        ret.push(curr.to_owned());
        curr = parent;
    }
    ret.push(curr.to_owned());

    ret.reverse();
    return ret;
}

fn parse_input(input_file: String) -> Result<OrbitMap> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut map = HashMap::new();

    for line in contents.lines() {
        let (obj1, obj2) = line.split_once(")").context("Invalid input line")?;
        let obj1 = obj1.to_owned();
        let obj2 = obj2.to_owned();

        let orbits = map.entry(obj1).or_insert(Vec::new());
        orbits.push(obj2);
    }

    return Ok(map);
}
