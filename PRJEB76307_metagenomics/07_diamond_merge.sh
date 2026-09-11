#!/usr/bin/env bash

#SBATCH --job-name=diamond_merge
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:05:00
#SBATCH --mem=16G

set -euo pipefail

module load StdEnv/2023 python/3.13.2 scipy-stack/2026a
