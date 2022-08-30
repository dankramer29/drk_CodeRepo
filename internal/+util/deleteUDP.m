function deleteUDP(u)

if isa(u,'udp')
    if strcmpi(u.Status,'open')
        fclose(u);
    end
    delete(u);
end