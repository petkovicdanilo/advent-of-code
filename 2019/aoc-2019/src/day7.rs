use crate::{Day, computer::{Computer, Status}};

use anyhow::{Context, Result, bail};

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
            match output_a.status {
                Status::Halted => {},
                Status::PausedForInput => {
                    bail!("Amp A required more input values than expected.")
                },
            }

            let input_b = vec![p[1]].into_iter()
                .chain(output_a.outputs.into_iter());
            let output_b = amp_b.run(input_b)?;
            match output_b.status {
                Status::Halted => {},
                Status::PausedForInput => {
                    bail!("Amp B required more input values than expected.")
                },
            }

            let input_c = vec![p[2]].into_iter()
                .chain(output_b.outputs.into_iter());
            let output_c = amp_c.run(input_c)?;
            match output_c.status {
                Status::Halted => {},
                Status::PausedForInput => {
                    bail!("Amp C required more input values than expected.")
                },
            }

            let input_d = vec![p[3]].into_iter()
                .chain(output_c.outputs.into_iter());
            let output_d = amp_d.run(input_d)?;
            match output_d.status {
                Status::Halted => {},
                Status::PausedForInput => {
                    bail!("Amp D required more input values than expected.")
                },
            }

            let input_e = vec![p[4]].into_iter()
                .chain(output_d.outputs.into_iter());
            let output_e = amp_e.run(input_e)?;
            match output_e.status {
                Status::Halted => {},
                Status::PausedForInput => {
                    bail!("Amp E required more input values than expected.")
                },
            }

            let thrust_output = output_e.outputs.iter().next()
                .context("Couldn't find thrust output.")?;
            if *thrust_output > res {
                res = *thrust_output;
                // max_perm = p.clone();
            }
        }

        println!("{res}");
        // println!("{max_perm:?}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let computer = Computer::from_file(&input_file)?;
        let permutations = generate_permutations(5);
        let mut res = 0;
        // let mut max_perm = Vec::new();

        for p in permutations {
            let mut amps = vec![
                computer.clone(),
                computer.clone(),
                computer.clone(),
                computer.clone(),
                computer.clone(),
            ];
            let mut halted = vec![false; 5];
            let mut inputs = vec![
                vec![],
                vec![],
                vec![],
                vec![],
                vec![],
            ];

            let mut curr = 0;
            let mut first_run = true;
            let mut sub_res = 0;

            loop {
                let amp = &mut amps[curr];
                if halted[curr] {
                    let amp_name = std::char::from_u32('A' as u32 + curr as u32)
                        .unwrap();
                    bail!("Amp {} is already halted, cannot run again", amp_name);
                }

                let mut input_values = inputs[curr].clone();
                let input_values = if first_run {
                    if curr == 0 {
                        let mut new = vec![p[0] + 5, 0];
                        new.append(&mut input_values);
                        new
                    } else {
                        let mut new = vec![p[curr] + 5];
                        new.append(&mut input_values);
                        new
                    }
                } else {
                    input_values
                };

                let res = amp.run(input_values.into_iter())?;
                if res.status == Status::Halted {
                    halted[curr] = true;
                    if curr == 4 {
                        if let Some(val) = res.outputs.last() {
                            sub_res = *val;
                        }
                        break;
                    }
                }

                if curr == 4 {
                    first_run = false;
                }
                
                curr = (curr + 1) % 5;
                inputs[curr] = res.outputs;
            }

            if sub_res > res {
                res = sub_res;
                // max_perm = p;
            }
        }

        println!("{res}");
        // println!("{max_perm:?}");

        return Ok(());
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
