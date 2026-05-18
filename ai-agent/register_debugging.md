# Register Debugging

Register probing is useful when logs are ambiguous.

## Read-Only Probe Examples

- RCC clock enable registers
- GPIO mode and alternate-function registers
- USART status and control registers
- USB device status
- reset flags
- fault status registers

## Safety Rule

Read operations are usually acceptable during diagnosis. Write operations require explicit engineer approval.
