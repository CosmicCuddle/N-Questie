# Read-only, fail-closed Questie-335 stage verifier for Windows PowerShell 5.1.
# Design: docs/NQ-335-WINDOWS-PS51-NTFS-VERIFIER-DESIGN.md (draft PR 151).
# This file does not create, delete, rename, or write. Fixture setup is a
# different program. A matching invented fixture still prints windows_gate: STOP.
# Owner-stage, gameplay, and peer review stay out of scope.
# Implementation extension (this draft only; frozen PR 151 is not edited):
# a proven extra named stream on a retained handle STOPs with reason
# named-stream and ADS: stop-extra. Design 151 says "Extra stream: STOP"
# and lists no reason token for that case. An incomplete stream chain,
# with no bounds-validated NextEntryOffset of 0, stays interop-unproven.
#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$RequiredPin,
    [Parameter(Mandatory = $true)][string]$StagePath
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$script:Utf8 = New-Object System.Text.UTF8Encoding $false
$OutputEncoding = $script:Utf8
try { [Console]::OutputEncoding = $script:Utf8 } catch { }

$script:Finished = $false
$script:Result = 'STOP'
$script:Reason = 'api-failed'
$script:FilesExpected = 0
$script:FilesSeen = 0
$script:DirsExpected = 0
$script:DirsSeen = 0
$script:ByteMismatches = 0
$script:HashMismatches = 0
$script:ContentReads = 0
$script:OutsideReads = 0
$script:PsCell = 'NOT TESTED'
$script:NtfsCell = 'NOT TESTED'
$script:AdsCell = 'NOT TESTED'
$script:AdsDirEof = 'no'
$script:Rereads = 0
$script:NtStatus = 'none'
$script:Filesystem = 'unread'
$script:ExceptionType = ''
$script:ExceptionLine = '0'
$script:ExceptionId = 'none'
$script:WalkPhase = 'none'
$script:AdsSample = ''
$script:VolumeRootMode = ''
$script:VolumeRootFirst = ''
$script:NoRecall = 'not-requested'
$script:NameQueryTerminal = 'none'
$script:NameProof = 'none'
$script:NameQueryMiss = 0
$script:AncestorIndex = -1
$script:AncestorCount = 0
$script:Ancestor0Length = -1
$script:NormalizedStatus = 'none'
$script:Handles = New-Object 'System.Collections.Generic.List[int64]'
$script:Retained = New-Object 'System.Collections.Generic.HashSet[int64]'
$script:NativeReady = $false

$script:OwnerPin = '73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52'
$script:AccessRead = [uint32]0x00120089
$script:ShareRead = [uint32]0x00000001
$script:FileOpen = [uint32]1
# FILE_OPEN_NO_RECALL (0x00400000) made NtCreateFile return
# STATUS_INVALID_PARAMETER (0xC000000D) on an ordinary NTFS directory
# in the first windows-2025 run. It is not requested. Cloud non-hydration
# stays NOT TESTED. Reparse flags are unchanged.
# Ancestors: directory + synchronous. No open-reparse flag.
$script:OptDir = [uint32]0x00000021
# Children: those bits plus the open-reparse flag (0x00200000).
$script:OptChildDir = [uint32]0x00200021
$script:OptFile = [uint32]0x00200060
$script:AttrReparse = [uint32]0x400
$script:AttrDirectory = [uint32]0x10
$script:AttrOffline = [uint32]0x1000
$script:AttrRecallOpen = [uint32]0x40000
$script:AttrRecallData = [uint32]0x400000
$script:StatusSuccess = [int]0
$script:StatusNoMoreFiles = [int]0x80000006
$script:StatusNoSuchFile = [int]0xC000000F
$script:StatusObjectNameNotFound = [int]0xC0000034
$script:StatusObjectPathNotFound = [int]0xC000003A
$script:StatusAccessDenied = [int]0xC0000022
$script:StatusSharingViolation = [int]0xC0000043
$script:StatusReparsePoint = [int]0xC000050B
$script:StatusNotADirectory = [int]0xC0000103
$script:StatusFileIsDirectory = [int]0xC00000BA
$script:StatusInvalidParameter = [int]0xC000000D
$script:StatusPending = [int]0x00000103

$script:Csharp = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class Nq335NtfsNative {
    public const int FileIdBothDirectoryInformation = 37;
    public const int FileFsAttributeInformation = 5;
    public const int FileNormalizedNameInformation = 48;
    public const int FileStreamInfo = 7;
    public const uint ObjDontReparse = 0x00001000;
    public const int StatusSuccess = 0;
    public const int StatusNoMoreFiles = unchecked((int)0x80000006);
    public const int StatusBufferOverflow = unchecked((int)0x80000005);
    public const int StatusNoSuchFile = unchecked((int)0xC000000F);
    public const int StatusObjectNameNotFound = unchecked((int)0xC0000034);
    public const int StatusInfoLengthMismatch = unchecked((int)0xC0000004);

    [StructLayout(LayoutKind.Sequential)]
    public struct UNICODE_STRING {
        public ushort Length;
        public ushort MaximumLength;
        public IntPtr Buffer;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct OBJECT_ATTRIBUTES {
        public uint Length;
        public IntPtr RootDirectory;
        public IntPtr ObjectName;
        public uint Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct IO_STATUS_BLOCK {
        public IntPtr Status;
        public IntPtr Information;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    public struct BY_HANDLE_FILE_INFORMATION {
        public uint FileAttributes;
        public long CreationTime;
        public long LastAccessTime;
        public long LastWriteTime;
        public uint VolumeSerialNumber;
        public uint FileSizeHigh;
        public uint FileSizeLow;
        public uint NumberOfLinks;
        public uint FileIndexHigh;
        public uint FileIndexLow;
    }

    public sealed class DirEnt {
        public string FileName;
        public string ShortName;
        public uint Attributes;
        public uint ReparseTag;
    }

    public sealed class DirQuery {
        public int Status;
        public int Terminal;
        public DirEnt[] Entries;
    }

    public sealed class OpenResult {
        public int Status;
        public long Handle;
    }

    public sealed class VolumeResult {
        public int Status;
        public string Name;
    }

    public sealed class LeafResult {
        public int Status;
        public string Leaf;
    }

    public sealed class LinkResult {
        public int Status;
        public uint Attributes;
        public uint NumberOfLinks;
        public long Size;
    }

    public sealed class StreamResult {
        public int Status;
        public string[] Names;
    }

    public sealed class ReadResult {
        public int Status;
        public int Read;
    }

    [DllImport("ntdll.dll")]
    static extern int NtCreateFile(
        out IntPtr FileHandle,
        uint DesiredAccess,
        ref OBJECT_ATTRIBUTES ObjectAttributes,
        out IO_STATUS_BLOCK IoStatusBlock,
        IntPtr AllocationSize,
        uint FileAttributes,
        uint ShareAccess,
        uint CreateDisposition,
        uint CreateOptions,
        IntPtr EaBuffer,
        uint EaLength);

    [DllImport("ntdll.dll")]
    static extern int NtQueryDirectoryFile(
        IntPtr FileHandle,
        IntPtr Event,
        IntPtr ApcRoutine,
        IntPtr ApcContext,
        out IO_STATUS_BLOCK IoStatusBlock,
        IntPtr FileInformation,
        uint Length,
        int FileInformationClass,
        [MarshalAs(UnmanagedType.U1)] bool ReturnSingleEntry,
        IntPtr FileName,
        [MarshalAs(UnmanagedType.U1)] bool RestartScan);

    [DllImport("ntdll.dll")]
    static extern int NtQueryVolumeInformationFile(
        IntPtr FileHandle,
        out IO_STATUS_BLOCK IoStatusBlock,
        IntPtr FsInformation,
        uint Length,
        int FsInformationClass);

    [DllImport("ntdll.dll")]
    static extern int NtQueryInformationFile(
        IntPtr FileHandle,
        out IO_STATUS_BLOCK IoStatusBlock,
        IntPtr FileInformation,
        uint Length,
        int FileInformationClass);

    [DllImport("ntdll.dll")]
    static extern int NtReadFile(
        IntPtr FileHandle,
        IntPtr Event,
        IntPtr ApcRoutine,
        IntPtr ApcContext,
        out IO_STATUS_BLOCK IoStatusBlock,
        byte[] Buffer,
        uint Length,
        ref long ByteOffset,
        IntPtr Key);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetFileInformationByHandle(
        IntPtr hFile,
        out BY_HANDLE_FILE_INFORMATION lpFileInformation);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetFileInformationByHandleEx(
        IntPtr hFile,
        int FileInformationClass,
        IntPtr lpFileInformation,
        uint dwBufferSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr hObject);

    public static int UnicodeSize() { return Marshal.SizeOf(typeof(UNICODE_STRING)); }
    public static int ObjectAttributesSize() { return Marshal.SizeOf(typeof(OBJECT_ATTRIBUTES)); }
    public static int IoStatusSize() { return Marshal.SizeOf(typeof(IO_STATUS_BLOCK)); }
    public static int ByHandleSize() { return Marshal.SizeOf(typeof(BY_HANDLE_FILE_INFORMATION)); }

    static IntPtr AllocUnicode(string value) {
        byte[] encoded = Encoding.Unicode.GetBytes(value);
        IntPtr buffer = Marshal.AllocHGlobal(encoded.Length + 2);
        Marshal.Copy(encoded, 0, buffer, encoded.Length);
        Marshal.WriteInt16(buffer, encoded.Length, 0);
        UNICODE_STRING uni = new UNICODE_STRING();
        uni.Length = (ushort)encoded.Length;
        uni.MaximumLength = (ushort)(encoded.Length + 2);
        uni.Buffer = buffer;
        IntPtr structured = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(UNICODE_STRING)));
        Marshal.StructureToPtr(uni, structured, false);
        return structured;
    }

    static void FreeUnicode(IntPtr structured) {
        if (structured == IntPtr.Zero) return;
        UNICODE_STRING uni = (UNICODE_STRING)Marshal.PtrToStructure(structured, typeof(UNICODE_STRING));
        if (uni.Buffer != IntPtr.Zero) Marshal.FreeHGlobal(uni.Buffer);
        Marshal.FreeHGlobal(structured);
    }

    static OpenResult Create(IntPtr root, string name, uint access, uint share, uint options, uint attributes) {
        OpenResult result = new OpenResult();
        result.Handle = 0;
        IntPtr uni = IntPtr.Zero;
        try {
            uni = AllocUnicode(name);
            OBJECT_ATTRIBUTES oa = new OBJECT_ATTRIBUTES();
            oa.Length = (uint)Marshal.SizeOf(typeof(OBJECT_ATTRIBUTES));
            oa.RootDirectory = root;
            oa.ObjectName = uni;
            oa.Attributes = attributes;
            oa.SecurityDescriptor = IntPtr.Zero;
            oa.SecurityQualityOfService = IntPtr.Zero;
            IntPtr handle;
            IO_STATUS_BLOCK ios;
            int status = NtCreateFile(
                out handle, access, ref oa, out ios, IntPtr.Zero, 0, share,
                1, options, IntPtr.Zero, 0);
            result.Status = status;
            if (status == StatusSuccess && handle != IntPtr.Zero) {
                result.Handle = handle.ToInt64();
            }
            return result;
        } catch {
            result.Status = unchecked((int)0xC0000001);
            result.Handle = 0;
            return result;
        } finally {
            FreeUnicode(uni);
        }
    }

    public static OpenResult OpenNtPath(string ntPath, uint access, uint share, uint options, uint attributes) {
        return Create(IntPtr.Zero, ntPath, access, share, options, attributes);
    }

    public static OpenResult OpenRelative(long root, string name, uint access, uint share, uint options) {
        OpenResult bad = new OpenResult();
        bad.Status = unchecked((int)0xC000000D);
        bad.Handle = 0;
        if (root == 0 || name == null || name.Length == 0 || name.IndexOf('\\') >= 0 || name.IndexOf('/') >= 0) {
            return bad;
        }
        return Create(new IntPtr(root), name, access, share, options, ObjDontReparse);
    }

    static DirEnt ParseBoth(IntPtr buffer, int available) {
        if (available < 104) return null;
        uint nameLength = (uint)Marshal.ReadInt32(buffer, 60);
        uint attributes = (uint)Marshal.ReadInt32(buffer, 56);
        uint eaOrTag = (uint)Marshal.ReadInt32(buffer, 64);
        int shortLength = Marshal.ReadByte(buffer, 68);
        if (nameLength > 1024 || (nameLength % 2) != 0 || shortLength < 0 || shortLength > 24 || (shortLength % 2) != 0) {
            return null;
        }
        if (104 + nameLength > available) return null;
        DirEnt ent = new DirEnt();
        ent.Attributes = attributes;
        ent.ReparseTag = ((attributes & 0x400) != 0) ? eaOrTag : 0;
        byte[] nameBytes = new byte[nameLength];
        Marshal.Copy(new IntPtr(buffer.ToInt64() + 104), nameBytes, 0, (int)nameLength);
        ent.FileName = Encoding.Unicode.GetString(nameBytes);
        if (shortLength > 0) {
            byte[] shortBytes = new byte[shortLength];
            Marshal.Copy(new IntPtr(buffer.ToInt64() + 70), shortBytes, 0, shortLength);
            ent.ShortName = Encoding.Unicode.GetString(shortBytes);
        } else {
            ent.ShortName = "";
        }
        return ent;
    }

    static DirQuery Query(long handle, string exact) {
        DirQuery query = new DirQuery();
        List<DirEnt> found = new List<DirEnt>();
        query.Status = StatusSuccess;
        query.Terminal = StatusSuccess;
        IntPtr buffer = IntPtr.Zero;
        IntPtr exactUni = IntPtr.Zero;
        try {
            buffer = Marshal.AllocHGlobal(8192);
            if (exact != null) exactUni = AllocUnicode(exact);
            bool restart = true;
            int guard = 0;
            while (guard < 10001) {
                guard++;
                IO_STATUS_BLOCK ios;
                int status = NtQueryDirectoryFile(
                    new IntPtr(handle), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, out ios,
                    buffer, 8192, FileIdBothDirectoryInformation, true, exactUni, restart);
                restart = false;
                if (status == StatusNoMoreFiles || status == StatusNoSuchFile || status == StatusObjectNameNotFound) {
                    query.Terminal = status;
                    break;
                }
                if (status != StatusSuccess) {
                    query.Status = status;
                    query.Terminal = status;
                    break;
                }
                DirEnt ent = ParseBoth(buffer, 8192);
                if (ent == null || ent.FileName == null) {
                    query.Status = StatusInfoLengthMismatch;
                    break;
                }
                found.Add(ent);
                if (exact != null) break;
            }
            if (guard > 10000 && query.Status == StatusSuccess) {
                query.Status = StatusInfoLengthMismatch;
            }
        } catch {
            query.Status = unchecked((int)0xC0000001);
        } finally {
            if (buffer != IntPtr.Zero) Marshal.FreeHGlobal(buffer);
            FreeUnicode(exactUni);
        }
        query.Entries = found.ToArray();
        return query;
    }

    public static DirQuery QueryOne(long handle, string name) { return Query(handle, name); }
    public static DirQuery QueryAll(long handle) { return Query(handle, null); }

    public static VolumeResult VolumeName(long handle) {
        VolumeResult result = new VolumeResult();
        result.Name = "";
        IntPtr buffer = Marshal.AllocHGlobal(1024);
        try {
            IO_STATUS_BLOCK ios;
            int status = NtQueryVolumeInformationFile(
                new IntPtr(handle), out ios, buffer, 1024, FileFsAttributeInformation);
            result.Status = status;
            if (status != StatusSuccess) return result;
            int nameLength = Marshal.ReadInt32(buffer, 8);
            if (nameLength <= 0 || nameLength > 512 || (nameLength % 2) != 0 || 12 + nameLength > 1024) {
                result.Status = StatusInfoLengthMismatch;
                return result;
            }
            byte[] bytes = new byte[nameLength];
            Marshal.Copy(new IntPtr(buffer.ToInt64() + 12), bytes, 0, nameLength);
            result.Name = Encoding.Unicode.GetString(bytes);
            return result;
        } catch {
            result.Status = unchecked((int)0xC0000001);
            return result;
        } finally {
            Marshal.FreeHGlobal(buffer);
        }
    }

    public static LeafResult NormalizedLeaf(long handle) {
        LeafResult result = new LeafResult();
        result.Leaf = "";
        IntPtr buffer = Marshal.AllocHGlobal(4096);
        try {
            IO_STATUS_BLOCK ios;
            int status = NtQueryInformationFile(
                new IntPtr(handle), out ios, buffer, 4096, FileNormalizedNameInformation);
            result.Status = status;
            if (status != StatusSuccess) return result;
            int nameLength = Marshal.ReadInt32(buffer, 0);
            if (nameLength <= 0 || nameLength > 4000 || (nameLength % 2) != 0) {
                result.Status = StatusInfoLengthMismatch;
                return result;
            }
            byte[] bytes = new byte[nameLength];
            Marshal.Copy(new IntPtr(buffer.ToInt64() + 4), bytes, 0, nameLength);
            string full = Encoding.Unicode.GetString(bytes);
            if (full.Length > 0 && full[full.Length - 1] == '\0') {
                full = full.Substring(0, full.Length - 1);
            }
            if (full.Length > 1 && full[full.Length - 1] == '\\') {
                full = full.Substring(0, full.Length - 1);
            }
            int cut = full.LastIndexOf('\\');
            string leaf = cut >= 0 ? full.Substring(cut + 1) : full;
            result.Leaf = leaf;
            return result;
        } catch {
            result.Status = unchecked((int)0xC0000001);
            return result;
        } finally {
            Marshal.FreeHGlobal(buffer);
        }
    }

    public static LinkResult LinkInfo(long handle) {
        LinkResult result = new LinkResult();
        try {
            BY_HANDLE_FILE_INFORMATION info;
            bool ok = GetFileInformationByHandle(new IntPtr(handle), out info);
            if (!ok) {
                result.Status = unchecked((int)0xC0000001);
                return result;
            }
            result.Status = StatusSuccess;
            result.Attributes = info.FileAttributes;
            result.NumberOfLinks = info.NumberOfLinks;
            result.Size = ((long)info.FileSizeHigh << 32) | info.FileSizeLow;
            return result;
        } catch {
            result.Status = unchecked((int)0xC0000001);
            return result;
        }
    }

    // Parse invented buffers independently of Win32; a native-success result
    // must have a complete, bounded, non-overlapping terminal record chain.
    // The caller must separately reject any disallowed stream shape.
    public static StreamResult ParseStreamBuffer(byte[] buffer) {
        StreamResult result = new StreamResult();
        result.Names = new string[0];
        if (buffer == null || buffer.Length < 24 || buffer.Length > 65536) {
            result.Status = StatusInfoLengthMismatch;
            return result;
        }
        int capacity = buffer.Length;
        List<string> names = new List<string>();
        HashSet<string> seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        int offset = 0;
        int guard = 0;
        bool terminated = false;
        while (guard < 64 && offset + 24 <= capacity) {
            guard++;
            int next = BitConverter.ToInt32(buffer, offset);
            int nameLength = BitConverter.ToInt32(buffer, offset + 4);
            if (nameLength < 0 || nameLength > 1024 ||
                (nameLength % 2) != 0 || offset + 24 + nameLength > capacity) {
                result.Status = StatusInfoLengthMismatch;
                return result;
            }
            string name = Encoding.Unicode.GetString(buffer, offset + 24, nameLength);
            if (name.Length == 0 || name[0] != ':' || !seen.Add(name)) {
                result.Status = StatusInfoLengthMismatch;
                return result;
            }
            names.Add(name);
            if (next == 0) {
                terminated = true;
                break;
            }
            // An offset within the current name body would read fabricated
            // bytes as the next record. Do not assume any alignment guarantee.
            if (next < 24 + nameLength) {
                result.Status = StatusInfoLengthMismatch;
                return result;
            }
            long advanced = (long)offset + (long)next;
            if (advanced < 0 || advanced + 24 > capacity) {
                result.Status = StatusInfoLengthMismatch;
                return result;
            }
            offset = (int)advanced;
        }
        if (!terminated) {
            result.Status = StatusInfoLengthMismatch;
            return result;
        }
        result.Status = StatusSuccess;
        result.Names = names.ToArray();
        return result;
    }

    // Pure, fail-closed semantic check. Directory stream success is not a
    // proven clean directory: only native ERROR_HANDLE_EOF is accepted.
    // Return 0 = accepted one default file stream, 1 = named stream,
    // 2 = insufficient/ambiguous evidence.
    public static int ClassifyStreamSet(string[] names, bool isDirectory) {
        if (names == null || names.Length == 0) return 2;
        foreach (string name in names) {
            if (!StringComparer.Ordinal.Equals(name, "::$DATA")) return 1;
        }
        if (isDirectory || names.Length != 1) return 2;
        return 0;
    }

    public static StreamResult Streams(long handle) {
        StreamResult result = new StreamResult();
        result.Names = new string[0];
        int capacity = 4096;
        int attempt = 0;
        while (attempt < 3) {
            attempt++;
            IntPtr buffer = Marshal.AllocHGlobal(capacity);
            try {
                // The API does not report the number of initialized bytes.
                // Zero the allocation before the native call, then require
                // a complete validated record chain; never infer a snapshot.
                byte[] raw = new byte[capacity];
                Marshal.Copy(raw, 0, buffer, capacity);
                bool ok = GetFileInformationByHandleEx(
                    new IntPtr(handle), FileStreamInfo, buffer, (uint)capacity);
                if (!ok) {
                    int win = Marshal.GetLastWin32Error();
                    if (win == 234) {
                        capacity = capacity * 4;
                        continue;
                    }
                    result.Status = win == 0 ? unchecked((int)0xC0000001) : (int)(0xC0000000 | (uint)win);
                    return result;
                }
                Marshal.Copy(buffer, raw, 0, capacity);
                return ParseStreamBuffer(raw);
            } catch {
                result.Status = unchecked((int)0xC0000001);
                return result;
            } finally {
                Marshal.FreeHGlobal(buffer);
            }
        }
        result.Status = StatusBufferOverflow;
        return result;
    }

    public static ReadResult ReadAt(long handle, long offset, byte[] buffer, int length) {
        ReadResult result = new ReadResult();
        try {
            long cursor = offset;
            IO_STATUS_BLOCK ios;
            int status = NtReadFile(
                new IntPtr(handle), IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, out ios,
                buffer, (uint)length, ref cursor, IntPtr.Zero);
            result.Status = status;
            if (status == StatusSuccess) {
                long info = ios.Information.ToInt64();
                if (info < 0 || info > length) {
                    result.Status = StatusInfoLengthMismatch;
                    result.Read = 0;
                } else {
                    result.Read = (int)info;
                }
            }
            return result;
        } catch {
            result.Status = unchecked((int)0xC0000001);
            result.Read = 0;
            return result;
        }
    }

    public static bool CloseHandle64(long handle) {
        if (handle == 0) return false;
        try { return CloseHandle(new IntPtr(handle)); }
        catch { return false; }
    }
}
'@

function Complete-Run {
    if ($script:Finished) { return }
    $script:Finished = $true
    $closeOk = $true
    if ($script:NativeReady) {
        foreach ($handle in @($script:Handles)) {
            if ($handle -ne 0) {
                $closed = [Nq335NtfsNative]::CloseHandle64($handle)
                if (-not $closed) { $closeOk = $false }
            }
        }
    }
    $script:Handles.Clear()
    if ($script:Result -eq 'PASS' -and -not $closeOk) {
        $script:Result = 'STOP'
        $script:Reason = 'api-failed'
    }
    Write-Output ('RESULT: ' + $script:Result)
    Write-Output ('reason: ' + $script:Reason)
    Write-Output ('files_expected: ' + $script:FilesExpected)
    Write-Output ('files_seen: ' + $script:FilesSeen)
    Write-Output ('dirs_expected: ' + $script:DirsExpected)
    Write-Output ('dirs_seen: ' + $script:DirsSeen)
    Write-Output ('byte_mismatches: ' + $script:ByteMismatches)
    Write-Output ('hash_mismatches: ' + $script:HashMismatches)
    Write-Output ('content_reads: ' + $script:ContentReads)
    Write-Output ('outside_reads: ' + $script:OutsideReads)
    Write-Output 'linux_synthetic: separate'
    Write-Output ('powershell_version: ' + $script:PsCell)
    Write-Output ('windows_ps51_ntfs: ' + $script:NtfsCell)
    Write-Output 'peer_review: pending'
    Write-Output 'gameplay: NOT TESTED'
    Write-Output 'windows_gate: STOP'
    Write-Output ('ADS: ' + $script:AdsCell)
    Write-Output ('ads_dir_eof: ' + $script:AdsDirEof)
    if ($script:AdsSample.Length -gt 0) {
        Write-Output ('ads_sample: ' + $script:AdsSample)
    }
    Write-Output ('diagnostic_rereads: ' + $script:Rereads)
    Write-Output ('filesystem: ' + $script:Filesystem)
    Write-Output ('ntstatus: ' + $script:NtStatus)
    Write-Output ('no_recall: ' + $script:NoRecall)
    if ($script:VolumeRootMode.Length -eq 0) { $script:VolumeRootMode = 'none' }
    if ($script:VolumeRootFirst.Length -eq 0) { $script:VolumeRootFirst = 'none' }
    Write-Output ('volume_root_mode: ' + $script:VolumeRootMode)
    Write-Output ('volume_root_first: ' + $script:VolumeRootFirst)
    Write-Output ('name_query_terminal: ' + $script:NameQueryTerminal)
    Write-Output ('name_proof: ' + $script:NameProof)
    Write-Output ('name_query_miss: ' + $script:NameQueryMiss)
    Write-Output ('ancestor_index: ' + $script:AncestorIndex)
    Write-Output ('ancestor_count: ' + $script:AncestorCount)
    Write-Output ('ancestor0_length: ' + $script:Ancestor0Length)
    Write-Output ('normalized_status: ' + $script:NormalizedStatus)
    if ($script:ExceptionType.Length -gt 0) {
        Write-Output ('exception_type: ' + $script:ExceptionType)
        Write-Output ('exception_line: ' + $script:ExceptionLine)
        Write-Output ('exception_id: ' + $script:ExceptionId)
    }
    Write-Output ('walk_phase: ' + $script:WalkPhase)
    if ($script:Result -eq 'PASS') { exit 0 }
    exit 1
}

function Stop-Run([string]$reason, [int]$status) {
    $script:Result = 'STOP'
    $script:Reason = $reason
    if ($status -ne 0) {
        $script:NtStatus = ('0x{0:x8}' -f ($status -band 0xFFFFFFFF))
    }
    Complete-Run
}

function Test-OrdinalSet {
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    [void]$set.Add('Modules')
    if ($set.Contains('modules')) { return $false }
    if (-not $set.Contains('Modules')) { return $false }
    $left = 'Questie-335'
    $right = 'questie-335'
    if ([System.StringComparer]::Ordinal.Equals($left, $right)) { return $false }
    if (-not [System.StringComparer]::Ordinal.Equals($left, $left)) { return $false }
    return $true
}

function Test-StageLexically([string]$stage) {
    if ([string]::IsNullOrEmpty($stage)) { return 'path-relative' }
    $chars = $stage.ToCharArray()
    foreach ($ch in $chars) {
        $code = [int]$ch
        if ($code -lt 32 -or $code -eq 127) { return 'path-ambiguous' }
    }
    if ($stage.IndexOf('/') -ge 0) { return 'path-ambiguous' }
    if ($stage.StartsWith('\\')) { return 'path-root' }
    if ($stage.StartsWith('\\?\')) { return 'path-ambiguous' }
    $drive = $false
    if ($stage.Length -ge 2 -and [char]::IsLetter($stage[0]) -and $stage[1] -eq ':') {
        $drive = $true
        if ($stage.Length -lt 3 -or $stage[2] -ne '\') { return 'path-drive-relative' }
    }
    if (-not $drive) {
        $relParts = $stage.Split('\')
        foreach ($part in $relParts) {
            if ($part -eq '..') { return 'path-dotdot' }
        }
        return 'path-relative'
    }
    $rest = $stage.Substring(3)
    if ($rest.Length -eq 0) { return 'path-root' }
    $parts = $rest.Split('\')
    foreach ($part in $parts) {
        if ($part.Length -eq 0 -or $part -eq '.' -or $part.Length -gt 255) { return 'path-ambiguous' }
        if ($part -eq '..') { return 'path-dotdot' }
        $last = $part[$part.Length - 1]
        if ($last -eq '.' -or $last -eq ' ') { return 'path-ambiguous' }
        if ($part.IndexOf(':') -ge 0) { return 'path-ambiguous' }
        if ($part.IndexOfAny([char[]]@('*', '?', '"', '<', '>', '|')) -ge 0) { return 'path-ambiguous' }
    }
    $final = $parts[$parts.Length - 1]
    if (-not [System.StringComparer]::Ordinal.Equals($final, 'Questie-335')) { return 'path-ambiguous' }
    return ''
}

function Get-StageComponents([string]$stage) {
    $rest = $stage.Substring(3)
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($part in $rest.Split('\')) { [void]$list.Add([string]$part) }
    return ,$list
}

function Read-Manifest {
    $pinOk = $RequiredPin.Length -eq 64 -and $RequiredPin -cmatch '^[0-9a-f]{64}$'
    if (-not $pinOk) { Stop-Run 'manifest-pin' 0 }
    $raw = $null
    try {
        $raw = [System.IO.File]::ReadAllBytes($ManifestPath)
    } catch {
        Stop-Run 'api-failed' 0
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $sha.ComputeHash($raw)
    } finally {
        $sha.Dispose()
    }
    $builder = New-Object System.Text.StringBuilder
    foreach ($byte in $digest) { [void]$builder.Append($byte.ToString('x2')) }
    $actual = $builder.ToString()
    if (-not [System.StringComparer]::Ordinal.Equals($actual, $RequiredPin)) { Stop-Run 'manifest-pin' 0 }
    foreach ($byte in $raw) {
        if ($byte -eq 13 -or $byte -eq 0) { Stop-Run 'manifest-malformed' 0 }
        if ($byte -gt 127) { Stop-Run 'manifest-malformed' 0 }
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false, $true
    $text = $null
    try { $text = $utf8.GetString($raw) } catch { Stop-Run 'manifest-malformed' 0 }
    $lines = $text.Split([char]10)
    if ($lines.Length -gt 0 -and $lines[$lines.Length - 1].Length -eq 0) {
        $trimmed = New-Object 'System.Collections.Generic.List[string]'
        for ($i = 0; $i -lt ($lines.Length - 1); $i++) { [void]$trimmed.Add($lines[$i]) }
        $lines = $trimmed.ToArray()
    }
    if ($lines.Length -lt 2) { Stop-Run 'manifest-malformed' 0 }
    if (-not [System.StringComparer]::Ordinal.Equals($lines[0], "path`tbytes`tgit_blob`tsha256")) {
        Stop-Run 'manifest-malformed' 0
    }
    $files = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $dirs = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $meta = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
    for ($row = 1; $row -lt $lines.Length; $row++) {
        $line = $lines[$row]
        if ($line.Length -eq 0) { Stop-Run 'manifest-malformed' 0 }
        $cols = $line.Split("`t")
        if ($cols.Length -ne 4) { Stop-Run 'manifest-malformed' 0 }
        $path = $cols[0]
        $sizeText = $cols[1]
        $blob = $cols[2]
        $hash = $cols[3]
        if ($path.Length -eq 0 -or $path.IndexOf('\') -ge 0 -or $path.IndexOf(':') -ge 0) { Stop-Run 'manifest-malformed' 0 }
        if ($path[0] -eq '/' -or $path[$path.Length - 1] -eq '/') { Stop-Run 'manifest-malformed' 0 }
        if ($sizeText -notmatch '^[0-9]+$') { Stop-Run 'manifest-malformed' 0 }
        if ($blob -notmatch '^[0-9a-f]{40}$') { Stop-Run 'manifest-malformed' 0 }
        if ($hash -notmatch '^[0-9a-f]{64}$') { Stop-Run 'manifest-malformed' 0 }
        $parts = $path.Split('/')
        for ($p = 0; $p -lt $parts.Length; $p++) {
            $part = $parts[$p]
            if ($part.Length -eq 0 -or $part -eq '.' -or $part -eq '..') { Stop-Run 'manifest-malformed' 0 }
            $tail = $part[$part.Length - 1]
            if ($tail -eq '.' -or $tail -eq ' ') { Stop-Run 'manifest-malformed' 0 }
            if ($part.IndexOfAny([char[]]@('*', '?', '"', '<', '>', '|')) -ge 0) { Stop-Run 'manifest-malformed' 0 }
        }
        if (-not $files.Add($path)) { Stop-Run 'manifest-malformed' 0 }
        for ($p = 1; $p -lt $parts.Length; $p++) {
            $prefix = [string]::Join('/', $parts[0..($p - 1)])
            [void]$dirs.Add($prefix)
        }
        $size = [int64]::Parse($sizeText)
        $meta.Add($path, @{ Size = $size; Hash = $hash })
    }
    if ([System.StringComparer]::Ordinal.Equals($RequiredPin, $script:OwnerPin)) {
        if ($files.Count -ne 557 -or $dirs.Count -ne 109) { Stop-Run 'manifest-malformed' 0 }
    }
    $script:FilesExpected = $files.Count
    $script:DirsExpected = $dirs.Count
    return @{ Files = $files; Dirs = $dirs; Meta = $meta }
}

function Import-Native {
    Add-Type -TypeDefinition $script:Csharp -Language CSharp
    $script:NativeReady = $true
    $ptr = [IntPtr]::Size
    $uni = [Nq335NtfsNative]::UnicodeSize()
    $oa = [Nq335NtfsNative]::ObjectAttributesSize()
    $ios = [Nq335NtfsNative]::IoStatusSize()
    $bh = [Nq335NtfsNative]::ByHandleSize()
    $expectUni = $(if ($ptr -eq 8) { 16 } else { 8 })
    $expectOa = $(if ($ptr -eq 8) { 48 } else { 24 })
    $expectIos = $ptr * 2
    if ($uni -ne $expectUni -or $oa -ne $expectOa -or $ios -ne $expectIos -or $bh -ne 52) {
        Stop-Run 'interop-unproven' 0
    }
}

function Remember-Handle([int64]$handle) {
    if ($handle -eq 0) { return }
    [void]$script:Handles.Add($handle)
}

function Map-OpenFailure([int]$status, [string]$reparseReason) {
    $script:NtStatus = ('0x{0:x8}' -f ($status -band 0xFFFFFFFF))
    if ($status -eq $script:StatusReparsePoint) { Stop-Run $reparseReason $status }
    if ($status -eq $script:StatusAccessDenied -or $status -eq $script:StatusSharingViolation) {
        Stop-Run 'access-denied' $status
    }
    if ($status -eq $script:StatusInvalidParameter -or $status -eq $script:StatusPending) {
        Stop-Run 'interop-unproven' $status
    }
    if ($status -eq $script:StatusNoSuchFile -or $status -eq $script:StatusObjectNameNotFound -or $status -eq $script:StatusObjectPathNotFound) {
        Stop-Run 'api-failed' $status
    }
    Stop-Run 'api-failed' $status
}

function Test-Cloud([uint32]$attributes, [uint32]$tag) {
    if (($attributes -band $script:AttrOffline) -ne 0) { return $true }
    if (($attributes -band $script:AttrRecallOpen) -ne 0) { return $true }
    if (($attributes -band $script:AttrRecallData) -ne 0) { return $true }
    if (($tag -band 0xFFFF0FFF) -eq 0x9000001A) { return $true }
    return $false
}

function Note-NameProof([string]$mode) {
    if ($script:NameProof -eq 'none' -or $script:NameProof -eq $mode) {
        $script:NameProof = $mode
    } else {
        $script:NameProof = 'mixed'
    }
}

function Find-ActualEntry([int64]$parent, [string]$requested, [bool]$allowSiblingScan) {
    $query = [Nq335NtfsNative]::QueryOne($parent, $requested)
    $script:NameQueryTerminal = ('0x{0:x8}' -f ([int]$query.Terminal -band 0xFFFFFFFF))
    if ($query.Status -ne $script:StatusSuccess -and $query.Status -ne $script:StatusNoMoreFiles -and $query.Status -ne $script:StatusNoSuchFile -and $query.Status -ne $script:StatusObjectNameNotFound) {
        Stop-Run 'interop-unproven' $query.Status
    }
    $entries = @($query.Entries)
    if ($entries.Count -gt 1) { Stop-Run 'interop-unproven' 0 }
    if ($entries.Count -eq 1 -and $null -ne $entries[0]) {
        $name = [string]$entries[0].FileName
        $short = [string]$entries[0].ShortName
        if (-not [System.StringComparer]::Ordinal.Equals($name, $requested)) {
            Stop-Run 'path-ambiguous' 0
        }
        if ($short.Length -gt 0 -and [System.StringComparer]::Ordinal.Equals($short, $requested) -and -not [System.StringComparer]::Ordinal.Equals($short, $name)) {
            Stop-Run 'path-ambiguous' 0
        }
        return @{
            Found = $true
            Name = $name
            Attributes = [uint32]$entries[0].Attributes
            ReparseTag = [uint32]$entries[0].ReparseTag
        }
    }
    $script:NameQueryMiss++
    if ($allowSiblingScan) {
        $all = [Nq335NtfsNative]::QueryAll($parent)
        if ($all.Status -ne $script:StatusSuccess) { Stop-Run 'interop-unproven' $all.Status }
        $sawDot = $false
        $sawDotDot = $false
        $ignore = $null
        foreach ($ent in @($all.Entries)) {
            if ($null -eq $ent) { continue }
            $candidate = [string]$ent.FileName
            if ([System.StringComparer]::Ordinal.Equals($candidate, '.')) { $sawDot = $true; continue }
            if ([System.StringComparer]::Ordinal.Equals($candidate, '..')) { $sawDotDot = $true; continue }
            if ([System.StringComparer]::Ordinal.Equals($candidate, $requested)) {
                return @{
                    Found = $true
                    Name = $candidate
                    Attributes = [uint32]$ent.Attributes
                    ReparseTag = [uint32]$ent.ReparseTag
                }
            }
            $shortName = [string]$ent.ShortName
            $caseFold = [System.StringComparer]::OrdinalIgnoreCase.Equals($candidate, $requested)
            $shortHit = $shortName.Length -gt 0 -and [System.StringComparer]::Ordinal.Equals($shortName, $requested)
            if ($caseFold -or $shortHit) {
                if ($null -ne $ignore) { Stop-Run 'path-ambiguous' 0 }
                $ignore = $ent
            }
        }
        if (-not $sawDot -or -not $sawDotDot) { Stop-Run 'interop-unproven' 0 }
        if ($null -ne $ignore) { Stop-Run 'path-ambiguous' 0 }
    }
    return @{ Found = $false; Name = ''; Attributes = [uint32]0; ReparseTag = [uint32]0 }
}

function Assert-NormalizedLeaf([int64]$handle, [string]$requested, [bool]$required) {
    $leaf = [Nq335NtfsNative]::NormalizedLeaf($handle)
    $script:NormalizedStatus = ('0x{0:x8}' -f ([int]$leaf.Status -band 0xFFFFFFFF))
    if ($leaf.Status -ne $script:StatusSuccess) {
        if ($required) { Stop-Run 'interop-unproven' $leaf.Status }
        return
    }
    $value = [string]$leaf.Leaf
    if ($value.IndexOf([char]0) -ge 0) { Stop-Run 'interop-unproven' 0 }
    if ($value.Length -eq 0 -or $value.Length -gt 255 -or $value.IndexOf('\') -ge 0 -or $value.IndexOf('/') -ge 0) {
        Stop-Run 'interop-unproven' 0
    }
    if (-not [System.StringComparer]::Ordinal.Equals($value, $requested)) {
        Stop-Run 'path-ambiguous' 0
    }
}

function Open-Component([int64]$parent, [string]$name, [uint32]$options) {
    $opened = [Nq335NtfsNative]::OpenRelative($parent, $name, $script:AccessRead, $script:ShareRead, $options)
    if ($opened.Status -ne $script:StatusSuccess -or $opened.Handle -eq 0) {
        return $opened
    }
    Remember-Handle ([int64]$opened.Handle)
    return $opened
}

function Test-StreamSet([int64]$handle, [bool]$isDir) {
    $streams = [Nq335NtfsNative]::Streams($handle)
    # Streams() reports Win32 ERROR_HANDLE_EOF (38) as 0xC0000026 when
    # GetFileInformationByHandleEx finds no stream records. A directory
    # with no named streams is documented to fail that way. A file is
    # expected to return ::$DATA, so EOF on a file stays unproven.
    # Signed form of 0xC0000026. Casting that bit pattern to uint32 throws
    # in Windows PowerShell, so compare the signed status directly.
    if ($isDir -and ($streams.Status -eq ([int]-1073741786))) {
        if ($script:AdsCell -ne 'stop-extra') { $script:AdsCell = 'checked' }
        $script:AdsDirEof = 'yes'
        return
    }
    if ($streams.Status -ne $script:StatusSuccess) {
        $script:AdsCell = 'NOT TESTED'
        Stop-Run 'interop-unproven' $streams.Status
    }
    $names = @($streams.Names)
    $shape = [Nq335NtfsNative]::ClassifyStreamSet([string[]]$names, $isDir)
    if ($shape -eq 1) {
        $script:AdsCell = 'stop-extra'
        # Fixed presence marker: never copy on-disk stream names into logs.
        $script:AdsSample = 'ads-present'
        Stop-Run 'named-stream' 0
    }
    if ($shape -ne 0) {
        $script:AdsCell = 'NOT TESTED'
        Stop-Run 'interop-unproven' 0
    }
    $script:AdsCell = 'checked'
}

function Walk-Stage([int64]$stageHandle, $manifest) {
    $seenFiles = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $seenDirs = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $fileHandles = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
    $pending = New-Object System.Collections.Queue
    $pending.Enqueue(@{ Handle = $stageHandle; Rel = '' })
    while ($pending.Count -gt 0) {
        $script:WalkPhase = 'query'
        $current = $pending.Dequeue()
        $listed = [Nq335NtfsNative]::QueryAll([int64]$current.Handle)
        if ($listed.Status -ne $script:StatusSuccess) { Stop-Run 'interop-unproven' $listed.Status }
        $sawDot = $false
        $sawDotDot = $false
        foreach ($ent in @($listed.Entries)) {
            $script:WalkPhase = 'name'
            $name = [string]$ent.FileName
            if ([System.StringComparer]::Ordinal.Equals($name, '.')) { $sawDot = $true; continue }
            if ([System.StringComparer]::Ordinal.Equals($name, '..')) { $sawDotDot = $true; continue }
            if ($name.IndexOf('\') -ge 0 -or $name.IndexOf('/') -ge 0 -or $name.IndexOf(':') -ge 0 -or $name.IndexOf([char]0) -ge 0) {
                Stop-Run 'path-ambiguous' 0
            }
            $script:WalkPhase = 'attrs'
            $rel = $(if ([string]$current.Rel -eq '') { $name } else { ([string]$current.Rel) + '/' + $name })
            $attrs = [uint32]$ent.Attributes
            $tag = [uint32]$ent.ReparseTag
            $isDir = ($attrs -band $script:AttrDirectory) -ne 0
            $isReparse = ($attrs -band $script:AttrReparse) -ne 0
            if ($isReparse -or (Test-Cloud $attrs $tag)) {
                $probeOpt = $(if ($isDir) { $script:OptChildDir } else { $script:OptFile })
                $probe = Open-Component ([int64]$current.Handle) $name $probeOpt
                if ($probe.Handle -ne 0) {
                    $info = [Nq335NtfsNative]::LinkInfo([int64]$probe.Handle)
                    if ($info.Status -eq $script:StatusSuccess -and (Test-Cloud ([uint32]$info.Attributes) 0)) {
                        Stop-Run 'sync-location' 0
                    }
                }
                if (Test-Cloud $attrs $tag) { Stop-Run 'sync-location' 0 }
                if ($probe.Status -eq $script:StatusReparsePoint -or $isReparse) { Stop-Run 'child-reparse' $probe.Status }
                Stop-Run 'child-reparse' $probe.Status
            }
            $script:WalkPhase = 'open'
            $opt = $(if ($isDir) { $script:OptChildDir } else { $script:OptFile })
            $opened = Open-Component ([int64]$current.Handle) $name $opt
            if ($opened.Status -ne $script:StatusSuccess) { Map-OpenFailure $opened.Status 'child-reparse' }
            $handle = [int64]$opened.Handle
            $info2 = [Nq335NtfsNative]::LinkInfo($handle)
            if ($info2.Status -ne $script:StatusSuccess) {
                if ($isDir) { Stop-Run 'api-failed' $info2.Status }
                Stop-Run 'hardlink-unproven' $info2.Status
            }
            if ((([uint32]$info2.Attributes) -band $script:AttrReparse) -ne 0) { Stop-Run 'child-reparse' 0 }
            if (Test-Cloud ([uint32]$info2.Attributes) 0) { Stop-Run 'sync-location' 0 }
            $script:WalkPhase = 'stream'
            Test-StreamSet $handle $isDir
            $script:WalkPhase = 'store'
            if ($isDir) {
                if (-not $seenDirs.Add($rel)) { Stop-Run 'path-ambiguous' 0 }
                $pending.Enqueue(@{ Handle = $handle; Rel = $rel })
            } else {
                if (-not $seenFiles.Add($rel)) { Stop-Run 'path-ambiguous' 0 }
                if ([uint32]$info2.NumberOfLinks -ne 1) { Stop-Run 'hardlink' 0 }
                $fileHandles.Add($rel, @{ Handle = $handle; Size = [int64]$info2.Size })
            }
        }
        $script:WalkPhase = 'dots'
        if (-not $sawDot -or -not $sawDotDot) { Stop-Run 'interop-unproven' 0 }
    }
    $script:WalkPhase = 'compare'
    $script:FilesSeen = $seenFiles.Count
    $script:DirsSeen = $seenDirs.Count
    if ($seenFiles.Count -ne $manifest.Files.Count -or $seenDirs.Count -ne $manifest.Dirs.Count) {
        Stop-Run 'set-mismatch' 0
    }
    foreach ($expected in $manifest.Files) {
        if (-not $seenFiles.Contains($expected)) { Stop-Run 'set-mismatch' 0 }
    }
    foreach ($expectedDir in $manifest.Dirs) {
        if (-not $seenDirs.Contains($expectedDir)) { Stop-Run 'set-mismatch' 0 }
    }
    foreach ($seen in $seenFiles) {
        if (-not $manifest.Files.Contains($seen)) { Stop-Run 'set-mismatch' 0 }
    }
    foreach ($seenDir in $seenDirs) {
        if (-not $manifest.Dirs.Contains($seenDir)) { Stop-Run 'set-mismatch' 0 }
    }
    # Byte length is checked before SHA-256. A longer or shorter body,
    # including a CRLF rewrite that changes length, STOPs size-mismatch
    # and is not hashed. A same-length body change STOPs hash-mismatch.
    # Either token is a valid safe STOP. Bodies are not normalized.
    foreach ($expected in $manifest.Files) {
        $item = $fileHandles[$expected]
        $want = $manifest.Meta[$expected]
        if ([int64]$item.Size -ne [int64]$want.Size) {
            $script:ByteMismatches++
            Stop-Run 'size-mismatch' 0
        }
    }
    foreach ($expected in $manifest.Files) {
        $item = $fileHandles[$expected]
        $handle = [int64]$item.Handle
        if (-not $script:Retained.Contains($handle)) { [void]$script:Retained.Add($handle) }
        $first = Read-HandleHash $handle ([int64]$item.Size)
        $script:ContentReads++
        if (-not [System.StringComparer]::Ordinal.Equals($first, [string]$manifest.Meta[$expected].Hash)) {
            $script:HashMismatches++
            Stop-Run 'hash-mismatch' 0
        }
        $second = Read-HandleHash $handle ([int64]$item.Size)
        $script:Rereads++
        if (-not [System.StringComparer]::Ordinal.Equals($first, $second)) { Stop-Run 'drift' 0 }
    }
}

function Read-HandleHash([int64]$handle, [int64]$size) {
    if (-not $script:Retained.Contains($handle)) {
        $script:OutsideReads++
        Stop-Run 'api-failed' 0
    }
    if ($size -lt 0 -or $size -gt 67108864) { Stop-Run 'api-failed' 0 }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $remaining = $size
        $offset = [int64]0
        while ($remaining -gt 0) {
            $chunk = [int][Math]::Min(65536, $remaining)
            $buffer = New-Object byte[] $chunk
            $read = [Nq335NtfsNative]::ReadAt($handle, $offset, $buffer, $chunk)
            if ($read.Status -ne $script:StatusSuccess -or $read.Read -ne $chunk) { Stop-Run 'api-failed' $read.Status }
            [void]$sha.TransformBlock($buffer, 0, $chunk, $buffer, 0)
            $offset += $chunk
            $remaining -= $chunk
        }
        $empty = New-Object byte[] 0
        [void]$sha.TransformFinalBlock($empty, 0, 0)
        $builder = New-Object System.Text.StringBuilder
        foreach ($byte in $sha.Hash) { [void]$builder.Append($byte.ToString('x2')) }
        return $builder.ToString()
    } finally {
        $sha.Dispose()
    }
}

function Invoke-Main {
    $edition = [string]$PSVersionTable.PSEdition
    $version = $PSVersionTable.PSVersion
    if ($edition -eq 'Desktop' -and $version.Major -eq 5 -and $version.Minor -eq 1) {
        $script:PsCell = 'Desktop 5.1'
    } else {
        Stop-Run 'interop-unproven' 0
    }
    if (-not (Test-OrdinalSet)) { Stop-Run 'interop-unproven' 0 }
    $manifest = Read-Manifest
    $lexical = Test-StageLexically $StagePath
    if ($lexical.Length -gt 0) { Stop-Run $lexical 0 }
    Import-Native
    $drive = $StagePath.Substring(0, 1)
    $ntRoot = '\??\' + $drive + ':\'
    $rootOpen = [Nq335NtfsNative]::OpenNtPath($ntRoot, $script:AccessRead, $script:ShareRead, $script:OptDir, [uint32][Nq335NtfsNative]::ObjDontReparse)
    if ($rootOpen.Status -eq $script:StatusSuccess -and $rootOpen.Handle -ne 0) {
        $script:VolumeRootMode = 'dont-reparse'
    } else {
        $script:VolumeRootFirst = ('0x{0:x8}' -f ($rootOpen.Status -band 0xFFFFFFFF))
        if ($rootOpen.Status -eq $script:StatusInvalidParameter -or $rootOpen.Status -eq $script:StatusReparsePoint) {
            # The DOS-device link is not an NTFS reparse point. A failed flag
            # on this one open does not relax later component opens.
            $rootOpen = [Nq335NtfsNative]::OpenNtPath($ntRoot, $script:AccessRead, $script:ShareRead, $script:OptDir, [uint32]0)
            $script:VolumeRootMode = 'dos-device-root'
        }
        if ($rootOpen.Status -eq $script:StatusInvalidParameter) {
            $rootOpen = [Nq335NtfsNative]::OpenNtPath($ntRoot, $script:AccessRead, $script:ShareRead, [uint32]1, [uint32]0)
            $script:VolumeRootMode = 'directory-file-only'
        }
        if ($rootOpen.Status -ne $script:StatusSuccess -or $rootOpen.Handle -eq 0) {
            Map-OpenFailure $rootOpen.Status 'ancestor-reparse'
        }
    }
    $parent = [int64]$rootOpen.Handle
    Remember-Handle $parent
    $components = $StagePath.Substring(3).Split('\')
    $script:AncestorCount = $components.Length
    $script:Ancestor0Length = $components[0].Length
    for ($i = 0; $i -lt $components.Length; $i++) {
        $requested = [string]$components[$i]
        $script:AncestorIndex = $i
        $allowScan = $i -gt 0
        $actual = Find-ActualEntry $parent $requested $allowScan
        $requiredLeaf = $true
        if ($actual.Found) {
            if (($actual.Attributes -band $script:AttrReparse) -ne 0 -or (Test-Cloud $actual.Attributes $actual.ReparseTag)) {
                $probe = Open-Component $parent ([string]$actual.Name) $script:OptChildDir
                if ($probe.Handle -ne 0) {
                    # Probe only. Do not list or read through a reparse ancestor.
                }
                if (Test-Cloud $actual.Attributes $actual.ReparseTag) { Stop-Run 'sync-location' 0 }
                Stop-Run 'ancestor-reparse' $probe.Status
            }
            Note-NameProof 'directory-entry'
            $openName = [string]$actual.Name
            $requiredLeaf = $false
        } else {
            # An empty exact query is not proof the component is absent.
            # The volume root is not listed. Open this one component and
            # require the retained-handle normalized leaf.
            Note-NameProof 'normalized-leaf'
            $openName = $requested
        }
        $opened = Open-Component $parent $openName $script:OptDir
        if ($opened.Status -ne $script:StatusSuccess) { Map-OpenFailure $opened.Status 'ancestor-reparse' }
        $handle = [int64]$opened.Handle
        $info = [Nq335NtfsNative]::LinkInfo($handle)
        if ($info.Status -ne $script:StatusSuccess) { Stop-Run 'api-failed' $info.Status }
        if ((([uint32]$info.Attributes) -band $script:AttrDirectory) -eq 0) { Stop-Run 'api-failed' 0 }
        if ((([uint32]$info.Attributes) -band $script:AttrReparse) -ne 0) { Stop-Run 'ancestor-reparse' 0 }
        if (Test-Cloud ([uint32]$info.Attributes) 0) { Stop-Run 'sync-location' 0 }
        Assert-NormalizedLeaf $handle $requested $requiredLeaf
        $parent = $handle
    }
    $script:AncestorIndex = $components.Length
    $volume = [Nq335NtfsNative]::VolumeName($parent)
    if ($volume.Status -ne $script:StatusSuccess) { Stop-Run 'interop-unproven' $volume.Status }
    if (-not [System.StringComparer]::Ordinal.Equals([string]$volume.Name, 'NTFS')) {
        $script:Filesystem = 'other'
        Stop-Run 'filesystem-not-ntfs' 0
    }
    $script:Filesystem = 'NTFS'
    $script:NtfsCell = 'synthetic-executed'
    # Stage-root directory handle retained above. Named streams on
    # Questie-335 itself are checked before Walk-Stage and before any
    # file byte read. No path-based stream fallback.
    $script:WalkPhase = 'root-stream'
    Test-StreamSet $parent $true
    Walk-Stage $parent $manifest
    $script:Result = 'PASS'
    $script:Reason = 'none'
    Complete-Run
}

try {
    Invoke-Main
} catch {
    if (-not $script:Finished) {
        $script:ExceptionType = $_.Exception.GetType().FullName
        $script:ExceptionLine = '0'
        $script:ExceptionId = 'none'
        try { $script:ExceptionLine = [string]$_.InvocationInfo.ScriptLineNumber } catch { }
        try {
            $id = [string]$_.FullyQualifiedErrorId
            $id = [regex]::Replace($id, '[A-Za-z]:\\[^\s]*', 'path')
            if ($id.Length -gt 80) { $id = $id.Substring(0, 80) }
            $script:ExceptionId = $id
        } catch { }
        $script:Result = 'STOP'
        $script:Reason = 'api-failed'
        Complete-Run
    }
}
