# Coleta de specs da maquina (Windows) - Infraestrutura de Hardware
# Como rodar (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\coletar_dados_windows.ps1
# Gera o arquivo: dados_maquina_windows.txt (na mesma pasta)

$out = Join-Path $PSScriptRoot "dados_maquina_windows.txt"
"=== COLETA DE SPECS - WINDOWS ===" | Out-File $out
"Data: $(Get-Date)" | Out-File $out -Append
"Hostname: $env:COMPUTERNAME" | Out-File $out -Append
"" | Out-File $out -Append

"--- SISTEMA OPERACIONAL ---" | Out-File $out -Append
Get-CimInstance Win32_OperatingSystem |
  Select-Object Caption, Version, BuildNumber, OSArchitecture |
  Format-List | Out-File $out -Append

"--- CPU ---" | Out-File $out -Append
Get-CimInstance Win32_Processor |
  Select-Object Name, NumberOfCores, NumberOfLogicalProcessors,
    MaxClockSpeed, L2CacheSize, L3CacheSize, AddressWidth, SocketDesignation |
  Format-List | Out-File $out -Append

"--- CACHE (por nivel) ---" | Out-File $out -Append
Get-CimInstance Win32_CacheMemory |
  Select-Object @{N='Nivel';E={$_.Level-2}}, MaxCacheSize, Associativity, Purpose |
  Format-Table -Auto | Out-File $out -Append

"--- MEMORIA (RAM) ---" | Out-File $out -Append
$ram = Get-CimInstance Win32_PhysicalMemory
$ram | Select-Object @{N='Capacidade_GB';E={[math]::Round($_.Capacity/1GB,1)}},
    Speed, ConfiguredClockSpeed, Manufacturer, PartNumber, DeviceLocator |
  Format-Table -Auto | Out-File $out -Append
"Total de modulos (canais aprox.): $($ram.Count)" | Out-File $out -Append
$total = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
"RAM total: $([math]::Round($total/1GB,1)) GB" | Out-File $out -Append
"" | Out-File $out -Append

"--- ARMAZENAMENTO ---" | Out-File $out -Append
Get-PhysicalDisk |
  Select-Object FriendlyName, MediaType, BusType,
    @{N='Tamanho_GB';E={[math]::Round($_.Size/1GB,0)}}, SpindleSpeed |
  Format-Table -Auto | Out-File $out -Append

"--- GPU / VIDEO ---" | Out-File $out -Append
Get-CimInstance Win32_VideoController |
  Select-Object Name, AdapterRAM, DriverVersion |
  Format-List | Out-File $out -Append

"--- PLACA-MAE ---" | Out-File $out -Append
Get-CimInstance Win32_BaseBoard |
  Select-Object Manufacturer, Product | Format-List | Out-File $out -Append

"=== FIM ===" | Out-File $out -Append
"" | Out-File $out -Append
"NOTA: PCIe (geracao/largura), conjuntos de instrucao (AVX) e latencias de cache" | Out-File $out -Append
"      nao saem por WMI - use CPU-Z / HWiNFO64 / AIDA64 para esses campos." | Out-File $out -Append

Write-Host "Pronto! Arquivo gerado em: $out"
Get-Content $out
