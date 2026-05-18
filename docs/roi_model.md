# ROI Model — AI Assisted Embedded Delivery

This model explains where the time and cost compression comes from. It is not a claim that AI replaces engineering judgement.

## 1. Estimation Boundary

This estimate assumes:

- the hardware platform is already defined;
- an STM32CubeMX or HAL baseline exists;
- the goal is firmware bringup, basic feature delivery, automated validation, and evidence handoff;
- PCB design, EMC testing, environmental testing, enclosure design, and production fixtures are outside scope;
- a qualified engineer reviews hardware assumptions, safety risks, and final code.

## 2. Traditional Manual Effort

| Work item | Manual estimate |
|---|---:|
| CMake / CubeCLT migration | 0.5 - 1 day |
| USB CDC shell framework | 1 - 2 days |
| UM982 initialization state machine | 1 - 2 days |
| RTCM configuration and forwarding | 1 - 2 days |
| RS422 DE timing debug | 1 - 2 days |
| Flash configuration persistence | 0.5 - 1 day |
| Watchdog strategy | 0.5 day |
| Automated serial tests | 1 - 2 days |
| RTCM CRC parser | 1 day |
| Documentation and evidence handoff | 1 day |
| Integration/debug buffer | 3 - 8 days |

Conservative total: 15 - 25 engineer-days.

## 3. AI-Assisted Compression Points

| Stage | AI contribution | Why time is compressed |
|---|---|---|
| Code change | Driver skeletons, shell commands, config structs | Less repetitive implementation |
| Build repair | Warning/error analysis | Faster feedback loop |
| Test scripts | PowerShell and parser scaffolding | Lower automation cost |
| Log analysis | Summarize serial logs and register dumps | Shorter diagnosis path |
| Evidence handoff | Draft summary, manifest, and reports | Less project-closing overhead |

## 4. What Should Not Be Compressed Away

- Schematic review
- Power and isolation safety assessment
- EMC / ESD judgement
- Protocol boundary confirmation
- Safety-related logic review
- Final code review
- Production risk review

## 5. Cost Example

Assumptions:

- engineer cost: RMB 2,000 / day;
- AI-assisted delivery: 3 engineer-days + about RMB 10 token cost;
- traditional manual delivery: 15 - 25 engineer-days.

| Approach | Time | Estimated cost |
|---|---:|---:|
| Human-in-the-loop AI workflow | 3 days | about RMB 6,010 |
| Conservative manual delivery | 15 - 25 days | about RMB 30,000 - 50,000 |

## 6. Conclusion

The workflow primarily compresses repetitive coding, build repair, log analysis, test generation, evidence packaging, and regression execution.

It does not remove the engineer's responsibility for architecture, hardware safety, quality judgement, and final acceptance.
