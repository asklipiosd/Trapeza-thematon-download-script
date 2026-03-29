#!/bin/bash

dir="${1:-./geometry-images}"
count=0

if [ ! -d "$dir" ]; then
    echo "Error: Directory '$dir' does not exist"
    exit 1
fi

for img in "$dir"/*; do
    [ -f "$img" ] || continue
    
    avg=$(convert "$img" -format "%[mean]" info: 2>/dev/null)
    if [ -n "$avg" ]; then
        int_avg=${avg%.*}
        if [ "$int_avg" -lt 128 ]; then
            convert "$img" -negate "$img"
            echo "Inverted: $img (mean: $avg)"
            ((count++))
        fi
    fi
done

echo "Total inverted: $count images"