function p05_reco_ringartifacts(nums, doreco)
if nargin < 1
    nums = [];
end
if nargin < 2
    doreco = 0;
end
if nargin < 3
    print_field = 'parfolder';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameter sets to loop over %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nn = 0;
default.interactive_determination_of_rot_axis = 1;
default.visualOutput = 1;
default.raw_bin = 2;
default.excentric_rot_axis = 0;
default.crop_at_rot_axis = 0;
default.stitch_projections = 0; 
default.proj_range = 1; 
default.ref_range = 1; 
default.correlation_method =  'ssim-ml';
default.flat_corr_area1 = [1 floor(100/default.raw_bin)]; % correlation area: index vector or relative/absolute position of [first pix, last pix]
default.flat_corr_area2 = [0.2 0.8]; %correlation area: index vector or relative/absolute position of [first pix, last pix]
default.do_phase_retrieval = 0;
default.do_tomo = 1;
default.ring_filter = 1;
default.rot_axis_offset = [];
default.rot_axis_tilt = 0;
default.parfolder = '';
default.write_to_scratch = 0;
default.write_flatcor = 0;
default.write_phase_map = 0; 
default.write_sino = 0; 
default.write_sino_phase = 0; 
default.write_reco = 1; 
default.write_float = 1; 
default.write_float_binned = 1; 
default.write_8bit = 0;
default.write_8bit_binned = 1;
default.write_16bit = 0; 

%% Data sets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% corroded screw
nn = nn + 1;
para(nn) = default;
para(nn).scan_path = '/asap3/petra3/gpfs/p05/2017/data/11002845/raw/ste_03_g4l_aa';
para(nn).parfolder = 'jm';
para(nn).out_path = '/asap3/petra3/gpfs/p05/2017/data/11002845/processed/ste_03_g4l';
para(nn).rot_axis_offset = -3.6/ para(nn).raw_bin;
para(nn).flat_corr_area1 = [1 floor(100/para(nn).raw_bin)]; 
para(nn).flat_corr_area2 = [0.1 0.7]; %correlation area: index vector or relative/absolute position of [first pix, last pix]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p05_reco_loop( nums, doreco, print_field, para)

