# مسار الملف المشترك
$outputFile = ".\web\real_temp.txt"

Write-Host "Starting Dual-Sensor Bridge (CPU + GPU)..." -ForegroundColor Cyan

while ($true) {
    try {
        # 1. البحث عن حرارة المعالج (CPU)
        $cpuSensor = Get-WmiObject -Namespace "root\OpenHardwareMonitor" -Class Sensor | 
                     Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -match "CPU" } | 
                     Select-Object -First 1

        # 2. البحث عن حرارة كارت الشاشة (GPU)
        $gpuSensor = Get-WmiObject -Namespace "root\OpenHardwareMonitor" -Class Sensor | 
                     Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -match "GPU" } | 
                     Select-Object -First 1

        # تجهيز القيم (لو ملقاش حساس بيحط 0)
        $cpuVal = if ($cpuSensor) { $cpuSensor.Value } else { "0" }
        $gpuVal = if ($gpuSensor) { $gpuSensor.Value } else { "0" }

        # الصيغة: CPU|GPU (مثلاً: 45.5|52.0)
        $finalString = "$cpuVal|$gpuVal"
        
        # الكتابة في الملف
        Set-Content -Path $outputFile -Value $finalString
        
        Write-Host "Sensors -> CPU: $cpuVal C | GPU: $gpuVal C" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: OpenHardwareMonitor not running?" -ForegroundColor Red
        Set-Content -Path $outputFile -Value "0|0"
    }
    
    Start-Sleep -Seconds 1
}