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

# Convert each page of the PDF into a PDF page
echo "Converting pages of PDF to PDF..."
page_count=$(pdfinfo "$pdf_file" | grep "Pages" | awk '{print $2}')
for ((i=1; i<=$page_count; i++)); do
    echo `$page_${i}`
    pdftk "$pdf_file" cat $i output "${output_dir}/page_${i}.pdf"
done

echo "Conversion complete. PDF files are saved in '${output_dir}' directory."

# Array of texts to search for
search_texts=("Dublin" "Fremont" "Pleasanton" "San Ramon")


# Search for each text in PDFs
echo "Searching for texts in PDFs..."
for file in ${output_dir}/*.pdf; do
    keep_file=false
    for text in "${search_texts[@]}"; do
        if pdftotext "$file" - | grep -q "$text"; then
            echo "Found '$text' in $file. Keeping."
            keep_file=true

            # Convert PDF to SVG
            svg_file="${output_dir}/${text}_detached.svg"
            pdftocairo -svg "$file" "$svg_file"
            echo "Converted $file to $svg_file."
        fi
    done

    if ! $keep_file; then
        echo "Deleting $file..."
        rm "$file"
    fi
done

echo "Search complete. PDF files containing the specified texts are kept."

# Delete remaining files in pdf_pages directory
echo "Cleaning up the directory..."
rm -f "${output_dir}"/*.pdf
# rm -f "${output_dir}"/*.svg

echo "Cleanup complete."
