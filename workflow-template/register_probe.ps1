param(
    [string[]]$Target = @("all"),
    [string]$Programmer = "STM32_Programmer_CLI",
    [string]$Connect = "port=SWD mode=HotPlug",
    [string]$OutputJson = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$validTargets = @("rcc", "gpio", "usart", "usb", "fault", "all")
$requestedTargets = @()
foreach ($item in $Target) {
    foreach ($part in ([string]$item -split ",")) {
        $trimmed = $part.Trim()
        if ($trimmed.Length -gt 0) {
            if ($validTargets -notcontains $trimmed) {
                throw "Invalid register probe target '$trimmed'. Valid targets: $($validTargets -join ', ')"
            }
            $requestedTargets += $trimmed
        }
    }
}

$expandedTargets = if ($requestedTargets -contains "all") {
    @("rcc", "gpio", "usart", "usb", "fault")
} else {
    @($requestedTargets)
}

foreach ($item in $expandedTargets) {
    Write-Host "[REG] target=$item"
    Write-Host "[REG] use $Programmer -c $Connect -r32 <address> <count>"
}

Write-Host "[REG] human approval recommended before write operations"

if ($OutputJson) {
    $parent = Split-Path -Parent $OutputJson
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [ordered]@{
        test = "register_probe"
        result = "TEMPLATE_PASS"
        targets = $expandedTargets
        programmer = $Programmer
        connect = $Connect
        note = "Template placeholder only. Replace with target-specific SWD register reads for customer handoff."
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputJson -Encoding utf8
}
