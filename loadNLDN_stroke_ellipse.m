function [loadedDataCG,loadedDataIC] = loadNLDN_stroke_ellipse(dateString,...
    timeStartString,timeEndString,minLat,maxLat,minLon,maxLon,maxSMA,...
    maxChiSq,onlyNeg,minNSR)

%Loads NLDN return stroke data, including the ellipse parameters
%
%
%%%%%%  Test Call  %%%%%%
%[loadedCGs, loadedICs] = loadNLDN_stroke_ellipse('130528','010826500','010827500',38.90,40.10,-98.15,-96.60,3,3,0,1)
%[loadedCGs, loadedICs] = loadNLDN_stroke_ellipse('130528','011655100','011655900',38.90,40.10,-98.15,-96.60,3,3,0,1)



%Opens NLDN text file according to the month provided in dateString
switch (str2double(dateString(3:4)))
    case 5
        dataFileName = 'KS_OM_80km_May2013.txt';
    case 6
        dataFileName = 'KS_OM_80km_June2013.txt';
    case 7
        dataFileName = 'KS_OM_80km_July2013.txt';
    case 8
        dataFileName = 'KS_OM_80km_Aug2013.txt';
    case 9
        dataFileName = 'KS_OM_80km_Sept2013.txt';
end
dataFileID = fopen(dataFileName);


%Loads the NLDN data file as formatted text
loadedData = textscan(dataFileID,'%s %s %f %f %f %f %f %f %f %s %f');
fclose(dataFileID);


%Loads each column of the data file into different column vectors
loadedDate = loadedData{1};
loadedTime = loadedData{2};
loadedLat = loadedData{3};
loadedLon = loadedData{4};
loadedIpk = loadedData{5};
loadedSMA = loadedData{6};
loadedSmA = loadedData{7};
loadedEllAz = loadedData{8};
loadedChiSq = loadedData{9};
loadedType = loadedData{10};
loadedNSR = loadedData{11};


%Converts dateString to the standard used in the NLDN files
dateString = ['20',dateString(1:2),'-',dateString(3:4),'-',dateString(5:6)];


%Converts timeStartString and timeEndString into seconds after midnight
timeStart = str2double(timeStartString(1:2))*60*60 + ...
    str2double(timeStartString(3:4))*60 + ...
    str2double(timeStartString(5:6)) + ...
    str2double(timeStartString(7:9))/1000;

timeEnd = str2double(timeEndString(1:2))*60*60 + ...
    str2double(timeEndString(3:4))*60 + ...
    str2double(timeEndString(5:6)) + ...
    str2double(timeEndString(7:9))/1000;


%Obtains and combines the masks used to keep only solutions of the chosen
%date and located inside the lat and lon ranges
dateMask = logical(strcmp(dateString,loadedDate(:)));
latMask = logical((loadedLat(:) >= minLat) & (loadedLat(:) <= maxLat));
lonMask = logical((loadedLon(:) >= minLon) & (loadedLon(:) <= maxLon));
chiSqMask = logical(loadedChiSq(:) < maxChiSq);
%onlyNegMask is defined depending on the value of onlyNeg
if onlyNeg == 1
    onlyNegMask = logical(loadedIpk ~= abs(loadedIpk));
else
    onlyNegMask = true(size(loadedIpk));
end
SMA_Mask = logical(loadedSMA(:) < maxSMA);
NSR_Mask = logical(loadedNSR(:) >= minNSR);


combinedMask = dateMask & latMask & lonMask & chiSqMask & ...
    onlyNegMask & SMA_Mask & NSR_Mask;



%Applies combinedMask to each data column vector
loadedDate = loadedDate(combinedMask);
loadedTime = loadedTime(combinedMask);
loadedLat = loadedLat(combinedMask);
loadedLon = loadedLon(combinedMask);
loadedIpk = loadedIpk(combinedMask);
loadedSMA = loadedSMA(combinedMask);
loadedSmA = loadedSmA(combinedMask);
loadedEllAz = loadedEllAz(combinedMask);
loadedChiSq = loadedChiSq(combinedMask);
loadedType = loadedType(combinedMask);
loadedNSR = loadedNSR(combinedMask);


%Creates timeMask for better performance, keeping only solutions that
%happened during the hours included between timeStart and timeEnd
hourStart = timeStartString(1:2);
hourEnd = timeEndString(1:2);
timeMask = false(length(loadedTime),1);
for hour = str2double(hourStart):str2double(hourEnd)
    if hour < 10
        hourStr = ['0',num2str(hour)];
    else
        hourStr = num2str(hour);
    end
    timeMask = timeMask | logical(strncmp(hourStr,loadedTime(:),2) | ...
        strncmp(hourStr,loadedTime(:),2));
end

%Applies timeMask to each data column vector
loadedDate = loadedDate(timeMask);
loadedTime = loadedTime(timeMask);
loadedLat = loadedLat(timeMask);
loadedLon = loadedLon(timeMask);
loadedIpk = loadedIpk(timeMask);
loadedSMA = loadedSMA(timeMask);
loadedSmA = loadedSmA(timeMask);
loadedEllAz = loadedEllAz(timeMask);
loadedChiSq = loadedChiSq(timeMask);
loadedType = loadedType(timeMask);
loadedNSR = loadedNSR(timeMask);


%Pre-allocates the vector used to store the times converted from the file
convertedSecOfDay = zeros(length(loadedTime)); 

%Goes through each element of loadedTime, converts into seconds after
%midnight and then stores them into convertedSecOfDay
for k=1:length(loadedTime)
    convertedSecOfDay(k) = str2double(loadedTime{k}(1:2))*60*60 + ...
    str2double(loadedTime{k}(4:5))*60 + ...
    str2double(loadedTime{k}(7:8)) + ...
    str2double(loadedTime{k}(10:18))/1e9;
end


%Creates the mask used to select only solutions obtained between
%timeStart and timeEnd, now restricting to the exact range of minutes
timeMask = logical((convertedSecOfDay(:) >= timeStart) & ...
    (convertedSecOfDay(:) <= timeEnd));

%Applies timeMask on the vector of each parameter
loadedDate = loadedDate(timeMask);
loadedTime = loadedTime(timeMask);
convertedSecOfDay = convertedSecOfDay(timeMask);
loadedLat = loadedLat(timeMask);
loadedLon = loadedLon(timeMask);
loadedIpk = loadedIpk(timeMask);
loadedSMA = loadedSMA(timeMask);
loadedSmA = loadedSmA(timeMask);
loadedEllAz = loadedEllAz(timeMask);
loadedChiSq = loadedChiSq(timeMask);
loadedType = loadedType(timeMask);
loadedNSR = loadedNSR(timeMask);


%Pre-allocates the vector used to store the times and dates to be
%converted from the file
convertedYear = zeros(length(loadedDate),1);
convertedMonth = zeros(length(loadedDate),1);
convertedDay = zeros(length(loadedDate),1);
convertedHour = zeros(length(loadedTime),1);
convertedMinute = zeros(length(loadedTime),1);
convertedSecond = zeros(length(loadedTime),1);


%Goes through each element of loadedTime and loadedDate, converts them into 
%seconds after midnight, hour, minute, second, year, month and day and then
%stores them into convertedTime, convertedYear, convertedMonth and
%convertedDay
for k=1:length(loadedTime)
    convertedYear(k) = str2double(loadedDate{k}(1:4));
    convertedMonth(k) = str2double(loadedDate{k}(6:7));
    convertedDay(k) = str2double(loadedDate{k}(9:10));
    convertedHour(k) = str2double(loadedTime{k}(1:2));
    convertedMinute(k) = str2double(loadedTime{k}(4:5));
    convertedSecond(k) = str2double(loadedTime{k}(7:length(loadedTime{k})));
end



%Sorts CGs from cloud pulses
typeMaskCG = logical(strcmp('G',loadedType(:)));
typeMaskIC = logical(strcmp('C',loadedType(:)));


%Returns all parameters
loadedDataCG = [convertedYear(typeMaskCG),convertedMonth(typeMaskCG),...
    convertedDay(typeMaskCG),convertedSecOfDay(typeMaskCG),...
    convertedHour(typeMaskCG),convertedMinute(typeMaskCG),...
    convertedSecond(typeMaskCG),loadedLat(typeMaskCG),loadedLon(typeMaskCG),...
    loadedIpk(typeMaskCG),loadedSMA(typeMaskCG),loadedSmA(typeMaskCG),...
    loadedEllAz(typeMaskCG),loadedChiSq(typeMaskCG),loadedNSR(typeMaskCG)];

loadedDataIC = [convertedYear(typeMaskIC),convertedMonth(typeMaskIC),...
    convertedDay(typeMaskIC),convertedSecOfDay(typeMaskIC),...
    convertedHour(typeMaskIC),convertedMinute(typeMaskIC),...
    convertedSecond(typeMaskIC),loadedLat(typeMaskIC),loadedLon(typeMaskIC),...
    loadedIpk(typeMaskIC),loadedSMA(typeMaskIC),loadedSmA(typeMaskIC),...
    loadedEllAz(typeMaskIC),loadedChiSq(typeMaskIC),loadedNSR(typeMaskIC)];


end