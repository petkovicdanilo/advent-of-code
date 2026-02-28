use std::{collections::{HashMap, HashSet}, fs};

use crate::Day;

use anyhow::{Context, Result};

pub(crate) struct Day14 {
}

impl Day for Day14 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let reactions = parse_input(input_file)?;
        // println!("{reactions:#?}");

        let mut chem_to_reaction_map = HashMap::new();
        for reaction in reactions {
            chem_to_reaction_map.insert(reaction.output.id.clone(), reaction);
        }

        let mut topological_order = topological_sort(&chem_to_reaction_map)?;
        topological_order.reverse();
        // println!("{topological_order:?}");

        let res = calc_min_ore(&chem_to_reaction_map, 1, &topological_order)?;
        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let reactions = parse_input(input_file)?;

        let mut chem_to_reaction_map = HashMap::new();
        for reaction in reactions {
            chem_to_reaction_map.insert(reaction.output.id.clone(), reaction);
        }

        let mut topological_order = topological_sort(&chem_to_reaction_map)?;
        topological_order.reverse();

        const MAX_ORE: u64 = 1000000000000;

        let mut low: u64 = 1;
        let mut high: u64 = MAX_ORE;

        let mut res: u64 = 1;
        while low <= high {
            let mid = low + (high - low) / 2;
            // println!("mid={mid}");

            let mid_res = calc_min_ore(&chem_to_reaction_map, mid, &topological_order)?;

            if mid_res == MAX_ORE {
                res = mid_res;
                break;
            }

            if mid_res < MAX_ORE {
                // This is a potential candidate.
                res = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        println!("{res}");

        return Ok(());
    }
}

fn calc_min_ore(
    chem_to_reaction_map: &HashMap<String, Reaction>,
    fuel_amount: u64,
    chemicals: &Vec<String>) -> Result<u64> {

    let mut amount_map = HashMap::new();
    amount_map.insert(String::from("FUEL"), fuel_amount);

    for chemical_id in chemicals[0..chemicals.len() - 1].iter() {
        let needed_amount = amount_map.get(chemical_id)
            .context(format!("Failed to find needed amount for {chemical_id}"))?;

        let reaction = chem_to_reaction_map.get(chemical_id)
            .context(format!("Failed to find reaction to get chemical {chemical_id}"))?;

        let produced_amount = reaction.output.amount;
        let multiplier = (*needed_amount as f64 / produced_amount as f64).ceil() as u64;

        for input in &reaction.inputs {
            let curr_amount = amount_map.entry(input.id.clone()).or_insert(0);
            *curr_amount += input.amount * multiplier;
        }
    }

    // println!("{amount_map:?}");

    let res = amount_map.get(&String::from("ORE")).unwrap();

    return Ok(*res);
}

fn topological_sort(chem_to_reaction_map: &HashMap<String, Reaction>) -> Result<Vec<String>> {
    let mut visited = HashSet::new();
    let mut order = Vec::new();
    dfs(&String::from("FUEL"), chem_to_reaction_map, &mut visited, &mut order)?;
    return Ok(order);
}

fn dfs(
    curr: &String,
    chem_to_reaction_map: &HashMap<String, Reaction>,
    visited: &mut HashSet<String>,
    order: &mut Vec<String>) -> Result<()> {

    visited.insert(curr.clone());

    if curr == &String::from("ORE") {
        order.push(curr.clone());
        return Ok(());
    }

    let reaction = chem_to_reaction_map.get(curr)
        .context(format!("Failed to find reaction to get chemical {curr}"))?;

    for input_chemical in &reaction.inputs {
        let input_id = &input_chemical.id;
        if visited.contains(input_id) {
            continue;
        }

        dfs(input_id, chem_to_reaction_map, visited, order)?;
    }

    order.push(curr.clone());

    return Ok(());
}

#[derive(Clone, Debug)]
struct Chemical {
    amount: u64,
    id: String,
}

#[derive(Clone, Debug)]
struct Reaction {
    inputs: Vec<Chemical>,
    output: Chemical,
}

fn parse_input(input_file: String) -> Result<Vec<Reaction>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut res = Vec::new();

    for line in contents.lines() {
        let (input_part, output_part) = line.split_once(" => ")
            .context("Couldn't find '=>'")?;

        let mut inputs = Vec::new();
        for part in input_part.split(", ") {
            let c = parse_chemical(&part)?;
            inputs.push(c);
        }

        let output = parse_chemical(&output_part)?;

        res.push(Reaction {inputs, output});
    }

    return Ok(res);
}

fn parse_chemical(s: &str) -> Result<Chemical> {
    let (amount, id) = s.split_once(" ")
        .context("Couldn't find ','")?;

    let amount = amount.parse::<u64>()?;
    let id = id.to_string();

    return Ok(Chemical { amount, id });
}
