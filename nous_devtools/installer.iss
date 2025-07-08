[Setup]
; Basic app information
AppName=Nous DevTools
AppVersion=1.0.0
AppPublisher=Your Company Name
AppPublisherURL=https://yourwebsite.com
AppSupportURL=https://yourwebsite.com/support
AppUpdatesURL=https://yourwebsite.com/updates
DefaultDirName={autopf}\Nous DevTools
DefaultGroupName=Nous DevTools
AllowNoIcons=yes
LicenseFile=LICENSE
InfoBeforeFile=README.txt
InfoAfterFile=CHANGELOG.txt
OutputDir=installer_output
OutputBaseFilename=NousDevToolsInstaller
SetupIconFile=assets\icons\app_icon.png
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64

; Minimum Windows version
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; Main executable and all dependencies from the correct Flutter build path
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Include Visual C++ Redistributable if needed
Source: "redist\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\Nous DevTools"; Filename: "{app}\nous_devtools.exe"
Name: "{group}\{cm:UninstallProgram,Nous DevTools}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Nous DevTools"; Filename: "{app}\nous_devtools.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\Nous DevTools"; Filename: "{app}\nous_devtools.exe"; Tasks: quicklaunchicon

[Run]
; Install Visual C++ Redistributable
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "Installing Visual C++ Redistributable..."; Flags: waituntilterminated
; Option to launch app after installation
Filename: "{app}\nous_devtools.exe"; Description: "{cm:LaunchProgram,Nous DevTools}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Registry]
Root: HKCU; Subkey: "Software\NousDevTools"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"