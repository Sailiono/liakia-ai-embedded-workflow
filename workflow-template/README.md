# Workflow Template

This folder sketches how another STM32 firmware project can be connected to the same delivery loop.

The adapter model is intentionally simple:

1. describe project paths and tools in `project-adapter.yaml`;
2. run build;
3. flash only after build passes;
4. run serial tests;
5. collect logs and optional register probes;
6. generate evidence package.

The template does not replace your existing IDE, HAL, FreeRTOS, or driver stack. It wraps the repeatable parts of delivery.

## Run

```powershell
.\run_workflow.ps1 -Adapter .\project-adapter.yaml -Stage all
```

Supported stages:

```text
env | build | flash | test | probe | evidence | all
```

Use `-DryRun` to validate command wiring before touching hardware:

```powershell
.\run_workflow.ps1 -Adapter .\project-adapter.yaml -Stage all -DryRun
```

## Files

- `project-adapter.yaml`: project-specific configuration.
- `run_workflow.ps1`: adapter-driven workflow entry.
- `build.ps1`: build command wrapper.
- `flash.ps1`: flash and verify wrapper.
- `test_shell.ps1`: serial shell test entry.
- `serial_capture.ps1`: serial capture helper.
- `rtcm_parse.ps1`: frame parser placeholder.
- `register_probe.ps1`: SWD register probe placeholder.
- `ai_debug_playbook.md`: failure-triage guidance.
- `handoff_template.md`: delivery report template.
- `evidence_template/`: manifest and report templates.
- `examples/`: migration examples for shell, sensor gateway, and motor-control style projects.
