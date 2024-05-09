#!/bin/bash


###########################################################
###     RINSW Blocked dMRI Pre-processing Pipeline      ###   
###########################################################


# Description:

# This script is designed for pre-processing of blocked diffusion-weighted
# imaging (DWI) data, acquired with two blocks of unique diffusion gradient directions per phase encoding polarity (AP and PA). 
# The following processing steps are performed: 
# - Combination of indivdual dMRI blocks
# - Denoise
# - Degibbs
# - Topup
# - Brain extraction
# - Eddy Correction
# - Bias Correction
# - Co-registration to structural T1-WI


# Expected Input:
# - The script expects a session directory which includes a folder with the raw data, and also a folder with the processed structural T1 data. All output will be saved in the folder "DWI", which will be created within the provided session directory.

# The following folders/files are required to run the script:

# Raw: Containing the raw DWI nifti, bvec and bval files.
# Anat: Contains the processed structual T1 files.


#   Subject/
#       |- Session/
#           |- Raw/
#               |- DWI_AP1.nii.gz                   # DWI acquisition (AP phase encoding, block 1)
#               |- DWI_AP1.bvec                     # bvec for DWI_AP1
#               |- DWI_AP1.bval                     # bval for DWI_AP1
#               |- DWI_AP2.nii.gz                   # DWI acquisition (AP phase encoding, block 2)
#               |- DWI_AP2.bvec                     # bvec for DWI_AP2
#               |- DWI_AP2.bval                     # bval for DWI_AP2
#               |- DWI_PA1.nii.gz                   # DWI acquisition (PA phase encoding, block 1)
#               |- DWI_PA1.bvec                     # bvec for DWI_PA1
#               |- DWI_PA1.bval                     # bval for DWI_PA1
#               |- DWI_PA2.nii.gz                   # DWI acquisition (PA phase encoding, block 2)
#               |- DWI_PA2.bvec                     # bvec for DWI_PA2
#               |- DWI_PA2.bval                     # bval for DWI_PA2
#           |- Anat/                                # Anatomical data directory (T1-weighted MRI processing output will be saved here)
#               |- T1_n4.nii.gz                     # N4 Corrected T1
#               |- T1_n4_brain.nii.gz               # Brain extracted T1
#               |- fast/
#                   |- T1_n4_brain_seg_2.nii.gz     # White matter segmentation from FSL-FAST



# Usage:
# Ensure the necessary packages (FSL, MRtrix3, ANTS) are installed.
# Run the script providing the session directory as the first argument:
#   proc_blocked_dmri.sh /path/to/session_directory

# Function to display script description and usage
show_usage() {
    echo ""
    echo "Usage: $0 <session_directory>"
    echo ""
    echo "session_directory: Path to the directory containing session MRI data."
    echo ""
}

# Function get full filepath
get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}


# Function to check of compulsory files exist
check_files_exist() {
    missing_files=()

    # Loop through each file in the list
    for file in "$@"; do
        # Check if the file exists
        if [ ! -e "$file" ]; then
            missing_files+=("$file")  # Add the missing file to the list
        fi
    done

    # If there are missing files, print and then exit
    if [ ${#missing_files[@]} -ne 0 ]; then
        echo "The following files do not exist:"
        for missing_file in "${missing_files[@]}"; do
            echo "$missing_file"
        done
        exit 1
    fi
}

# Function to check if a package is installed
check_package_installed() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed."
        exit 1
    fi
}



check_package_installed fslmaths
check_package_installed mrconvert
check_package_installed N4BiasFieldCorrection


# Check if argument count is correct or if -h flag is provided
if [ "$#" -ne 1 ] || [ "$1" == "-h" ]; then
    show_usage
    exit 1
fi

session_dir=$1

dti_base=DWI_120_Dir




base_dir_full=$(get_abs_filename $session_dir )
base_dir="${base_dir_full}"



scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
anat_dir="${base_dir}"/Anat
raw_dir="${base_dir}"/Raw
dwi_dir="${base_dir}"/DWI





compulsory_files=("${raw_dir}"/DWI_AP1.nii.gz "${raw_dir}"/DWI_AP2.nii.gz "${raw_dir}"/DWI_PA1.nii.gz "${raw_dir}"/DWI_PA2.nii.gz "${raw_dir}"/DWI_AP1.bval "${raw_dir}"/DWI_AP2.bval "${raw_dir}"/DWI_PA1.bval "${raw_dir}"/DWI_PA2.bval "${raw_dir}"/DWI_AP1.bvec "${raw_dir}"/DWI_AP2.bvec "${raw_dir}"/DWI_PA1.bvec "${raw_dir}"/DWI_PA2.bvec "${anat_dir}"/T1_n4.nii.gz "${anat_dir}"/T1_n4_brain.nii.gz "${anat_dir}"/fast/T1_n4_brain_seg_2.nii.gz)


check_files_exist "${compulsory_files[@]}"


### If all compulsory files exist, start pre-processing.


if [[ ! -e "${dwi_dir}" ]]; then 
    mkdir "${dwi_dir}"
fi



# ### Combine indidvidual DWI runs into single Nifti file and output combined bvec and bval files ###

# mrconvert ${raw_dir}/DWI_AP1.nii.gz "${dwi_dir}"/DWI_AP1.mif -fslgrad  ${raw_dir}/DWI_AP1.bvec  ${raw_dir}/DWI_AP1.bval  -force
# mrconvert ${raw_dir}/DWI_AP2.nii.gz "${dwi_dir}"/DWI_AP2.mif -fslgrad  ${raw_dir}/DWI_AP2.bvec  ${raw_dir}/DWI_AP2.bval  -force
# mrconvert ${raw_dir}/DWI_PA1.nii.gz "${dwi_dir}"/DWI_PA1.mif -fslgrad  ${raw_dir}/DWI_PA1.bvec  ${raw_dir}/DWI_PA1.bval  -force
# mrconvert ${raw_dir}/DWI_PA2.nii.gz "${dwi_dir}"/DWI_PA2.mif -fslgrad  ${raw_dir}/DWI_PA2.bvec  ${raw_dir}/DWI_PA2.bval  -force

# dwicat "${dwi_dir}"/DWI_AP1.mif "${dwi_dir}"/DWI_AP2.mif "${dwi_dir}"/DWI_PA1.mif "${dwi_dir}"/DWI_PA2.mif "${dwi_dir}"/"${dti_base}".mif -force
# mrconvert "${dwi_dir}"/"${dti_base}".mif "${dwi_dir}"/"${dti_base}".nii.gz -export_grad_fsl "${dwi_dir}"/"${dti_base}".bvec "${dwi_dir}"/"${dti_base}".bval -force
# rm "${dwi_dir}"/DWI_AP1.mif "${dwi_dir}"/DWI_AP2.mif "${dwi_dir}"/DWI_PA1.mif "${dwi_dir}"/DWI_PA2.mif


cd "${dwi_dir}"

# ### Denoise and Degibbs ###

# dwidenoise "${dti_base}".nii.gz  -noise "$dti_base"_noise.mif  - -force | mrdegibbs - "$dti_base"_pre_processed.nii.gz -axes 0,1 -force


# ## Extract 2 b0s for Topup ###

# bu_file="${dti_base}"_blip_up.nii.gz
# bd_file="${dti_base}"_blip_down.nii.gz


# l=($( fslval  "$dti_base"_pre_processed.nii.gz dim4 ))
# u=$((l  /2 ))

# fslroi "$dti_base"_pre_processed.nii.gz "${bu_file}" 0 1
# fslroi "$dti_base"_pre_processed.nii.gz "${bd_file}" "$u" 1

# fslmerge -t "${dti_base}"_b0s.nii.gz "${bu_file}" "${bd_file}"




# if [[ -e acq_param.txt ]]; then 
#     rm acq_param.txt
# fi 

# bu_b0_length=$( fslval "$bu_file" dim4 )
# for i in $( seq $bu_b0_length ); do echo 0 1 0 0.1 >> acq_param.txt ; done

# bd_b0_length=$( fslval "$bd_file" dim4 )
# for i in $( seq $bd_b0_length ); do echo 0 -1 0 0.1 >> acq_param.txt ; done


# rm "${bu_file}" "${bd_file}"

# ## Run Topup ###


# echo Running Topup

# topup --imain="${dti_base}"_b0s.nii.gz   --datain=acq_param.txt --config=b02b0.cnf --out="$dti_base"_results --fout="$dti_base"_field --iout="$dti_base"_unwrapped_images -v 



# ### Generation of brain mask ###


# fslmaths "$dti_base"_unwrapped_images -Tmean "$dti_base"_b0_corrected_mean.nii.gz ;
# bet "$dti_base"_b0_corrected_mean.nii.gz "$dti_base"_brain.nii.gz  -f 0.2


# sienax  "$dti_base"_brain.nii.gz -d -r

# old=$IFS

# IFS=$'\n' 


# c=($( cluster   -i "$dti_base"_brain_sienax/I_stdmask_segvent.nii.gz  -t 1 ))

# IFS=$'\t'

# read -r -a l <<< "${c[1]}"

# x_cord=${l[6]}
# y_cord=${l[7]}
# z_cord=${l[8]}

# echo Using Centre of Gravity Coordinates: $x_cord,$y_cord,$z_cord


# IFS=$old

# bet "$dti_base"_b0_corrected_mean.nii.gz "$dti_base"_brain.nii.gz -f 0.2 -m -c $x_cord $y_cord $z_cord

# rm -r "$dti_base"_brain_sienax




# ### Define index file for eddy, assuming half of the volumes have reversed phase enoding polarisation ###


# if [[ -e index.txt ]]; then 
#     rm index.txt
# fi 

# l=($( fslval  "$dti_base"_pre_processed.nii.gz dim4 ))
# u=$((l  /2 + 1))
# for ((i=1; i<=$l; i+=1)); do
#     if [[ $i -lt $u ]]; then 
#         indx="$indx 1"
#     else
#         indx="$indx 2"
#     fi 

# done

# echo $indx > index.txt 



# ##### Run Eddy ####


# eddy_cuda10.2  -v --cnr_maps --repol  --imain="${dti_base}"_pre_processed.nii.gz --mask="${dti_base}"_brain_mask.nii.gz --acqp=acq_param.txt --index=index.txt --bvecs="${dti_base}".bvec --bvals="${dti_base}".bval --topup="$dti_base"_results --out="$dti_base"_denoise_eddy_corrected 

# echo eddy_quad "$dti_base"_denoise_eddy_corrected  -idx index.txt -par acq_param.txt -m "$dti_base"_brain_mask.nii.gz -b "${dti_base}".bval


# ##### Run Bias Correction ####


# dwibiascorrect ants "$dti_base"_denoise_eddy_corrected.nii.gz "$dti_base"_denoise_eddy_bias_corrected.nii.gz -fslgrad "$dti_base"_denoise_eddy_corrected.eddy_rotated_bvecs "${dti_base}".bval   -force 



# ### BB co-registration to T1 ###

# dwiextract -bzero "$dti_base"_denoise_eddy_bias_corrected.nii.gz "$dti_base"_denoise_eddy_bias_corrected_b0.nii.gz -fslgrad "$dti_base"_denoise_eddy_corrected.eddy_rotated_bvecs "${dti_base}".bval -force
# fslmaths "$dti_base"_denoise_eddy_bias_corrected_b0.nii.gz -Tmean "$dti_base"_denoise_eddy_bias_corrected_b0_mean.nii.gz
# fslmaths "$dti_base"_denoise_eddy_bias_corrected_b0_mean.nii.gz -mas "${dti_base}"_brain_mask.nii.gz "$dti_base"_denoise_eddy_bias_corrected_b0_mean_brain.nii.gz
# rm "$dti_base"_denoise_eddy_bias_corrected_b0.nii.gz

# epi_reg --epi="$dti_base"_denoise_eddy_bias_corrected_b0_mean_brain.nii.gz --t1="${anat_dir}"/T1_n4.nii.gz --t1brain="${anat_dir}"/T1_n4_brain.nii.gz --out="${dti_base}"_reg2_t1 --wmseg="${anat_dir}"/fast/T1_n4_brain_seg_2.nii.gz

# convert_xfm -omat "${dti_base}"_reg2_t1_inverse.mat -inverse "${dti_base}"_reg2_t1.mat


# ## Fit Tensor Model with FSL-DTIFIT

# dtifit -k "$dti_base"_denoise_eddy_bias_corrected.nii.gz -m   "${dti_base}"_brain_mask.nii.gz -r "$dti_base"_denoise_eddy_corrected.eddy_rotated_bvecs -b "${dti_base}".bval -o "${dti_base}"_DTI_denoise_eddy_corrected_dtifit


# ### Transform FA to T1-WI space

# flirt -in "${dti_base}"_DTI_denoise_eddy_corrected_dtifit_FA.nii.gz -ref "${anat_dir}"/T1_n4_brain.nii.gz -out "${dti_base}"_DTI_denoise_eddy_corrected_dtifit_FA_reg2_t1.nii.gz -applyxfm -init "${dti_base}"_reg2_t1.mat




### Estimate FODs ###

### Estimate response function ###


# voxel_size=1.2

# mrgrid "$dti_base"_denoise_eddy_bias_corrected.nii.gz regrid -template "$dti_base"_denoise_eddy_bias_corrected.nii.gz  -voxel "$voxel_size"  - -force | mrconvert -fslgrad "$dti_base"_denoise_eddy_corrected.eddy_rotated_bvecs "${dti_base}".bval  - "$dti_base"_denoise_eddy_bias_corrected_iso.mif   -force

# mrgrid "${dti_base}"_brain_mask.nii.gz  regrid -template "${dti_base}"_brain_mask.nii.gz -voxel "$voxel_size" "$dti_base"_brain_mask_iso.nii.gz -force
# fslmaths "$dti_base"_brain_mask_iso.nii.gz -bin "$dti_base"_brain_mask_iso.nii.gz

# dwi2response dhollander "$dti_base"_denoise_eddy_bias_corrected_iso.mif RF_WM_DHol.txt RF_GM_DHol.txt RF_CSF_DHol.txt -mask "$dti_base"_brain_mask_iso.nii.gz -force -voxels "$dti_base"_rf_voxels.nii.gz -force


# dwi2fod msmt_csd "$dti_base"_denoise_eddy_bias_corrected_iso.mif RF_WM_DHol.txt WM_FODs.mif RF_GM_DHol.txt GM_FODs.mif RF_CSF_DHol.txt CSF_FODs.mif -mask "$dti_base"_brain_mask_iso.nii.gz -force


# sh2peaks WM_FODs.mif peaks.nii.gz -num 3 -force ;

# docker run -v "$PWD":/data --gpus all wasserth/tractseg_container:master TractSeg -i /data/peaks.nii.gz -o /data --output_type tract_segmentation
# docker run -v "$PWD":/data --gpus all wasserth/tractseg_container:master TractSeg -i /data/peaks.nii.gz -o /data --output_type endings_segmentation
# docker run -v "$PWD":/data --gpus all wasserth/tractseg_container:master TractSeg -i /data/peaks.nii.gz -o /data --output_type TOM
# docker run -v "$PWD":/data --gpus all wasserth/tractseg_container:master Tracking -i /data/peaks.nii.gz -o /data --tracking_format tck


# TractSeg -i peaks.nii.gz --bundle_specific_thr 
# TractSeg -i peaks.nii.gz --output_type endings_segmentation --postprocess 
# TractSeg -i peaks.nii.gz --output_type TOM --bundle_specific_thr 
# Tracking -i peaks.nii.gz --tracking_dir TOM_trackings_filt --tracking_format tck --nr_fibers 10000 

dwi2tensor  "$dti_base"_denoise_eddy_bias_corrected_iso.mif "$dti_base"_denoise_eddy_bias_corrected_iso_tensor.mif -force

if [[ ! -e brain_tensors ]]; then
		mkdir brain_tensors
fi 

tensor2metric -mask "$dti_base"_brain_mask_iso.nii.gz  -fa brain_tensors/"$dti_base"_denoise_eddy_bias_corrected_iso_tensor_FA.nii.gz  -adc brain_tensors/"$dti_base"_denoise_eddy_bias_corrected_iso_tensor_MD.nii.gz -ad brain_tensors/"$dti_base"_denoise_eddy_bias_corrected_iso_tensor_AD.nii.gz -rd brain_tensors/"$dti_base"_denoise_eddy_bias_corrected_iso_tensor_RD.nii.gz  "$dti_base"_denoise_eddy_bias_corrected_iso_tensor.mif -force
