function nii_3d = load_data(filepath)
    % Load the NIfTI file
    nii = niftiread(filepath);

    % Extract the dimensions of the image
    dims = nii_info.ImageSize;

    % Reshape the 3D array
    nii_3d = reshape(nii, dims);
end