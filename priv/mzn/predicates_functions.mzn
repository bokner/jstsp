function var int: switches(int: current_job, int: next_job) =
         sum(t in TOOLS)(bool2int(magazine[schedule[next_job], t] > magazine[schedule[current_job], t]));