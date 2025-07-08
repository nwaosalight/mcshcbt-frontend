# Firebase C++ SDK Setup Script - Updated for version 12.7.0
# This script downloads and sets up the Firebase C++ SDK for Flutter Windows

$ErrorActionPreference = "Stop"

# Configuration to match your CMakeLists.txt expectations
$sdkVersion = "12.7.0"
$downloadUrl = "https://dl.google.com/firebase/sdk/cpp/firebase_cpp_sdk_12.7.0.zip"
$firebaseDir = "windows/firebase"
$finalSdkPath = "$firebaseDir/firebase_cpp_sdk_windows"

# Show current directory for debugging
Write-Host "Current directory: $(Get-Location)"
Write-Host "Will create Firebase SDK at: $finalSdkPath"

# Create firebase directory structure if it doesn't exist
Write-Host "Creating Firebase directory structure..."
if (-not (Test-Path "windows")) {
    New-Item -ItemType Directory -Path "windows" -Force
    Write-Host "Created directory: windows"
}
if (-not (Test-Path $firebaseDir)) {
    New-Item -ItemType Directory -Path $firebaseDir -Force
    Write-Host "Created directory: $firebaseDir"
}

# Download Firebase C++ SDK
$zipFile = "$firebaseDir/firebase_cpp_sdk.zip"
Write-Host "Downloading Firebase C++ SDK version $sdkVersion..."
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $zipFile)
    Write-Host "Download completed successfully!"
} catch {
    Write-Error "Failed to download Firebase SDK: $($_.Exception.Message)"
    exit 1
}

# Extract the SDK
Write-Host "Extracting Firebase C++ SDK..."
try {
    Expand-Archive -Path $zipFile -DestinationPath $firebaseDir -Force
    Write-Host "Extraction completed successfully!"
} catch {
    Write-Error "Failed to extract Firebase SDK: $($_.Exception.Message)"
    exit 1
}

# Rename the extracted folder to match CMakeLists.txt expectations
$extractedPath = "$firebaseDir/firebase_cpp_sdk"
if (Test-Path $extractedPath) {
    if (Test-Path $finalSdkPath) {
        Write-Host "Removing existing SDK directory..."
        Remove-Item -Recurse -Force $finalSdkPath
    }
    Write-Host "Renaming SDK directory to match CMakeLists.txt expectations..."
    Rename-Item -Path $extractedPath -NewName "firebase_cpp_sdk_windows"
    Write-Host "SDK renamed to: $finalSdkPath"
} else {
    Write-Error "Extracted SDK directory not found at expected location: $extractedPath"
    exit 1
}

# Clean up the zip file
Remove-Item $zipFile
Write-Host "Cleanup completed!"

# Verify the installation
if (Test-Path $finalSdkPath) {
    Write-Host "✅ Firebase C++ SDK setup completed successfully!"
    Write-Host "SDK Location: $(Resolve-Path $finalSdkPath)"
    Write-Host ""
    Write-Host "SDK Contents:"
    Get-ChildItem -Path $finalSdkPath -Directory | Select-Object Name | Format-Table -AutoSize
} else {
    Write-Error "❌ SDK installation failed - directory not found at: $finalSdkPath"
    exit 1
}