import os
import csv
import pandas as pd

def process_folders(root_dir='vanilla'):
    """
    Walks through the directory structure and merges the files in leaf folders.
    """
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Skip if no files in this directory
        if not filenames:
            continue

        # Group files by prefix
        file_groups = {}
        for filename in filenames:
            # Skip hidden files or non-relevant files
            if filename.startswith('.'):
                continue
                
            print(f"Processing file {filename}")
            # Extract prefix (e.g., "from_eu" from "app_from_eu.csv")
            prefix = filename.split('.csv')[0] if '.csv' in filename else filename
            
            if prefix not in file_groups:
                file_groups[prefix] = []
            file_groups[prefix].append(filename)
        
        print(f"Processing directory {dirpath}")
        print(f"Found file groups: {file_groups}")
        # Process each group of files
        for prefix, files in file_groups.items():
            # Look for the pair of files (text file and CSV)
            csv_file = None
            txt_file = None
            
            for file in files:
                if file.endswith('.csv'):
                    csv_file = os.path.join(dirpath, file)
                elif not file.endswith('.csv'):
                    txt_file = os.path.join(dirpath, file)
            print(f"Processing csv_file: {csv_file} and txt_file: {txt_file}")
            
            # If we found both files, merge them
            if csv_file and txt_file:
                merge_files(txt_file, csv_file, dirpath)

def merge_files(txt_file, csv_file, output_dir):
    """
    Merges a text file and a CSV file, adding the text file content as a new column.
    """
    # Read the text file
    with open(txt_file, 'r') as f:
        text_lines = [line.strip() for line in f.readlines()]
    
    # Read the CSV file
    df = pd.read_csv(csv_file)
    
    # Verify both files have the same number of rows
    if len(df) != len(text_lines):
        print(f"Warning: Files {txt_file} and {csv_file} have different number of rows. Skipping.")
        return
    
    # Add text file data as a new column
    df[ "Worker"] = text_lines
    
    # Save the merged result
    output_file = os.path.join(output_dir, f"merged_{os.path.basename(csv_file)}")
    df.to_csv(output_file, index=False)
    print(f"Merged file saved to {output_file}")

if __name__ == "__main__":
    process_folders()
    print("Processing complete.")