function st = validationJobInfo

st.jobType = 'Framework';
st.jobArgs = {};
st.fwConfig = {@Framework.Config.Endpoint2D,'CenterOut'};
st.fwArgs = {'headless',false,'disableEndComment',true,'taskLimit',4,'heartbeatMode','task'};
st.heartbeatTimeout = 15;
st.validationFcnList = {};
