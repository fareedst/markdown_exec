# Demo options: output_execution_report, output_execution_summary

::: Options are initially True
```opts :(document_opts) +[document_options]
output_execution_report: true
output_execution_summary: true
pause_after_script_execution: true
```
```bash
whoami
pwd >&2
date >&1 1>&2
```

## output_execution_report
### Example
		 -^-
		Command: mde ./examples/opt_output_execution_summary.md
		StdOut: logs/mde_2024-07-08-03-21-59_opt_output_execution_summary_,_whoami___pwd__&2___date__&1_1_&2_.out.txt
		 -v-
### Toggle
```opts
output_execution_report: false
```
```opts
output_execution_report: true
```

## output_execution_summary
### Example (edited)
		:execute_aborted_at:
		:execute_completed_at: 2024-07-08 03:21:59.988451000 Z
		:execute_error:
		:execute_error_message:
		:execute_options: { ... }
		:execute_started_at: 2024-07-08 03:21:59.864442000 Z
		:saved_filespec:
		:script_block_name:
		:streamed_lines: { ... }
### Toggle
```opts
output_execution_summary: false
```
```opts
output_execution_summary: true
```
