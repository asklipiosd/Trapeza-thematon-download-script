#!/bin/bash
command -v wget >/dev/null 2>&1 || { echo "Error: wget is required but not installed." >&2; exit 1; }

read -p "Eisage Thema: " doc_id
read -p "Des thema[y/N]: " thema_check
read -p "Katevase fotografia[y/N]: " photo_check
read -p "Katevase thema[y/N]: " down_check


if ! [[ "$doc_id" =~ ^[0-9]+$ ]]; then
    echo "Error: lathos ID"
    exit 1
fi

downloaded_file="document_${doc_id}.pdf"

echo "Downloading thema: $doc_id..."
wget -q --show-progress -O "$downloaded_file" "https://trapeza.iep.edu.gr/public/showfile.php/?id=${doc_id}&filetype=subject"

if [ $? -ne 0 ] || [ ! -f "$downloaded_file" ]; then
    echo "Error: Failed to download thema"
    exit 1
fi
if [[ "$thema_check" == "y" ]]; then
  tdf "$downloaded_file"
  # tdf removed - user can manually process PDF if needed
fi
if [[ "$photo_check" == "y" ]]; then
  pdfimages -all $downloaded_file /home/asklipiosdimoglou/trapeza/document_${doc_id}
fi
if [[ "$down_check" == "y" ]]; then
  echo ""
else
  rm "$downloaded_file"
fi
#tdf "$downloaded_file"
