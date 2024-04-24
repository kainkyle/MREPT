function ConductivityMap = Surface_integral_based_QCM(Inputs)
%DESCRIPTION: ConductivityMap = Integral_equation_QCM(Inputs)
%             Calculates the conductivity map based on the integral equation 
%
%INPUTS:
%   Inputs.PhaseMap (3D array) - B1 phase map in radians
%   Inputs.TissueMask (3D array) - Tissue mask
%   Inputs.ROImask (3D array) - ROI mask where the conductivity is
%                                      to be calculated
%   Inputs.Method(string) - 'ell','mag','seg','magseg'
%   Inputs.Resolution(vector) - Resolution in mm
%   Inputs.FieldStrength(double) - Main magnetic field strength in Tesla
%   Inputs.KernelRadiiDiff(vector) - Kernel radii for the differentiation in mm
%   Inputs.KernelRadiiInt(vector) - Kernel radii for the surface integral in mm
%   Inputs.MagnitudeMap (3D array) - Magnitude map
%   Inputs.LabelMap = %(3D array) - Segmentation label map
%
%OUTPUTS:
%   ConductivityMap (3D double array) - Conductivity map in S/m
%
%DEPENDENCIES:
%   ak_DifferentiatePhi0.m
%   ak_DifferentiatePhi0_MagSeg.m
%   ak_IntegrateDiffPhi0.m
%   ak_IntegrateDiffPhi0_MagSeg.m
%   ZeroFilling.m
%
%AUTHOR: 
%   Anita Karsa, University College London, 2021

warning('off','MATLAB:singularMatrix');
warning('off','MATLAB:rankDeficientMatrix');

if ~isfield(Inputs,'PhaseMap')||length(size(Inputs.PhaseMap))~=3
    warndlg('Please specify Inputs.PhaseMap (3D array) = the B1 phase map in radians!','!! Warning !!');
    return;
end

if ~isfield(Inputs,'TissueMask')||sum(size(Inputs.TissueMask)~=size(Inputs.PhaseMap))
    warndlg('Please specify Inputs.TissueMask (3D array) = tissue mask of high-SNR voxels (same dimensions as PhaseMap)!','!! Warning !!');
    return;
end

if ~isfield(Inputs,'Method')||~ismember(Inputs.Method,{'ell','mag','seg','magseg'})
    warndlg('Please specify Inputs.Method (string) = ell/mag/seg/magseg!','!! Warning !!');
    return;
end

if ~isfield(Inputs,'Resolution')||numel(Inputs.Resolution)~=3||sum(Inputs.Resolution<=0)~=0
    warndlg('Please specify Inputs.Resolution (in mm)!','!! Warning !!');
    return;
end

if ~isfield(Inputs,'FieldStrength')||numel(Inputs.FieldStrength)~=1||Inputs.FieldStrength<=0
    warndlg('Please specify Inputs.FieldStrength = main magnetic field strength in Tesla!','!! Warning !!');
    return;
end

if ~isfield(Inputs,'KernelRadiiDiff')||numel(Inputs.KernelRadiiDiff)~=3||sum(Inputs.KernelRadiiDiff<=0)~=0
    warndlg('Please specify Inputs.KernelRadiiDiff = kernel radii for the differentiation in the x,y,z directions in mm!','!! Warning !!');
    return;
end

if ~isfield(Inputs,'KernelRadiiInt')||numel(Inputs.KernelRadiiInt)~=3||sum(Inputs.KernelRadiiInt<=0)~=0
    warndlg('Please specify Inputs.KernelRadiiDiff = kernel radii for the surface integral in the x,y,z directions in mm!','!! Warning !!');
    return;
end

Inputs.KernelRadiiDiff = round(Inputs.KernelRadiiDiff./Inputs.Resolution);
Inputs.KernelRadiiInt = round(Inputs.KernelRadiiInt./Inputs.Resolution);

% ROImask for the differentiation has to be bigger than for the surface
% integral
KernelHalfSize = Inputs.KernelRadiiInt;
dx = Inputs.Resolution;
[Y,X,Z] = meshgrid((-KernelHalfSize(2):KernelHalfSize(2)),dx(1)*(-KernelHalfSize(1):KernelHalfSize(1)),dx(3)*(-KernelHalfSize(3):KernelHalfSize(3)));
Shape = X.^2/(KernelHalfSize(1)*dx(1))^2+Y.^2/(KernelHalfSize(2)*dx(2))^2+Z.^2/(KernelHalfSize(3)*dx(3))^2;
Shape(Shape<=1) = 1;
Shape(Shape~=1) = 0;
Inputs.ROImaskDiff = convn(Inputs.ROImask,Shape,'same').*Inputs.TissueMask;
Inputs.ROImaskDiff(Inputs.ROImaskDiff~=0) = 1;

switch Inputs.Method
    
    case 'ell'

        [Diff1s,~] = ak_DifferentiatePhi0(Inputs.PhaseMap,Inputs.Resolution,Inputs.KernelRadiiDiff,[1 0]);
        ConductivityMap = ak_IntegrateDiffPhi0(Diff1s,Inputs.Resolution,Inputs.KernelRadiiInt,Inputs.FieldStrength).*Inputs.TissueMask;
        
    case 'mag'
        
        if ~isfield(Inputs,'MagnitudeMap')||sum(size(Inputs.MagnitudeMap)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.MagnitudeMap = the MRI magnitude map in arbitrary units (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        if ~isfield(Inputs,'ROImask')||sum(size(Inputs.ROImask)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.ROImask = mask where the conductivity values are to be calculated (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        [Diff1s,~] = ak_DifferentiatePhi0_MagSeg(Inputs.PhaseMap,Inputs.MagnitudeMap,Inputs.TissueMask,...
            Inputs.TissueMask+Inputs.ROImaskDiff,Inputs.Resolution,Inputs.KernelRadiiDiff,0.45);
        ConductivityMap = ak_IntegrateDiffPhi0_MagSeg(Diff1s,Inputs.MagnitudeMap,Inputs.TissueMask,...
            Inputs.TissueMask+Inputs.ROImask,Inputs.Resolution,Inputs.KernelRadiiInt,0.45,Inputs.FieldStrength);
        
    case 'seg'
        
        if ~isfield(Inputs,'LabelMap')||sum(size(Inputs.LabelMap)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.LabelMap = the segmentation label map with integer values (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        if ~isfield(Inputs,'ROImask')||sum(size(Inputs.ROImask)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.ROImask = mask where the conductivity values are to be calculated (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        [Diff1s,~] = ak_DifferentiatePhi0_MagSeg(Inputs.PhaseMap,Inputs.TissueMask,Inputs.LabelMap,...
            Inputs.TissueMask+Inputs.ROImaskDiff,Inputs.Resolution,Inputs.KernelRadiiDiff,20);
        ConductivityMap = ak_IntegrateDiffPhi0_MagSeg(Diff1s,Inputs.TissueMask,Inputs.LabelMap,...
            Inputs.TissueMask+Inputs.ROImask,Inputs.Resolution,Inputs.KernelRadiiInt,20,Inputs.FieldStrength);
        
    case 'magseg'
        
        if ~isfield(Inputs,'MagnitudeMap')||sum(size(Inputs.MagnitudeMap)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.MagnitudeMap = the MRI magnitude map in arbitrary units (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        if ~isfield(Inputs,'LabelMap')||sum(size(Inputs.LabelMap)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.LabelMap = the segmentation label map with integer values (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        if ~isfield(Inputs,'ROImask')||sum(size(Inputs.ROImask)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.ROImask = mask where the conductivity values are to be calculated (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        [Diff1s,~] = ak_DifferentiatePhi0_MagSeg(Inputs.PhaseMap,Inputs.MagnitudeMap,Inputs.LabelMap,...
            Inputs.TissueMask+Inputs.ROImaskDiff,Inputs.Resolution,Inputs.KernelRadiiDiff,0.45);
        ConductivityMap = ak_IntegrateDiffPhi0_MagSeg(Diff1s,Inputs.MagnitudeMap,Inputs.LabelMap,...
            Inputs.TissueMask+Inputs.ROImask,Inputs.Resolution,Inputs.KernelRadiiInt,0.45,Inputs.FieldStrength);
        
end
        
warning('on','MATLAB:singularMatrix');
warning('on','MATLAB:rankDeficientMatrix');
        
        
        