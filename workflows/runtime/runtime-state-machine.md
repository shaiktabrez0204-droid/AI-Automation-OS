# Runtime State Machine

## Execution States

- PENDING
- LOADING_CONTEXT
- EXECUTING
- VALIDATING
- COMPLETED
- FAILED
- ESCALATED

## State Definitions

### PENDING
Execution created but not started.

### LOADING_CONTEXT
Retrieval system assembling operational context.

### EXECUTING
Workflow actively running.

### VALIDATING
Execution outputs being verified.

### COMPLETED
Execution finished successfully.

### FAILED
Execution failed and requires retry or review.

### ESCALATED
Execution exceeded recovery thresholds.
