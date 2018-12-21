#!/usr/bin/env python2


"""
Generates a data (.dat) file for IBM ILOG CPLEX solver.

"""


########## Import Statements ###################################################

from __future__ import print_function
from __future__ import division

import argparse

import numpy as np


########## Helper Functions ####################################################

def HEFT(period, tasks, adjacency, costs):
    """
    Finds processor assignment and ordering of tasks on assigned processors 
    using HEFT algorithm (detailed in the paper).

    Args:
        period: period of arrival of task graphs
        tasks 
        adjacency: adjacency matrix of the task graph
        costs: task workloads

    Output: 
        P_HEFT: processor assignment of tasks
        O_HEFT: ordering of tasks on assigned processors
    """
    num_tasks = len(tasks)
    rank = np.zeros(num_tasks, dtype=np.float64)
    rank_count = 0
    for i in range(num_tasks):
         children = np.where(adjacency[i] == 1)[0]
         if (len(children) == 0):
             rank[i] = costs[tasks[i]]
             rank_count = rank_count + 1
    while (rank_count < num_tasks):
        for i in range(num_tasks):
            if (rank[i] > 0):
                continue
            children = np.where(adjacency[i] == 1)[0]
            flag = 0
            for j in children:
                if (rank[j] == 0):
                    flag = 1
                    break    
            if (flag == 0):
                rank_candidates = []
                for j in children:
                    rank_candidates.append(rank[j])  
                rank_candidates = np.array(rank_candidates)
                rank[i] = costs[tasks[i]] + np.max(rank_candidates)
                rank_count = rank_count + 1
    
    rank = np.argsort(rank)
    rank = rank[::-1]

    P = []
    for i in range(args.num_cores):
        p = []
        P.append(p)
    task_endtime = np.zeros(num_tasks, dtype=np.float64)
    task_readytime = np.zeros(num_tasks, dtype=np.float64)
    for v in rank:
        parents = np.where(adjacency[:, v] == 1)[0]
        if (len(parents) == 0):
            task_readytime[v] = 0
        else:
            readytime_candidates = [task_endtime[u] for u in parents]
            task_readytime[v] = np.max(np.array(readytime_candidates))
        
        endtime_candidates = np.zeros(args.num_cores, dtype=np.float64)
        endtime_candidates = endtime_candidates + 2 * period
        for k in range(len(P)):
            if (len(P[k]) == 0):
                endtime_candidates[k] = task_readytime[v] + costs[tasks[v]]
                if (endtime_candidates[k] > period):
                    endtime_candidates[k] = 2 * period     
            else:
                for i in range(len(P[k])):
                    if (task_readytime[v] >= P[k][i][1]):
                        continue

                    else:
                        if (i == 0):
                            if(task_readytime[v] + costs[tasks[v]] <= P[k][i][1]):
                                endtime_candidates[k] = task_readytime[v] + costs[tasks[v]]
                                if (endtime_candidates[k] > period):
                                    endtime_candidates[k] = 2 * period
                        elif (0 < i):
                            if(np.max([task_readytime[v], P[k][i-1][2]]) + costs[tasks[v]] <= P[k][i][1]):
                                endtime_candidates[k] = np.max([task_readytime[v], P[k][i-1][2]]) + costs[tasks[v]]
                                if (endtime_candidates[k] > period):
                                    endtime_candidates[k] = 2 * period
                           
                if (endtime_candidates[k] == 2 * period):
                    if (np.max([task_readytime[v], P[k][i][2]]) + costs[tasks[v]] <= period):
                        endtime_candidates[k] = np.max([task_readytime[v], P[k][i][2]]) + costs[tasks[v]]

        task_endtime[v] = np.min(endtime_candidates)
        if (task_endtime[v] == 2 * period):
            print ("scheduling error in HEFT, insufficient resources")
            quit()
        else:
            t = (v, (task_endtime[v] - costs[tasks[v]]), task_endtime[v])
            P[np.argmin(endtime_candidates)].append(t)
            P[np.argmin(endtime_candidates)].sort(key=lambda tup: tup[2])
                      
    
    P_HEFT = np.zeros(num_tasks, dtype = np.uint8)
    for u in range(len(P_HEFT)): 
        for k in range(len(P)):
            tmp = [i for i in P[k] if i[0] == u]
            if(len(tmp) == 1):
                P_HEFT[u] = k
    P_HEFT = P_HEFT + 1
    
	

    O_HEFT = np.zeros((num_tasks, num_tasks), dtype = np.uint8)
    for k in range(len(P)):
        for i in range(len(P[k])-1):
            O_HEFT[P[k][i][0]][P[k][i+1][0]] = 1

    return P_HEFT, O_HEFT

def read_graph(file_path):
    """
    Read graph description from tgff file

    Args:
        file_path: path to input file
    """

    with open(file_path, 'r') as f:
        lines = f.readlines()

        period = int(lines[0].strip().split()[1])

        # Read graph nodes and edges
        for i, line in enumerate(lines):
            if line.startswith("@TASK_GRAPH"):
                # Read nodes
                tasks = []
                for task_line in lines[i + 3 :]:
                    if task_line == '\n':
                        break

                    tasks.append(int(task_line.strip().split()[3]))

                # Read edges
                num_tasks = len(tasks)
                adjacency = np.zeros((num_tasks, num_tasks), dtype=np.uint8)
                for edge_line in lines[i + 4 + num_tasks :]:
                    if edge_line == '\n':
                        break

                    elements = edge_line.strip().split()
                    source = int(elements[3][elements[3].find('_') + 1 :])
                    destination = int(elements[5][elements[5].find('_') + 1 :])
                    adjacency[source, destination] = 1

                break

        # Read workloads
        for i, line in enumerate(lines):
            if line.startswith("@NODE_WORKLOADS"):
                costs = []
                for workload_line in lines[i + 2 :]:
                    if workload_line.startswith('}'):
                        break

                    costs.append(float(workload_line.strip().split()[2]))

                break

    return period, tasks, adjacency, costs

def write_dat(args, period, tasks, adjacency, costs, P_HEFT, O_HEFT):
    """
    Generates a data (.dat) file for OPL solver

    Args:
        args: command line arguments
        period: period of arrival of task graphs
        tasks
        adjacency: adjacency matrix of the task graph
        costs: task workloads
    """

    with open(args.out_file, 'w') as f:
        f.write("dataset_label = \"{}\";\n".format(args.label))

        f.write("NbCores = {};\n".format(args.num_cores))

        f.write("NbFreqs = {};\n".format(len(args.freqs)))

        f.write("Freq = [{}];\n".format(' '.join([str(fr) for fr in args.freqs])))

        f.write("NbTasks = {};\n".format(len(tasks)))

        f.write("Td = {};\n".format(period))

        f.write("Tsw = {};\n".format(args.t_sw))

        f.write("a = {};\n".format(args.a))
        f.write("b = {};\n".format(args.b))
        f.write("c = {};\n".format(args.c))

        f.write("Dynpow_Exponent = {};\n".format(args.pow_exp))

        f.write("Etr = {};\n".format(args.e_sw))

        f.write("Totalwork = [\n")
        f.write("{}".format(', '.join([str(costs[u] * args.freqs[-1]) for u in tasks])))
        f.write("];\n")
       
        f.write("Adjmatrix = [\n")
        for i in range(len(tasks)):
            f.write('[')
            f.write("{}".format(' '.join([str(n) for n in adjacency[i]])))
            f.write("],\n")
        f.write("];\n")

        f.write("P_HEFT = [{}];\n".format(' '.join([str(k) for k in P_HEFT])))
        f.write("O_HEFT = [\n")
        for i in range(len(tasks)):
            f.write('[')
            f.write("{}".format(' '.join([str(n) for n in O_HEFT[i]])))
            f.write("],\n")
        f.write("];\n")

        f.close()                   
             

########## main ################################################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="OPL Data Generator")
    parser.add_argument("--in_file", type=str)
    parser.add_argument("--out_file", type=str)

    parser.add_argument("--label", type=str)
    parser.add_argument("--num_cores", type=int, default=4)

    parser.add_argument("--freqs", nargs='*', default=[1.01, 1.26, 1.53, 1.81, 2.10], help="frequencies (smallest to largest)")

    parser.add_argument("--t_sw", type=float, default=5.0, help="time overhead for switching")
    parser.add_argument("--e_sw", type=float, default=385.0, help="energy overhead for switching")
    parser.add_argument("--a", type=float, default=23.8729, help="parameter \"a\" in the power model presented in Eq. 1")
    parser.add_argument("--b", type=float, default=401.6654, help="parameter \"b\" in the power model presented in Eq. 1")
    parser.add_argument("--c", type=float, default=276, help="parameter \"c\" in the power model presented in Eq. 1")
    parser.add_argument("--pow_exp", type=float, default=3.2941, help="value of exponent in the power model presented in Eq. 1")    

    args = parser.parse_args()

    period, tasks, adjacency, costs = read_graph(args.in_file)

    P_HEFT, O_HEFT = HEFT(period, tasks, adjacency, costs)

    write_dat(args, period, tasks, adjacency, costs, P_HEFT, O_HEFT)
