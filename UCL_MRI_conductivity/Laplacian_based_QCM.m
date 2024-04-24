function ConductivityMap = Laplacian_based_QCM(Inputs)
%DESCRIPTION: ConductivityMap = Laplacian_based_QCM(Inputs)
%             Calculates the conductivity map based on the differential equation 
%
%INPUTS:
%   Inputs.PhaseMap (3D array) - B1 phase map in radians
%   Inputs.TissueMask (3D array) - Tissue mask
%   Inputs.ROImask (3D array) - ROI mask where the conductivity is
%                                      to be calculated
%   Inputs.Method (string) - 'ell','mag','seg','magseg'
%   Inputs.Resolution (vector) - Resolution in mm
%   Inputs.FieldStrength (double) - Main magnetic field strength in Tesla
%   Inputs.KernelRadii (vector) - Kernel radii in mm
%   Inputs.MagnitudeMap (3D array) - Magnitude map
%   Inputs.LabelMap = %(3D array) - Segmentation label map
%
%OUTPUTS:
%   ConductivityMap (3D double array) - Conductivity map in S/m
%
%DEPENDENCIES:
%   ak_DifferentiatePhi0.m
%   ak_DifferentiatePhi0_MagSeg.m
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

if ~isfield(Inputs,'KernelRadii')||numel(Inputs.KernelRadii)~=3||sum(Inputs.KernelRadii<=0)~=0
    warndlg('Please specify Inputs.KernelRadii = kernel radii in the x,y,z directions in mm!','!! Warning !!');
    return;
end

Inputs.KernelRadii = round(Inputs.KernelRadii./Inputs.Resolution);

switch Inputs.Method
    
    case 'ell'

        [~,Diff2s] = ak_DifferentiatePhi0(Inputs.PhaseMap,Inputs.Resolution,Inputs.KernelRadii,[0 1]);
        ConductivityMap = (Diff2s{1}+Diff2s{2}+Diff2s{3}).*Inputs.TissueMask/(Inputs.FieldStrength*267.52219*4*pi*1e-7);
        
    case 'mag'
        
        if ~isfield(Inputs,'MagnitudeMap')||sum(size(Inputs.MagnitudeMap)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.MagnitudeMap = the MRI magnitude map in arbitrary units (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        if ~isfield(Inputs,'ROImask')||sum(size(Inputs.ROImask)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.ROImask = mask where the conductivity values are to be calculated (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        [~,Diff2s] = ak_DifferentiatePhi0_MagSeg(Inputs.PhaseMap,Inputs.MagnitudeMap,Inputs.TissueMask,...
            Inputs.TissueMask+Inputs.ROImask,Inputs.Resolution,Inputs.KernelRadii,0.45);
        ConductivityMap = (Diff2s{1}+Diff2s{2}+Diff2s{3}).*Inputs.ROImask/(Inputs.FieldStrength*267.52219*4*pi*1e-7);
        
    case 'seg'
        
        if ~isfield(Inputs,'LabelMap')||sum(size(Inputs.LabelMap)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.LabelMap = the segmentation label map with integer values (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        if ~isfield(Inputs,'ROImask')||sum(size(Inputs.ROImask)~=size(Inputs.PhaseMap))
            warndlg('Please specify Inputs.ROImask = mask where the conductivity values are to be calculated (same dimensions as PhaseMap)!','!! Warning !!');
            return;
        end
        
        [~,Diff2s] = ak_DifferentiatePhi0_MagSeg(Inputs.PhaseMap,Inputs.TissueMask,Inputs.LabelMap,...
            Inputs.TissueMask+Inputs.ROImask,Inputs.Resolution,Inputs.KernelRadii,20); 
        ConductivityMap = (Diff2s{1}+Diff2s{2}+Diff2s{3}).*Inputs.ROImask/(Inputs.FieldStrength*267.52219*4*pi*1e-7);
        
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
        
        % set last argument automatically?
        [~,Diff2s] = ak_DifferentiatePhi0_MagSeg(Inputs.PhaseMap,Inputs.MagnitudeMap,Inputs.LabelMap,...
            Inputs.TissueMask+Inputs.ROImask,Inputs.Resolution,Inputs.KernelRadii,0.45); 
        ConductivityMap = (Diff2s{1}+Diff2s{2}+Diff2s{3}).*Inputs.ROImask/(Inputs.FieldStrength*267.52219*4*pi*1e-7);
        
end
        
warning('on','MATLAB:singularMatrix');
warning('on','MATLAB:rankDeficientMatrix');
        
        
        