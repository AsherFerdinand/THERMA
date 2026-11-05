function name=c3_block(parent,name,library,position,varargin)
%C3_BLOCK Add a labeled native block at an explicit component-layout position.
add_block(['simulink/' library],[parent '/' name],'Position',position,varargin{:});
end
