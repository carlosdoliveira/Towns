; ============================================================================
; Towns NSIS Installer Script
;
; Passed definitions (via makensis /D flags from the workflow):
;   VERSION   — version string, e.g. "15"  (leading 'v' already stripped)
;   DIST_DIR  — absolute path to the dist\Towns staging folder
;   OUTFILE   — absolute path for the produced installer .exe
; ============================================================================

Unicode True

; ── Product metadata ──────────────────────────────────────────────────────────
!define PRODUCT_NAME      "Towns"
!define PUBLISHER         "Towns Project"
!define INSTALL_REG_KEY   "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Towns"
!define STARTMENU_FOLDER  "Towns"

; ── Installer output ──────────────────────────────────────────────────────────
OutFile "${OUTFILE}"

; ── Default install directory ────────────────────────────────────────────────
InstallDir "$PROGRAMFILES64\Towns"
InstallDirRegKey HKLM "${INSTALL_REG_KEY}" "InstallLocation"

; ── Visual settings ───────────────────────────────────────────────────────────
Name "${PRODUCT_NAME} ${VERSION}"
ShowInstDetails show
ShowUnInstDetails show

; ── Compression ───────────────────────────────────────────────────────────────
SetCompressor /SOLID lzma

; ── Request admin privileges (needed to write to Program Files and HKLM) ──────
RequestExecutionLevel admin

; ── Modern UI (optional but friendlier) ──────────────────────────────────────
!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_ICON           "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON         "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ── Install section ───────────────────────────────────────────────────────────
Section "Towns (required)" SecMain
  SectionIn RO   ; cannot be deselected

  SetOutPath "$INSTDIR"

  ; Copy all application files from the staging folder
  File /r "${DIST_DIR}\*.*"

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; ── Start Menu shortcut ───────────────────────────────────────────────────
  CreateDirectory "$SMPROGRAMS\${STARTMENU_FOLDER}"
  CreateShortcut "$SMPROGRAMS\${STARTMENU_FOLDER}\Towns.lnk" \
    "$INSTDIR\Towns.exe" "" "$INSTDIR\Towns.exe" 0

  CreateShortcut "$SMPROGRAMS\${STARTMENU_FOLDER}\Uninstall Towns.lnk" \
    "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

  ; ── Desktop shortcut ─────────────────────────────────────────────────────
  CreateShortcut "$DESKTOP\Towns.lnk" \
    "$INSTDIR\Towns.exe" "" "$INSTDIR\Towns.exe" 0

  ; ── Add/Remove Programs registry entries ─────────────────────────────────
  WriteRegStr   HKLM "${INSTALL_REG_KEY}" "DisplayName"      "${PRODUCT_NAME} ${VERSION}"
  WriteRegStr   HKLM "${INSTALL_REG_KEY}" "DisplayVersion"   "${VERSION}"
  WriteRegStr   HKLM "${INSTALL_REG_KEY}" "Publisher"        "${PUBLISHER}"
  WriteRegStr   HKLM "${INSTALL_REG_KEY}" "InstallLocation"  "$INSTDIR"
  WriteRegStr   HKLM "${INSTALL_REG_KEY}" "UninstallString"  '"$INSTDIR\uninstall.exe"'
  WriteRegStr   HKLM "${INSTALL_REG_KEY}" "DisplayIcon"      "$INSTDIR\Towns.exe"
  WriteRegDWORD HKLM "${INSTALL_REG_KEY}" "NoModify"         1
  WriteRegDWORD HKLM "${INSTALL_REG_KEY}" "NoRepair"         1

SectionEnd

; ── Uninstall section ─────────────────────────────────────────────────────────
Section "Uninstall"

  ; ── Remove shortcuts first ────────────────────────────────────────────────
  Delete "$SMPROGRAMS\${STARTMENU_FOLDER}\Towns.lnk"
  Delete "$SMPROGRAMS\${STARTMENU_FOLDER}\Uninstall Towns.lnk"
  RMDir  "$SMPROGRAMS\${STARTMENU_FOLDER}"
  Delete "$DESKTOP\Towns.lnk"

  ; ── Remove registry entries ───────────────────────────────────────────────
  DeleteRegKey HKLM "${INSTALL_REG_KEY}"

  ; ── Remove all installed files and the install directory. ────────────────
  ; Note: user save data is stored in the user profile (not the install dir),
  ; so a full removal is safe here.
  RMDir /r /REBOOTOK "$INSTDIR"

SectionEnd
