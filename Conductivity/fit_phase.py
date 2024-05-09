import numpy as np
import nibabel as nib
from scipy.stats import linregress
import sys
from tqdm import tqdm




def find_voxel_center(data_shape):
    # Find the voxel at the center of the image
    center = np.array(data_shape) // 2
    return tuple(center)


def read_time_values(filename):
    with open(filename, 'r') as file:
        # Read the time values from the file, one per line
        time_values = [float(line.strip()) for line in file if line.strip()]
        time_values.sort()  # Sort the time values in ascending order
    return time_values



def linear_regression_4d_nifti(nifti_file, mask_file, time_values_file,output_name):
    # Load the 4D NIfTI file
    img = nib.load(nifti_file)
    data = img.get_fdata()

    # Load the mask file
    mask_img = nib.load(mask_file)
    mask_data = mask_img.get_fdata()

    # Ensure mask and data have the same dimensions
    if mask_data.shape != data.shape[:3]:
        raise ValueError("Mask and data dimensions do not match.")


    
    # Read time values from the input file
    time_values = read_time_values(time_values_file)
    
    print(time_values)


    # Perform linear regression for each voxel inside the mask
    nx, ny, nz, nt = data.shape
    beta_values = np.zeros((nx, ny, nz, 1))  # Initialize beta values array
    intercept_values = np.zeros((nx, ny, nz, 1))  # Initialize intercept values array
    r_squared_values = np.zeros((nx, ny, nz, 1))  # Initialize R-squared values array
    progress_bar = tqdm(total=nx * ny * nz, desc="Processing voxels", unit="voxel")
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                if mask_data[i, j, k] != 0:
                    voxel_values = data[i, j, k, :]
                    slope, intercept, r_value, _, _ = linregress(time_values, voxel_values)
                    beta_values[i, j, k, 0] = slope
                    intercept_values[i, j, k, 0] = intercept
                    r_squared_values[i, j, k, 0] = r_value**2
                progress_bar.update(1)
    progress_bar.close()

    # Create NIfTI images for beta values and R-squared values
    beta_img = nib.Nifti1Image(beta_values, img.affine, img.header)
    intercept_img = nib.Nifti1Image(intercept_values, img.affine, img.header)
    r_squared_img = nib.Nifti1Image(r_squared_values, img.affine, img.header)
    

    # Save the beta values and R-squared values as 3D NIfTI files
    nib.save(beta_img, output_name +'_slope.nii.gz')
    nib.save(intercept_img, output_name +'_intercept.nii.gz')
    nib.save(r_squared_img, output_name +'_r_squared.nii.gz')

    

# Example usage:
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python script.py <nifti_file> <mask_file> <time_values>")
        sys.exit(1)

    nifti_file = sys.argv[1]  # replace 'data.nii.gz' with the path to your 4D NIfTI file
    mask_file = sys.argv[2]   # replace 'mask.nii.gz' with the path to your mask file
    time_values_file = sys.argv[3]  # replace 'time_values.txt' with the path to your time values file
    output_name = sys.argv[4]
    linear_regression_4d_nifti(nifti_file, mask_file, time_values_file, output_name)
