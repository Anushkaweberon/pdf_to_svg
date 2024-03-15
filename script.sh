#!/bin/bash

# Check if the input URL is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <pdf_url>"
    exit 1
fi

# Input PDF URL
pdf_url="$1"

# Create a directory to store the PDF pages
output_dir="pdf_pages"
mkdir -p "$output_dir"

# Download the PDF file
echo "Downloading PDF file..."
pdf_file="${output_dir}/input_pdf.pdf"
curl -o "$pdf_file" "$pdf_url"

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download PDF file from the provided URL."
    exit 1
fi

echo "PDF download complete."

# Array of texts to search for
search_texts=("Dublin" "Fremont" "Pleasanton" "San Ramon")

# Search for each text in the PDF
echo "Searching for texts in PDF..."
for text in "${search_texts[@]}"; do
    if pdftotext "$pdf_file" - | grep -q "$text"; then
        echo "Found '$text' in $pdf_file. Keeping."

        # Create a directory for the text
        text_dir="${output_dir}/${text}_pages"
        mkdir -p "$text_dir"

        # Extract pages containing the text
        pdftk "$pdf_file" cat "$(pdftk "$pdf_file" search "$text" | grep "BookmarkPageNumber" | cut -d":" -f2 | tr '\n' ' ')" output "${text_dir}/pages_containing_${text}.pdf"

        # Convert the extracted PDF to SVG
        svg_file="${output_dir}/${text}_detached.svg"
        pdftocairo -svg "${text_dir}/pages_containing_${text}.pdf" "$svg_file"
        echo "Converted pages containing '$text' to $svg_file."


        rm -rf "$text_dir"
        echo "Removed $text_dir."
    fi
done

echo "Search complete."

# Cleanup the directory
echo "Cleaning up the directory..."
rm -f "${output_dir}"/*.pdf

echo "Cleanup complete."
