# MediaGenie Backend Test Script

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "           MediaGenie Backend API Test Suite                        " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:9001"
$testResults = @()

# Function to test endpoint
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Body = $null
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  URL: $Url" -ForegroundColor Gray
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -TimeoutSec 10
        } else {
            $jsonBody = $Body | ConvertTo-Json
            $response = Invoke-WebRequest -Uri $Url -Method POST -Body $jsonBody -ContentType "application/json" -UseBasicParsing -TimeoutSec 30
        }
        
        if ($response.StatusCode -eq 200) {
            Write-Host "  ‚ú?PASSED (Status: $($response.StatusCode))" -ForegroundColor Green
            return @{Name=$Name; Status="PASSED"; StatusCode=$response.StatusCode; Response=$response.Content}
        } else {
            Write-Host "  ‚ö†Ô∏è  WARNING (Status: $($response.StatusCode))" -ForegroundColor Yellow
            return @{Name=$Name; Status="WARNING"; StatusCode=$response.StatusCode; Response=$response.Content}
        }
    } catch {
        Write-Host "  ‚ú?FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return @{Name=$Name; Status="FAILED"; Error=$_.Exception.Message}
    }
    Write-Host ""
}

# Wait for service to be ready
Write-Host "‚è?Waiting for service to start..." -ForegroundColor Yellow
$maxRetries = 10
$retryCount = 0
$serviceReady = $false

while ($retryCount -lt $maxRetries -and -not $serviceReady) {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $serviceReady = $true
            Write-Host "  ‚ú?Service is ready!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "  Attempt $retryCount/$maxRetries..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $serviceReady) {
    Write-Host ""
    Write-Host "‚ú?Service is not responding!" -ForegroundColor Red
    Write-Host "  Please make sure the backend service is running:" -ForegroundColor Yellow
    Write-Host "  .\start_backend.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                        Running Tests                               " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
$result = Test-Endpoint -Name "Health Check" -Url "$baseUrl/health"
$testResults += $result

# Test 2: API Documentation
$result = Test-Endpoint -Name "API Documentation" -Url "$baseUrl/docs"
$testResults += $result

# Test 3: Text-to-Speech
Write-Host "Testing: Text-to-Speech (TTS)" -ForegroundColor Yellow
Write-Host "  URL: $baseUrl/api/speech/text-to-speech" -ForegroundColor Gray
try {
    $body = @{
        text = "‰Ω†Â•ΩÔºåËøôÊòØMediaGenieÊµãËØï"
        voice = "zh-CN-XiaoxiaoNeural"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/speech/text-to-speech" `
        -Method POST `
        -Body $body `
        -ContentType "application/json" `
        -UseBasicParsing `
        -TimeoutSec 30 `
        -OutFile "test_tts_output.mp3"
    
    if (Test-Path "test_tts_output.mp3") {
        $fileSize = (Get-Item "test_tts_output.mp3").Length
        if ($fileSize -gt 0) {
            Write-Host "  ‚ú?PASSED (Generated audio: $fileSize bytes)" -ForegroundColor Green
            $testResults += @{Name="Text-to-Speech"; Status="PASSED"; FileSize=$fileSize}
        } else {
            Write-Host "  ‚ú?FAILED (Empty audio file)" -ForegroundColor Red
            $testResults += @{Name="Text-to-Speech"; Status="FAILED"; Error="Empty file"}
        }
    }
} catch {
    Write-Host "  ‚ú?FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Name="Text-to-Speech"; Status="FAILED"; Error=$_.Exception.Message}
}
Write-Host ""

# Test 4: GPT Chat
$result = Test-Endpoint -Name "GPT Chat" -Url "$baseUrl/api/gpt/chat" -Method "POST" -Body @{
    message = "‰Ω†Â•Ω"
    conversation_id = "test-001"
}
$testResults += $result

# Test 5: Task List
$result = Test-Endpoint -Name "Task List" -Url "$baseUrl/api/tasks"
$testResults += $result

# Test 6: Create Task
$result = Test-Endpoint -Name "Create Task" -Url "$baseUrl/api/tasks" -Method "POST" -Body @{
    title = "Test Task"
    description = "This is a test task"
}
$testResults += $result

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                        Test Summary                                " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$passed = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAILED" }).Count
$total = $testResults.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

# Display detailed results
Write-Host "Detailed Results:" -ForegroundColor Cyan
Write-Host ""
foreach ($result in $testResults) {
    $statusColor = switch ($result.Status) {
        "PASSED" { "Green" }
        "FAILED" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    $statusSymbol = switch ($result.Status) {
        "PASSED" { "‚ú? }
        "FAILED" { "‚ú? }
        "WARNING" { "‚ö†Ô∏è" }
        default { "?" }
    }
    
    Write-Host "  $statusSymbol $($result.Name)" -ForegroundColor $statusColor
    if ($result.StatusCode) {
        Write-Host "    Status Code: $($result.StatusCode)" -ForegroundColor Gray
    }
    if ($result.Error) {
        Write-Host "    Error: $($result.Error)" -ForegroundColor Gray
    }
    if ($result.FileSize) {
        Write-Host "    File Size: $($result.FileSize) bytes" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

if ($failed -eq 0) {
    Write-Host "üéâ All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the test results above" -ForegroundColor White
    Write-Host "  2. Test additional endpoints manually at: $baseUrl/docs" -ForegroundColor White
    Write-Host "  3. When ready, deploy to Azure using the deployment package" -ForegroundColor White
} else {
    Write-Host "‚ö†Ô∏è  Some tests failed. Please review the errors above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "  1. Check the backend logs: backend\media-service\logs\media-service.log" -ForegroundColor White
    Write-Host "  2. Verify Azure service keys are correct in main.py" -ForegroundColor White
    Write-Host "  3. Ensure network connectivity to Azure services" -ForegroundColor White
}

Write-Host ""
Write-Host "Generated files:" -ForegroundColor Cyan
if (Test-Path "test_tts_output.mp3") {
    Write-Host "  ‚Ä?test_tts_output.mp3 (TTS test audio)" -ForegroundColor White
}

Write-Host ""

