#!/bin/bash

set -e

taxi=$(printf "Α' Λυκείου\nΒ' Λυκείου\nΓ' Λυκείου\n" | fzf)
mathima=$(printf "Φυσική\nΦυσική Προσανατολισμού\nΧημεία\nΆλγεβρα\nΓεωμετρία\nΝεοελληνική Γλώσσα\nΛατινικά\nΝεοελληνική Λογοτεχνία\nΜαθηματικά Προσανατολισμού\nΟικονομία\nΙστορία\n" | fzf)
thema=$(printf "1\n2\n3\n4\n" | fzf)

sel=$(grep "/$taxi/$mathima/$thema" /home/asklipios/Trapeza-thematon-download-script/exercises_formatted.txt \
  | sed 's#/.*##' | fzf -m)
mapfile -t arr <<< "$sel"

temp_files=()
for doc_id in "${arr[@]}"; do
    [ -z "$doc_id" ] && continue
    downloaded_file="document_${doc_id}.pdf"
    echo "Downloading thema: $doc_id..."
    wget -q --show-progress -O "$downloaded_file" "https://trapeza.iep.edu.gr/public/showfile.php/?id=${doc_id}&filetype=subject"

    if [ $? -ne 0 ] || [ ! -f "$downloaded_file" ]; then
        echo "Error: Failed to download thema"
        rm -f "${temp_files[@]}"
        exit 1
    fi
    temp_files+=("$downloaded_file")
done

if [ ${#temp_files[@]} -eq 1 ]; then
    merged_file="${temp_files[0]}"
else
    merged_file="docs-${arr[*]}.pdf"
    merged_file="${merged_file// /-}"
    pdfunite "${temp_files[@]}" "$merged_file"
    rm -f "${temp_files[@]}"
fi

tdf -m 1 "$merged_file"
rm -f "$merged_file"
