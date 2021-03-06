function MakeParFile(StartEndVoxels,NumOfFirstAndLastProjection,EffectivePixelSize,AngleBetweenProjections,ParentPath,DataPrefix)
% Make par files for all data set contained in ParentPath/data/. Rotation
% axis is computed automatically using quali images and image correlation.
% The volume to reconstruct can be set as an cell array defining start and
% end voxels.
%
% StartEndVoxels: empty cell ([],default), or (Number of data
% sets)x(2x3)-cell. Cell array defining the volume(s) that will be 
% reconstructed, first row = 1x3-Vector of START_VOXELs, second row =
% 1x3-Vectors of END_VOXELs. For each data set one cell component. If an
% empty array [] is given the whole volume(s) will be reconstructed.   
% NumOfFirstAndLastProjection: 1x2 Vector, or 1x3 Vector. 1st and 2nd
% compontent is the number of the first and the last projection,
% respectively, that are used for tomographic reconstruction. Optional 3rd,
% component is the proper number of projections that were taken for a full
% tomogram. Due to PyHST problems sometimes you have to modify the number
% of projections used for tomographic reconstruction to be even. 3rd number
% is very important  to pick the right images for the automatic
% determination of the rotation axis, too.
% EffectivePixelSize: effective pixel size of the projections given in
% microns.
% ParentPath: path to the parent folder containing the subfolders where the
% raw data, the flat-and-dark-field corrected intensities (int), the
% retrieved phases (phase), and the tomographic projections (vol) are
% stored. 

%% Default arguments
if nargin < 1
    % For new data set just use StartEndVoxels = [].
    StartEndVoxels{1} = [];
end
if nargin < 2
    % [FirstProjectionToUse LastProjectionToUse NumberOfProjectionsOverFullAngle]
    % Due to PyHST problems sometimes you have to adjust the number of
    % projections used for PyHST although the number of projection used for
    % a full tomograph
    % !! if NumOfFirstAndLastProjection is cell then
    % AngleBetweenProjections has to be a cell, too !!
    NumOfFirstAndLastProjection(1:5)  = {[1 1600 1599]};
    NumOfFirstAndLastProjection{3}    = [1 999 1000];
end
if nargin < 3
    EffectivePixelSize = 1.4;
end
if nargin < 4
    AngleBetweenProjections(1:5) = {360/1599};
    AngleBetweenProjections{5}   = 360/999;
end
if nargin < 5
    ParentPath = '/mnt/tomoraid3/user/moosmann';
end
if nargin < 6
    DataPrefix = 0;
end

%% Check path string ending.
if ParentPath(end) ~= '/'
    ParentPath = [ParentPath '/'];
end
%% Set parameters.
if ~iscell(NumOfFirstAndLastProjection)
    NUM_FIRST_IMAGE = NumOfFirstAndLastProjection(1,1);
    NUM_LAST_IMAGE  = NumOfFirstAndLastProjection(1,2);
    ANGLE_BETWEEN_PROJECTIONS = AngleBetweenProjections;
end
%% Read folder names of reconstructed data and loop over it.
DataPath     = [ParentPath 'data/'];
if DataPrefix == 0
    DataDirNames      = dir(DataPath);
    DataDirNames(1:2) = [];
else
    DataDirNames      = dir([DataPath DataPrefix '*']);
end
IntPath      = [ParentPath 'int/'];
PhasePath    = [ParentPath 'phase/'];
RecoPath     = [ParentPath 'vol/'];
if ~exist(RecoPath,'dir')
    mkdir(RecoPath);
end
%% Loop over different data sets.
for DataDirNum = numel(DataDirNames):-1:1%1:numel(DataDirNames)
    % Pixel size.
    if iscell(EffectivePixelSize)
        IMAGE_PIXEL_SIZE = EffectivePixelSize{DataDirNum};
    else
        IMAGE_PIXEL_SIZE = EffectivePixelSize;
    end
    %
    if iscell(NumOfFirstAndLastProjection)
        NUM_FIRST_IMAGE = NumOfFirstAndLastProjection{DataDirNum}(1,1);
        NUM_LAST_IMAGE  = NumOfFirstAndLastProjection{DataDirNum}(1,2);
        ANGLE_BETWEEN_PROJECTIONS = AngleBetweenProjections{DataDirNum};
    end  
    %% Get folder names of the retrieved phases.
    PhaseSubDirNames = dir([PhasePath DataDirNames(DataDirNum).name '/*alpha*']);
    warning('off','MATLAB:MKDIR:DirectoryExists');
    mkdir(RecoPath,DataDirNames(DataDirNum).name);
    %% Compute rotation axis using additional images recorded after the scan was completed.
    if numel(NumOfFirstAndLastProjection) == 3
        im1num = NumOfFirstAndLastProjection(3)+3;
        im2num = NumOfFirstAndLastProjection(3)+1;
    else
    im1num = NUM_LAST_IMAGE+3;
    im2num = NUM_LAST_IMAGE+1;
    end
    FILE_PREFIX = sprintf('%s%s/int_',IntPath,DataDirNames(DataDirNum).name);
    im1         = pmedfread(sprintf('%s%04u.edf',FILE_PREFIX,im1num))';
    im2         = fliplr(pmedfread(sprintf('%s%04u.edf',FILE_PREFIX,im2num))');
    out         = ImageCorrelation(im1,im2,0,0);
    RotAxisPos  = out.VerticalRotationAxisPosition;
    %% Image dimensions.
    [PixelsVer PixelsHor] = size(im1);
    %% Volume to reconstruct.
    % If cell StartVoxel isn't defined, the whole volume will be
    % rexonstructed.
    if iscell(StartEndVoxels)%(DataDirNum < size(StartEndVoxels,2)) && (2 == size(StartEndVoxels{DataDirNum},1))
        START_VOXEL_1 = StartEndVoxels{DataDirNum}(1,1);
        START_VOXEL_2 = StartEndVoxels{DataDirNum}(1,2);
        START_VOXEL_3 = StartEndVoxels{DataDirNum}(1,3);
        END_VOXEL_1   = StartEndVoxels{DataDirNum}(2,1);
        END_VOXEL_2   = StartEndVoxels{DataDirNum}(2,2);
        END_VOXEL_3   = StartEndVoxels{DataDirNum}(2,3);
    else
        if StartEndVoxels == 0
            START_VOXEL_1 = 1;
            START_VOXEL_2 = 1;
            START_VOXEL_3 = 1;
            END_VOXEL_1   = PixelsHor;
            END_VOXEL_2   = PixelsHor;
            END_VOXEL_3   = PixelsVer;
        elseif StartEndVoxels <= 1
            START_VOXEL_1 = 1;
            START_VOXEL_2 = 1;
            START_VOXEL_3 = ceil(PixelsVer*StartEndVoxels);
            END_VOXEL_1   = PixelsHor;
            END_VOXEL_2   = PixelsHor;
            END_VOXEL_3   = ceil(PixelsVer*StartEndVoxels);
        elseif StartEndVoxels > 1              
            START_VOXEL_1 = 1;
            START_VOXEL_2 = 1;
            START_VOXEL_3 = StartEndVoxels;
            END_VOXEL_1   = PixelsHor;
            END_VOXEL_2   = PixelsHor;
            END_VOXEL_3   = StartEndVoxels;
        end
    end
    %% PAR FILE FOR INTENSITY DATA.
            %% Set input file prefixes and output file name.
        FILE_PREFIX = sprintf('%s%s/int_',IntPath,DataDirNames(DataDirNum).name);
        OUTPUT_FILE = sprintf('%s%s/int.vol',RecoPath,DataDirNames(DataDirNum).name);
        %% Open .par file.
        ParFileName = sprintf('%s.par',OUTPUT_FILE);
        fid = fopen(ParFileName,'wt');
        %% Write into .par file.
        fprintf(fid, ...
            ['# HST_SLAVE PARAMETER FILE\n' ...
            '# This parameter file was created automatically by Matlab script ''MakeParFile''\n' ...
            '\n' ...
            'RECONSTRUCT_FROM_SINOGRAMS = NO\n'...
            '\n'...
            '# Parameters defining the projection file series\n' ...
            'FILE_PREFIX = ' FILE_PREFIX '\n' ...
            'NUM_FIRST_IMAGE = ' num2str(NUM_FIRST_IMAGE,'%i') ' # No. of first projection file\n' ...
            'NUM_LAST_IMAGE  = ' num2str(NUM_LAST_IMAGE,'%i') ' # No. of last projection file\n' ...
            'NUMBER_LENGTH_VARIES = NO\n' ...
            'LENGTH_OF_NUMERICAL_PART = 4 # No. of characters\n' ...
            'FILE_POSTFIX = .edf\n' ...
            'FILE_INTERVAL = 1 # Interval between input files\n' ...
            '\n' ...
            '# Parameters defining the projection file format\n' ...
            'NUM_IMAGE_1 = ' num2str(PixelsHor,'%u') ' # Number of pixels horizontally\n' ...
            'NUM_IMAGE_2 = ' num2str(PixelsVer,'%u') ' # Number of pixels vertically\n' ...
            'IMAGE_PIXEL_SIZE_1 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size horizontally (microns)\n' ...
            'IMAGE_PIXEL_SIZE_2 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size vertically\n' ...
            '\n' ...
            '# Parameters defining background treatment\n' ...
            'SUBTRACT_BACKGROUND = NO # No background subtraction\n' ...
            'BACKGROUND_FILE = N.N. \n' ...
            '\n' ...
            '# Parameters defining flat-field treatment\n' ...
            'CORRECT_FLATFIELD = NO # No flat-field correction\n' ...
            'FLATFIELD_CHANGING = N.A.\n' ...
            'FLATFIELD_FILE = N.A.\n' ...
            'FF_PREFIX = N.A.\n' ...
            'FF_NUM_FIRST_IMAGE = N.A.\n' ...
            'FF_NUM_LAST_IMAGE = N.A.\n' ...
            'FF_NUMBER_LENGTH_VARIES = N.A.\n' ...
            'FF_LENGTH_OF_NUMERICAL_PART = N.A.\n' ...
            'FF_POSTFIX = N.A.\n' ...
            'FF_FILE_INTERVAL = N.A.\n' ...
            '\n' ...
            'TAKE_LOGARITHM = NO # Take log of projection values\n' ...
            '\n' ...
            '# Parameters defining experiment\n' ...
            'ANGLE_BETWEEN_PROJECTIONS = ' num2str(ANGLE_BETWEEN_PROJECTIONS,'%f') ' # Increment angle in degrees\n' ...
            'ROTATION_VERTICAL = YES\n' ...
            'ROTATION_AXIS_POSITION = ' num2str(RotAxisPos,'%f') ' # Position in pixels\n' ...
            '\n' ...
            '# Parameters defining reconstruction\n' ...
            'OUTPUT_SINOGRAMS = NO # Output sinograms to files or not\n' ...
            'OUTPUT_RECONSTRUCTION = YES # Reconstruct and save or not\n' ...
            'START_VOXEL_1 = ' num2str(START_VOXEL_1,'%u') ' # X-start of reconstruction volume\n' ...
            'START_VOXEL_2 = ' num2str(START_VOXEL_2,'%u') ' # Y-start of reconstruction volume\n' ...
            'START_VOXEL_3 = ' num2str(START_VOXEL_3,'%u') ' # Z-start of reconstruction volume\n' ...
            'END_VOXEL_1 = ' num2str(END_VOXEL_1,'%u') ' # X-end of reconstruction volume\n' ...
            'END_VOXEL_2 = ' num2str(END_VOXEL_2,'%u') ' # Y-end of reconstruction volume\n' ...
            'END_VOXEL_3 = ' num2str(END_VOXEL_3,'%u') ' # Z-end of reconstruction volume\n' ...
            'OVERSAMPLING_FACTOR = 4 # 0 = Linear, 1 = Nearest pixel\n' ...
            'ANGLE_OFFSET = 0.000000 # Reconstruction rotation offset angle in degrees\n' ...
            'CACHE_KILOBYTES = 4096 # Size of processor cache (L2) per processor (KBytes)\n' ...
            'SINOGRAM_MEGABYTES = 800 # Maximum size of sinogram storage (megabytes)\n' ...
            '\n' ...
            '# Parameters defining output file / format\n' ...
            'OUTPUT_FILE = ' OUTPUT_FILE '\n' ...
            '# Reconstruction program options\n' ...
            'DISPLAY_GRAPHICS = NO # No images\n' ...
            '\n']);
        fclose(fid);
    %% PAR FILE FOR RETRIEVED PHASES.
    %Loop over different phase retrievals.
    for PhaseSubDirNum = 1: numel(PhaseSubDirNames)
        %% Set input file prefixes and output file name.
        FILE_PREFIX = sprintf('%s%s/%s/phase_',PhasePath,DataDirNames(DataDirNum).name,PhaseSubDirNames(PhaseSubDirNum).name);
        OUTPUT_FILE = sprintf('%s%s/%s.vol',RecoPath,DataDirNames(DataDirNum).name,PhaseSubDirNames(PhaseSubDirNum).name);
        %% Open .par file.
        ParFileName = sprintf('%s.par',OUTPUT_FILE);
        fid = fopen(ParFileName,'wt');
        %% Write into .par file.
        fprintf(fid, ...
            ['# HST_SLAVE PARAMETER FILE\n' ...
            '# This parameter file was created automatically by Matlab script ''MakeParFile''\n' ...
            '\n' ...
            'RECONSTRUCT_FROM_SINOGRAMS = NO\n'...
            '\n'...
            '# Parameters defining the projection file series\n' ...
            'FILE_PREFIX = ' FILE_PREFIX '\n' ...
            'NUM_FIRST_IMAGE = ' num2str(NUM_FIRST_IMAGE,'%u') ' # No. of first projection file\n' ...
            'NUM_LAST_IMAGE  = ' num2str(NUM_LAST_IMAGE,'%u') ' # No. of last projection file\n' ...
            'NUMBER_LENGTH_VARIES = NO\n' ...
            'LENGTH_OF_NUMERICAL_PART = 4 # No. of characters\n' ...
            'FILE_POSTFIX = .edf\n' ...
            'FILE_INTERVAL = 1 # Interval between input files\n' ...
            '\n' ...
            '# Parameters defining the projection file format\n' ...
            'NUM_IMAGE_1 = ' num2str(PixelsHor,'%u') ' # Number of pixels horizontally\n' ...
            'NUM_IMAGE_2 = ' num2str(PixelsVer,'%u') ' # Number of pixels vertically\n' ...
            'IMAGE_PIXEL_SIZE_1 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size horizontally (microns)\n' ...
            'IMAGE_PIXEL_SIZE_2 = ' num2str(IMAGE_PIXEL_SIZE,'%f') ' # Pixel size vertically\n' ...
            '\n' ...
            '# Parameters defining background treatment\n' ...
            'SUBTRACT_BACKGROUND = NO # No background subtraction\n' ...
            'BACKGROUND_FILE = N.N. \n' ...
            '\n' ...
            '# Parameters defining flat-field treatment\n' ...
            'CORRECT_FLATFIELD = NO # No flat-field correction\n' ...
            'FLATFIELD_CHANGING = N.A.\n' ...
            'FLATFIELD_FILE = N.A.\n' ...
            'FF_PREFIX = N.A.\n' ...
            'FF_NUM_FIRST_IMAGE = N.A.\n' ...
            'FF_NUM_LAST_IMAGE = N.A.\n' ...
            'FF_NUMBER_LENGTH_VARIES = N.A.\n' ...
            'FF_LENGTH_OF_NUMERICAL_PART = N.A.\n' ...
            'FF_POSTFIX = N.A.\n' ...
            'FF_FILE_INTERVAL = N.A.\n' ...
            '\n' ...
            'TAKE_LOGARITHM = NO # Take log of projection values\n' ...
            '\n' ...
            '# Parameters defining experiment\n' ...
            'ANGLE_BETWEEN_PROJECTIONS = ' num2str(ANGLE_BETWEEN_PROJECTIONS) ' # Increment angle in degrees\n' ...
            'ROTATION_VERTICAL = YES\n' ...
            'ROTATION_AXIS_POSITION = ' num2str(RotAxisPos,'%f') ' # Position in pixels\n' ...
            '\n' ...
            '# Parameters defining reconstruction\n' ...
            'OUTPUT_SINOGRAMS = NO # Output sinograms to files or not\n' ...
            'OUTPUT_RECONSTRUCTION = YES # Reconstruct and save or not\n' ...
            'START_VOXEL_1 = ' num2str(START_VOXEL_1) ' # X-start of reconstruction volume\n' ...
            'START_VOXEL_2 = ' num2str(START_VOXEL_2) ' # Y-start of reconstruction volume\n' ...
            'START_VOXEL_3 = ' num2str(START_VOXEL_3) ' # Z-start of reconstruction volume\n' ...
            'END_VOXEL_1 = ' num2str(END_VOXEL_1) ' # X-end of reconstruction volume\n' ...
            'END_VOXEL_2 = ' num2str(END_VOXEL_2) ' # Y-end of reconstruction volume\n' ...
            'END_VOXEL_3 = ' num2str(END_VOXEL_3) ' # Z-end of reconstruction volume\n' ...
            'OVERSAMPLING_FACTOR = 4 # 0 = Linear, 1 = Nearest pixel\n' ...
            'ANGLE_OFFSET = 0.000000 # Reconstruction rotation offset angle in degrees\n' ...
            'CACHE_KILOBYTES = 4096 # Size of processor cache (L2) per processor (KBytes)\n' ...
            'SINOGRAM_MEGABYTES = 800 # Maximum size of sinogram storage (megabytes)\n' ...
            '\n' ...
            '# Parameters defining output file / format\n' ...
            'OUTPUT_FILE = ' OUTPUT_FILE '\n' ...
            '# Reconstruction program options\n' ...
            'DISPLAY_GRAPHICS = NO # No images\n' ...
            '\n']);
        fclose(fid);
    end
end
%% PyHST extra features.
%             '\n' ...
%             '# Parameters extra features PyHST\n' ...
%             'DO_CCD_FILTER = NO # CCD filter (spikes)\n' ...
%             'CCD_FILTER = "CCD_Filter"\n' ...
%             'CCD_FILTER_PARA = {"threshold": 0.040000 }\n' ...
%             'DO_SINO_FILTER = NO # Sinogram filter (rings)\n' ...
%             'SINO_FILTER = "SINO_Filter"\n' ...
%             'ar = Numeric.ones(2048,''f'')\n' ...
%             'ar[0]=0.0\n' ...
%             'ar[2:18]=0.0\n' ...
%             'SINO_FILTER_PARA = {"FILTER": ar }\n' ...
%             'DO_AXIS_CORRECTION = NO # Axis correction\n' ...
%             'AXIS_CORRECTION_FILE = correct.txt\n' ...
%             '#konditionaler Medianfilter' ...
%             '#DO_CCD_FILTER= YES' ...
%             '#CCD_FILTER = "CCD_Filter"' ...
%             '#CCD_FILTER_PARA={"threshold": 0.0000 } #0.0005 Bedingung/Schwellwert' ...

