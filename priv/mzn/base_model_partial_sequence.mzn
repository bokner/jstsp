include "base_model.mzn";
% Используем подпоследовательность набора работ,
% найденную на предыдущем шаге
array[1..3] of JOBS: partial_sequence = [3, 5, 1];

% value_precede_chain constraint:
% Ограничивает основную последовательность работ
% таким образом, что подпоследовательность сохраняет в ней свой порядок.
%
include "value_precede_chain.mzn";

constraint value_precede_chain(partial_sequence, sequence);