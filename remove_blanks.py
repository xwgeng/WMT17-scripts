#!/usr/bin/python3
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import argparse
import fileinput
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--src", type=str)
    parser.add_argument("--tgt", type=str)
    args = parser.parse_args()

    seen = set()
    with fileinput.input(args.src, mode="r") as isrc, fileinput.input(args.tgt, mode="r") as itgt, \
         open(args.src + '.rmb', mode="w") as osrc, open(args.tgt + '.rmb', mode="w") as otgt:
        for i, (src_line, tgt_line) in enumerate(zip(isrc, itgt)):
            src_line, tgt_line = src_line.strip(), tgt_line.strip()
            if len(src_line) > 0 and len(tgt_line) > 0:
                osrc.write(src_line + '\n')
                otgt.write(tgt_line + '\n')
            if i % 1000000 == 0:
                print(i, file=sys.stderr, end="", flush=True)
            elif i % 100000 == 0:
                print(".", file=sys.stderr, end="", flush=True)
    print(file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()
