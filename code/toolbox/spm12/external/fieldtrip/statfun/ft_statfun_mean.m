function [s, cfg] = ft_statfun_mean(cfg, dat, design)

% FT_STATFUN_MEAN computes the mean over all replications for each of
% the observations (i.e. channel-time-frequency points or voxels).
%
% This function does not depend on the experimental design and cannot
% be used for statistical testing. However, it serves as example how
% you can use the statistical framework in FieldTrip to perform a
% simple (or more complex) task, without having to worry about the
% representation of the data. The output of FT_TIMELOCKSTATISTICS,
% FT_FREQSTATISTICS or FT_SOURCESTATISTICS will be an appropriate
% structure, that contains the result of the computation inside this
% function in the stat field.
%
% See also FT_STATFUN_DIFF for an other simple example statfun

% Copyright (C) 2012, Donders Centre for Cognitive Neuroimaging, Nijmegen, NL
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
% $Id: ft_statfun_mean.m 10801 2015-10-20 12:05:28Z roboos $

s = mean(dat,2);

