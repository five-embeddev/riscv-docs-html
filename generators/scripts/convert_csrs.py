#!/bin/env python3

import sys
import os
import shutil
import argparse

parser = argparse.ArgumentParser(
    description='Extract the CSR info from the riscv-opcodes support script.')
parser.add_argument('csr_info', 
                    type=str, 
                    default="../../external/riscv-opcodes/parse-opcodes",
                    help='riscv-opcodes support script')

sys.path.append(os.curdir)

def main(csr_info_in):
    csr_info_out="convert_csr_info.py"
    with open(csr_info_in, "r") as fin:
        with open(csr_info_out,"w") as fout:
            for line in fin:
                if line.find("def ") == 0:
                    break
                fout.write(line)

    from convert_csr_info import csrs, csrs32

    print("{")
    for index, csr in csrs+csrs32:
        print(f'"{csr}" => {index},')
    print("}")


if __name__ == "__main__":
    args = parser.parse_args()
    main(args.csr_info)

