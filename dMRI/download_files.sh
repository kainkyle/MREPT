#!/bin/bash

project_dir=$1
subject=$2
session_label=$3

subject_dir="${project_dir}/${subject}"

if [[ ! -e "${subject_dir}" ]]; then 
    mkdir -p "${subject_dir}"/DICOM
    mkdir -p "${subject_dir}"/Raw
fi 



IFS=$'\n'

declare -A sequence_list

sequence_list=(['T1_MEMPRAGE Iso0.9mm_64ch RMS']="T1" ['AP_BLOCK_1_DIFFUSION_30DIR']="DWI_AP1" ['AP_BLOCK_2_DIFFUSION_30DIR']="DWI_AP2" ['PA_BLOCK_1_DIFFUSION_30DIR']="DWI_PA1"  ['PA_BLOCK_2_DIFFUSION_30DIR']="DWI_PA2" ['t2_space_dark-fluid_sag_p2_ns-t2prep new']="FLAIR")





for seq in  "${!sequence_list[@]}" ; do 
    echo "${seq}"
    python ~/Documents/Scripts/Flywheel/Utilities/download_dicom_series.py "${session_label}" "${subject_dir}"/DICOM "${seq}" "${sequence_list[$seq]}"
done

echo "Converting to Nifti"


for seq in  "${!sequence_list[@]}" ; do 
    seq_name="${sequence_list[$seq]}"
    d="${subject_dir}"/DICOM/"${seq_name}"
    if [[ -e "${d}" ]]; then 
        dcm2niix -o "${subject_dir}"/Raw -z y -f "${seq_name}" "${d}"
    fi 
done

for i in "${subject_dir}"/Raw/*.nii.gz ; 
    do echo $i 
done