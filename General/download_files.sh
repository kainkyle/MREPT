#!/bin/bash

# Script to download DICOM series from Flywheel and convert them to Nifti format.

# Usage: download_dicom_files.sh <project_dir> <subject> <session_label>
#   <project_dir>: Path to the project directory where subject data will be stored.
#   <subject>: ID of the subject.
#   <session_label>: Label of the session in Flywheel.


project_dir=$1 
subject=$2     
session_label=$3 


scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Directory for the subject
subject_dir="${project_dir}/${subject}"

# Create subject directory if it doesn't exist
if [[ ! -e "${subject_dir}" ]]; then 
    mkdir -p "${subject_dir}"
fi 




# Define DICOM sequences and corresponding names
declare -A sequence_list

sequence_list=(['greME9_p31_256_Iso1mm_new_Pha']="GRE_phase" ['greME9_p31_256_Iso1mm_new_Mag']="GRE_mag")

sequence_list=(['T1_MEMPRAGE Iso0.9mm_64ch RMS']="T1")



echo "Available sequences: ${!sequence_list[*]}"

# Loop through each sequence and download DICOM series
for seq in "${!sequence_list[@]}" ; do 
    echo "Downloading DICOM for ${seq}"
    python ${scripts}/download_dicom_series.py "${session_label}" "${subject_dir}" "${seq}" "${sequence_list[$seq]}"
done

dicom_dir=$( find "${subject_dir}" -maxdepth 2 -type d -name DICOM)
session_dir=$( dirname "$dicom_dir" )
study_tp=$( basename "$session_dir" )

if [[ ! -e "$session_dir"/Raw ]]; then 
    mkdir "$session_dir"/Raw
fi 

# Convert DICOM to Nifti format
echo "Converting to Nifti"
for seq in "${!sequence_list[@]}" ; do 
    seq_name="${sequence_list[$seq]}"
    
    d="${dicom_dir}"/"${seq_name}"
    if [[ -e "${d}" ]]; then 
        dcm2niix -o "${session_dir}"/Raw -z y -f "$subject"_"$study_tp"_"${seq_name}" "${d}"
    fi 
done

for i in "${subject_dir}"/Raw/*.nii.gz ; do 
    echo "$i" 
done
