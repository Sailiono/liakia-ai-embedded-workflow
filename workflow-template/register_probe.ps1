param(
    [ValidateSet("rcc","gpio","usart","usb","fault","all")]
    [string]$Target = "all",
    [string]$Programmer = "STM32_Programmer_CLI",
    [string]$Connect = "port=SWD mode=HotPlug"
)

Write-Host "[REG] target=$Target"
Write-Host "[REG] use $Programmer -c $Connect -r32 <address> <count>"
Write-Host "[REG] human approval recommended before write operations"
