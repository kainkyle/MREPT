function [Diff1s,Diff2s] = ak_DifferentiatePhi0(Phi0,dx,KernelHalfSize,IsDiffs)
%DESCRIPTION: [Diff1s,Diff2s] = ak_DifferentiatePhi0(Phi0,mask,dx);
%             Calculates the first and second derivatives of Phi0 
%
%INPUTS:
%   Phi0(double array) - input image in radians
%   mask(double array) - image mask
%   dx(double vector)  - image resolution vector (dx,dy,dz) in mm (default = 1 mm isotropic)
%   IsDiffs(binary)    - (0 1) to calculate decond derivatives only,
%                        (1 1) to calculate both first and second derivatives
%
%OUTPUTS:
%   Diff1s(a 3-by-1 cell of double array) - First derivatives is each direction
%   Diff2s(a 3-by-1 cell of double array) - Second derivatives is each direction
%
%DEPENDENCIES:
%   ZeroFilling.m
%
%AUTHOR: 
%   Anita Karsa, University College London, 2019

% Version 1
% Diff1s{1} = zeros(size(Phi0));
% Diff1s{1}(1:end-1,:,:) = diff(Phi0,1,1)/dx(1);
% Diff1s{2} = zeros(size(Phi0));
% Diff1s{2}(:,1:end-1,:) = diff(Phi0,1,2)/dx(2);
% Diff1s{3} = zeros(size(Phi0));
% Diff1s{3}(:,:,1:end-1) = diff(Phi0,1,3)/dx(3);
% 
% Diff2s{1} = zeros(size(Phi0));
% Diff2s{1}(2:end-1,:,:) = diff(Phi0,2,1)/dx(1)^2;
% Diff2s{2} = zeros(size(Phi0));
% Diff2s{2}(:,2:end-1,:) = diff(Phi0,2,2)/dx(2)^2;
% Diff2s{3} = zeros(size(Phi0));
% Diff2s{3}(:,:,2:end-1) = diff(Phi0,2,3)/dx(3)^2;

% Version 2
% Diff1s{1} = zeros(size(Phi0));
% Diff1s{1}(2:end-1,:,:) = (Phi0(3:end,:,:) - Phi0(1:end-2,:,:))/(2*dx(1));
% Diff1s{2} = zeros(size(Phi0));
% Diff1s{2}(:,2:end-1,:) = (Phi0(:,3:end,:) - Phi0(:,1:end-2,:))/(2*dx(2));
% Diff1s{3} = zeros(size(Phi0));
% Diff1s{3}(:,:,2:end-1) = (Phi0(:,:,3:end) - Phi0(:,:,1:end-2))/(2*dx(3));
% 
% Diff2s{1} = zeros(size(Phi0));
% Diff2s{1}(2:end-1,:,:) = (Phi0(3:end,:,:) + Phi0(1:end-2,:,:) - 2*Phi0(2:end-1,:,:))/dx(1)^2;
% Diff2s{2} = zeros(size(Phi0));
% Diff2s{2}(:,2:end-1,:) = (Phi0(:,3:end,:) + Phi0(:,1:end-2,:) - 2*Phi0(:,2:end-1,:))/dx(2)^2;
% Diff2s{3} = zeros(size(Phi0));
% Diff2s{3}(:,:,2:end-1) = (Phi0(:,:,3:end) + Phi0(:,:,1:end-2) - 2*Phi0(:,:,2:end-1))/dx(3)^2;




% Version 3

[Phi0,Slices] = ZeroFilling(Phi0,ceil(size(Phi0)+2*KernelHalfSize));

%KernelHalfSize = [1 1 1];
[Y,X,Z] = meshgrid(dx(2)*(-KernelHalfSize(2):KernelHalfSize(2)),dx(1)*(-KernelHalfSize(1):KernelHalfSize(1)),dx(3)*(-KernelHalfSize(3):KernelHalfSize(3)));
InsideEllipsoid = find(X.^2/(KernelHalfSize(1)*dx(1))^2+Y.^2/(KernelHalfSize(2)*dx(2))^2+Z.^2/(KernelHalfSize(3)*dx(3))^2<=1);
X = X(InsideEllipsoid);
Y = Y(InsideEllipsoid);
Z = Z(InsideEllipsoid);

A = [X(:).^2 X(:) Y(:).^2 Y(:) Z(:).^2 Z(:) ones(numel(X),1) X(:).*Y(:) X(:).*Z(:) Z(:).*Y(:)];

%Delta = [10 10 10];
%Weights = exp(-X(:).^2/(2*Delta(1)^2)-Y(:).^2/(2*Delta(2)^2)-Z(:).^2/(2*Delta(3)^2));
Weights = ones(size(A,1),1);
A = A.*repmat(Weights(:),[1 size(A,2)]);

% Additional magnitude weighting somehow? In the Lee 2016 paper it's
% actually Gauss(abs(M(r)-M(r0)))

A = pinv(A);

if IsDiffs(1)
    % First derivatives in the middle => bx, by, and bz
    for j = 1:3
        Kernel = zeros(2*KernelHalfSize+1);
        Kernel(InsideEllipsoid) = A(2*j,:)'.*Weights(:);
        Kernel = ZeroFilling(Kernel,size(Phi0));
        Diff1s{j} = fftshift(ifftn(ifftshift( fftshift(fftn(ifftshift(Phi0))) .* fftshift(fftn(ifftshift(Kernel))) )));
        Diff1s{j} = Diff1s{j}(Slices{1},Slices{2},Slices{3});
    end
else
    Diff1s = 0;
end

if IsDiffs(2)
    % Second derivatives in the middle => 2ax, 2ay, and 2az
    for j = 1:3
        Kernel = zeros(2*KernelHalfSize+1);
        Kernel(InsideEllipsoid) = A(2*j-1,:)'.*Weights(:);
        Kernel = ZeroFilling(Kernel,size(Phi0));
        Diff2s{j} = 2 * fftshift(ifftn(ifftshift( fftshift(fftn(ifftshift(Phi0))) .* fftshift(fftn(ifftshift(Kernel))) )));
        Diff2s{j} = Diff2s{j}(Slices{1},Slices{2},Slices{3});
    end
else
    Diff2s = 0;
end




% % Version 4 (parallel computing)
% KernelHalfSize = [12 12 7];
% [Y,X,Z] = meshgrid(dx(2)*-KernelHalfSize(2):KernelHalfSize(2),dx(1)*-KernelHalfSize(1):KernelHalfSize(1),dx(3)*-KernelHalfSize(3):KernelHalfSize(3));
% A = [X(:).^2 X(:) Y(:).^2 Y(:) Z(:).^2 Z(:) ones(numel(X),1) X(:).*Y(:) X(:).*Z(:) Z(:).*Y(:)];
% 
% Indices = find(mask==1);
% [Indx,Indy,Indz] = ind2sub(size(mask),Indices);
% 
% parfor j = 1:length(Indx)
%     indx = Indx(j); indy = Indy(j); indz = Indz(j);
%     Phi0_patch = Phi0((indx-KernelHalfSize(1)):(indx+KernelHalfSize(1)),...
%         (indy-KernelHalfSize(2)):(indy+KernelHalfSize(2)),(indz-KernelHalfSize(3)):(indz+KernelHalfSize(3)));
%     Coeffs = A\Phi0_patch(:);
%     AllCoeffs(:,j) = Coeffs(1:6);
% end
% 
% for j = 1:3
%     Diff1s{j} = zeros(size(mask));
%     Diff1s{j}(Indices) = AllCoeffs(2*j,:); 
%     
%     Diff2s{j} = zeros(size(mask));
%     Diff2s{j}(Indices) = 2*AllCoeffs(2*j-1,:); 
% end


