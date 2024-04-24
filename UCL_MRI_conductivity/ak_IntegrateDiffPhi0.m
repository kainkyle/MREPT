function Sigma = ak_IntegrateDiffPhi0(Phi0_diff,dx,KernelHalfSize,B0)
%DESCRIPTION: Sigma = ak_IntegrateDiffPhi0(Phi0_diff,dx,KernelHalfSize,B0)
%solves the integral-based equation for ellipses of size
%KernelHalfSize
%
%INPUTS:
%   Phi0_diff(double array) - first derivatives of the phase
%   dx(double vector)  - image resolution vector (dx,dy,dz) in mm (default = 1 mm isotropic)
%   KernelHalfSize - kernel half size in voxels
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

% Zero padding
for j = 1:3
    [Phi0_diff{j},Slices] = ZeroFilling(Phi0_diff{j},ceil(size(Phi0_diff{j})+2*KernelHalfSize));
end

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

% Calculate volume of the shape
V = ak_volume_of_shape(ds,Shape)*prod(dx);

% Calculate Sigma
Sigma = ak_integral_with_shape(Phi0_diff,ds,Shape)/(mu0*omega*V);

% Crop image
Sigma = Sigma(Slices{1},Slices{2},Slices{3});

end

function Integral = ak_integral_with_shape(Phi0_diff,ds,Shape)
   
    Kernel = zeros(3,1,1);
    Kernel(1,1,1) = -1;
    Kernel(3,1,1) = 1;
    ShapeX = convn(Shape,Kernel,'same').*Shape*ds(1);
    
    Kernel = zeros(1,3,1);
    Kernel(1,1,1) = -1;
    Kernel(1,3,1) = 1;
    ShapeY = convn(Shape,Kernel,'same').*Shape*ds(2);
    
    Kernel = zeros(1,1,3);
    Kernel(1,1,1) = -1;
    Kernel(1,1,3) = 1;
    ShapeZ = convn(Shape,Kernel,'same').*Shape*ds(3);

    Integral = convn(Phi0_diff{1},ShapeX,'same')+convn(Phi0_diff{2},ShapeY,'same')+...
        convn(Phi0_diff{3},ShapeZ,'same');

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
