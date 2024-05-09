
session_dir=$1


get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}


base_dir_full=$(get_abs_filename $session_dir )
subject=$( basename $( dirname $base_dir_full ) )
tp=$( basename  $base_dir_full )



base_dir="${base_dir_full}"


scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
raw_dir="${base_dir}"/Raw
mrept_dir="${base_dir}"/Analysis/MREPT
file_base="$subject"_"$tp"


echo $mrept_dir

if [[ ! -e "$mrept_dir" ]]; then 
    mkdir -p "$mrept_dir"
fi 

if [[ ! -e "$mrept_dir"/unwrapped_phase ]]; then 
    mkdir -p "$mrept_dir"/unwrapped_phase
fi 


# for i in "$raw_dir"/*GRE_phase*.json; do 
#     b=${i%.json}
#     e=$( python "$scripts"/return_field.py "$i" 'EchoTime' )
#     mv "$i" "$raw_dir"/"$e"_GRE_phase.json
#     mv "$b".nii.gz  "$raw_dir"/"$e"_GRE_phase.nii.gz
# done

if [[ ! -e  "$mrept_dir"/echo_times.txt ]]; then 

    for i in "$raw_dir"/*GRE_phase*.json; do 
        b=${i%.json}
        e=$( python "$scripts"/return_field.py "$i" 'EchoTime' )
        echo $e >> "$mrept_dir"/echo_times.txt
    done
fi 


# for i in "$raw_dir"/*GRE_mag*.json; do 
#     b=${i%.json}
#     e=$( python "$scripts"/return_field.py "$i" 'EchoTime' )
#     mv "$i" "$raw_dir"/"$e"_GRE_mag.json
#     mv "$b".nii.gz  "$raw_dir"/"$e"_GRE_mag.nii.gz
# done


# fslmerge -t "$mrept_dir"/"$file_base"_GRE_mag_merged.nii.gz "$raw_dir"/*GRE_mag.nii.gz
# fslmaths "$mrept_dir"/"$file_base"_GRE_mag_merged.nii.gz -Tmedian "$mrept_dir"/"$file_base"_GRE_mag_mean.nii.gz

# hd-bet -i "$mrept_dir"/"$file_base"_GRE_mag_mean.nii.gz -o "$mrept_dir"/"$file_base"_GRE_mag_mean_brain.nii.gz -device 0 -tta 1

# for i in "$raw_dir"/*GRE_phase.nii.gz; do 
#     echo $i
#     b=${i%_phase.nii.gz}
#     out_base=$( basename "$b" )
#     fslmaths "$i" -div 4096 -mul 3.14159 "$mrept_dir"/unwrapped_phase/"$out_base"_phase_rads.nii.gz
# done


# echo "Unwrapping Phase Maps"

# for i in "$raw_dir"/*GRE_phase.nii.gz; do 
#     echo $i
#     b=${i%_phase.nii.gz}
#     out_base=$( basename "$b" )
#     prelude -v -a "$b"_mag.nii.gz -p "$mrept_dir"/unwrapped_phase/"$out_base"_phase_rads.nii.gz -o "$mrept_dir"/unwrapped_phase/"$out_base"_phase_unwrapped.nii.gz -m "$mrept_dir"/"$file_base"_GRE_mag_mean_brain_mask.nii.gz
# done


# fslmerge -t "$mrept_dir"/"$file_base"_phase_unwrapped_merged.nii.gz "$mrept_dir"/unwrapped_phase/*_phase_unwrapped.nii.gz


# python "$scripts"/fit_phase.py "$mrept_dir"/"$file_base"_phase_unwrapped_merged.nii.gz "$mrept_dir"/"$file_base"_GRE_mag_mean_brain_mask.nii.gz "$mrept_dir"/echo_times.txt "$mrept_dir"/"$file_base"


# fslmaths "$mrept_dir"/"$file_base"_intercept.nii.gz -div 2  "$mrept_dir"/"$file_base"_transmit_phase.nii.gz


# echo 'Processing T1'


# fslreorient2std "$raw_dir"/"$file_base"_T1.nii.gz  "$mrept_dir"/"$file_base"_T1.nii.gz
# N4BiasFieldCorrection -i "$mrept_dir"/"$file_base"_T1.nii.gz -o "$mrept_dir"/"$file_base"_T1_n4.nii.gz




# hd-bet -i "$mrept_dir"/"$file_base"_T1_n4.nii.gz -o "$mrept_dir"/"$file_base"_T1_n4_brain.nii.gz -device 0 -tta 1

cd "${mrept_dir}"

# old=$IFS

# IFS=$'\n' 


# c=($( cluster   -i "$file_base"_T1_n4_brain_mask.nii.gz  -t 1 ))

# IFS=$'\t'

# read -r -a l <<< "${c[1]}"

# x_cord=${l[6]}
# y_cord=${l[7]}
# z_cord=${l[8]}

# echo Using Centre of Gravity Coordinates: $x_cord,$y_cord,$z_cord


# IFS=$old

# bet "$file_base"_T1_n4.nii.gz "$file_base"_T1_n4_bet_brain.nii.gz -f 0.3 -s -c $x_cord $y_cord $z_cord

# rm "$file_base"_T1_n4_bet_brain.nii.gz


# brain="$file_base"_T1_n4_brain_mask.nii.gz
# skull="$file_base"_T1_n4_bet_brain_skull.nii.gz


# echo 'Running SIENAX'


# $scripts/sienax_skull_stripped "$file_base"_T1_n4.nii.gz -d -r -P "$brain" "$skull"


# mkdir first

# cp "$file_base"_T1_n4_brain.nii.gz first


# run_first_all -b -i first/"$file_base"_T1_n4_brain.nii.gz -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal -o first/"$file_base"_T1_n4_brain_first


# fslmaths "$file_base"_T1_n4_sienax/I_stdmaskbrain_pve_0_segvent.nii.gz -thr 0.5 -bin -mul 1 "$file_base"_T1_n4_sienax/"$file_base"_vcsf_indexed.nii.gz
# fslmaths "$file_base"_T1_n4_sienax/I_stdmaskbrain_seg_2.nii.gz -bin -mul 2 "$file_base"_T1_n4_sienax/"$file_base"_wm_indexed.nii.gz
# fslmaths "$file_base"_T1_n4_sienax/I_stdmaskbrain_seg_1.nii.gz -add first/"$file_base"_T1_n4_brain_first_all_none_firstseg.nii.gz -bin -mul 3 "$file_base"_T1_n4_sienax/"$file_base"_gm_indexed.nii.gz



# fslmerge -t "$file_base"_tissue_mask.nii.gz "$file_base"_T1_n4_sienax/"$file_base"_vcsf_indexed.nii.gz "$file_base"_T1_n4_sienax/"$file_base"_gm_indexed.nii.gz "$file_base"_T1_n4_sienax/"$file_base"_wm_indexed.nii.gz

# fslmaths "$file_base"_tissue_mask.nii.gz -Tmax "$file_base"_tissue_mask.nii.gz


# flirt -in "$file_base"_T1_n4_brain.nii.gz  -ref "$mrept_dir"/"$file_base"_GRE_mag_mean.nii.gz -out "$file_base"_T1_reg2_GRE.nii.gz -omat "$file_base"_T1_reg2_GRE.mat -dof 6 -searchrx -20 20 -searchry -20 20 -searchrz -20 20 

# flirt -in "$file_base"_tissue_mask.nii.gz -ref "$mrept_dir"/"$file_base"_GRE_mag_mean.nii.gz -out "$file_base"_tissue_mask_reg2_GRE.nii.gz -applyxfm -init "$file_base"_T1_reg2_GRE.mat -interp nearestneighbour

fslmaths "$file_base"_tissue_mask_reg2_GRE.nii.gz -bin "$file_base"_ROI_mask_reg2_GRE.nii.gz






