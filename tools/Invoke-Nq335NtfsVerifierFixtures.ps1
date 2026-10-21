# Synthetic fixture runner for the read-only NTFS stage verifier.
# Invented names and bytes only. Setup is the only write phase.
# A PASS here is not an owner-stage GO and windows_gate stays STOP.
# named-stream is an implementation extension for a proven extra stream.
# Frozen design 151 lists no such token; incomplete enumeration stays
# interop-unproven. The verifier header records the same extension.
# outside_reads and outside_reads_max are verifier-reported telemetry,
# not an OS audit and not proof that canary bytes were unread.
# A CRLF change STOPs as size-mismatch when the byte length changes and
# as hash-mismatch when the length stays the same. Either is a safe STOP.
# Four coverage gaps stay NOT TESTED: sharing drift, real cloud-sync
# detection, non-NTFS, and the on-disk trailing-dot form.
#Requires -Version 5.1
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$script:Canary = 'CANARY-OUTSIDE-DO-NOT-READ-7f3a'
$script:AdsStreamLabel = 'nqinvented'
$script:AdsGuardPrefix = 'nqsyn'
$script:VerifierOutside = New-Object System.Collections.Generic.List[string]
$script:Blob = '0000000000000000000000000000000000000000'
$script:OwnerPin = '73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52'
$script:Rows = New-Object System.Collections.Generic.List[object]
$script:Failed = $false
$script:PowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$script:Verifier = Join-Path $PSScriptRoot 'Invoke-Nq335NtfsStageVerifier.ps1'
$script:Cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'
$script:Fsutil = Join-Path $env:SystemRoot 'System32\fsutil.exe'

function Write-Row([string]$name, [string]$result, [string]$reason, [string]$outside, [string]$note, [string]$extra) {
    if ([string]::IsNullOrEmpty($outside)) { $outside = '0' }
    Write-Output ('FIXTURE: ' + $name)
    Write-Output ('result: ' + $result)
    Write-Output ('reason: ' + $reason)
    Write-Output ('outside_reads: ' + $outside)
    if (-not [string]::IsNullOrEmpty($extra)) { Write-Output $extra }
    if (-not [string]::IsNullOrEmpty($note)) { Write-Output ('note: ' + $note) }
    $ok = $result -ne 'HARNESS-FAIL'
    if (-not $ok) { $script:Failed = $true }
    $script:Rows.Add([pscustomobject]@{
        Name = $name; Result = $result; Reason = $reason; Outside = $outside; Note = $note
    }) | Out-Null
}

function Add-NotTested([string]$name, [string]$note) {
    Write-Row $name 'NOT TESTED' 'not-run' '0' $note ''
}

function Get-Sha256([byte[]]$bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }
    $builder = New-Object System.Text.StringBuilder
    foreach ($byte in $digest) { [void]$builder.Append($byte.ToString('x2')) }
    return $builder.ToString()
}

function Write-InventedManifest([string]$path, $rows) {
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append("path`tbytes`tgit_blob`tsha256`n")
    foreach ($row in $rows) {
        $hash = Get-Sha256 ([byte[]]$row.Bytes)
        [void]$builder.Append([string]$row.Rel)
        [void]$builder.Append("`t")
        [void]$builder.Append(([byte[]]$row.Bytes).Length.ToString())
        [void]$builder.Append("`t")
        [void]$builder.Append($script:Blob)
        [void]$builder.Append("`t")
        [void]$builder.Append($hash)
        [void]$builder.Append("`n")
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $bytes = $utf8.GetBytes($builder.ToString())
    [System.IO.File]::WriteAllBytes($path, $bytes)
    return (Get-Sha256 $bytes)
}

function Read-Captured([string]$path) {
    if (-not [System.IO.File]::Exists($path)) { return '' }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) {
        return [System.Text.Encoding]::Unicode.GetString($bytes)
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Test-Leak([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return $false }
    if ($text.IndexOf($script:Canary, [System.StringComparison]::Ordinal) -ge 0) { return $true }
    if ($text -match '[A-Za-z]:\\') { return $true }
    if ($text.IndexOf('\\', [System.StringComparison]::Ordinal) -ge 0) { return $true }
    return $false
}

function Test-AdsLabel([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return $false }
    if ($text.IndexOf($script:AdsStreamLabel, [System.StringComparison]::Ordinal) -ge 0) { return $true }
    if ($text.IndexOf($script:AdsGuardPrefix, [System.StringComparison]::Ordinal) -ge 0) { return $true }
    return $false
}

function Invoke-Verifier([string]$manifest, [string]$pin, [string]$stage) {
    $id = [guid]::NewGuid().ToString('n')
    $outFile = Join-Path $script:Base ('out-' + $id + '.txt')
    $errFile = Join-Path $script:Base ('err-' + $id + '.txt')
    $proc = Start-Process -FilePath $script:PowerShell -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Verifier,
        '-ManifestPath', $manifest, '-RequiredPin', $pin, '-StagePath', $stage
    ) -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $text = Read-Captured $outFile
    $err = Read-Captured $errFile
    try { [System.IO.File]::Delete($outFile) } catch { }
    try { [System.IO.File]::Delete($errFile) } catch { }
    return [pscustomobject]@{
        Exit = $proc.ExitCode
        Text = $text
        Err = $err
        Leak = ((Test-Leak $text) -or (Test-Leak $err))
    }
}

function Get-Field([string]$text, [string]$name) {
    $prefix = $name + ': '
    foreach ($line in ($text -split "`n")) {
        $trim = $line.Trim()
        if ($trim.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
            return $trim.Substring($prefix.Length)
        }
    }
    return $null
}

function Expect-Run {
    param(
        [string]$Name,
        $Run,
        [string]$Result,
        [string[]]$Reasons,
        [hashtable]$Equals
    )
    $adsLabel = $false
    if ($null -ne $Run) {
        if ((Test-AdsLabel $Run.Text) -or (Test-AdsLabel $Run.Err)) { $adsLabel = $true }
    }
    if ($null -eq $Run -or $Run.Leak -or $adsLabel) {
        [void]$script:VerifierOutside.Add('')
        $held = 'output withheld'
        if ($adsLabel) { $held = 'ads-label' }
        Write-Row $Name 'HARNESS-FAIL' 'redaction' '' $held ''
        return
    }
    $got = Get-Field $Run.Text 'RESULT'
    $reason = Get-Field $Run.Text 'reason'
    $outside = Get-Field $Run.Text 'outside_reads'
    if ($null -eq $outside) { [void]$script:VerifierOutside.Add('') }
    else { [void]$script:VerifierOutside.Add([string]$outside) }
    $gate = Get-Field $Run.Text 'windows_gate'
    $game = Get-Field $Run.Text 'gameplay'
    $extra = ''
    $sampleLeak = $false
    foreach ($key in @('content_reads', 'files_expected', 'files_seen', 'dirs_expected', 'dirs_seen', 'ADS', 'windows_ps51_ntfs', 'filesystem', 'byte_mismatches', 'hash_mismatches', 'diagnostic_rereads', 'ntstatus', 'exception_type', 'ads_sample', 'powershell_version', 'volume_root_mode', 'volume_root_first', 'no_recall', 'name_query_terminal', 'name_proof', 'name_query_miss', 'ancestor_index', 'ancestor_count', 'ancestor0_length', 'normalized_status', 'ads_dir_eof', 'walk_phase', 'exception_line', 'exception_id')) {
        $value = Get-Field $Run.Text $key
        if ($null -eq $value) { continue }
        if ($key -eq 'ads_sample' -and -not [System.StringComparer]::Ordinal.Equals([string]$value, 'ads-present')) {
            $sampleLeak = $true
            $extra += 'ads_sample=withheld; '
            continue
        }
        $extra += ($key + '=' + $value + '; ')
    }
    $ok = $true
    $note = 'matched'
    if ($sampleLeak) { $ok = $false; $note = 'ads-label' }
    if ($got -ne $Result) { $ok = $false; if ($note -eq 'matched') { $note = 'result' } }
    $reasonOk = $false
    foreach ($allowed in $Reasons) {
        if ([System.StringComparer]::Ordinal.Equals([string]$reason, $allowed)) { $reasonOk = $true }
    }
    if (-not $reasonOk) { $ok = $false; if ($note -eq 'matched') { $note = 'reason' } }
    if ($outside -ne '0') { $ok = $false; if ($note -eq 'matched') { $note = 'outside_reads' } }
    if ($gate -ne 'STOP' -or $game -ne 'NOT TESTED') { $ok = $false; if ($note -eq 'matched') { $note = 'gate' } }
    if ($null -ne $Equals) {
        foreach ($key in @($Equals.Keys)) {
            $actual = Get-Field $Run.Text ([string]$key)
            if (-not [System.StringComparer]::Ordinal.Equals([string]$actual, [string]$Equals[$key])) {
                $ok = $false
                if ($note -eq 'matched') { $note = 'field' }
            }
        }
    }
    $exitOk = (($Result -eq 'PASS' -and $Run.Exit -eq 0) -or ($Result -eq 'STOP' -and $Run.Exit -eq 1))
    if (-not $exitOk) { $ok = $false; if ($note -eq 'matched') { $note = 'exit' } }
    if (-not $ok) {
        Write-Row $Name 'HARNESS-FAIL' ([string]$reason) ([string]$outside) $note $extra
        return
    }
    Write-Row $Name $Result ([string]$reason) ([string]$outside) 'matched' $extra
}

function New-WorkRoot {
    $path = Join-Path $script:Base ('case-' + [guid]::NewGuid().ToString('n'))
    [void][System.IO.Directory]::CreateDirectory($path)
    return $path
}

function Remove-OwnedTree([string]$path) {
    $present = $false
    try {
        $null = [System.IO.File]::GetAttributes($path)
        $present = $true
    } catch {
        $present = $false
    }
    if (-not $present) { return }
    $attr = [System.IO.File]::GetAttributes($path)
    if (($attr -band 0x400) -ne 0) {
        if (($attr -band 0x10) -ne 0) { [System.IO.Directory]::Delete($path, $false) }
        else { [System.IO.File]::Delete($path) }
        return
    }
    if (($attr -band 0x10) -ne 0) {
        foreach ($child in [System.IO.Directory]::EnumerateFileSystemEntries($path)) {
            Remove-OwnedTree $child
        }
        [System.IO.Directory]::Delete($path, $false)
        return
    }
    try { [System.IO.File]::SetAttributes($path, [System.IO.FileAttributes]::Normal) } catch { }
    [System.IO.File]::Delete($path)
}

function Invoke-Quiet([string]$file, [string[]]$argList) {
    $id = [guid]::NewGuid().ToString('n')
    $outFile = Join-Path $script:Base ('q-' + $id + '.out')
    $errFile = Join-Path $script:Base ('q-' + $id + '.err')
    $proc = Start-Process -FilePath $file -ArgumentList $argList -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    try { [System.IO.File]::Delete($outFile) } catch { }
    try { [System.IO.File]::Delete($errFile) } catch { }
    return $proc.ExitCode
}

function New-CanaryFile([string]$path) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($script:Canary + "`n")
    [System.IO.File]::WriteAllBytes($path, $bytes)
}

function New-CleanSmall([string]$parent) {
    $stage = Join-Path $parent 'Questie-335'
    $folder = Join-Path $stage 'Folder'
    [void][System.IO.Directory]::CreateDirectory($folder)
    $alphaBytes = [System.Text.Encoding]::ASCII.GetBytes("invented-alpha`n")
    $betaBytes = [System.Text.Encoding]::ASCII.GetBytes("invented-beta`n")
    $alpha = Join-Path $stage 'Alpha.txt'
    $beta = Join-Path $folder 'Beta.txt'
    [System.IO.File]::WriteAllBytes($alpha, $alphaBytes)
    [System.IO.File]::WriteAllBytes($beta, $betaBytes)
    $manifest = Join-Path $parent 'manifest.tsv'
    $pin = Write-InventedManifest $manifest @(
        @{ Rel = 'Alpha.txt'; Bytes = $alphaBytes },
        @{ Rel = 'Folder/Beta.txt'; Bytes = $betaBytes }
    )
    return [pscustomobject]@{
        Stage = $stage; Manifest = $manifest; Pin = $pin; Alpha = $alpha
        Beta = $beta; Folder = $folder; Parent = $parent
        AlphaBytes = $alphaBytes; BetaBytes = $betaBytes
    }
}

function Add-NamedStream([string]$path) {
    Set-Content -LiteralPath $path -Stream $script:AdsStreamLabel -Value 'invented-stream' -Encoding Ascii -ErrorAction Stop -WarningAction SilentlyContinue
}

function Add-GuardStreams([string]$path, [int]$count) {
    for ($i = 0; $i -lt $count; $i++) {
        $label = $script:AdsGuardPrefix + ('{0:d2}' -f $i)
        Set-Content -LiteralPath $path -Stream $label -Value 'x' -Encoding Ascii -ErrorAction Stop -WarningAction SilentlyContinue
    }
}

function Remove-NamedStream([string]$path) {
    $stream = $path + ':' + $script:AdsStreamLabel
    try { [System.IO.File]::Delete($stream) } catch { }
}

function Get-ShortLeaf([string]$path) {
    $fso = New-Object -ComObject Scripting.FileSystemObject
    $attr = [System.IO.File]::GetAttributes($path)
    if (($attr -band 0x10) -ne 0) { return [string]$fso.GetFolder($path).ShortName }
    return [string]$fso.GetFile($path).ShortName
}

function Try-DistinctShort([string]$path, [string]$leaf) {
    $short = ''
    try { $short = Get-ShortLeaf $path } catch { return '' }
    if (-not [string]::IsNullOrEmpty($short) -and -not [System.StringComparer]::Ordinal.Equals($short, $leaf)) {
        return $short
    }
    if (-not [System.IO.File]::Exists($script:Fsutil)) { return '' }
    $code = Invoke-Quiet $script:Fsutil @('file', 'setshortname', $path, 'LONGAN~1')
    if ($code -ne 0) { return '' }
    try { $short = Get-ShortLeaf $path } catch { return '' }
    if (-not [string]::IsNullOrEmpty($short) -and -not [System.StringComparer]::Ordinal.Equals($short, $leaf)) {
        return $short
    }
    return ''
}

function Rename-CaseOnly([string]$directory, [string]$fromLeaf, [string]$toLeaf) {
    $parent = [System.IO.Path]::GetDirectoryName($directory)
    $hold = Join-Path $parent ('hold-' + [guid]::NewGuid().ToString('n'))
    [System.IO.Directory]::Move($directory, $hold)
    $dest = Join-Path $parent $toLeaf
    [System.IO.Directory]::Move($hold, $dest)
    return $dest
}

function New-LargeModel {
    $dirs = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt 16; $i++) {
        $l1 = 'Area{0:d2}' -f $i
        [void]$dirs.Add($l1)
        for ($j = 0; $j -lt 4; $j++) {
            [void]$dirs.Add(('{0}/Group{1:d2}' -f $l1, $j))
        }
    }
    $l2 = New-Object System.Collections.Generic.List[string]
    foreach ($dir in $dirs) {
        if ($dir.IndexOf('/') -ge 0) { [void]$l2.Add($dir) }
    }
    for ($k = 0; $k -lt 29; $k++) {
        [void]$dirs.Add(('{0}/Leaf{1:d2}' -f $l2[$k], $k))
    }
    $rels = New-Object System.Collections.Generic.List[string]
    [void]$rels.Add('RootA.txt')
    [void]$rels.Add('RootB.txt')
    [void]$rels.Add('RootC.txt')
    for ($di = 0; $di -lt $dirs.Count; $di++) {
        [void]$rels.Add(('{0}/marker.txt' -f $dirs[$di]))
        $extras = 4
        if ($di -lt 9) { $extras = 5 }
        for ($e = 0; $e -lt $extras; $e++) {
            [void]$rels.Add(('{0}/pad{1:d2}.txt' -f $dirs[$di], $e))
        }
    }
    return [pscustomobject]@{ Dirs = $dirs; Rels = $rels }
}

function New-LargeStage([string]$parent) {
    $model = New-LargeModel
    if ($model.Rels.Count -ne 557 -or $model.Dirs.Count -ne 109) {
        return $null
    }
    $derived = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($rel in $model.Rels) {
        $parts = $rel.Split('/')
        for ($i = 1; $i -lt $parts.Length; $i++) {
            [void]$derived.Add([string]::Join('/', $parts[0..($i - 1)]))
        }
    }
    if ($derived.Count -ne 109) { return $null }
    $stage = Join-Path $parent 'Questie-335'
    [void][System.IO.Directory]::CreateDirectory($stage)
    $rows = New-Object System.Collections.Generic.List[object]
    $index = 0
    foreach ($rel in $model.Rels) {
        $relPath = $rel.Replace('/', '\')
        $full = Join-Path $stage $relPath
        $dir = [System.IO.Path]::GetDirectoryName($full)
        if (-not [System.IO.Directory]::Exists($dir)) {
            [void][System.IO.Directory]::CreateDirectory($dir)
        }
        $payload = [System.Text.Encoding]::ASCII.GetBytes(('invented-' + $index.ToString('d4') + "`n"))
        [System.IO.File]::WriteAllBytes($full, $payload)
        $rows.Add([pscustomobject]@{ Rel = [string]$rel; Bytes = $payload }) | Out-Null
        $index++
    }
    $manifest = Join-Path $parent 'manifest.tsv'
    $pin = Write-InventedManifest $manifest $rows
    if ([System.StringComparer]::Ordinal.Equals($pin, $script:OwnerPin)) { return $null }
    return [pscustomobject]@{
        Stage = $stage; Manifest = $manifest; Pin = $pin
        Files = 557; Dirs = 109
        RootFile = (Join-Path $stage 'RootA.txt')
        Area = (Join-Path $stage 'Area00')
    }
}

function Invoke-Guarded([string]$name, [scriptblock]$body) {
    $work = New-WorkRoot
    try {
        & $body $work
    } catch {
        Write-Row $name 'HARNESS-FAIL' 'exception' '0' $_.Exception.GetType().FullName ''
    } finally {
        try { Remove-OwnedTree $work } catch { Write-Row ($name + '-cleanup') 'HARNESS-FAIL' 'cleanup' '0' 'type-only' '' }
    }
}

function Assert-CleanReads($run, [string]$name) {
    if ($null -eq $run) { return }
    $reads = Get-Field $run.Text 'content_reads'
    $outside = Get-Field $run.Text 'outside_reads'
    if ($reads -ne '0' -or $outside -ne '0') {
        $script:Failed = $true
        Write-Output ('content_guard: ' + $name)
    }
}

$edition = [string]$PSVersionTable.PSEdition
$version = $PSVersionTable.PSVersion
Write-Output ('ps_edition: ' + $edition)
Write-Output ('ps_version: ' + $version.ToString())
$os = [System.Environment]::OSVersion.Version
Write-Output ('host_os_version: ' + $os.Major + '.' + $os.Minor + '.' + $os.Build)
Write-Output ('host_ptr_bits: ' + ([IntPtr]::Size * 8))
if ($edition -ne 'Desktop' -or $version.Major -ne 5 -or $version.Minor -ne 1) {
    Write-Output 'ps_gate: STOP'
    exit 1
}

$tempRoot = $env:RUNNER_TEMP
if ([string]::IsNullOrEmpty($tempRoot)) { $tempRoot = [System.IO.Path]::GetTempPath() }
$script:Base = Join-Path $tempRoot ('nq335-' + [guid]::NewGuid().ToString('n'))
[void][System.IO.Directory]::CreateDirectory($script:Base)
$volumeRoot = [System.IO.Path]::GetPathRoot($script:Base)
$fmt = (New-Object System.IO.DriveInfo($volumeRoot.Substring(0, 1))).DriveFormat
Write-Output ('fixture_filesystem: ' + $fmt)
if (-not [System.StringComparer]::Ordinal.Equals([string]$fmt, 'NTFS')) {
    Write-Output 'fixture_filesystem_gate: STOP'
    exit 1
}

if (-not [System.IO.File]::Exists($script:Verifier)) {
    Write-Output 'verifier_missing: STOP'
    exit 1
}
$source = [System.IO.File]::ReadAllText($script:Verifier)
foreach ($token in @('Get-ChildItem', 'FILE_SHARE_WRITE', 'Resolve-Path', 'Get-FileHash', 'GetFullPath', 'FollowSymlink', '-Recurse')) {
    if ($source.IndexOf($token, [System.StringComparison]::Ordinal) -ge 0) {
        Write-Output ('source_ban: ' + $token)
        exit 1
    }
}
Write-Output 'source_ban: none'
Write-Output 'windows_gate: STOP'
Write-Output 'owner_stage: NOT TESTED'
Write-Output 'gameplay: NOT TESTED'

try {
    Invoke-Guarded 'small-safe' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-safe' $run 'PASS' @('none') @{
            files_expected = '2'; files_seen = '2'; dirs_expected = '1'; dirs_seen = '1'
            content_reads = '2'; diagnostic_rereads = '2'; byte_mismatches = '0'; hash_mismatches = '0'
            ADS = 'checked'; filesystem = 'NTFS'; windows_ps51_ntfs = 'synthetic-executed'
            powershell_version = 'Desktop 5.1'
        }
    }

    Invoke-Guarded 'manifest-wrong-pin' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest ('00' * 32) $tree.Stage
        Expect-Run 'manifest-wrong-pin' $run 'STOP' @('manifest-pin') @{
            content_reads = '0'; files_seen = '0'; windows_ps51_ntfs = 'NOT TESTED'
        }
    }

    Invoke-Guarded 'manifest-cr' {
        param($work)
        $tree = New-CleanSmall $work
        $raw = [System.IO.File]::ReadAllBytes($tree.Manifest)
        $text = [System.Text.Encoding]::UTF8.GetString($raw).Replace("`n", "`r`n")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        [System.IO.File]::WriteAllBytes($tree.Manifest, $bytes)
        $run = Invoke-Verifier $tree.Manifest (Get-Sha256 $bytes) $tree.Stage
        Expect-Run 'manifest-cr' $run 'STOP' @('manifest-malformed') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'manifest-dotdot' {
        param($work)
        $bad = Join-Path $work 'bad.tsv'
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("path`tbytes`tgit_blob`tsha256`n../Alpha.txt`t1`t$script:Blob`t" + ('ab' * 32) + "`n")
        [System.IO.File]::WriteAllBytes($bad, $bytes)
        $run = Invoke-Verifier $bad (Get-Sha256 $bytes) 'C:\no-such-nq\Questie-335'
        Expect-Run 'manifest-dotdot' $run 'STOP' @('manifest-malformed') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'manifest-backslash' {
        param($work)
        $bad = Join-Path $work 'bad.tsv'
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("path`tbytes`tgit_blob`tsha256`nFolder\Alpha.txt`t1`t$script:Blob`t" + ('ab' * 32) + "`n")
        [System.IO.File]::WriteAllBytes($bad, $bytes)
        $run = Invoke-Verifier $bad (Get-Sha256 $bytes) 'C:\no-such-nq\Questie-335'
        Expect-Run 'manifest-backslash' $run 'STOP' @('manifest-malformed') @{ content_reads = '0' }
    }

    Invoke-Guarded 'manifest-columns' {
        param($work)
        $bad = Join-Path $work 'bad.tsv'
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("path`tbytes`tgit_blob`tsha256`nAlpha.txt`t1`t$script:Blob`n")
        [System.IO.File]::WriteAllBytes($bad, $bytes)
        $run = Invoke-Verifier $bad (Get-Sha256 $bytes) 'C:\no-such-nq\Questie-335'
        Expect-Run 'manifest-columns' $run 'STOP' @('manifest-malformed') @{ content_reads = '0' }
    }

    Invoke-Guarded 'manifest-duplicate' {
        param($work)
        $bad = Join-Path $work 'bad.tsv'
        $line = "Alpha.txt`t1`t$script:Blob`t" + ('ab' * 32)
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("path`tbytes`tgit_blob`tsha256`n$line`n$line`n")
        [System.IO.File]::WriteAllBytes($bad, $bytes)
        $run = Invoke-Verifier $bad (Get-Sha256 $bytes) 'C:\no-such-nq\Questie-335'
        Expect-Run 'manifest-duplicate' $run 'STOP' @('manifest-malformed') @{ content_reads = '0' }
    }

    Invoke-Guarded 'manifest-nonhex' {
        param($work)
        $bad = Join-Path $work 'bad.tsv'
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("path`tbytes`tgit_blob`tsha256`nAlpha.txt`t1`t$script:Blob`tzzzz`n")
        [System.IO.File]::WriteAllBytes($bad, $bytes)
        $run = Invoke-Verifier $bad (Get-Sha256 $bytes) 'C:\no-such-nq\Questie-335'
        Expect-Run 'manifest-nonhex' $run 'STOP' @('manifest-malformed') @{ content_reads = '0' }
    }

    Invoke-Guarded 'path-relative' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest $tree.Pin 'Questie-335'
        Expect-Run 'path-relative' $run 'STOP' @('path-relative') @{ content_reads = '0'; files_seen = '0'; windows_ps51_ntfs = 'NOT TESTED' }
        $run2 = Invoke-Verifier $tree.Manifest $tree.Pin '.\Questie-335'
        Expect-Run 'path-relative-dot' $run2 'STOP' @('path-relative') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'path-drive-relative' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest $tree.Pin 'C:Questie-335'
        Expect-Run 'path-drive-relative' $run 'STOP' @('path-drive-relative') @{ content_reads = '0'; files_seen = '0' }
        $run2 = Invoke-Verifier $tree.Manifest $tree.Pin 'C:..\x'
        Expect-Run 'path-drive-relative-dotdot' $run2 'STOP' @('path-drive-relative') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'path-dotdot' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest $tree.Pin 'C:\zz\..\Questie-335'
        Expect-Run 'path-dotdot' $run 'STOP' @('path-dotdot') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'path-root' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest $tree.Pin 'C:\'
        Expect-Run 'path-root' $run 'STOP' @('path-root') @{ content_reads = '0'; files_seen = '0'; dirs_seen = '0' }
        $run2 = Invoke-Verifier $tree.Manifest $tree.Pin '\\server\share'
        Expect-Run 'path-unc-root' $run2 'STOP' @('path-root') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'path-ambiguous-shape' {
        param($work)
        $tree = New-CleanSmall $work
        $run = Invoke-Verifier $tree.Manifest $tree.Pin 'C:\temp\Questie-335.'
        Expect-Run 'path-trailing-dot' $run 'STOP' @('path-ambiguous') @{ content_reads = '0'; files_seen = '0' }
        $run2 = Invoke-Verifier $tree.Manifest $tree.Pin 'C:\temp\Questie-335:stream'
        Expect-Run 'path-stream-syntax' $run2 'STOP' @('path-ambiguous') @{ content_reads = '0'; files_seen = '0' }
        $run3 = Invoke-Verifier $tree.Manifest $tree.Pin 'C:\temp\QUESTI~1'
        Expect-Run 'path-final-not-exact' $run3 'STOP' @('path-ambiguous') @{ content_reads = '0'; files_seen = '0' }
    }

    Invoke-Guarded 'small-ancestor-junction' {
        param($work)
        $real = Join-Path $work 'real-target'
        [void][System.IO.Directory]::CreateDirectory($real)
        $tree = New-CleanSmall $real
        New-CanaryFile (Join-Path $real 'marker.txt')
        $link = Join-Path $work 'link-parent'
        $code = Invoke-Quiet $script:Cmd @('/c', 'mklink', '/J', $link, $real)
        if ($code -ne 0) { Add-NotTested 'small-ancestor-junction' 'junction-create'; return }
        $stage = Join-Path $link 'Questie-335'
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $stage
        Expect-Run 'small-ancestor-junction' $run 'STOP' @('ancestor-reparse') @{ content_reads = '0'; outside_reads = '0' }
    }

    Invoke-Guarded 'small-child-junction' {
        param($work)
        $tree = New-CleanSmall $work
        $canary = Join-Path $work 'outside-canary'
        [void][System.IO.Directory]::CreateDirectory($canary)
        New-CanaryFile (Join-Path $canary 'marker.txt')
        $jump = Join-Path $tree.Stage 'JumpOut'
        $code = Invoke-Quiet $script:Cmd @('/c', 'mklink', '/J', $jump, $canary)
        if ($code -ne 0) { Add-NotTested 'small-child-junction' 'junction-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-child-junction' $run 'STOP' @('child-reparse') @{ content_reads = '0'; outside_reads = '0' }
    }

    Invoke-Guarded 'small-dir-symlink' {
        param($work)
        $tree = New-CleanSmall $work
        $canary = Join-Path $work 'outside-canary'
        [void][System.IO.Directory]::CreateDirectory($canary)
        New-CanaryFile (Join-Path $canary 'marker.txt')
        $jump = Join-Path $tree.Stage 'JumpOut'
        $code = Invoke-Quiet $script:Cmd @('/c', 'mklink', '/D', $jump, $canary)
        if ($code -ne 0) { Add-NotTested 'small-dir-symlink' 'symlink-privilege'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-dir-symlink' $run 'STOP' @('child-reparse') @{ content_reads = '0'; outside_reads = '0' }
    }

    Invoke-Guarded 'small-file-symlink' {
        param($work)
        $tree = New-CleanSmall $work
        $canary = Join-Path $work 'outside-file.txt'
        New-CanaryFile $canary
        [System.IO.File]::Delete($tree.Alpha)
        $code = Invoke-Quiet $script:Cmd @('/c', 'mklink', $tree.Alpha, $canary)
        if ($code -ne 0) { Add-NotTested 'small-file-symlink' 'symlink-privilege'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-file-symlink' $run 'STOP' @('child-reparse') @{ content_reads = '0'; outside_reads = '0' }
    }

    Invoke-Guarded 'small-hardlink' {
        param($work)
        $tree = New-CleanSmall $work
        $outside = Join-Path $work 'outside-hard.txt'
        [System.IO.File]::WriteAllBytes($outside, $tree.AlphaBytes)
        [System.IO.File]::Delete($tree.Alpha)
        $code = Invoke-Quiet $script:Cmd @('/c', 'mklink', '/H', $tree.Alpha, $outside)
        if ($code -ne 0) { Add-NotTested 'small-hardlink' 'hardlink-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-hardlink' $run 'STOP' @('hardlink') @{ content_reads = '0'; outside_reads = '0' }
    }

    Invoke-Guarded 'small-extra-empty-dir' {
        param($work)
        $tree = New-CleanSmall $work
        [void][System.IO.Directory]::CreateDirectory((Join-Path $tree.Stage 'EmptyDir'))
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-extra-empty-dir' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-extra-file' {
        param($work)
        $tree = New-CleanSmall $work
        [System.IO.File]::WriteAllBytes((Join-Path $tree.Stage 'Extra.txt'), [byte[]](97))
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-extra-file' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-missing-file' {
        param($work)
        $tree = New-CleanSmall $work
        [System.IO.File]::Delete($tree.Alpha)
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-missing-file' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-renamed-file' {
        param($work)
        $tree = New-CleanSmall $work
        [System.IO.File]::Move($tree.Alpha, (Join-Path $tree.Stage 'Gamma.txt'))
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-renamed-file' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-case-file' {
        param($work)
        $stage = Join-Path $work 'Questie-335'
        $folder = Join-Path $stage 'Folder'
        [void][System.IO.Directory]::CreateDirectory($folder)
        $alphaBytes = [System.Text.Encoding]::ASCII.GetBytes("invented-alpha`n")
        $betaBytes = [System.Text.Encoding]::ASCII.GetBytes("invented-beta`n")
        [System.IO.File]::WriteAllBytes((Join-Path $stage 'alpha.txt'), $alphaBytes)
        [System.IO.File]::WriteAllBytes((Join-Path $folder 'Beta.txt'), $betaBytes)
        $manifest = Join-Path $work 'manifest.tsv'
        $pin = Write-InventedManifest $manifest @(
            @{ Rel = 'Alpha.txt'; Bytes = $alphaBytes },
            @{ Rel = 'Folder/Beta.txt'; Bytes = $betaBytes }
        )
        $run = Invoke-Verifier $manifest $pin $stage
        Expect-Run 'small-case-file' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-case-dir' {
        param($work)
        $stage = Join-Path $work 'Questie-335'
        $folder = Join-Path $stage 'folder'
        [void][System.IO.Directory]::CreateDirectory($folder)
        $alphaBytes = [System.Text.Encoding]::ASCII.GetBytes("invented-alpha`n")
        $betaBytes = [System.Text.Encoding]::ASCII.GetBytes("invented-beta`n")
        [System.IO.File]::WriteAllBytes((Join-Path $stage 'Alpha.txt'), $alphaBytes)
        [System.IO.File]::WriteAllBytes((Join-Path $folder 'Beta.txt'), $betaBytes)
        $manifest = Join-Path $work 'manifest.tsv'
        $pin = Write-InventedManifest $manifest @(
            @{ Rel = 'Alpha.txt'; Bytes = $alphaBytes },
            @{ Rel = 'Folder/Beta.txt'; Bytes = $betaBytes }
        )
        $run = Invoke-Verifier $manifest $pin $stage
        Expect-Run 'small-case-dir' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-miscase-root' {
        param($work)
        $tree = New-CleanSmall $work
        $mis = Rename-CaseOnly $tree.Stage 'Questie-335' 'questie-335'
        $spoof = Join-Path $work 'Questie-335'
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $spoof
        Expect-Run 'small-miscase-root' $run 'STOP' @('path-ambiguous') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-8.3-ancestor' {
        param($work)
        $long = Join-Path $work 'LongAncestorName'
        [void][System.IO.Directory]::CreateDirectory($long)
        $tree = New-CleanSmall $long
        $short = Try-DistinctShort $long 'LongAncestorName'
        if ([string]::IsNullOrEmpty($short)) { Add-NotTested 'small-8.3-ancestor' 'short-name-unavailable'; return }
        $stage = Join-Path (Join-Path $work $short) 'Questie-335'
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $stage
        Expect-Run 'small-8.3-ancestor' $run 'STOP' @('path-ambiguous') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-altered-byte' {
        param($work)
        $tree = New-CleanSmall $work
        $flipped = [byte[]]$tree.AlphaBytes.Clone()
        $flipped[$flipped.Length - 1] = [byte]([int]$flipped[$flipped.Length - 1] -bxor 1)
        [System.IO.File]::WriteAllBytes($tree.Alpha, $flipped)
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-altered-byte' $run 'STOP' @('hash-mismatch') @{ hash_mismatches = '1'; outside_reads = '0' }
    }

    Invoke-Guarded 'small-crlf' {
        param($work)
        $tree = New-CleanSmall $work
        $crlf = [System.Text.Encoding]::ASCII.GetBytes("invented-alpha`r`n")
        [System.IO.File]::WriteAllBytes($tree.Alpha, $crlf)
        # Length change: size is checked before SHA-256, so this STOP is
        # size-mismatch. A same-length body change is hash-mismatch.
        # Either token is a valid safe STOP. This fixture changes length.
        if ($crlf.Length -eq $tree.AlphaBytes.Length) {
            Write-Row 'small-crlf' 'HARNESS-FAIL' 'crlf-length' '0' 'expected-length-change' ''
            return
        }
        Write-Output 'crlf_rule: length-change-is-size-mismatch; same-length-is-hash-mismatch; both-safe-stop'
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-crlf' $run 'STOP' @('size-mismatch') @{ content_reads = '0'; byte_mismatches = '1' }
    }

    Invoke-Guarded 'small-size-mismatch' {
        param($work)
        $tree = New-CleanSmall $work
        $bigger = [System.Text.Encoding]::ASCII.GetBytes("invented-alpha`n!")
        [System.IO.File]::WriteAllBytes($tree.Alpha, $bigger)
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-size-mismatch' $run 'STOP' @('size-mismatch') @{ content_reads = '0'; byte_mismatches = '1' }
    }

    Invoke-Guarded 'small-unknown-notice' {
        param($work)
        $tree = New-CleanSmall $work
        [System.IO.File]::WriteAllBytes((Join-Path $tree.Stage 'NOTICE.txt'), [System.Text.Encoding]::ASCII.GetBytes("invented-notice`n"))
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-unknown-notice' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }

    Invoke-Guarded 'small-file-ads' {
        param($work)
        $tree = New-CleanSmall $work
        try { Add-NamedStream $tree.Alpha } catch { Add-NotTested 'small-file-ads' 'stream-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-file-ads' $run 'STOP' @('named-stream') @{
            content_reads = '0'; ADS = 'stop-extra'; ads_sample = 'ads-present'; windows_gate = 'STOP'
        }
    }

    Invoke-Guarded 'small-dir-ads' {
        param($work)
        $tree = New-CleanSmall $work
        try { Add-NamedStream $tree.Folder } catch { Add-NotTested 'small-dir-ads' 'dir-stream-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-dir-ads' $run 'STOP' @('named-stream') @{
            content_reads = '0'; ADS = 'stop-extra'; ads_sample = 'ads-present'; windows_gate = 'STOP'
        }
    }

    Invoke-Guarded 'small-root-ads' {
        param($work)
        $tree = New-CleanSmall $work
        try { Add-NamedStream $tree.Stage } catch { Add-NotTested 'small-root-ads' 'root-stream-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'small-root-ads' $run 'STOP' @('named-stream') @{
            content_reads = '0'; ADS = 'stop-extra'; ads_sample = 'ads-present'
            windows_gate = 'STOP'; walk_phase = 'root-stream'
        }
    }

    Invoke-Guarded 'small-stream-terminator' {
        param($work)
        $tree = New-CleanSmall $work
        try { Add-GuardStreams $tree.Alpha 65 } catch { Add-NotTested 'small-stream-terminator' 'stream-guard-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        if ($null -ne (Get-Field $run.Text 'ads_sample')) {
            Write-Row 'small-stream-terminator' 'HARNESS-FAIL' 'ads-label' '' 'marker-on-incomplete-chain' ''
            return
        }
        Expect-Run 'small-stream-terminator' $run 'STOP' @('interop-unproven') @{
            content_reads = '0'; windows_gate = 'STOP'; ADS = 'NOT TESTED'; ntstatus = '0xc0000004'
        }
    }

    Add-NotTested 'stream-parser-bounds' 'forged-next-offset-and-short-buffer-not-injectable'

    Invoke-Guarded 'small-share-conflict' {
        param($work)
        $tree = New-CleanSmall $work
        $held = $null
        try {
            $held = [System.IO.File]::Open($tree.Alpha, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
            $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
            Expect-Run 'small-share-conflict' $run 'STOP' @('access-denied', 'api-failed') @{ content_reads = '0' }
        } finally {
            if ($null -ne $held) { $held.Dispose() }
        }
    }

    Invoke-Guarded 'small-drift' {
        param($work)
        $tree = New-CleanSmall $work
        $writer = [System.IO.File]::Open($tree.Alpha, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
        $opened = $false
        try {
            $reader = $null
            try {
                $reader = [System.IO.File]::Open($tree.Alpha, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
                $opened = $true
            } catch {
                $opened = $false
            } finally {
                if ($null -ne $reader) { $reader.Dispose() }
            }
        } finally {
            $writer.Dispose()
        }
        if ($opened) {
            Add-NotTested 'small-drift' 'probe-opened-without-observed-byte-change'
        } else {
            Add-NotTested 'small-drift' 'share-policy-blocks-mutation'
        }
    }

    Add-NotTested 'small-sync-location' 'no-cloud-placeholder-api'
    Add-NotTested 'small-hardlink-unproven-non-ntfs' 'no-non-ntfs-volume'
    Add-NotTested 'small-trailing-dot-ondisk' 'lexical-stop-only-ondisk-form-unproven'

    Invoke-Guarded 'small-access-denied' {
        param($work)
        $tree = New-CleanSmall $work
        $denied = $false
        try {
            $acl = Get-Acl -LiteralPath $tree.Alpha
            $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, 'ReadAndExecute', 'Deny')
            $acl.AddAccessRule($rule)
            Set-Acl -LiteralPath $tree.Alpha -AclObject $acl
            $denied = $true
            $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
            Expect-Run 'small-access-denied' $run 'STOP' @('access-denied', 'api-failed') @{ content_reads = '0' }
        } catch {
            if (-not $denied) { Add-NotTested 'small-access-denied' 'acl-create' }
            else { throw }
        }
    }

    $script:SmallSafeOk = $false
    foreach ($row in $script:Rows) {
        if ($row.Name -eq 'small-safe' -and $row.Result -eq 'PASS') { $script:SmallSafeOk = $true }
    }
    if (-not $script:SmallSafeOk) {
        Add-NotTested 'large-safe' 'blocked-by-small-safe'
        Add-NotTested 'large-file-ads' 'blocked-by-small-safe'
        Add-NotTested 'large-dir-ads' 'blocked-by-small-safe'
        Add-NotTested 'large-root-ads' 'blocked-by-small-safe'
        Add-NotTested 'large-miscase-root' 'blocked-by-small-safe'
        Add-NotTested 'large-8.3-ancestor' 'blocked-by-small-safe'
        Add-NotTested 'large-share-conflict' 'blocked-by-small-safe'
        Add-NotTested 'large-missing-file' 'blocked-by-small-safe'
    } else {
    Write-Output 'large_fixture: start'
    Invoke-Guarded 'large-safe' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-safe' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        Write-Output ('large_files: ' + $tree.Files)
        Write-Output ('large_dirs: ' + $tree.Dirs)
        Write-Output ('large_pin: ' + $tree.Pin)
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'large-safe' $run 'PASS' @('none') @{
            files_expected = '557'; files_seen = '557'; dirs_expected = '109'; dirs_seen = '109'
            content_reads = '557'; diagnostic_rereads = '557'; byte_mismatches = '0'; hash_mismatches = '0'
            ADS = 'checked'; filesystem = 'NTFS'; windows_ps51_ntfs = 'synthetic-executed'
        }
    }

    Invoke-Guarded 'large-file-ads' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-file-ads' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        try { Add-NamedStream $tree.RootFile } catch { Add-NotTested 'large-file-ads' 'stream-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'large-file-ads' $run 'STOP' @('named-stream') @{
            content_reads = '0'; ADS = 'stop-extra'; ads_sample = 'ads-present'; windows_gate = 'STOP'
        }
    }

    Invoke-Guarded 'large-dir-ads' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-dir-ads' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        try { Add-NamedStream $tree.Area } catch { Add-NotTested 'large-dir-ads' 'dir-stream-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'large-dir-ads' $run 'STOP' @('named-stream') @{
            content_reads = '0'; ADS = 'stop-extra'; ads_sample = 'ads-present'; windows_gate = 'STOP'
        }
    }

    Invoke-Guarded 'large-root-ads' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-root-ads' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        try { Add-NamedStream $tree.Stage } catch { Add-NotTested 'large-root-ads' 'root-stream-create'; return }
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'large-root-ads' $run 'STOP' @('named-stream') @{
            content_reads = '0'; ADS = 'stop-extra'; ads_sample = 'ads-present'
            windows_gate = 'STOP'; walk_phase = 'root-stream'
        }
    }

    Invoke-Guarded 'large-miscase-root' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-miscase-root' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        $null = Rename-CaseOnly $tree.Stage 'Questie-335' 'questie-335'
        $spoof = Join-Path $work 'Questie-335'
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $spoof
        Expect-Run 'large-miscase-root' $run 'STOP' @('path-ambiguous') @{ content_reads = '0' }
    }

    Invoke-Guarded 'large-8.3-ancestor' {
        param($work)
        $long = Join-Path $work 'LongAncestorName'
        [void][System.IO.Directory]::CreateDirectory($long)
        $tree = New-LargeStage $long
        if ($null -eq $tree) { Write-Row 'large-8.3-ancestor' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        $short = Try-DistinctShort $long 'LongAncestorName'
        if ([string]::IsNullOrEmpty($short)) { Add-NotTested 'large-8.3-ancestor' 'short-name-unavailable'; return }
        $stage = Join-Path (Join-Path $work $short) 'Questie-335'
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $stage
        Expect-Run 'large-8.3-ancestor' $run 'STOP' @('path-ambiguous') @{ content_reads = '0' }
    }

    Invoke-Guarded 'large-share-conflict' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-share-conflict' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        $held = $null
        try {
            $held = [System.IO.File]::Open($tree.RootFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
            $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
            Expect-Run 'large-share-conflict' $run 'STOP' @('access-denied', 'api-failed') @{ content_reads = '0' }
        } finally {
            if ($null -ne $held) { $held.Dispose() }
        }
    }

    Invoke-Guarded 'large-missing-file' {
        param($work)
        $tree = New-LargeStage $work
        if ($null -eq $tree) { Write-Row 'large-missing-file' 'HARNESS-FAIL' 'shape' '0' 'count' ''; return }
        [System.IO.File]::Delete($tree.RootFile)
        $run = Invoke-Verifier $tree.Manifest $tree.Pin $tree.Stage
        Expect-Run 'large-missing-file' $run 'STOP' @('set-mismatch') @{ content_reads = '0' }
    }
    }
} finally {
    try { Remove-OwnedTree $script:Base } catch { Write-Output 'base_cleanup: api-failed' }
}

$pass = 0
$stop = 0
$untested = 0
$bad = 0
foreach ($row in $script:Rows) {
    if ($row.Result -eq 'PASS') { $pass++ }
    elseif ($row.Result -eq 'STOP') { $stop++ }
    elseif ($row.Result -eq 'NOT TESTED') { $untested++ }
    else { $bad++ }
}
Write-Output ('summary_pass: ' + $pass)
Write-Output ('summary_stop: ' + $stop)
Write-Output ('summary_not_tested: ' + $untested)
Write-Output ('summary_harness_fail: ' + $bad)
foreach ($required in @('small-drift', 'small-sync-location', 'small-hardlink-unproven-non-ntfs', 'small-trailing-dot-ondisk')) {
    $foundGap = $false
    foreach ($row in $script:Rows) {
        if ($row.Name -eq $required -and $row.Result -eq 'NOT TESTED') { $foundGap = $true }
    }
    if (-not $foundGap) {
        $script:Failed = $true
        Write-Output ('coverage_gap_missing: ' + $required)
    }
}
$outsideMax = -1
$telemetryFail = $false
if ($script:VerifierOutside.Count -eq 0) { $telemetryFail = $true }
foreach ($rawOutside in $script:VerifierOutside) {
    if ($rawOutside -match '^[0-9]+$') {
        $parsedOutside = [int]$rawOutside
        if ($parsedOutside -gt $outsideMax) { $outsideMax = $parsedOutside }
        if ($parsedOutside -ne 0) { $telemetryFail = $true }
    } else {
        $telemetryFail = $true
    }
}
if ($telemetryFail) { $script:Failed = $true }
Write-Output ('outside_reads_max: ' + $outsideMax)
Write-Output ('outside_reads_rows: ' + $script:VerifierOutside.Count)
Write-Output 'outside_reads_source: verifier-reported-telemetry'
Write-Output 'outside_reads_limit: not-independent-proof'
if ($telemetryFail) { Write-Output 'outside_reads_telemetry: FAIL' }
else { Write-Output 'outside_reads_telemetry: checked' }
Write-Output 'windows_gate: STOP'
Write-Output 'owner_stage: NOT TESTED'
if ($script:Failed -or $bad -gt 0) {
    Write-Output 'HARNESS: FAIL'
    exit 1
}
Write-Output 'HARNESS: PASS'
exit 0
