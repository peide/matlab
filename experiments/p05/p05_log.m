function [par,cur, cam] = p05_log( file )
% Read log file of beamline P05.
%
% ARGUMENTS
% file : string. Folder of or path to log file
% 
% Written by Julian Moosmann, 2016-12-12. Last version: 2016-12-12
%
% par = p05_log(filename)

%% Default arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1
    %file = '/asap3/petra3/gpfs/p05/2015/data/11001102/raw/hzg_wzb_mgag_14/hzg_wzb_mgag_14scan.log';
    %file = '/asap3/petra3/gpfs/p05/2016/data/11001978/raw/mah_28_15R_top/mah_28_15R_topscan.log';
    file = '/asap3/petra3/gpfs/p05/2016/data/11001994/raw/szeb_74_13/scan.log';
end

%% Main %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist( file , 'file') ~= 2
    s = dir( [file '/*scan.log'] );    
    file = [s.folder filesep s.name];
end

[~, name] = fileparts( file );
if length( name ) > 4
    cam = 'EHD';
    [par, cur] = EHD_log( file );
else
    cam = 'KIT';
    [par, cur] = KIT_log( file ); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [par, cur] = KIT_log( file )
fid = fopen( file );
c = textscan( fid, '%s');
fclose( fid );

%% Possible parameter list
par.energy = '%f';
par.num_flat_per_block = '%u' ;
par.ROI = '%u%u%u%u';
par.scan_duration = '%f';
par.eff_pix_size = '%f';
par.projections = '%u';
par.ref_prefix = '%s';
par.sample = '%s';
par.rotation = '%f';
par.num_img_per_block = '%u';
par.angle_list = '%f';
par.angle_order = '%s';
par.height_steps = '%u';
par.dark_prefix = '%s';
par.num_dark_img = '%u';
par.pos_dpc_s_pos_z = '%f';
par.camera_distance = '%f';
par.proj_prefix = '%s';
par.exposure_time = '%f';
par.off_axes = '%u';

%% Compare possible paramters with strings from log file
fn = fieldnames( par );
for nn = 1:numel( fn )
    p_field = fn{nn}; % cell array
    b = contains( c{1}, fn(nn) ); %
    if sum( b ) == 1
        p_val = par.(p_field);
        %         cl = textscan( c{1}{b}, sprintf( '%s %s', p_field, p_val ), ...
        %             1, 'Delimiter', {'=',','}, 'CollectOutput', 1, 'MultipleDelimsAsOne', 1);
        cl = textscan( c{1}{b}(2+numel(p_field):end), p_val, ...
            'Delimiter', {'=',','}, 'CollectOutput', 1, 'MultipleDelimsAsOne', 1);
        
        val = cl{1};
        if iscell( val )
            par.(p_field) = val{1};
        else
            par.(p_field) = val;
        end
    elseif sum( b ) > 1
        fprintf( 'WARNING: Parameter not unique' );
    else
        par = rmfield( par, p_field);
    end
    
end

%% Ring current
[folder] = fileparts( file );
proj_cur = read_dat( sprintf('%s/proj_current.dat', folder ) );
ref_cur = read_dat( sprintf('%s/ref_current.dat', folder ) );
for nn = 1:numel( proj_cur )    
    cur.proj(nn).val = proj_cur(nn);
    cur.proj(nn).ind = nn - 1;
    cur.proj(nn).angle = par.angle_list(nn);
end
for nn = 1:numel( ref_cur )    
    cur.ref(nn).val = ref_cur(nn);
    cur.ref(nn).ind = nn - 1;
    cur.ref(nn).angle = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [par, cur] = EHD_log( file )
fid = fopen( file );
%% Read log file until ring current
cl = {{[]}};
cl_counter = 1;
while 1
    c = textscan( fid, '%s', 1, 'Delimiter', {'\n', '\r'} );
    s = c{1}{1};
    if ~strcmpi( s(1), '*')
        cl{1}{cl_counter} = s;
        cl_counter = cl_counter + 1;
    end
    if strcmpi( c{1}{1}(1:6), '/PETRA' )
        c_break = c;
        break
    end
end

%% Possible parameter to read out

% p info
par.Energy = '%f';
par.undulator_gap = '%f';
par.undulator_harmonic = '%u';
par.n_dark = '%u';
par.n_ref_min = '%u';
par.n_ref_max = '%u';
par.n_img = '%u';
par.n_angle = '%u';
par.ref_count = '%u';
par.img_bin = '%u';
par.img_xmin = '%u';
par.img_xmax = '%u';
par.img_ymin = '%u';
par.img_ymax = '%u';
par.exptime = '%u';

% camera info
par.ccd_pixsize = '%f';
par.ccd_xsize =  '%u';
par.ccd_ysize =  '%u';
par.o_screen_changer = '%f';
par.o_focus = '%f';
par.o_aperture = '%f';
par.o_lens_changer = '%f';
par.o_ccd_high = '%f';
par.magn = '%f';

% apparatus info
par.pos_s_pos_x = '%f';
par.pos_s_pos_y = '%f';
par.pos_s_pos_z = '%f';
par.pos_s_stage_z = '%f';
par.s_in_pos = '%f';
par.s_out_dist = '%f';
par.o_ccd_dist = '%f';

% optimization info
par.p05_dcm_xtal2_pitch_delta = '%f';
par.com_delta_threshhold =  '%f';

%% Compare possible paramters with strings from log file
fn = fieldnames( par );
for nn = 1:numel( fn )
    p_field = fn{nn};
    b = contains( cl{1}, fn(nn) );
    if sum( b ) == 1
        p_val = par.(p_field);
        c = textscan( cl{1}{b}, sprintf( '%s %s', p_field, p_val ), 1, 'Delimiter', {'=', ':'});
        par.(p_field) = c{1};
    elseif sum( b ) > 1
        fprintf( 'WARNING: Parameter found more than once' );
    else
        par = rmfield( par, p_field);
    end
    
end

%% ring current

% ************************************************
% /PETRA/Idc/Buffer-0/I.SCH
% @1480217687541[99.99254@1480217687487]
% dark /gpfs/current/raw/mah_28_15R_top/mah_28_15R_top00000.dar
% /PETRA/Idc/Buffer-0/I.SCH
% @1480217687953[99.98162@1480217687928]

% ************************************************
% /PETRA/Idc/Buffer-0/I.SCH
% @1436994685507[89.40661@1436994685435]
%
% ref /gpfs/current/raw/hzg_wzb_mgag_00/hzg_wzb_mgag_0000005.ref       0.00000
% /PETRA/Idc/Buffer-0/I.SCH
% @1436994686180[89.39424@1436994686098]

% Move back to first occurence of /PETRA...
fseek( fid, - ( length( c_break{1}{1} ) + 1 ), 'cof' );

% Read all current fields
fs = '/%*s@%*f[%f@%*f]%s/%*s@%*f[%f@%*f]%*s';
c  = textscan( fid, fs, 'Delimiter', {'\n', '\r'},  'MultipleDelimsAsOne', 1);

ref_count = 1;
proj_count = 1;
for nn = 1:numel( c{1} )
    str = c{2}{nn};
    val = ( c{1}(nn) + c{3}(nn) ) / 2;
    switch str(1:3)
        case 'ref'
            st_c = textscan(str, '%*s%s%f');
            cur.ref(ref_count).ind = str2double(st_c{1}{1}(end-8:end-4));
            cur.ref(ref_count).angle = st_c{2};
            cur.ref(ref_count).val = val;
            ref_count = ref_count + 1;
        case 'img'
            st_c = textscan(str, '%*s%s%f');
            cur.proj(proj_count).ind = str2double(st_c{1}{1}(end-8:end-4));
            cur.proj(proj_count).angle = st_c{2};
            cur.proj(proj_count).val = val;
            proj_count = proj_count + 1;
    end
end

fclose( fid );
% End %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%