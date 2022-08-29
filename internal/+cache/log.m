function log(logfcn,msg,priority)
feval(logfcn{1}{:},msg,priority,logfcn{2}{:});