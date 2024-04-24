
%% Corresponding abstract and paper:  
%
% Karsa, Anita, et al. "New Approaches for Simultaneous Noise Suppression 
% and Edge Preservation in Quantitative Conductivity Mapping From Low-SNR 
% Data." Proceedings of the 29th Annual Meeting of ISMRM. p.3774. 2021.
%
% TBC

%% Calculating the conductivity map by solving the differential equation

%---------Arguments---------

Inputs.PhaseMap = %(3D array) - B1 phase map in radians (you may need to 
%divide by 2 to get the B1 transmit phase)

Inputs.TissueMask = %(3D array) - Tissue mask including all voxels with 
%reliable phase information. This is different from the ROI mask which is 
%just a portion of the Tissue mask.

Inputs.Method = %(string) - 'ell','mag','seg', or 'magseg' specifies the 
%edge preservation method (see abstracts and paper for more details). 'ell' 
%performs a 3D quadratic fit within an ellipsoid around each voxel, while
%'mag', 'seg', and 'magseg' include magnitude- and/or segmentation-based
%edge preservation.

Inputs.KernelRadii = %(vector) - Radii (along x,y,z in mm) of the ellipsoid where 
%the 3D quadratic fit is performed. We have found the optimal kernel radii
%in an image with magnitude SNR = 16 and 1 mm isotropic resolution to be:
% 'ell' - [9 9 9]
% 'mag' - [11 11 11]
% 'seg' - [11 11 11]
% 'magseg' - [13 13 13]

Inputs.Resolution = %(vector) - Resolution in mm

Inputs.FieldStrength = %(double) - Main magnetic field strength in Tesla

%---------Optional inputs for Inputs.Method = 'mag','seg', or 'magseg'---------

Inputs.ROImask = %(3D array) - ROI mask where the conductivity is to be cal-
%culated. For Inputs.Method = 'mag','seg', or 'magseg', processing a whole
%brain could take several hours (especially when using large kernels). This
%option allows the user to calculate the conductivity values within a
%specific ROI only, thus considerably reducing the processing time.

Inputs.MagnitudeMap = %(3D array) - Magnitude image for Inputs.Method = 
%'mag' and 'magseg'

Inputs.LabelMap = %(3D array) - Segmentation label map with integer values
% for Inputs.Method = 'seg' and 'magseg'

ConductivityMap = Laplacian_based_QCM(Inputs);

%% Calculating the conductivity map by solving the integral equation

%---------Arguments---------

Inputs.PhaseMap = %(3D array) - B1 phase map in radians (you may need to 
%divide by 2 to get the B1 transmit phase)

Inputs.TissueMask = %(3D array) - Tissue mask including all voxels with 
%reliable phase information. This is different from the ROI mask which is 
%just a portion of the Tissue mask.

Inputs.Method = %(string) - 'ell','mag','seg', or 'magseg' specifies the 
%edge preservation method (see abstracts and paper for more details). 'ell' 
%performs a 3D quadratic fit within an ellipsoid around each voxel to cal-
%culate the first derivatives followed by surface integration on another 
%ellipsoid. 'mag', 'seg', and 'magseg' include magnitude- and/or segmenta-
%tion-based edge preservation for both steps.

Inputs.KernelRadiiDiff = %(vector) - Radii (along x,y,z in mm) of the ellipsoid 
%where the 3D quadratic fit to estimate the first derivatives is performed. 
%We have found the optimal kernel radii in an image with magnitude SNR = 16 
%and 1 mm isotropic resolution to be:
% 'ell' - [5 5 5]
% 'mag' - [10 10 10]
% 'seg' - [9 9 9]
% 'magseg' - [10 10 10]

Inputs.KernelRadiiInt = %(vector) - Radii (along x,y,z in mm) of the ellipsoid 
%where the surface integral is performed. We have found the optimal kernel 
%radii in an image with magnitude SNR = 16 and 1 mm isotropic resolution to 
%be:
% 'ell' - [6 6 6]
% 'mag' - [14 14 14]
% 'seg' - [10 10 10]
% 'magseg' - [20 20 20]

Inputs.Resolution = %(vector) - Resolution in mm

Inputs.FieldStrength = %(double) - Main magnetic field strength in Tesla

%---------Optional inputs for Inputs.Method = 'mag','seg', or 'magseg'---------

Inputs.ROImask = %(3D array) - ROI mask where the conductivity is to be cal-
%culated. For Inputs.Method = 'mag','seg', or 'magseg', processing a whole
%brain could take several hours (especially when using large kernels). This
%option allows the user to calculate the conductivity values within a
%specific ROI only, thus considerably reducing the processing time.

Inputs.MagnitudeMap = %(3D array) - Magnitude image for Inputs.Method = 
%'mag' and 'magseg'

Inputs.LabelMap = %(3D array) - Segmentation label map with integer values
% for Inputs.Method = 'seg' and 'magseg'

ConductivityMap = Surface_integral_based_QCM(Inputs);