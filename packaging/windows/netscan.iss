#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
[Setup]
AppId={{188A248E-22C6-475A-9ED0-3E3F9107CA22}
AppName=Netscan
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\Netscan
DefaultGroupName=Netscan
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=netscan-windows-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
LicenseFile=..\..\LICENSE
UninstallDisplayIcon={app}\netscan.exe
[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Netscan"; Filename: "{app}\netscan.exe"
[Run]
Filename: "{app}\netscan.exe"; Description: "Open Netscan"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Classes\netscan"; ValueType: string; ValueName: ""; ValueData: "URL:Netscan"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\netscan"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\netscan\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\netscan.exe"" ""%1"""
