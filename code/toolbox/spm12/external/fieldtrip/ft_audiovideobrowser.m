function ft_audiovideobrowser(cfg, data)

% FT_AUDIOVIDEOBROWSER reads and vizualizes the audio and/or video data
% corresponding to the EEG/MEG data that is passed into this function.
%
% Use as
%   ft_audiovideobrowser(cfg)
% or as
%   ft_audiovideobrowser(cfg, data)
% where the input data is the result from FT_PREPROCESSING or from FT_COMPONENTANALYSIS.
%
% The configuration structure can contain the following options
%   cfg.datahdr     = header structure of the EEG/MEG data, see FT_READ_HEADER
%   cfg.audiohdr    = header structure of the audio data, see FT_READ_HEADER
%   cfg.videohdr    = header structure of the video data, see FT_READ_HEADER
%   cfg.audiofile   = string with the filename
%   cfg.videofile   = string with the filename
%   cfg.trl         = Nx3 matrix, see FT_DEFINETRIAL
%   cfg.anonimize   = [x1 x2 y1 y2], range in pixels for placing a bar over the eyes (default = [])
%   cfg.interactive = 'yes' or 'no' (default = 'yes')
%
% If you do NOT specify cfg.datahdr, the header must be present in the input data.
% If you do NOT specify cfg.audiohdr, the header will be read from the audio file.
% If you do NOT specify cfg.videohdr, the header will be read from the video file.
% If you do NOT specify cfg.trl, the input data should contain a sampleinfo field.
%
% See also FT_DATABROWSER

% Copyright (C) 2015 Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: ft_audiovideobrowser.m 11050 2016-01-09 17:06:16Z roboos $

persistent previous_audiofile previous_videofile previous_audiohdr previous_videohdr

revision = '$Id: ft_audiovideobrowser.m 11050 2016-01-09 17:06:16Z roboos $';

% do the general setup of the function
ft_defaults
ft_preamble init
ft_preamble debug
ft_preamble loadvar data
ft_preamble provenance data
ft_preamble trackconfig

% the abort variable is set to true or false in ft_preamble_init
if abort
  return
end

if nargin>1
  data = ft_checkdata(data, 'datatype', {'raw+comp', 'raw'}, 'feedback', 'yes', 'hassampleinfo', 'yes');
end

% get the options from the user or set defaults
cfg.interactive = ft_getopt(cfg, 'interactive', 'yes');
cfg.anonimize   = ft_getopt(cfg, 'anonimize');
% the headers contain the information required for synchronization
cfg.datahdr     = ft_getopt(cfg, 'datahdr');
cfg.audiohdr    = ft_getopt(cfg, 'audiohdr');
cfg.videohdr    = ft_getopt(cfg, 'videohdr');
% the data is read on the fly
cfg.audiofile   = ft_getopt(cfg, 'audiofile');
cfg.videofile   = ft_getopt(cfg, 'videofile');

if ~isempty(cfg.datahdr)
  % get it from the configuration
  datahdr = cfg.datahdr;
elseif nargin>1
  % get it from the input data
  datahdr = ft_fetch_header(data);
else
  % in principle it would be possible to read it from cfg.datafile, but the
  % synchronization information will not automatically be present, as that
  % requires parsing one of the trigger channels
  error('the data header is not available')
end

assert(isfield(datahdr, 'FirstTimeStamp'), 'sycnhronization information is missing in the data header');
assert(isfield(datahdr, 'TimeStampPerSample'), 'sycnhronization information is missing in the data header');

% determine the begin and end samples of the data segments, the corresponding audio and video fragments will be displayes
if isfield(cfg, 'trl')
  fprintf('using cfg.trl\n');
  trl = cfg.trl;
elseif nargin>1 && isfield(data, 'sampleinfo')
  fprintf('using data.sampleinfo\n');
  trl = data.sampleinfo;
else
  error('the EEG/MEG data segments should be specified');
end

numtrl = size(trl,1);
trllop = 1;
while (true)
  
  fprintf('processing trial %d from %d\n', trllop, numtrl);
  audiodat = [];
  videodat = [];
  
  %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if ~isempty(cfg.audiofile)
    if isequal(previous_audiofile, cfg.audiofile)
      audiohdr = previous_audiohdr;
    elseif ~isempty(cfg.audiohdr)
      fprintf('using the header and timestamps from the configuration\n');
      audiohdr = cfg.audiohdr;
    else
      fprintf('reading the header and timestamps from %s\n', cfg.audiofile);
      audiohdr = ft_read_header(cfg.audiofile);
    end
    
    % the FirstTimeStamp might be expressed as uint32 or uint64
    datahdr.FirstTimeStamp  = double(datahdr.FirstTimeStamp);
    audiohdr.FirstTimeStamp = double(audiohdr.FirstTimeStamp);
    
    begsample    = trl(trllop, 1); % expressed in the MEG/EEG data
    begtimestamp = (begsample-1)*datahdr.TimeStampPerSample + double(datahdr.FirstTimeStamp);
    begsample    = double(begtimestamp - audiohdr.FirstTimeStamp)/audiohdr.TimeStampPerSample + 1; % expressed in the audio data
    begsample    = round(begsample);
    
    endsample    = trl(trllop, 2); % expressed in the MEG/EEG data
    endtimestamp = cast((endsample-1)*datahdr.TimeStampPerSample, 'like', audiohdr.FirstTimeStamp) + datahdr.FirstTimeStamp;
    endsample    = double(endtimestamp - audiohdr.FirstTimeStamp)/audiohdr.TimeStampPerSample + 1; % expressed in the audio data
    endsample    = round(endsample);
    
    % read the audio data that corresponds to the selected MEG/EEG data
    audiodat = ft_read_data(cfg.audiofile, 'begsample', begsample, 'endsample', endsample, 'header', audiohdr);
    
    % remember the header details to speed up subsequent calls
    previous_audiohdr  = audiohdr;
    previous_audiofile = cfg.audiofile;
  end
  
  %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if ~isempty(cfg.videofile)
    if isequal(previous_videofile, cfg.videofile)
      videohdr = previous_videohdr;
    elseif ~isempty(cfg.videohdr)
      fprintf('using the header and timestamps from the configuration\n');
      videohdr = cfg.videohdr;
    else
      fprintf('reading the header and timestamps from %s\n', cfg.videofile);
      videohdr = ft_read_header(cfg.videofile);
    end
    
    % the FirstTimeStamp might be expressed as uint32 or uint64
    datahdr.FirstTimeStamp  = double(datahdr.FirstTimeStamp);
    videohdr.FirstTimeStamp = double(videohdr.FirstTimeStamp);
    
    begsample    = trl(trllop,1); % expressed in the MEG/EEG data
    begtimestamp = (begsample-1)*datahdr.TimeStampPerSample + double(datahdr.FirstTimeStamp);
    begsample    = double(begtimestamp - videohdr.FirstTimeStamp)/videohdr.TimeStampPerSample + 1; % expressed in the audio data
    begsample    = round(begsample);
    
    endsample    = trl(trllop,2); % expressed in the MEG/EEG data
    endtimestamp = cast((endsample-1)*datahdr.TimeStampPerSample, 'like', videohdr.FirstTimeStamp) + datahdr.FirstTimeStamp;
    endsample    = double(endtimestamp - videohdr.FirstTimeStamp)/videohdr.TimeStampPerSample + 1; % expressed in the audio data
    endsample    = round(endsample);
    
    % read the video data that corresponds to the selected MEG/EEG data
    videodat = ft_read_data(cfg.videofile, 'begsample', begsample, 'endsample', endsample, 'header', videohdr);
    
    videodat = uint8(videodat);
    videodat = reshape(videodat, [videohdr.orig.dim size(videodat,2)]);
    
    if ~isempty(cfg.anonimize)
      % place a bar over the eyes
      videodat(cfg.anonimize(1):cfg.anonimize(2), cfg.anonimize(3):cfg.anonimize(4), :) = 0;
    end
    
    % remember the header details to speed up subsequent calls
    previous_videohdr  = videohdr;
    previous_videofile = cfg.videofile;
  end
  %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % FIXME this one does not play automatically
  if ~isempty(videodat)
    implay(videodat, videohdr.Fs);
    drawnow
  end
  
  % FIXME this one plays automatically
  if ~isempty(audiodat)
    soundview(sum(audiodat,1), audiohdr.Fs);
    drawnow
  end
  
  if istrue(cfg.interactive)
    response = 'x';
    while ~ismember(response, {'n', 'p', 'q'});
      response = input('press ''n'' for the next trial, ''p'' for the previous trial or ''q'' to quit: [N/p/q] ', 's');
    end
    switch response
      case 'n'
        if trllop==numtrl
          warning('already at the last trial');
        else
          trllop = trllop+1;
        end
      case 'p'
        if trllop==1
          warning('already at first trial');
        else
          trllop = trllop-1;
        end
      case 'q'
        break
    end
    
  else
    % not interactive, show the audio/video of all trials
    if trllop<numtrl
      trllop = trllop+1;
    else
      break
    end
    
  end % if interactive
  
end % while true

% do the general cleanup and bookkeeping at the end of the function
ft_postamble debug
ft_postamble trackconfig
ft_postamble previous data
ft_postamble provenance
