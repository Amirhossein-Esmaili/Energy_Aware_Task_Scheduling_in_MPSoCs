This software provides methods for energy-aware static scheduling of deadline-constrained task graphs in multiprocessor system-on-chip (MPSoC) platforms through integrated dynamic power management (DPM), and dynamic voltage and frequency scaling (DVFS).

- [Description](#description)
- [License](#license)
- [Installation](#installation)
- [Sample Script](#sample-script)
- [Developers](#developers)
- [Reference](#reference)

## Description
This work presents a novel approach for modeling idle intervals in MPSoC platforms, which leads to a mixed integer linear programming (MILP) formulation integrating DPM, DVFS, and task scheduling of periodic task graphs subject to a hard deadline. 
It also presents a heuristic approach for solving the MILP, which achieves significant speedups compared to solving the MILP directly while finding comparable solutions in terms of energy consumption. For each task, we are looking for processor assignment for the task, task execution start time, and distribution of the total number of required processor cycles for the complete execution of the task among available frequencies of processors.

## License
Please refer to the LICENSE file.  

## Installation

### On Linux

#### Install Dependencies  
`sudo apt install git-all python2.7 python-numpy build-essential`

#### Install TGFF  
[Task Graphs for Free (TGFF)](http://ziyang.eecs.umich.edu/projects/tgff) provides a flexible and standard way of generating pseudo-random task graphs.  

- Download the latest version of TGFF (currently 3.6) from the website  
`wget http://ziyang.eecs.umich.edu/projects/tgff/tgff-3.6.tgz`  

- Unpack the downloaded file and install TGFF  
`tar -xvzf tgff-3.6.tgz`  
`cd tgff-3.6`  
`make -j4`  

- Add TGFF to `PATH`  
`echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc`  

#### Install IBM ILOG CPLEX Optimization Studio  
[IBM ILOG CPLEX Optimization Studio](https://www.ibm.com/products/ilog-cplex-optimization-studio) is a powerful integrated development environment (IDE) that supports Optimization Programming Language (OPL) and the high-performance CPLEX and CP Optimizer solvers. 
It has a [**free academic license**](https://ibm.onthehub.com/WebStore/OfferingDetails.aspx?o=733c3d21-0ce1-e711-80fa-000d3af41938&pmv=00000000-0000-0000-0000-000000000000) for students and faculty.  

- Download the latest version of IBM ILOG CPLEX Optimization Studio (currently 12.8) from the website and install using the following command:  
`sudo ./cplex_studio128.linux-x86-64.bin`

- Add OPL to `PATH`   
`echo "export PATH=\$PATH:/opt/ibm/ILOG/CPLEX_Studio128/opl/bin/x86-64_linux" >> ~/.bashrc`  
`echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/ibm/ILOG/CPLEX_Studio128/opl/bin/x86-64_linux" >> ~/.bashrc`  

- Update environment variables  
`source ~/.bashrc`

#### Clone the Repository  
`git clone https://github.com/Amirhossein-Esmaili/Energy_Aware_Task_Scheduling_in_MPSoCs.git`


### On Windows
- Install Python 2.7
- Install [TGFF (Windows version)](http://ziyang.eecs.umich.edu/projects/tgff/tgff3_1.exe)
- Install [IBM ILOG CPLEX Optimization Studio (Windows version)](https://www.ibm.com/products/ilog-cplex-optimization-studio)
- [Download](https://github.com/Amirhossein-Esmaili/Energy_Aware_Task_Scheduling_in_MPSoCs/archive/master.zip) the repository 

## Sample Script
`sample_script.sh` includes an example of how to use this software. It comprises of the following steps:  

- setup parameters (change `SEED` to generate different pseudo-random graphs)
- run the Python script that generates inputs for TGFF  
- run TGFF  
- run the Python script that processes TGFF outputs and generates IBM ILOG CPLEX Optimization Studio input data `.dat`  
- solve MILP using exact method  
- solve MILP using proposed heuristic  

The following figures illustrate a sample graph with 10 nodes, scheduled on an MPSoC using the exact and heuristic MILP solutions. The exact MILP solution is referred to as "iSCT". In this example, the MPSoC platform comprises of 4 processors where each one supports 5 discrete frequencies ranging from 1.01 GHz to 2.1 GHz, and the average workload of each task is set to 2 * 10 <sup> 6 </sup> cycles (around 1 ms execution time under the maximum available frequency). You can reproduce the results by running the following command:  
`bash sample_script.sh`  

You can change the simulation parameters in `sample_script.sh` to explore the results for other task graphs and different MPSoC platform parameters.  


![graph](https://github.com/Amirhossein-Esmaili/Energy_Aware_Task_Scheduling_in_MPSoCs/blob/master/docs/img/TGFF0.png)  
\
![iSCT](https://github.com/Amirhossein-Esmaili/Energy_Aware_Task_Scheduling_in_MPSoCs/blob/master/docs/img/iSCT_TGFF0.png)  
\
![Heuristic](https://github.com/Amirhossein-Esmaili/Energy_Aware_Task_Scheduling_in_MPSoCs/blob/master/docs/img/Heuristic_TGFF0.png)  


## Developers
Amirhossein Esmaili (<esmailid@usc.edu>)  
Mahdi Nazemi (<mnazemi@usc.edu>)  
Massoud Pedram (<pedram@usc.edu>)  

## Reference
If you use this software in your research, please cite the following paper:  
  
```
@inproceedings{esmaili2019modeling,
  title={Modeling Processor Idle Times in {MPSoC} Platforms to Enable Integrated {DPM}, {DVFS}, and Task Scheduling Subject to a Hard Deadline},
  author={Esmaili, Amirhossein and Nazemi, Mahdi and Pedram, Massoud},
  booktitle={Asia and South Pacific Design Automation Conference (ASP-DAC)},
  year={2019}
}
```

The preprint version of the above paper can be found here: https://arxiv.org/abs/1812.07723.  
