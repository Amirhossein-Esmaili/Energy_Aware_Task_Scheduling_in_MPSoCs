#!/usr/bin/env python2


"""
Generates a configuration file for TGFF.

"""


########## Import Statements ###################################################

from __future__ import print_function
from __future__ import division

import argparse


########## Helper Functions ####################################################

def write_config(args):
    """
    Generates a configuration file for TGFF using the provided command line 
    arguments

    Args:
        args: command line arguments
    """

    with open(args.filename, 'w') as f:
        f.write("seed {}\n".format(args.seed))

        f.write("period_mul {}\n".format(', '.join([str(mul) for mul in args.multiplier])))

        f.write("period_g_deadline {}\n".format(1 if args.not_p_g_d else 0))

        f.write("period_laxity {}\n".format(args.laxity))

        f.write("tg_cnt {}\n".format(args.graph_cnt))

        f.write("task_degree {}\n".format(' '.join([str(deg) for deg in args.task_degree])))

        f.write("task_cnt {}\n".format(' '.join([str(cnt) for cnt in args.task_cnt])))

        f.write("task_unique {}\n".format(1 if args.unique else 0))

        f.write("task_trans_time {}\n".format(args.task_trans_time))

        f.write("task_type_cnt {}\n".format(args.task_type_cnt))
        
        f.write("trans_type_cnt {}\n".format(args.trans_type_cnt))
        
        f.write("tg_write\n")
        f.write("eps_write\n")
        f.write("vcg_write\n")

        f.write("table_cnt {}\n".format(1))
        f.write("table_label {}\n".format("NODE_WORKLOADS"))
        f.write("table_attrib\n")
        f.write("type_attrib {} {}\n".format(args.table_attr, ' '.join([str(v) for v in args.table_attr_values])))
        f.write("pe_write\n")


########## main ################################################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="{}\n{}".format("TGFF Config. Generator Parser", 
        "Please refer to TGFF documentation for description of arguments"), 
            formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument("--filename", type=str)

    parser.add_argument("--seed", type=int)

    parser.add_argument("--multiplier", nargs='*', default=[1])

    parser.add_argument("--not_p_g_d", action="store_false", default=True)

    parser.add_argument("--laxity", type=float, default=2.0)

    parser.add_argument("--graph_cnt", type=int, default=1)

    parser.add_argument("--task_degree", nargs=2, default=[2, 3])
    parser.add_argument("--task_cnt", nargs=2)
    parser.add_argument("--unique", action="store_true", default=False)
    parser.add_argument("--task_trans_time", type=float, default=1)

    parser.add_argument("--task_type_cnt", type=int, default=10)
    parser.add_argument("--trans_type_cnt", type=int, default=5)
    parser.add_argument("--table_attr", type=str, default="execution_time_using_highest_frequency")
    parser.add_argument("--table_attr_values", nargs='*', default=[1, 0.3, 0.0, 0.0]) 

    args = parser.parse_args()

    write_config(args)
