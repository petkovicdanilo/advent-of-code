use std::collections::{HashMap, VecDeque};

use anyhow::{Result, bail};

use crate::{Day, computer::{Computer, Status}};

pub(crate) struct Day23 {
}

const N: usize = 50;

impl Day for Day23 {
    fn part1(&mut self, input_file: String) -> Result<()> {
        let computer = Computer::from_file(&input_file)?;

        let mut computers = Vec::with_capacity(N);
        let mut packet_queues = Vec::with_capacity(N);
        for addr in 0..N {
            let mut c = computer.clone();
            let input = std::iter::once(addr as i64);
            let output = c.run(input)?;
            
            if output.status == Status::Halted {
                bail!("Computer with addr {addr} halted unexpectedly");
            }

            computers.push(c);
            packet_queues.push(VecDeque::new());
        }

        let res;

        let mut curr = 0;
        'outer:
        loop {
            let c = &mut computers[curr];
            let queue = &mut packet_queues[curr];

            let input = if let Some((x, y)) = queue.pop_front() {
                vec![x, y]
            } else {
                vec![-1]
            };
            let output = c.run(input.into_iter())?;
            if output.status == Status::Halted {
                bail!("Computer with addr {curr} halted unexpectedly");
            }

            if output.outputs.len() > 0 {
                for chunk in output.outputs.chunks(3) {
                    let addr = chunk[0] as usize;
                    let x = chunk[1];
                    let y = chunk[2];

                    if addr == 255 {
                        res = y;
                        break 'outer;
                    }
                    packet_queues[addr].push_back((x, y));
                }
            }

            if packet_queues[curr].len() == 0 {
                curr = (curr + 1) % N;
            }
        }

        println!("{res}");

        return Ok(());
    }

    fn part2(&mut self, input_file: String) -> Result<()> {
        let computer = Computer::from_file(&input_file)?;

        let mut computers = Vec::with_capacity(N);
        let mut packet_queues = Vec::with_capacity(N);
        let mut nat_queue = None;

        for addr in 0..N {
            let mut c = computer.clone();
            let input = std::iter::once(addr as i64);
            let output = c.run(input)?;
            
            if output.status == Status::Halted {
                bail!("Computer with addr {addr} halted unexpectedly");
            }

            computers.push(c);
            packet_queues.push(VecDeque::new());
        }

        let mut last_addr_0_y = None;
        let mut computer_active_map = HashMap::new();
        for i in 0..N {
            computer_active_map.insert(i, true);
        }

        let mut curr = 0;
        loop {
            let network_is_idle = packet_queues
                .iter()
                .filter(|q| q.len() > 0)
                .count() == 0;
            let all_computers_inactive = computer_active_map
                .values()
                .filter(|active| **active == true)
                .count() == 0;

            if network_is_idle && all_computers_inactive {
                if nat_queue.is_none() {
                    bail!("Invalid state, no NAT packet found to send to addr 0");
                }
                let (x, y) = nat_queue.unwrap();
                packet_queues[0].push_back((x, y));
                if let Some(last_y) = last_addr_0_y && last_y == y {
                    break;
                }
                last_addr_0_y = Some(y);
            }

            let c = &mut computers[curr];
            let queue = &mut packet_queues[curr];

            let input = if let Some((x, y)) = queue.pop_front() {
                vec![x, y]
            } else {
                vec![-1]
            };
            let output = c.run(input.into_iter())?;
            if output.status == Status::Halted {
                bail!("Computer with addr {curr} halted unexpectedly");
            }

            if output.outputs.len() > 0 {
                for chunk in output.outputs.chunks(3) {
                    let addr = chunk[0] as usize;
                    let x = chunk[1];
                    let y = chunk[2];

                    if addr == 255 {
                        nat_queue = Some((x, y));
                    } else {
                        packet_queues[addr].push_back((x, y));
                    }
                }
                computer_active_map.insert(curr, true);
            } else {
                computer_active_map.insert(curr, false);
            }

            if packet_queues[curr].len() == 0 {
                curr = (curr + 1) % N;
            }
        }

        println!("{}", last_addr_0_y.unwrap());

        return Ok(());
    }
}
