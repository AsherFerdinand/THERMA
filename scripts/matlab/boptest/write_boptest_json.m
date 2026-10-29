function write_boptest_json(file, value)
%WRITE_BOPTEST_JSON UTF-8 diagnostic artifact writer; caller owns output directory.
fid = fopen(file,'w','n','UTF-8');
assert(fid >= 0,'THERMA:WriteFailed','Cannot write diagnostic output.');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
