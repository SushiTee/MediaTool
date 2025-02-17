<#
    .NOTES
        MICROSOFT LIMITED PUBLIC LICENSE version 1.1
        This license governs use of code marked as “sample” or “example” available on this web site without a license agreement, as provided under the section above titled “NOTICE SPECIFIC TO SOFTWARE AVAILABLE ON THIS WEB SITE.” If you use such code (the “software”), you accept this license. If you do not accept the license, do not use the software.
        1. Definitions
        The terms “reproduce,” “reproduction,” “derivative works,” and “distribution” have the same meaning here as under U.S. copyright law.
        A “contribution” is the original software, or any additions or changes to the software.
        A “contributor” is any person that distributes its contribution under this license.
        “Licensed patents” are a contributor’s patent claims that read directly on its contribution.
        2. Grant of Rights
        (A) Copyright Grant - Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free copyright license to reproduce its contribution, prepare derivative works of its contribution, and distribute its contribution or any derivative works that you create.
        (B) Patent Grant - Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free license under its licensed patents to make, have made, use, sell, offer for sale, import, and/or otherwise dispose of its contribution in the software or derivative works of the contribution in the software.
        3. Conditions and Limitations
        (A) No Trademark License- This license does not grant you rights to use any contributors’ name, logo, or trademarks.
        (B) If you bring a patent claim against any contributor over patents that you claim are infringed by the software, your patent license from such contributor to the software ends automatically.
        (C) If you distribute any portion of the software, you must retain all copyright, patent, trademark, and attribution notices that are present in the software.
        (D) If you distribute any portion of the software in source code form, you may do so only under this license by including a complete copy of this license with your distribution. If you distribute any portion of the software in compiled or object code form, you may only do so under a license that complies with this license.
        (E) The software is licensed “as-is.” You bear the risk of using it. The contributors give no express warranties, guarantees or conditions. You may have additional consumer rights under your local laws which this license cannot change. To the extent permitted under your local laws, the contributors exclude the implied warranties of merchantability, fitness for a particular purpose and non-infringement.
        (F) Platform Limitation - The licenses granted in sections 2(A) and 2(B) extend only to the software or derivative works that you create that run directly on a Microsoft Windows operating system product, Microsoft run-time technology (such as the .NET Framework or Silverlight), or Microsoft application platform (such as Microsoft Office or Microsoft Dynamics).
#>

$code  = @"
/*
From: http://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f
*/
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Win32.SafeHandles;
namespace WIMInterop {
    /// <summary>
    /// P/Invoke methods and associated enums, flags, and structs.
    /// </summary>
    public class
    NativeMethods {
        #region Delegates and Callbacks
        #region WIMGAPI
        ///<summary>
        ///User-defined function used with the RegisterMessageCallback or UnregisterMessageCallback function.
        ///</summary>
        ///<param name="MessageId">Specifies the message being sent.</param>
        ///<param name="wParam">Specifies additional message information. The contents of this parameter depend on the value of the
        ///MessageId parameter.</param>
        ///<param name="lParam">Specifies additional message information. The contents of this parameter depend on the value of the
        ///MessageId parameter.</param>
        ///<param name="UserData">Specifies the user-defined value passed to RegisterCallback.</param>
        ///<returns>
        ///To indicate success and to enable other subscribers to process the message return WIM_MSG_SUCCESS.
        ///To prevent other subscribers from receiving the message, return WIM_MSG_DONE.
        ///To cancel an image apply or capture, return WIM_MSG_ABORT_IMAGE when handling the WIM_MSG_PROCESS message.
        ///</returns>
        public delegate uint
        WimMessageCallback(
            uint   MessageId,
            IntPtr wParam,
            IntPtr lParam,
            IntPtr UserData
        );
        public static void
        RegisterMessageCallback(
            WimFileHandle hWim,
            WimMessageCallback callback) {
            uint _callback = NativeMethods.WimRegisterMessageCallback(hWim, callback, IntPtr.Zero);
            int rc = Marshal.GetLastWin32Error();
            if (0 != rc) {
                // Throw an exception if something bad happened on the Win32 end.
                throw
                    new InvalidOperationException(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            "Unable to register message callback."
                ));
            }
        }
        public static void
        UnregisterMessageCallback(
            WimFileHandle hWim,
            WimMessageCallback registeredCallback) {
            bool status = NativeMethods.WimUnregisterMessageCallback(hWim, registeredCallback);
            int rc = Marshal.GetLastWin32Error();
            if (!status) {
                throw
                    new InvalidOperationException(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            "Unable to unregister message callback."
                ));
            }
        }
        #endregion WIMGAPI
        #endregion Delegates and Callbacks
        #region Constants
        #region WIMGAPI
        public   const uint  WIM_FLAG_VERIFY                      = 0x00000002;
        public   const uint  WIM_FLAG_INDEX                       = 0x00000004;
        public   const uint  WM_APP                               = 0x00008000;
        #endregion WIMGAPI
        #endregion Constants
        #region WIMGAPI
        [FlagsAttribute]
        internal enum
        WimCreateFileDesiredAccess
            : uint {
            WimQuery                   = 0x00000000,
            WimGenericRead             = 0x80000000
        }
        /// <summary>
        /// Specifies how the file is to be treated and what features are to be used.
        /// </summary>
        [FlagsAttribute]
        internal enum
        WimApplyFlags
            : uint {
            /// <summary>
            /// No flags.
            /// </summary>
            WimApplyFlagsNone          = 0x00000000,
            /// <summary>
            /// Reserved.
            /// </summary>
            WimApplyFlagsReserved      = 0x00000001,
            /// <summary>
            /// Verifies that files match original data.
            /// </summary>
            WimApplyFlagsVerify        = 0x00000002,
            /// <summary>
            /// Specifies that the image is to be sequentially read for caching or performance purposes.
            /// </summary>
            WimApplyFlagsIndex         = 0x00000004,
            /// <summary>
            /// Applies the image without physically creating directories or files. Useful for obtaining a list of files and directories in the image.
            /// </summary>
            WimApplyFlagsNoApply       = 0x00000008,
            /// <summary>
            /// Disables restoring security information for directories.
            /// </summary>
            WimApplyFlagsNoDirAcl      = 0x00000010,
            /// <summary>
            /// Disables restoring security information for files
            /// </summary>
            WimApplyFlagsNoFileAcl     = 0x00000020,
            /// <summary>
            /// The .wim file is opened in a mode that enables simultaneous reading and writing.
            /// </summary>
            WimApplyFlagsShareWrite    = 0x00000040,
            /// <summary>
            /// Sends a WIM_MSG_FILEINFO message during the apply operation.
            /// </summary>
            WimApplyFlagsFileInfo      = 0x00000080,
            /// <summary>
            /// Disables automatic path fixups for junctions and symbolic links.
            /// </summary>
            WimApplyFlagsNoRpFix       = 0x00000100,
            /// <summary>
            /// Returns a handle that cannot commit changes, regardless of the access level requested at mount time.
            /// </summary>
            WimApplyFlagsMountReadOnly = 0x00000200,
            /// <summary>
            /// Reserved.
            /// </summary>
            WimApplyFlagsMountFast     = 0x00000400,
            /// <summary>
            /// Reserved.
            /// </summary>
            WimApplyFlagsMountLegacy   = 0x00000800
        }
        public enum WimMessage : uint {
            WIM_MSG                    = WM_APP + 0x1476,
            WIM_MSG_TEXT,
            ///<summary>
            ///Indicates an update in the progress of an image application.
            ///</summary>
            WIM_MSG_PROGRESS,
            ///<summary>
            ///Enables the caller to prevent a file or a directory from being captured or applied.
            ///</summary>
            WIM_MSG_PROCESS,
            ///<summary>
            ///Indicates that volume information is being gathered during an image capture.
            ///</summary>
            WIM_MSG_SCANNING,
            ///<summary>
            ///Indicates the number of files that will be captured or applied.
            ///</summary>
            WIM_MSG_SETRANGE,
            ///<summary>
            ///Indicates the number of files that have been captured or applied.
            ///</summary>
            WIM_MSG_SETPOS,
            ///<summary>
            ///Indicates that a file has been either captured or applied.
            ///</summary>
            WIM_MSG_STEPIT,
            ///<summary>
            ///Enables the caller to prevent a file resource from being compressed during a capture.
            ///</summary>
            WIM_MSG_COMPRESS,
            ///<summary>
            ///Alerts the caller that an error has occurred while capturing or applying an image.
            ///</summary>
            WIM_MSG_ERROR,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            WIM_MSG_ALIGNMENT,
            WIM_MSG_RETRY,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            WIM_MSG_SPLIT,
            WIM_MSG_SUCCESS            = 0x00000000,
            WIM_MSG_ABORT_IMAGE        = 0xFFFFFFFF
        }
        internal enum
        WimCreationDisposition
            : uint {
            WimOpenExisting            = 0x00000003,
        }
        internal enum
        WimActionFlags
            : uint {
            WimIgnored                 = 0x00000000,
            WimFileChunked             = 0x20000000
        }
        internal enum
        WimCompressionType
            : uint {
            WimIgnored                 = 0x00000000
        }
        internal enum
        WimCreationResult
            : uint {
            WimCreatedNew              = 0x00000000,
            WimOpenedExisting          = 0x00000001
        }
        #endregion WIMGAPI
        #region WIMGAPI P/Invoke
        #region SafeHandle wrappers for WimFileHandle and WimImageHandle
        public sealed class WimFileHandle : SafeHandle {
            public WimFileHandle(
                string wimPath)
                : base(IntPtr.Zero, true) {
                if (String.IsNullOrEmpty(wimPath)) {
                    throw new ArgumentNullException("wimPath");
                }
                if (!File.Exists(Path.GetFullPath(wimPath))) {
                    throw new FileNotFoundException((new FileNotFoundException()).Message, wimPath);
                }
                NativeMethods.WimCreationResult creationResult;
                this.handle = NativeMethods.WimCreateFile(
                    wimPath,
                    NativeMethods.WimCreateFileDesiredAccess.WimGenericRead,
                    NativeMethods.WimCreationDisposition.WimOpenExisting,
                    NativeMethods.WimActionFlags.WimFileChunked,
                    NativeMethods.WimCompressionType.WimIgnored,
                    out creationResult
                );
                // Check results.
                if (creationResult != NativeMethods.WimCreationResult.WimOpenedExisting) {
                    throw new Win32Exception();
                }
                if (this.handle == IntPtr.Zero) {
                    throw new Win32Exception();
                }
                // Set the temporary path.
                NativeMethods.WimSetTemporaryPath(
                    this,
                    Environment.ExpandEnvironmentVariables("%TEMP%")
                );
            }
            protected override bool ReleaseHandle() {
                return NativeMethods.WimCloseHandle(this.handle);
            }
            public override bool IsInvalid {
                get { return this.handle == IntPtr.Zero; }
            }
        }
        public sealed class WimImageHandle : SafeHandle {
            public WimImageHandle(
                WimFile Container,
                uint ImageIndex)
                : base(IntPtr.Zero, true) {
                if (null == Container) {
                    throw new ArgumentNullException("Container");
                }
                if ((Container.Handle.IsClosed) || (Container.Handle.IsInvalid)) {
                    throw new ArgumentNullException("The handle to the WIM file has already been closed, or is invalid.", "Container");
                }
                if (ImageIndex > Container.ImageCount) {
                    throw new ArgumentOutOfRangeException("ImageIndex", "The index does not exist in the specified WIM file.");
                }
                this.handle = NativeMethods.WimLoadImage(
                    Container.Handle.DangerousGetHandle(),
                    ImageIndex);
            }
            protected override bool ReleaseHandle() {
                return NativeMethods.WimCloseHandle(this.handle);
            }
            public override bool IsInvalid {
                get { return this.handle == IntPtr.Zero; }
            }
        }
        #endregion SafeHandle wrappers for WimFileHandle and WimImageHandle
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMCreateFile")]
        internal static extern IntPtr
        WimCreateFile(
            [In, MarshalAs(UnmanagedType.LPWStr)] string WimPath,
            [In]    WimCreateFileDesiredAccess DesiredAccess,
            [In]    WimCreationDisposition CreationDisposition,
            [In]    WimActionFlags FlagsAndAttributes,
            [In]    WimCompressionType CompressionType,
            [Out, Optional] out WimCreationResult CreationResult
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMCloseHandle")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimCloseHandle(
            [In]    IntPtr Handle
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMLoadImage")]
        internal static extern IntPtr
        WimLoadImage(
            [In]    IntPtr Handle,
            [In]    uint ImageIndex
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMGetImageCount")]
        internal static extern uint
        WimGetImageCount(
            [In]    WimFileHandle Handle
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMApplyImage")]
        internal static extern bool
        WimApplyImage(
            [In]    WimImageHandle Handle,
            [In, Optional, MarshalAs(UnmanagedType.LPWStr)] string Path,
            [In]    WimApplyFlags Flags
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMGetImageInformation")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimGetImageInformation(
            [In]        SafeHandle Handle,
            [Out]   out StringBuilder ImageInfo,
            [Out]   out uint SizeOfImageInfo
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMSetTemporaryPath")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimSetTemporaryPath(
            [In]    WimFileHandle Handle,
            [In]    string TempPath
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMRegisterMessageCallback", CallingConvention = CallingConvention.StdCall)]
        internal static extern uint
        WimRegisterMessageCallback(
            [In, Optional] WimFileHandle      hWim,
            [In]           WimMessageCallback MessageProc,
            [In, Optional] IntPtr             ImageInfo
        );
        [DllImport("Wimgapi.dll", CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMUnregisterMessageCallback", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool
        WimUnregisterMessageCallback(
            [In, Optional] WimFileHandle      hWim,
            [In]           WimMessageCallback MessageProc
        );
        #endregion WIMGAPI P/Invoke
    }
    #region WIM Interop
    public class WimFile {
        internal XDocument m_xmlInfo;
        internal List<WimImage> m_imageList;
        private static NativeMethods.WimMessageCallback wimMessageCallback;
        #region Events
        /// <summary>
        /// DefaultImageEvent handler
        /// </summary>
        public delegate void DefaultImageEventHandler(object sender, DefaultImageEventArgs e);
        ///<summary>
        ///ProcessFileEvent handler
        ///</summary>
        public delegate void ProcessFileEventHandler(object sender, ProcessFileEventArgs e);
        ///<summary>
        ///Enable the caller to prevent a file resource from being compressed during a capture.
        ///</summary>
        public event ProcessFileEventHandler ProcessFileEvent;
        ///<summary>
        ///Indicate an update in the progress of an image application.
        ///</summary>
        public event DefaultImageEventHandler ProgressEvent;
        ///<summary>
        ///Alert the caller that an error has occurred while capturing or applying an image.
        ///</summary>
        public event DefaultImageEventHandler ErrorEvent;
        ///<summary>
        ///Indicate that a file has been either captured or applied.
        ///</summary>
        public event DefaultImageEventHandler StepItEvent;
        ///<summary>
        ///Indicate the number of files that will be captured or applied.
        ///</summary>
        public event DefaultImageEventHandler SetRangeEvent;
        ///<summary>
        ///Indicate the number of files that have been captured or applied.
        ///</summary>
        public event DefaultImageEventHandler SetPosEvent;
        #endregion Events
        private
        enum
        ImageEventMessage : uint {
            ///<summary>
            ///Enables the caller to prevent a file or a directory from being captured or applied.
            ///</summary>
            Progress = NativeMethods.WimMessage.WIM_MSG_PROGRESS,
            ///<summary>
            ///Notification sent to enable the caller to prevent a file or a directory from being captured or applied.
            ///To prevent a file or a directory from being captured or applied, call WindowsImageContainer.SkipFile().
            ///</summary>
            Process = NativeMethods.WimMessage.WIM_MSG_PROCESS,
            ///<summary>
            ///Enables the caller to prevent a file resource from being compressed during a capture.
            ///</summary>
            Compress = NativeMethods.WimMessage.WIM_MSG_COMPRESS,
            ///<summary>
            ///Alerts the caller that an error has occurred while capturing or applying an image.
            ///</summary>
            Error = NativeMethods.WimMessage.WIM_MSG_ERROR,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            Alignment = NativeMethods.WimMessage.WIM_MSG_ALIGNMENT,
            ///<summary>
            ///Enables the caller to align a file resource on a particular alignment boundary.
            ///</summary>
            Split = NativeMethods.WimMessage.WIM_MSG_SPLIT,
            ///<summary>
            ///Indicates that volume information is being gathered during an image capture.
            ///</summary>
            Scanning = NativeMethods.WimMessage.WIM_MSG_SCANNING,
            ///<summary>
            ///Indicates the number of files that will be captured or applied.
            ///</summary>
            SetRange = NativeMethods.WimMessage.WIM_MSG_SETRANGE,
            ///<summary>
            ///Indicates the number of files that have been captured or applied.
            /// </summary>
            SetPos = NativeMethods.WimMessage.WIM_MSG_SETPOS,
            ///<summary>
            ///Indicates that a file has been either captured or applied.
            ///</summary>
            StepIt = NativeMethods.WimMessage.WIM_MSG_STEPIT,
            ///<summary>
            ///Success.
            ///</summary>
            Success = NativeMethods.WimMessage.WIM_MSG_SUCCESS,
            ///<summary>
            ///Abort.
            ///</summary>
            Abort = NativeMethods.WimMessage.WIM_MSG_ABORT_IMAGE
        }
        ///<summary>
        ///Event callback to the Wimgapi events
        ///</summary>
        private
        uint
        ImageEventMessagePump(
            uint MessageId,
            IntPtr wParam,
            IntPtr lParam,
            IntPtr UserData) {
            uint status = (uint) NativeMethods.WimMessage.WIM_MSG_SUCCESS;
            DefaultImageEventArgs eventArgs = new DefaultImageEventArgs(wParam, lParam, UserData);
            switch ((ImageEventMessage)MessageId) {
                case ImageEventMessage.Progress:
                    ProgressEvent(this, eventArgs);
                    break;
                case ImageEventMessage.Process:
                    if (null != ProcessFileEvent) {
                        string fileToImage = Marshal.PtrToStringUni(wParam);
                        ProcessFileEventArgs fileToProcess = new ProcessFileEventArgs(fileToImage, lParam);
                        ProcessFileEvent(this, fileToProcess);
                        if (fileToProcess.Abort == true) {
                            status = (uint)ImageEventMessage.Abort;
                        }
                    }
                    break;
                case ImageEventMessage.Error:
                    if (null != ErrorEvent) {
                        ErrorEvent(this, eventArgs);
                    }
                    break;
                case ImageEventMessage.SetRange:
                    if (null != SetRangeEvent) {
                        SetRangeEvent(this, eventArgs);
                    }
                    break;
                case ImageEventMessage.SetPos:
                    if (null != SetPosEvent) {
                        SetPosEvent(this, eventArgs);
                    }
                    break;
                case ImageEventMessage.StepIt:
                    if (null != StepItEvent) {
                        StepItEvent(this, eventArgs);
                    }
                    break;
                default:
                    break;
            }
            return status;
        }
        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="wimPath">Path to the WIM container.</param>
        public
        WimFile(string wimPath) {
            if (string.IsNullOrEmpty(wimPath)) {
                throw new ArgumentNullException("wimPath");
            }
            if (!File.Exists(Path.GetFullPath(wimPath))) {
                throw new FileNotFoundException((new FileNotFoundException()).Message, wimPath);
            }
            Handle = new NativeMethods.WimFileHandle(wimPath);
            // Hook up the events before we return.
            //wimMessageCallback = new NativeMethods.WimMessageCallback(ImageEventMessagePump);
            //NativeMethods.RegisterMessageCallback(this.Handle, wimMessageCallback);
        }
        /// <summary>
        /// Closes the WIM file.
        /// </summary>
        public void
        Close() {
            foreach (WimImage image in Images) {
                image.Close();
            }
            if (null != wimMessageCallback) {
                NativeMethods.UnregisterMessageCallback(this.Handle, wimMessageCallback);
                wimMessageCallback = null;
            }
            if ((!Handle.IsClosed) && (!Handle.IsInvalid)) {
                Handle.Close();
            }
        }
        /// <summary>
        /// Provides a list of WimImage objects, representing the images in the WIM container file.
        /// </summary>
        public List<WimImage>
        Images {
            get {
                if (null == m_imageList) {
                    int imageCount = (int)ImageCount;
                    m_imageList = new List<WimImage>(imageCount);
                    for (int i = 0; i < imageCount; i++) {
                        // Load up each image so it's ready for us.
                        m_imageList.Add(
                            new WimImage(this, (uint)i + 1));
                    }
                }
                return m_imageList;
            }
        }
        /// <summary>
        /// Provides a list of names of the images in the specified WIM container file.
        /// </summary>
        public List<string>
        ImageNames {
            get {
                List<string> nameList = new List<string>();
                foreach (WimImage image in Images) {
                    nameList.Add(image.ImageName);
                }
                return nameList;
            }
        }
        /// <summary>
        /// Indexer for WIM images inside the WIM container, indexed by the image number.
        /// The list of Images is 0-based, but the WIM container is 1-based, so we automatically compensate for that.
        /// this[1] returns the 0th image in the WIM container.
        /// </summary>
        /// <param name="ImageIndex">The 1-based index of the image to retrieve.</param>
        /// <returns>WinImage object.</returns>
        public WimImage
        this[int ImageIndex] {
            get { return Images[ImageIndex - 1]; }
        }
        /// <summary>
        /// Indexer for WIM images inside the WIM container, indexed by the image name.
        /// WIMs created by different processes sometimes contain different information - including the name.
        /// Some images have their name stored in the Name field, some in the Flags field, and some in the EditionID field.
        /// We take all of those into account in while searching the WIM.
        /// </summary>
        /// <param name="ImageName"></param>
        /// <returns></returns>
        public WimImage
        this[string ImageName] {
            get {
                return
                    Images.Where(i => (
                        i.ImageName.ToUpper()  == ImageName.ToUpper() ||
                        i.ImageFlags.ToUpper() == ImageName.ToUpper() ))
                    .DefaultIfEmpty(null)
                        .FirstOrDefault<WimImage>();
            }
        }
        /// <summary>
        /// Returns the number of images in the WIM container.
        /// </summary>
        internal uint
        ImageCount {
            get { return NativeMethods.WimGetImageCount(Handle); }
        }
        /// <summary>
        /// Returns an XDocument representation of the XML metadata for the WIM container and associated images.
        /// </summary>
        internal XDocument
        XmlInfo {
            get {
                if (null == m_xmlInfo) {
                    StringBuilder builder;
                    uint bytes;
                    if (!NativeMethods.WimGetImageInformation(Handle, out builder, out bytes)) {
                        throw new Win32Exception();
                    }
                    // Ensure the length of the returned bytes to avoid garbage characters at the end.
                    int charCount = (int)bytes / sizeof(char);
                    if (null != builder) {
                        // Get rid of the unicode file marker at the beginning of the XML.
                        builder.Remove(0, 1);
                        builder.EnsureCapacity(charCount - 1);
                        builder.Length = charCount - 1;
                        // This isn't likely to change while we have the image open, so cache it.
                        m_xmlInfo = XDocument.Parse(builder.ToString().Trim());
                    } else {
                        m_xmlInfo = null;
                    }
                }
                return m_xmlInfo;
            }
        }
        public NativeMethods.WimFileHandle Handle {
            get;
            private set;
        }
    }
    public class
    WimImage {
        internal XDocument m_xmlInfo;
        public
        WimImage(
            WimFile Container,
            uint ImageIndex) {
            if (null == Container) {
                throw new ArgumentNullException("Container");
            }
            if ((Container.Handle.IsClosed) || (Container.Handle.IsInvalid)) {
                throw new ArgumentNullException("The handle to the WIM file has already been closed, or is invalid.", "Container");
            }
            if (ImageIndex > Container.ImageCount) {
                throw new ArgumentOutOfRangeException("ImageIndex", "The index does not exist in the specified WIM file.");
            }
            Handle = new NativeMethods.WimImageHandle(Container, ImageIndex);
        }
        public enum
        Architectures : uint {
            x86   = 0x0,
            ARM   = 0x5,
            IA64  = 0x6,
            AMD64 = 0x9
        }
        public void
        Close() {
            if ((!Handle.IsClosed) && (!Handle.IsInvalid)) {
                Handle.Close();
            }
        }
        public void
        Apply(
            string ApplyToPath) {
            if (string.IsNullOrEmpty(ApplyToPath)) {
                throw new ArgumentNullException("ApplyToPath");
            }
            ApplyToPath = Path.GetFullPath(ApplyToPath);
            if (!Directory.Exists(ApplyToPath)) {
                throw new DirectoryNotFoundException("The WIM cannot be applied because the specified directory was not found.");
            }
            if (!NativeMethods.WimApplyImage(
                this.Handle,
                ApplyToPath,
                NativeMethods.WimApplyFlags.WimApplyFlagsNone
            )) {
                throw new Win32Exception();
            }
        }
        public NativeMethods.WimImageHandle
        Handle {
            get;
            private set;
        }
        internal XDocument
        XmlInfo {
            get {
                if (null == m_xmlInfo) {
                    StringBuilder builder;
                    uint bytes;
                    if (!NativeMethods.WimGetImageInformation(Handle, out builder, out bytes)) {
                        throw new Win32Exception();
                    }
                    // Ensure the length of the returned bytes to avoid garbage characters at the end.
                    int charCount = (int)bytes / sizeof(char);
                    if (null != builder) {
                        // Get rid of the unicode file marker at the beginning of the XML.
                        builder.Remove(0, 1);
                        builder.EnsureCapacity(charCount - 1);
                        builder.Length = charCount - 1;
                        // This isn't likely to change while we have the image open, so cache it.
                        m_xmlInfo = XDocument.Parse(builder.ToString().Trim());
                    } else {
                        m_xmlInfo = null;
                    }
                }
                return m_xmlInfo;
            }
        }
        public string
        ImageIndex {
            get { return XmlInfo.Element("IMAGE").Attribute("INDEX").Value; }
        }
        public string
        ImageName {
            get { return XmlInfo.XPathSelectElement("/IMAGE/NAME").Value; }
        }
        public string
        ImageEditionId {
            get { return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/EDITIONID").Value; }
        }
        public string
        ImageFlags {
            get { return XmlInfo.XPathSelectElement("/IMAGE/FLAGS").Value; }
        }
        public string
        ImageProductType {
            get {
                return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/PRODUCTTYPE").Value;
            }
        }
        public string
        ImageInstallationType {
            get { return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/INSTALLATIONTYPE").Value; }
        }
        public string
        ImageDescription {
            get { return XmlInfo.XPathSelectElement("/IMAGE/DESCRIPTION").Value; }
        }
        public ulong
        ImageSize {
            get { return ulong.Parse(XmlInfo.XPathSelectElement("/IMAGE/TOTALBYTES").Value); }
        }
        public Architectures
        ImageArchitecture {
            get {
                int arch = -1;
                try {
                    arch = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/ARCH").Value);
                } catch { }
                return (Architectures)arch;
            }
        }
        public string
        ImageDefaultLanguage {
            get {
                string lang = null;
                try {
                    lang = XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/LANGUAGES/DEFAULT").Value;
                } catch { }
                return lang;
            }
        }
        public Version
        ImageVersion {
            get {
                int major = 0;
                int minor = 0;
                int build = 0;
                int revision = 0;
                try {
                    major = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/MAJOR").Value);
                    minor = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/MINOR").Value);
                    build = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/BUILD").Value);
                    revision = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/SPBUILD").Value);
                } catch { }
                return (new Version(major, minor, build, revision));
            }
        }
        public string
        ImageDisplayName {
            get { return XmlInfo.XPathSelectElement("/IMAGE/DISPLAYNAME").Value; }
        }
        public string
        ImageDisplayDescription {
            get { return XmlInfo.XPathSelectElement("/IMAGE/DISPLAYDESCRIPTION").Value; }
        }
    }
    ///<summary>
    ///Describes the file that is being processed for the ProcessFileEvent.
    ///</summary>
    public class
    DefaultImageEventArgs : EventArgs {
        ///<summary>
        ///Default constructor.
        ///</summary>
        public
        DefaultImageEventArgs(
            IntPtr wideParameter,
            IntPtr leftParameter,
            IntPtr userData) {
            WideParameter = wideParameter;
            LeftParameter = leftParameter;
            UserData      = userData;
        }
        ///<summary>
        ///wParam
        ///</summary>
        public IntPtr WideParameter {
            get;
            private set;
        }
        ///<summary>
        ///lParam
        ///</summary>
        public IntPtr LeftParameter {
            get;
            private set;
        }
        ///<summary>
        ///UserData
        ///</summary>
        public IntPtr UserData {
            get;
            private set;
        }
    }
    ///<summary>
    ///Describes the file that is being processed for the ProcessFileEvent.
    ///</summary>
    public class
    ProcessFileEventArgs : EventArgs {
        ///<summary>
        ///Default constructor.
        ///</summary>
        ///<param name="file">Fully qualified path and file name. For example: c:\file.sys.</param>
        ///<param name="skipFileFlag">Default is false - skip file and continue.
        ///Set to true to abort the entire image capture.</param>
        public
        ProcessFileEventArgs(
            string file,
            IntPtr skipFileFlag) {
            m_FilePath = file;
            m_SkipFileFlag = skipFileFlag;
        }
        ///<summary>
        ///Skip file from being imaged.
        ///</summary>
        public void
        SkipFile() {
            byte[] byteBuffer = {
                    0
            };
            int byteBufferSize = byteBuffer.Length;
            Marshal.Copy(byteBuffer, 0, m_SkipFileFlag, byteBufferSize);
        }
        ///<summary>
        ///Fully qualified path and file name.
        ///</summary>
        public string
        FilePath {
            get {
                string stringToReturn = "";
                if (m_FilePath != null) {
                    stringToReturn = m_FilePath;
                }
                return stringToReturn;
            }
        }
        ///<summary>
        ///Flag to indicate if the entire image capture should be aborted.
        ///Default is false - skip file and continue. Setting to true will
        ///abort the entire image capture.
        ///</summary>
        public bool Abort {
            set { m_Abort = value; }
            get { return m_Abort;  }
        }
        private string m_FilePath;
        private bool m_Abort;
        private IntPtr m_SkipFileFlag;
    }
    #endregion WIM Interop
}
"@

if (-not ([System.Management.Automation.PSTypeName]'WIMInterop.WimFile').Type)
{
    Add-Type -TypeDefinition $code -ReferencedAssemblies "Microsoft.Win32.Primitives","System.Collections","System.Core","System.Text.RegularExpressions","System.Xml","System.Xml.XDocument","System.Xml.XPath.XDocument","System.Linq","System.Xml.Linq"
}

function Get-WimFileImagesInfo
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$WimFilePath = "D:\Sources\install.wim"
    )
    PROCESS
    {
        $w = new-object WIMInterop.WimFile -ArgumentList $WimFilePath
        return $w.Images
    }
}