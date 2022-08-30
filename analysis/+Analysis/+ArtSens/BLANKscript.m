%to run real touch TEST
mapBM=GridMap('\\striatum\Data\neural\working\Real Touch\P008_realtouch\P08_Research_62218_RealTouch_map.csv');
blcBM=BLc.Reader('\\striatum\Data\neural\working\Real Touch\P008_realtouch\P08_Research_62218_RealTouch-000.blc');
dataBM=blcBM.read;
ch=[71:86];
%dt=cell(length(ch),1);
fs=2000;
mltplr=fs/1000; %what to multiply your desired ms by to include that many samples
st=1000*mltplr;
tend=2000*mltplr; 
for ii=1:length(this.End{1,3})
    for jj=1:length(ch)
    dt(:,ii,jj)=this.End{1,3}(ii).end(st:tend, ch(jj));
    end
end

%for roberto's trial data from stereo/dbs direct reach
%open C:\Users\Daniel\Documents\DATA\P024\Beta drop in response phase
%P024\Beta drop in response phase P024 and open data

%Arranges time by trials by channels chosen
ch=[1:4];
%phasedata=cell(length(ch),1);
fs=2000;
mltplr=fs/1000;
st=1;
tend=1000; 
ph=2; %1=iti 2=fixate 3=move
for ii=1:size(data{1},2) %for trials
    for jj=1:length(ch)
    phasedata(:,ii,jj)=data{1}{ph,ii}(st:tend, ch(jj));
    end
end
