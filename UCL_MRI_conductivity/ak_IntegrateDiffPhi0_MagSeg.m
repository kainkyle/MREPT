function Sigma = ak_IntegrateDiffPhi0_MagSeg(Phi0_diff,Mag,Labels,mask,dx,KernelHalfSize,Gauss_std,B0)
%DESCRIPTION: Sigma = ak_IntegrateDiffPhi0_MagSeg(Phi0_diff,Mag,Labels,mask,dx,KernelHalfSize,Gauss_std,B0)
%solves the integral-based equation for ellipsoids of size
%KernelHalfSize with magnitude- and segmentation-based restrictions
%
%INPUTS:
%   Phi0_diff(double array) - first derivatives of the phase
%   Mag(double array)  - magnitude image
%   Labels(double array)  - segmentation label map
%   mask(double array) - image mask (set to 2 where the derivatives are to be estimated)
%   dx(double vector)  - image resolution vector (dx,dy,dz) in mm (default = 1 mm isotropic)
%   KernelHalfSize - kernel half size in voxels
%   Gauss_std - standard deviation of the magnitude weighting
%   B0(double) - main magnetic field in Tesla
%
%OUTPUTS:
%   Sigma(double array) - conductivity map
%
%DEPENDENCIES:
%   None
%
%AUTHOR:
%   Anita Karsa, University College London, 2020

warning('off','MATLAB:rankDeficientMatrix');

% Zero padding
for j = 1:3
    [Phi0_diff{j},Slices] = ZeroFilling(Phi0_diff{j},ceil(size(Phi0_diff{j})+2*KernelHalfSize));
end
Mag = ZeroFilling(Mag,ceil(size(Mag)+2*KernelHalfSize));
mask = ZeroFilling(mask,ceil(size(mask)+2*KernelHalfSize));
Labels = ZeroFilling(Labels,ceil(size(Labels)+2*KernelHalfSize));

% mu0 and omega
mu0 = 4*pi*1e-7;
omega = B0*267.52219;
% *10^+6 for the gyromagnetic ratio,
% but * 10^-6 because of the conversion from mm to m

% Calculate the infinitesimal area vector
ds = [dx(2)*dx(3) dx(1)*dx(3) dx(1)*dx(2)];

% Create ellipsoidal kernel shape
[Y,X,Z] = meshgrid(dx(2)*(-KernelHalfSize(2):KernelHalfSize(2)),dx(1)*(-KernelHalfSize(1):KernelHalfSize(1)),dx(3)*(-KernelHalfSize(3):KernelHalfSize(3)));
Shape = X.^2/(KernelHalfSize(1)*dx(1))^2+Y.^2/(KernelHalfSize(2)*dx(2))^2+Z.^2/(KernelHalfSize(3)*dx(3))^2;
Shape(Shape<=1) = 1;
Shape(Shape~=1) = 0;

% Identify voxels where the calculations are to be carried out
Indices = find(mask==2);
[Indx,Indy,Indz] = ind2sub(size(mask),Indices);
mask(mask~=0) = 1;

% Normalise magnitude
Mag = Mag.*mask;
Mag = Mag - mean(Mag(mask==1));
if std(Mag(mask==1))~=0 
    Mag = Mag/std(Mag(mask==1));
end
Mag(mask==0) = 100;

% Separate the label map into connected regions
Labs = unique(Labels(:).*mask(:));
Labs = Labs(Labs~=0);
for k = 1:length(Labs)
    regions = zeros(size(mask));
    regions(Labels==Labs(k)) = 1;
    regions = bwlabeln(regions,6);
    Labels(Labels==Labs(k)) = 0;
    Labels(regions~=0) = regions(regions~=0) + max(Labels(:));
end
Labels = Labels.*mask;

parfor j = 1:length(Indices)
    % Patch
    indx = (Indx(j)-KernelHalfSize(1)):(Indx(j)+KernelHalfSize(1));
    indy = (Indy(j)-KernelHalfSize(2)):(Indy(j)+KernelHalfSize(2));
    indz = (Indz(j)-KernelHalfSize(3)):(Indz(j)+KernelHalfSize(3));
    
    % Magnitude patch
    Mag_patch = Mag(indx,indy,indz);
    Mag_patch = abs(Mag_patch - Mag_patch(KernelHalfSize(1)+1,KernelHalfSize(2)+1,KernelHalfSize(3)+1));
    
    % Labels patch
    Labels_patch = Labels(indx,indy,indz);
    Label = Labels_patch(KernelHalfSize(1)+1,KernelHalfSize(2)+1,KernelHalfSize(3)+1);
    
    % Redefine Shape
    Shape_patch = Shape;
    for k = 1:max(KernelHalfSize)
        Edges = bwperim(Shape_patch,26);
        Shape_patch(or(and(Edges==1,Mag_patch>Gauss_std),and(Edges==1,Labels_patch~=Label))) = 0;
    end
    
    % Calculate volume
    V = ak_volume_of_shape(ds,Shape_patch)*prod(dx);
    
    % Find surfaces facing in all directions
    Kernel = zeros(3,1,1);
    Kernel(1,1,1) = -1;
    Kernel(3,1,1) = 1;
    ShapeX = convn(Shape_patch,Kernel,'same').*Shape_patch*ds(1);
    
    Kernel = zeros(1,3,1);
    Kernel(1,1,1) = -1;
    Kernel(1,3,1) = 1;
    ShapeY = convn(Shape_patch,Kernel,'same').*Shape_patch*ds(2);
    
    Kernel = zeros(1,1,3);
    Kernel(1,1,1) = -1;
    Kernel(1,1,3) = 1;
    ShapeZ = convn(Shape_patch,Kernel,'same').*Shape_patch*ds(3);
    
    % Calculate Sigma
    Weighted = Phi0_diff{1}(indx,indy,indz).*ShapeX + Phi0_diff{2}(indx,indy,indz).*ShapeY +...
        Phi0_diff{3}(indx,indy,indz).*ShapeZ;
    Sigma_pseudo(j) = -sum(Weighted(:))/(mu0*omega*V);
    
end

Sigma = zeros(size(Mag));
Sigma(Indices) = Sigma_pseudo;

% Crop image
Sigma = Sigma(Slices{1},Slices{2},Slices{3});

end

function Volume = ak_volume_of_shape(ds,Shape)

Kernel = zeros(3,3,3);
Kernel([1 3],2,2) = ds(1);
Kernel(2,[1 3],2) = ds(2);
Kernel(2,2,[1 3]) = ds(3);
Kernel = Kernel/sum(Kernel(:));

Volume = convn(Shape,Kernel,'same').*Shape;
Volume = sum(Volume(:));

end
