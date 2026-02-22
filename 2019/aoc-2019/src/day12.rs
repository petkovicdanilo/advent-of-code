use std::fs;

use crate::Day;

use anyhow::{Context, Result};

pub(crate) struct Day12 {
}

impl Day for Day12 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let mut positions = parse_input(input_file)?;
        // println!("{positions:?}");

        let l = positions.len();
        let mut velocities = Vec::with_capacity(l);
        for _ in 0..l {
            velocities.push(Vec3 { x: 0, y: 0, z: 0 });
        }

        const ITER: u32 = 1000;
        // const ITER: u32 = 100;

        // for i in 0..l {
        //     let pos = &positions[i];
        //     let vel = &velocities[i];
        //     println!("pos={pos:?}, vel={vel:?}");
        // }
        // println!();

        for _ in 1..=ITER {
            for i in 0..l-1 {
                for j in (i+1)..l {
                    let first = &positions[i];
                    let second = &positions[j];

                    if first.x < second.x {
                        velocities[i].x += 1;
                        velocities[j].x -= 1;
                    } else if first.x > second.x {
                        velocities[j].x += 1;
                        velocities[i].x -= 1;
                    }

                    if first.y < second.y {
                        velocities[i].y += 1;
                        velocities[j].y -= 1;
                    } else if first.y > second.y {
                        velocities[j].y += 1;
                        velocities[i].y -= 1;
                    }

                    if first.z < second.z {
                        velocities[i].z += 1;
                        velocities[j].z -= 1;
                    } else if first.z > second.z {
                        velocities[j].z += 1;
                        velocities[i].z -= 1;
                    }
                }
            }

            for (i, v) in velocities.iter().enumerate() {
                positions[i].x += v.x;
                positions[i].y += v.y;
                positions[i].z += v.z;
            }

            // println!("iter = {iter}",);
            // for i in 0..l {
            //     let pos = &positions[i];
            //     let vel = &velocities[i];
            //     println!("pos={pos:?}, vel={vel:?}");
            // }
            // println!();
        }

        let mut res = 0;

        for i in 0..l {
            let p = &positions[i];
            let v = &velocities[i];

            let pot = p.x.abs() + p.y.abs() + p.z.abs();
            let kin = v.x.abs() + v.y.abs() + v.z.abs();

            let total = pot * kin;
            res += total;
        }

        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let mut positions = parse_input(input_file)?;

        let l = positions.len();
        let mut velocities = Vec::with_capacity(l);
        for _ in 0..l {
            velocities.push(Vec3 { x: 0, y: 0, z: 0 });
        }

        let starting_positions = positions.clone();

        let mut x_period = None;
        let mut y_period = None;
        let mut z_period = None;

        let mut iter: u64 = 0;
        while x_period.is_none() || y_period.is_none() || z_period.is_none() {
            iter += 1;
            for i in 0..l-1 {
                for j in (i+1)..l {
                    let first = &positions[i];
                    let second = &positions[j];

                    if first.x < second.x {
                        velocities[i].x += 1;
                        velocities[j].x -= 1;
                    } else if first.x > second.x {
                        velocities[j].x += 1;
                        velocities[i].x -= 1;
                    }

                    if first.y < second.y {
                        velocities[i].y += 1;
                        velocities[j].y -= 1;
                    } else if first.y > second.y {
                        velocities[j].y += 1;
                        velocities[i].y -= 1;
                    }

                    if first.z < second.z {
                        velocities[i].z += 1;
                        velocities[j].z -= 1;
                    } else if first.z > second.z {
                        velocities[j].z += 1;
                        velocities[i].z -= 1;
                    }
                }
            }

            for (i, v) in velocities.iter().enumerate() {
                positions[i].x += v.x;
                positions[i].y += v.y;
                positions[i].z += v.z;
            }

            if x_period.is_none() {
                let mut is_period = true;
                for i in 0..l {
                    if starting_positions[i].x != positions[i].x ||
                        velocities[i].x != 0 {
                        is_period = false;
                        break;
                    }
                }
                
                if is_period {
                    x_period = Some(iter);
                }
            }

            if y_period.is_none() {
                let mut is_period = true;
                for i in 0..l {
                    if starting_positions[i].y != positions[i].y ||
                        velocities[i].y != 0 {
                        is_period = false;
                        break;
                    }
                }
                
                if is_period {
                    y_period = Some(iter);
                }
            }

            if z_period.is_none() {
                let mut is_period = true;
                for i in 0..l {
                    if starting_positions[i].z != positions[i].z ||
                        velocities[i].z != 0 {
                        is_period = false;
                        break;
                    }
                }
                
                if is_period {
                    z_period = Some(iter);
                }
            }
        }

        let mut res = lcm(x_period.unwrap(), y_period.unwrap());
        res = lcm(res, z_period.unwrap());
        println!("{res}");

        return Ok(());
    }
}

fn gcd(a: u64, b: u64) -> u64 {
    let mut a = a;
    let mut b = b;
    while b > 0 {
        let r = a % b;
        a = b;
        b = r;
    }
    return a;
}

fn lcm(a: u64, b: u64) -> u64 {
    return a * b / gcd(a, b);
}


fn parse_input(input_file: String) -> Result<Vec<Vec3>> {
    let contents = fs::read_to_string(input_file)
        .context("Couldn't read from the input file")?;

    let mut res = Vec::new();

    for line in contents.lines() {
        let l = line.len();
        let line = &line[1..l-1];
        let mut s = line.split(", ");

        let x = s.next()
            .context("Invalid input")?[2..]
            .parse::<i32>()?;
        let y = s.next()
            .context("Invalid input")?[2..]
            .parse::<i32>()?;
        let z = s.next()
            .context("Invalid input")?[2..]
            .parse::<i32>()?;

        res.push(Vec3 { x, y, z });
    }

    return Ok(res);
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct Vec3 {
    x: i32,
    y: i32,
    z: i32,
}
