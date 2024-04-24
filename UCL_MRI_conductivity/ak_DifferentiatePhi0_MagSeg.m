function [Diff1s,Diff2s] = ak_DifferentiatePhi0_MagSeg(Phi0,Mag,Labels,mask,dx,KernelHalfSize,Gauss_std)
%DESCRIPTION: [Diff1s,Diff2s] = ak_DifferentiatePhi0_MagSeg(Phi0,Mag,Labels,mask,dx,KernelHalfSize,Gauss_std);
%             Calculates the first and second derivatives of Phi0 based on
%             Lee et al., MRM, 76:530–539, 2016 combined with segmentations
%
%INPUTS:
%   Phi0(double array) - input image in radians
%   Mag(double array)  - magnitude image
%   Labels(double array)  - segmentation label map
%   mask(double array) - image mask (set to 2 where the derivatives are to be estimated)
%   dx(double vector)  - image resolution vector (dx,dy,dz) in mm (default = 1 mm isotropic)
%   KernelHalfSize - kernel half size in voxels
%   Gauss_std - standard deviation of the magnitude weighting
%
%OUTPUTS:
%   Diff1s(a 3-by-1 cell of double array) - First derivatives is each direction
%   Diff2s(a 3-by-1 cell of double array) - Second derivatives is each direction
%
%DEPENDENCIES:
%   None
%
%AUTHOR: 
%   Anita Karsa, University College London, 2019

% Zero padding
[Phi0,Slices] = ZeroFilling(Phi0,ceil(size(Phi0)+2*KernelHalfSize));
Mag = ZeroFilling(Mag,ceil(size(Mag)+2*KernelHalfSize));
mask = ZeroFilling(mask,ceil(size(mask)+2*KernelHalfSize));
Labels = ZeroFilling(Labels,ceil(size(Labels)+2*KernelHalfSize));

% Generate ellipsoidal kernel
[Y,X,Z] = meshgrid(dx(2)*(-KernelHalfSize(2):KernelHalfSize(2)),dx(1)*(-KernelHalfSize(1):KernelHalfSize(1)),dx(3)*(-KernelHalfSize(3):KernelHalfSize(3)));
InsideEllipsoid = find(X.^2/(KernelHalfSize(1)*dx(1))^2+Y.^2/(KernelHalfSize(2)*dx(2))^2+Z.^2/(KernelHalfSize(3)*dx(3))^2<=1);
X = X(InsideEllipsoid);
Y = Y(InsideEllipsoid);
Z = Z(InsideEllipsoid);
A = [X(:).^2 X(:) Y(:).^2 Y(:) Z(:).^2 Z(:) ones(numel(X),1) X(:).*Y(:) X(:).*Z(:) Z(:).*Y(:)];

% Identify voxels where the differentiation is to be carried out
Indices = find(mask==2);
[Indx,Indy,Indz] = ind2sub(size(mask),Indices);
mask(mask~=0) = 1;

% Normalise magnitude image
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
    
    % Phase patch
    indx = Indx(j); indy = Indy(j); indz = Indz(j);
    Phi0_patch = Phi0((indx-KernelHalfSize(1)):(indx+KernelHalfSize(1)),...
        (indy-KernelHalfSize(2)):(indy+KernelHalfSize(2)),(indz-KernelHalfSize(3)):(indz+KernelHalfSize(3)));
    Phi0_patch = Phi0_patch(InsideEllipsoid);
    
    % Labels patch
    Labels_patch = Labels((indx-KernelHalfSize(1)):(indx+KernelHalfSize(1)),...
        (indy-KernelHalfSize(2)):(indy+KernelHalfSize(2)),(indz-KernelHalfSize(3)):(indz+KernelHalfSize(3)));
    Label = Labels_patch(KernelHalfSize(1)+1,KernelHalfSize(2)+1,KernelHalfSize(3)+1);
    Labels_patch = Labels_patch(InsideEllipsoid);
    
    % Magnitude_patch
    Mag_patch = Mag((indx-KernelHalfSize(1)):(indx+KernelHalfSize(1)),...
        (indy-KernelHalfSize(2)):(indy+KernelHalfSize(2)),(indz-KernelHalfSize(3)):(indz+KernelHalfSize(3)));
    Mag_middle = Mag_patch(KernelHalfSize(1)+1,KernelHalfSize(2)+1,KernelHalfSize(3)+1);
    Mag_patch = Mag_patch(InsideEllipsoid);
    
    % Calculate weights
    Weights = Mag_patch - Mag_middle;
    Weights = exp(-Weights.^2/(2*Gauss_std^2));
        
    % Exclude different segmentations
    A_patch = A(Labels_patch==Label,:);
    Weights = Weights(Labels_patch==Label);
    Phi0_patch = Phi0_patch(Labels_patch==Label);
    
    % Calculate coefficients
    Coeffs = (A_patch.*repmat(Weights(:),[1 10]))\(Phi0_patch(:).*Weights(:));
    AllCoeffs(:,j) = Coeffs(1:6);
    
end

% Sort fitted coefficients into Diff1s and Diff2s
for j = 1:3
    Diff1s{j} = zeros(size(mask));
    Diff1s{j}(Indices) = -AllCoeffs(2*j,:); 
    Diff1s{j} = Diff1s{j}(Slices{1},Slices{2},Slices{3});
    Diff1s{j}(isnan(Diff1s{j})) = 0;
    Diff1s{j}(isinf(Diff1s{j})) = 0;
    
    Diff2s{j} = zeros(size(mask));
    Diff2s{j}(Indices) = 2*AllCoeffs(2*j-1,:); 
    Diff2s{j} = Diff2s{j}(Slices{1},Slices{2},Slices{3});
    Diff2s{j}(isnan(Diff2s{j})) = 0;
    Diff2s{j}(isinf(Diff2s{j})) = 0;
end


