#!/usr/bin/python3
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import argparse
import fileinput
import hashlib
import sys
from multiprocessing import Pool


def get_hashes_and_lines(raw_line):
    hash = hashlib.md5(raw_line[0] + raw_line[1]).hexdigest()
    return hash, raw_line


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--src", type=str)
    parser.add_argument("--tgt", type=str)
    args = parser.parse_args()

    seen = set()
    with fileinput.input(args.src, mode="rb") as isrc, fileinput.input(args.tgt, mode="rb") as itgt, \
         open(args.src + '.dup', mode="wb") as osrc, open(args.tgt + '.dup', mode="wb") as otgt:
        pool = Pool(args.workers)
        results = pool.imap_unordered(get_hashes_and_lines, zip(isrc, itgt), 1000)
        for i, (hash, raw_line) in enumerate(results):
            if hash not in seen:
                seen.add(hash)
                osrc.write(raw_line[0])
                otgt.write(raw_line[1])
            if i % 1000000 == 0:
                print(i, file=sys.stderr, end="", flush=True)
            elif i % 100000 == 0:
                print(".", file=sys.stderr, end="", flush=True)
    print(file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()
