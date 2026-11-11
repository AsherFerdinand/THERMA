function available = therma_history_space(destination,required)
%THERMA_HISTORY_SPACE Conservative volume check; user quotas may be stricter.
assert(isfinite(required) && required>=0,'THERMA:HistorySpace','Invalid storage estimate.');
available=double(java.io.File(char(destination)).getUsableSpace());
assert(available>0,'THERMA:HistorySpaceUnknown', ...
    'Destination free space is zero/unavailable. Choose another drive or ask IT to confirm capacity.');
assert(available>=required,'THERMA:HistorySpace', ...
    'Insufficient destination space: require %.0f bytes; volume reports %.0f bytes. No source files modified.', ...
    required,available);
end
