# Invented managed byte buffers only, not a native NTFS proof.
# Does not read user files or create any fixtures, packages, or reports.
#Requires -Version 5.1
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$verifier = Join-Path $PSScriptRoot 'Invoke-Nq335NtfsStageVerifier.ps1'
$text = [System.IO.File]::ReadAllText($verifier)
$marker = '$script:Csharp = @' + [char]39
$mark = $text.IndexOf($marker, [StringComparison]::Ordinal)
if ($mark -lt 0) { throw 'PARSER-HARNESS: missing C# start marker' }
$begin = $text.IndexOf([char]10, $mark) + 1
if ($begin -le 0) { throw 'PARSER-HARNESS: unterminated source marker' }
$finish = $text.IndexOf(([string][char]10 + "'@"), $begin, [StringComparison]::Ordinal)
if ($finish -lt $begin) { throw 'PARSER-HARNESS: missing C# end marker' }
$definition = $text.Substring($begin, $finish - $begin)
Add-Type -TypeDefinition $definition -Language CSharp

$script:Passed = 0
function New-Buffer([int]$size = 4096) {
    if ($size -lt 0) { throw 'invalid invented capacity' }
    return ,(New-Object byte[] $size)
}
function Put-Record([byte[]]$bytes, [int]$offset, [string]$name, [int]$next, [int]$forcedLength = -1) {
    if ($offset -lt 0 -or ($offset + 8) -gt $bytes.Length) { throw 'fixture header outside buffer' }
    $utf16 = [Text.Encoding]::Unicode.GetBytes($name)
    $nameLength = $(if ($forcedLength -ge 0) { $forcedLength } else { $utf16.Length })
    [Array]::Copy([BitConverter]::GetBytes([int]$next), 0, $bytes, $offset, 4)
    [Array]::Copy([BitConverter]::GetBytes([int]$nameLength), 0, $bytes, $offset + 4, 4)
    $limit = [Math]::Min($utf16.Length, [Math]::Max(0, $bytes.Length - $offset - 24))
    if ($limit -gt 0) { [Array]::Copy($utf16, 0, $bytes, $offset + 24, $limit) }
}
function Test-Case([string]$name, [bool]$accept, [int]$expectedShape, [scriptblock]$make, [bool]$isDirectory = $false, [int]$expectedCount = -1, [int]$capacity = 4096) {
    $bytes = New-Buffer $capacity
    & $make $bytes
    $result = [Nq335NtfsNative]::ParseStreamBuffer($bytes)
    $ok = ($result.Status -eq 0)
    if ($ok -ne $accept) {
        throw ('PARSER-HARNESS: ' + $name + ' expected-parse=' + $accept + ' actual=' + $ok + ' status=' + $result.Status)
    }
    if ($ok) {
        $names = [string[]]$result.Names
        if ($expectedCount -ge 0 -and $names.Length -ne $expectedCount) {
            throw ('PARSER-HARNESS: ' + $name + ' count=' + $names.Length)
        }
        $shape = [Nq335NtfsNative]::ClassifyStreamSet($names, $isDirectory)
        if ($shape -ne $expectedShape) {
            throw ('PARSER-HARNESS: ' + $name + ' shape=' + $shape + ' wanted=' + $expectedShape)
        }
    }
    $script:Passed++
    Write-Output ('PARSER_CASE: ' + $name + ' PASS')
}

Test-Case 'default-file' $true 0 { param($b) Put-Record $b 0 '::$DATA' 0 } $false 1
Test-Case 'named-stream' $true 1 { param($b) Put-Record $b 0 ':extra:$DATA' 0 } $false 1
Test-Case 'default-plus-named' $true 1 {
    param($b) Put-Record $b 0 '::$DATA' 40; Put-Record $b 40 ':alt:$DATA' 0
} $false 2
Test-Case 'duplicate-default' $false -1 {
    param($b) Put-Record $b 0 '::$DATA' 40; Put-Record $b 40 '::$DATA' 0
}
Test-Case 'duplicate-case-variant' $false -1 {
    param($b) Put-Record $b 0 '::$DATA' 40; Put-Record $b 40 '::$data' 0
}
Test-Case 'duplicate-named-case-variant' $false -1 {
    param($b) Put-Record $b 0 ':extra:$DATA' 48; Put-Record $b 48 ':EXTRA:$DATA' 0
}
Test-Case 'overlap-next-24' $false -1 { param($b) Put-Record $b 0 '::$DATA' 24 }
Test-Case 'overlap-next-32' $false -1 { param($b) Put-Record $b 0 '::$DATA' 32 }
Test-Case 'next-exact-record-length' $true 1 {
    param($b) Put-Record $b 0 '::$DATA' 38; Put-Record $b 38 '::$DATA2' 0
} $false 2
Test-Case 'next-short-23' $false -1 { param($b) Put-Record $b 0 '::$DATA' 23 }
Test-Case 'next-negative' $false -1 { param($b) Put-Record $b 0 '::$DATA' -40 }
Test-Case 'next-beyond-capacity' $false -1 { param($b) Put-Record $b 0 '::$DATA' 4096 }
Test-Case 'odd-name-length' $false -1 { param($b) Put-Record $b 0 '::$DATA' 0 13 }
Test-Case 'name-length-over-1024' $false -1 { param($b) Put-Record $b 0 '::$DATA' 0 1026 }
Test-Case 'missing-leading-colon' $false -1 { param($b) Put-Record $b 0 'ABC' 0 }
Test-Case 'empty-name' $false -1 { param($b) Put-Record $b 0 '' 0 }
Test-Case 'name-spans-end' $false -1 { param($b) Put-Record $b 0 '::$DATA' 0 } $false -1 32
Test-Case 'unterminated-64-records' $false -1 {
    param($b)
    for ($i = 0; $i -lt 64; $i++) { Put-Record $b ($i * 40) (':s' + $i + ':$DATA') 40 }
}
Test-Case 'directory-success-default-unproven' $true 2 {
    param($b) Put-Record $b 0 '::$DATA' 0
} $true 1
Test-Case 'directory-success-named-refused' $true 1 {
    param($b) Put-Record $b 0 ':other:$DATA' 0
} $true 1
Test-Case 'short-buffer' $false -1 { param($b) } $false -1 20

$emptyFile = [Nq335NtfsNative]::ClassifyStreamSet([string[]]@(), $false)
$emptyDirectory = [Nq335NtfsNative]::ClassifyStreamSet([string[]]@(), $true)
if ($emptyFile -ne 2 -or $emptyDirectory -ne 2) { throw 'PARSER-HARNESS: empty result accepted' }
$script:Passed++
Write-Output 'PARSER_CASE: empty-stream-set-refused PASS'

$nullResult = [Nq335NtfsNative]::ParseStreamBuffer([byte[]]$null)
if ($nullResult.Status -eq 0) { throw 'PARSER-HARNESS: null buffer accepted' }
$script:Passed++
Write-Output 'PARSER_CASE: null-buffer-refused PASS'
Write-Output ('parser_model_cases_passed: ' + $script:Passed)
Write-Output 'parser_model_scope: managed-invented-buffers-only'
Write-Output 'windows_gate: STOP'
