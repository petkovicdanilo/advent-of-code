use crate::{Day, computer::Computer};

use anyhow::{Context, Result};

pub(crate) struct Day7 {
}

impl Day for Day7 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let computer = Computer::from_file(&input_file)?;
        let permutations = generate_permutations(5);
        let mut res = 0;
        // let mut max_perm = Vec::new();

        for p in permutations {
            let mut amp_a = computer.clone();
            let mut amp_b = computer.clone();
            let mut amp_c = computer.clone();
            let mut amp_d = computer.clone();
            let mut amp_e = computer.clone();

            let input_a = vec![p[0], 0].into_iter();
            let output_a = amp_a.run(input_a)?;

            let input_b = vec![p[1]].into_iter().chain(output_a);
            let output_b = amp_b.run(input_b)?;

            let input_c = vec![p[2]].into_iter().chain(output_b);
            let output_c = amp_c.run(input_c)?;

            let input_d = vec![p[3]].into_iter().chain(output_c);
            let output_d = amp_d.run(input_d)?;

            let input_e = vec![p[4]].into_iter().chain(output_d);
            let mut output_e = amp_e.run(input_e)?;

            let thrust_output = output_e.next()
                .context("Couldn't find thrust output.")?;
            if thrust_output > res {
                res = thrust_output;
                // max_perm = p.clone();
            }
        }

        println!("{res}");
        // println!("{max_perm:?}");

        return Ok(());
    }

    fn part2(&mut self, _input_file: String) -> Result<()> {
        todo!()
    }
}

fn generate_permutations(n: i32) -> Vec<Vec<i32>> {
    let mut curr_state = Vec::new();
    return generate_permutations_inner(n, &mut curr_state);
}

fn generate_permutations_inner(n: i32, curr_state: &mut Vec<i32>) -> Vec<Vec<i32>> {
    if (curr_state.len() as i32) == n {
        return vec![curr_state.clone()];
    }

    let mut res = Vec::new();

    for i in 0..n {
        if curr_state.contains(&i) {
            continue;
        }

        curr_state.push(i);
        let sub_res = generate_permutations_inner(n, curr_state);
        curr_state.pop().unwrap();

        res.extend(sub_res);
    }

    return res;
}
