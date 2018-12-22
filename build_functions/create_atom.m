%% create_atom.m
% * This function creates particles within a certain region defined by <limits>
% * Can also add particles on a plane by setting Lx|Ly|Lz to 0 or something small
% 
%% Similar
% * insert_atom
% * ionize_atom
% * solvate_atom
%
%% Version
% 2.0
%
%% Contact
% Please report bugs to michael.holmboe@umu.se
%
%% Arguments
% * {type} is particle/atomtype
% * {resname} is resname
% * [limits] is a 1x3 or 1x6 volume variable
% * The number nmax is the max number of particles
% * Optional scale number (varargin{1}) is a how-many-diameters-between-the-particles-thingy
%
%% Dependencies
% * radius_ion
% * add2atom
% * replicate_atom
% * translate_atom
% * merge_atom
% * slice_atom
% * update_atom
% * distance_matrix_atom
%
%% Examples
% # atom = create_atom('Na','Na',[10 20 30],10)
% # atom = create_atom('Na','Na',[10 20 30],10,1.5)
% # atom = create_atom('Na','Na',[10 20 30],10,1.5,in_atom)

function atom = create_atom(type,resname,limits,nmax,varargin)

if iscell(type)==0;type={type}; end
if iscell(resname)==0;resname={resname};end

radii = abs(radius_ion(type));
if nargin > 4
    scale=varargin{1};
else
    scale=2;
end
Box_dim_temp=scale*[2*radii 2*radii 2*radii];
atom = add2atom(type,[0 0 0],resname,[]);

if numel(limits)==1
    Lx=limits(1);
    Ly=limits(1);
    Lz=limits(1);
    limits(4)=limits(1);
    limits(5)=limits(1);
    limits(6)=limits(1);
    limits(1:3)=0;
elseif numel(limits)==3
    Lx=limits(1);
    Ly=limits(2);
    Lz=limits(3);
    limits(4)=limits(1);
    limits(5)=limits(2);
    limits(6)=limits(3);
    limits(1:3)=0;
elseif numel(limits)==6
    Lx=limits(4)-limits(1);
    Ly=limits(5)-limits(2);
    Lz=limits(6)-limits(3);
end

nx=ceil(Lx/Box_dim_temp(1));
ny=ceil(Ly/Box_dim_temp(2));
nz=ceil(Lz/Box_dim_temp(3));

if nx==0;nx=1;end
if ny==0;ny=1;end
if nz==0;nz=1;end

atom=replicate_atom(atom,Box_dim_temp,[nx ny nz]); % nx/ny/nz==0 is set to 1 in replicate_atom

molid=num2cell([1:size(atom,2)]);
[atom.molid]=deal(molid{:});

% Move things around a little bit
for i=1:size(atom,2)
    if nx>0;atom(i).x=atom(i).x-scale*rand(1)*radii;end
    if ny>0;atom(i).y=atom(i).y-scale*rand(1)*radii;end
    if nz>0;atom(i).z=atom(i).z-scale*rand(1)*radii;end
end

if (limits(1)+limits(2)+limits(3)) ~= 0
    disp('Translating the water box');
    atom=translate_atom(atom,[limits(1) limits(2) limits(3)],'all');
end

disp('nAtom before merge')
size(atom,2)

if nargin==6 && size(varargin{2},2) > 0
    in_atom=varargin{2};
    if size(atom,2) > 10000 || size(in_atom,2) > 20000
        natom_block=size(atom,2)/(nx*ny*nz);
        atom_count=1;atom_merged=[];count=1;
        while atom_count< size(atom,2)
            atom_block= atom(atom_count:atom_count+natom_block-1);
            atom_block = merge_atom(in_atom,limits(4:6),atom_block,'type',type,scale*radii);
            atom_merged = [atom_merged atom_block];
            atom_count=atom_count+natom_block;
            disp('box number...')
            count=count+1
        end
        atom=atom_merged;
    else
        atom = merge_atom(in_atom,limits(4:6),atom,'type',type,scale*radii);
    end
else
    atom = slice_atom(atom,limits,0);
end
% assignin('base','atom3',atom);
atom=update_atom(atom);

% Randomize order of the particles
nAtoms=size(atom,2);
ind_rand=randperm(nAtoms);
ind_sel=ismember(ind_rand,1:nAtoms);
atom_ind=ind_rand(ind_sel);
atom(atom_ind)=atom;


if iscellstr({nmax}) == 1
    nmax=size(atom,2); 
end

% If not filled up yet, remove the particles that are nearest some other particles
% until we have achieved nmax
i=1;
distmatrix=dist_matrix_atom(atom,Box_dim);
distmatrix(distmatrix==0)=1000000; % Dummy distance in the distance matrix
while size(atom,2)>nmax+1
    [row,col]=find(distmatrix==min(min(distmatrix)));
    ind_rm=max([row col]);
    if ind_rm>i
        i=i+1;
    end
    atom(row)=[];
    distmatrix(row,:)=[];
    distmatrix(:,col)=[];
end

% Delete particles if not using the <maxion> option
if iscellstr({nmax}) == 0
    if nmax > size(atom,2)
        disp('Ooops, you asked for too many particles...')
        disp('Max number of particles allowed without changing scale is:')
        size(atom,2)
        atom=atom(1:nmax);
    else
        atom=atom(1:nmax);
    end
end

disp('nIon after merge')
size(atom,2)

atom=update_atom(atom);

assignin('caller','limits',limits);


