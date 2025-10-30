# Remove Azure Secrets from Documentation Files
# This script replaces real Azure service keys with placeholder values

$files = Get-ChildItem -Path . -Include "*.md" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Replace Azure Speech Key
    $content = $content -replace 'YOUR_AZURE_SPEECH_KEY_HERE', 'YOUR_AZURE_SPEECH_KEY_HERE'

    # Replace Azure Storage Connection String
    $content = $content -replace 'DefaultEndpointsProtocol=https;AccountName=mediagenie;AccountKey=vZdULPjHgd/yiZf0mA9Occh28EGn\+i/ZXhdrT75QuxbnmU78myC2\+ktwzW0mWQgCMXPC2Y59wz5U\+ASty69YaQ==;EndpointSuffix=core\.windows\.net', 'YOUR_AZURE_STORAGE_CONNECTION_STRING_HERE'

    # Replace Azure OpenAI Key (if any real keys exist)
    $content = $content -replace 'sk-YOUR_AZURE_SPEECH_KEY_HEREr678', 'YOUR_AZURE_OPENAI_KEY_HERE'

    # Replace Azure Vision Key (if any real keys exist)
    $content = $content -replace 'your-vision-key', 'YOUR_AZURE_VISION_KEY_HERE'

    # Replace Azure Vision Endpoint
    $content = $content -replace 'https://your-vision\.cognitive\.\.\.', 'YOUR_AZURE_VISION_ENDPOINT_HERE'

    Set-Content $file.FullName $content -NoNewline
    Write-Host "Processed: $($file.FullName)"
}

Write-Host "All Azure secrets have been replaced with placeholder values."