#!/bin/bash

set -e

output_dir="geometry-images"
mkdir -p "$output_dir"

ids=$(cat ~/Trapeza-thematon-download-script/exercises_formatted.txt | grep "Γεωμετρία" | cut -d'/' -f1 | sort -u)

for doc_id in $ids; do
    [ -z "$doc_id" ] && continue
    downloaded_file="document_${doc_id}.pdf"
    echo "Downloading thema: $doc_id..."
    
    if wget -q --show-progress -O "$downloaded_file" "https://trapeza.iep.edu.gr/public/showfile.php/?id=${doc_id}&filetype=subject"; then
        echo "Extracting images from $downloaded_file..."
        pdfimages -png -list "$downloaded_file" "$output_dir/${doc_id}_" 2>/dev/null || true
        pdfimages -png "$downloaded_file" "$output_dir/${doc_id}_"
        rm -f "$downloaded_file"
        echo "Done with $doc_id"
    else
        echo "Error: Failed to download thema $doc_id"
        rm -f "$downloaded_file"
    fi
done

echo "All done! Images saved to $output_dir"