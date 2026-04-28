
function c = check_settings_matfile(c, folderPath, folderName)


% look for a settings file in the folder and path
% if it exists, overwrite c with these entries but be careful not to
% obliterate nested fields containing other settings that might not
% be in c_settings
% NOTE: c.first.second is a unique subfield that will be removed if
% your c_settings.first structure does not contain the field
% 'second' !!!

settings_mat_path = fullfile(folderPath, [folderName, '_settings.mat']);
if exist(settings_mat_path,'file')
    
    disp(['Found setting file for ',folderName,' ... updating structure c'])
    load(settings_mat_path,'c_settings');
    
    % get the top level fields in the structure (usually 'freezeSettings')
    c_fields_1 = fieldnames(c_settings);
    for ii = 1:numel(c_fields_1)
        
        if isstruct(c.(c_fields_1{ii}))
            % if the top level field is a structure, find the subfields and
            % only over write those in the saved structure but preserve all
            % the others.
            c_fields_2 = fieldnames(c_settings.(c_fields_1{ii}));
            
            for jj = 1:numel(c_fields_2)
                if isstruct(c.(c_fields_1{ii}).(c_fields_2{jj}))
                    error('%s: structure contains additional subfields -- need to update code to account for this')
                else
                    c.(c_fields_1{ii}).(c_fields_2{jj}) = c_settings.(c_fields_1{ii}).(c_fields_2{jj});
                end
            end
        else
            c.(c_fields_1{ii}) = c_settings.(c_fields_1{ii});
        end
    end
else
    % do nothing to structure c
    fprintf(sprintf('%s: no additional settings file found, maintaining original strucure c\n', mfilename))
end


end

