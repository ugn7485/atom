%% Run these commands from each subfolder

dirs={...
    'build_functions';...
    'export_functions';...
    'forcefield_functions';...
    'general_functions';...
    'import_functions';...
    'neigh_functions';...
    'structures';...
    };

for j=1:size(dirs,1)
    
    cd(char(dirs(j)))
    filelist = dir('*.m')
    for i=1:size(filelist,1)
        publish(filelist(i).name,'evalCode',false,'outputDir','/Users/miho0052/Dropbox/MATLAB/Matlab_scripts/functions/atom/html')
    end
    cd ..
    
end