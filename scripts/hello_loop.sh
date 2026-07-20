#!/bin/bash
start=$(date +%s.%N)

for i in $(seq 1 1000); do
    echo "Hello, World! ($i)"
done

end=$(date +%s.%N)
elapsed=$(echo "$end - $start" | bc)

echo "----------------------------------------"
echo "Completed 100 iterations in $elapsed seconds"
