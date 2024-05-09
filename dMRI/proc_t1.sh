subject_dir=$1


get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}


base_dir_full=$(get_abs_filename $subject_dir )
subject=$( basename $base_dir_full )

base_dir="${base_dir_full}"

echo $base_dir

scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
raw_dir="${base_dir}"/Raw
anat_dir="${base_dir}"/Anat
dwi_dir="${base_dir}"/DWI
dti_base=DWI_120_Dir

t1="${raw_dir}"/T1.nii.gz



if [[ ! -e "${t1}" ]]; then
    echo Missing file "${t1}"
    exit
fi 

if [[ ! -e "${anat_dir}" ]]; then 
    mkdir "${anat_dir}"
fi 


cd "${anat_dir}"

fslreorient2std  "${t1}" T1.nii.gz
N4BiasFieldCorrection -i T1.nii.gz -o T1_n4.nii.gz



#### Run AI model for brain extraction ####

echo ~/Documents/Scripts/Utilities/run_brain_extraction.sh T1_n4.nii.gz

bet2  T1_n4.nii.gz T1_n4_brain.nii.gz -m -c 105 115 196

echo 'Running FAST'

mkdir "${anat_dir}"/fast
cp "${anat_dir}"/T1_n4_brain.nii.gz "${anat_dir}"/fast
cd "${anat_dir}"/fast


fast -N -g T1_n4_brain.nii.gz


