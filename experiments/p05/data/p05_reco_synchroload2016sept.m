function p05_reco_synchroload2016sept( SUBSETS, RUN_RECO, PRINT_PARAMETERS)
if nargin < 1
    SUBSETS = [];
end
if nargin < 2
    RUN_RECO = 0;
end
if nargin < 3
    PRINT_PARAMETERS = '';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEFAULT PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

raw_roi = [];
scan_path = '';
raw_bin = 1;
excentric_rot_axis = 0;
crop_at_rot_axis = 0;
stitch_projections = 0; 
proj_range = 1; 
ref_range = 1; 
correlation_method =  'ssim-ml';
do_phase_retrieval = 0;
do_tomo = 1;
fbp_filter_padding = 1;
ring_filter = 1;
ring_filter_method = 'jm';
ring_filter_median_width = 11;
dec_levels = 7;
wname = 'db25';
sigma = 2.4;
rot_axis_offset = [];
rot_axis_tilt = 0.001;
parfolder = '';
write_to_scratch = 0;
write_flatcor = 0;
write_phase_map = 0; 
write_sino = 0; 
write_sino_phase = 0; 
write_reco = 1; 
write_float = 0; 
write_float_binned = 1; 
write_8bit = 0;
write_8bit_binned = 1;
write_16bit = 0; 
subfolder_reco = '';
gpu_index = [];

SET_DEFAULT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PARAMETER / DATA SETS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 2016-09-13 commissioning synload
raw = '/asap3/petra3/gpfs/p05/2016/commissioning/c20160913_000_synload/raw/';
raw_roi = [141 1940];

scan_path = [raw, 'mg5gd_02_1w'];rot_axis_offset = 2.0;ADD
scan_path = [raw, 'mg10gd_38_1w'];rot_axis_offset = [];ADD
scan_path = [raw, 'mg10gd_41_2w'];ADD
scan_path = [raw, 'mg10gd_44_3w'];ADD
scan_path = [raw, 'mg10gd_50_4w']; ADD% reco problems CHECK
scan_path = [raw, 'mg5gd_02_1w'];ADD
scan_path = [raw, 'mg5gd_13_2w'];ADD
scan_path = [raw, 'mg5gd_21_3w'];ADD
scan_path = [raw, 'mg5gd_25_4w'];ADD('r')

%% 2016-09-15 commissioning ynload
scan_path = '/asap3/petra3/gpfs/p05/2016/commissioning/c20160915_000_synload/raw/mg10gd_50_4w';
raw_roi = [121 2240];ADD('r')

%% 2016-09-20 commissioning diana
%% furchtbarer verdreckter/kaputter Scintillator oder Optik, daher die Ring artefakte
raw = '/asap3/petra3/gpfs/p05/2016/commissioning/c20160920_000_diana/raw/';
raw_roi = [];
scan_path = [raw, 'Mg-10Gd39_1w'];ADD
scan_path = [raw, 'Mg-10Gd42_2w'];ADD
scan_path = [raw, 'Mg-10Gd45_3w'];ADD
scan_path = [raw, 'Mg-10Gd49_4w'];ADD
scan_path = [raw, 'Mg-5Gd17_2w'];ADD
scan_path = [raw, 'Mg-5Gd22_3w'];ADD
scan_path = [raw, 'Mg-5Gd28_4w'];ADD

scan_path = [raw, 'Mg-10Gd39_1w'];
correlation_method =  'entropy';
parfolder = correlation_method;
write_flatcor = 1;
ADD('r')

scan_path = [raw, 'Mg-10Gd39_1w'];
ring_filter_method = 'jm';
ring_filter_median_width = [3 5 7 11 13];
parfolder = 'ringfilt_jm_multi';
ADD('r')

scan_path = [raw, 'Mg-10Gd39_1w'];
ring_filter_method = 'wavelet-fft'; 
dec_levels = 2:6;
wname = 'db25';
sigma = 2.4;
parfolder = 'ringfilt_wavelet-fft';
ADD('r')

scan_path = [raw, 'Mg-10Gd39_1w'];
ring_filter_method = 'jm';
ring_filter_median_width = [7 21 39];
parfolder = 'ringfilt_jm_multi_72139';
write_flatcor = 1;
ADD('r')


scan_path = [raw, 'Mg-10Gd39_1w'];
ring_filter_method = 'jm';
ring_filter_median_width = 11;
darkFiltPixHot = 0;
darkFiltPixDark = 0;
refFiltPixHot = 0;
refFiltPixDark = 0;
projFiltPixHot = 0; 
projFiltPixDark = 0; 
parfolder = 'ringfilt_nopixfilter';
write_flatcor = 1;
ADD('r')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p05_reco_loop( SUBSETS, RUN_RECO, PRINT_PARAMETERS)
