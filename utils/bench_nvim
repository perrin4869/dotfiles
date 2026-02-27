#!/bin/bash

# Settings
ITERATIONS=25
WARMUPS=5
LOG_FILE="startuptime.log"

echo "⏱️  Measuring Total Neovim Startup"
echo "Mode: $ITERATIONS runs + $WARMUPS warmups"
echo "--------------------------------------"

declare -a timings

for ((i=1; i<=$((ITERATIONS + WARMUPS)); i++)); do
    if [ -e tmp_bench.log ]; then
        rm tmp_bench.log
    fi

    # Run nvim, open a file, and quit immediately
    # --startuptime writes the profile to tmp_bench.log
    nvim --startuptime tmp_bench.log --headless +qall

    # Extract the 'TOTAL' line (the very last timestamp recorded)
    # Using awk to get the first column of the line containing "NVIM STARTED"
    msec=$(grep "NVIM STARTED" tmp_bench.log | tail -n 1 | awk '{print $1}')

    if [ $i -le $WARMUPS ]; then
        echo "  [Warmup]  Run $i: ${msec}ms"
    else
        echo "  [Active]  Run $((i - WARMUPS)): ${msec}ms"
        timings+=("$msec")
    fi
done

# Calculation
sum=0
min=${timings[0]}
max=${timings[0]}

for val in "${timings[@]}"; do
    sum=$(echo "$sum + $val" | bc)
    if (( $(echo "$val < $min" | bc -l) )); then min=$val; fi
    if (( $(echo "$val > $max" | bc -l) )); then max=$val; fi
done

avg=$(echo "scale=2; $sum / $ITERATIONS" | bc)

echo "--------------------------------------"
echo "📊 RESULTS (Avg of $ITERATIONS):"
echo "🚀 Average: ${avg}ms"
echo "📉 Min:     ${min}ms"
echo "📈 Max:     ${max}ms"
echo "--------------------------------------"
