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

## Files

- `project-adapter.yaml`: project-specific configuration.
- `build.ps1`: build command wrapper.
- `flash.ps1`: flash and verify wrapper.
- `test_shell.ps1`: serial shell test entry.
- `serial_capture.ps1`: serial capture helper.
- `rtcm_parse.ps1`: frame parser placeholder.
- `register_probe.ps1`: SWD register probe placeholder.
- `ai_debug_playbook.md`: failure-triage guidance.
- `handoff_template.md`: delivery report template.
- `evidence_template/`: manifest and report templates.
