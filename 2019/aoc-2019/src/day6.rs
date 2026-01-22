use std::{collections::HashMap, fs};

use anyhow::{Context, Result};

use crate::Day;

pub(crate) struct Day6;

impl Day for Day6 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let orbit_map = parse_input(input_file)?;
        // println!("{orbit_map:#?}");

        let orbit_count_map = calculate_orbits(String::from("COM"), &orbit_map)?;
        // println!("{orbit_count_map:#?}");

        let mut res = 0;
        for count in orbit_count_map.values() {
            res += count;
        }

        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, _input_file: String) -> Result<()> {
        todo!()
    }
}

type OrbitMap = HashMap<String, Vec<String>>;

fn calculate_orbits(start: String, orbit_map: &OrbitMap) -> Result<HashMap<String, u32>> {
    let mut count_map = HashMap::new();
    calculate_orbits_inner(start, 0, orbit_map, &mut count_map)?;
    return Ok(count_map);
}

fn calculate_orbits_inner(
    start: String, count: u32, orbit_map: &OrbitMap, count_map: &mut HashMap<String, u32>
    ) -> Result<()> {

    count_map.insert(start.clone(), count);
    if let Some(children) = orbit_map.get(&start) {
        for child in children {
            calculate_orbits_inner(child.to_owned(), count + 1, orbit_map, count_map)?;
        }
    }

    return Ok(());
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
