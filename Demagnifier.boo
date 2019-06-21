import System
import System.IO
import OpenPop.Pop3 from 'extra/OpenPop'
import IniParser from 'extra/INIFileParser'

static class INI:
	public mail_user	= "[I Am Error]" # DATA EXPUNGED !
	public mail_server	= "mail.ru"
	public mail_port	= 995
	public mail_pass	= "[I Am Error]" # DATA EXPUNGED !
	public root_dir		= "shots"
	public delim		= "/@/"
	public index		= "mails.idx"
	public last_marker	= ".Last_Processed."
	public final header = """
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
# Demagnifier snapshot serializer v0.3
# Developed in 2015 by Guevara-chan.
# *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
"""
# -------------------- #
class MailBox:
	final net_link = Pop3Client()
	protected db as IniParser.Model.IniData
	property fail as Exception
	property current_msg = 0
	property idx_path = ""

	# --Methods goes here.
	def constructor(server, port as int, user as string, password as string, fs as Storage):
		try:
			net_link.Connect("pop.$server", port, true)
			net_link.Authenticate(user, password)
			idx_path = fs.request_file(INI.index)
			db = FileIniDataParser().ReadFile(idx_path)			
		except ex: fail = ex

	def current_subject():
		return net_link.GetMessageHeaders(current_msg).Subject

	def last_index():
		unless subj 		= db.Global[INI.last_marker]:	return 1
		unless current_msg 	= int.Parse(db.Global[subj]):	return 1
		unless subj == current_subject():					return 1
		return current_msg

	def check_current_msg() as bool:
		db.Global[INI.last_marker] = subj = current_subject()
		accum = db.Global[subj]; db.Global[subj] = current_msg.ToString()
		return accum == null

	def dump_current_msg():
		for file in net_link.GetMessage(current_msg).FindAllAttachments():
			yield file.FileName, file.Body

	def tick():
		mail_count	= net_link.GetMessageCount()
		for idx in range(last_index(), mail_count + 1):
			current_msg = idx; yield current_subject()

	def destructor():
		FileIniDataParser().SaveFile(idx_path, db)
# -------------------- #
class Storage:
	root = ""
	public dump_counter = 0

	# --Methods goes here.
	def constructor(dest_dir):
		root = dest_dir; mkdir ""

	def rel_path(dest):
		return Path.Combine(root, dest)

	def mkdir(dir_name as string):
		return Directory.CreateDirectory(rel_path(dir_name))

	def request_file(name as string):
		File.OpenWrite(file_path = rel_path(name)).Close()
		return file_path

	def save(source as string, naming as string, bytes as (byte)):
		if File.Exists(dest = Path.Combine(source, naming)):	 						return "EXCESS"	, dest, false
		else:
			mkdir source; dump_counter++; File.WriteAllBytes(rel_path(dest), bytes);	return "GOT"	, dest, true

	def save_log(source as string, naming as string, bytes as (byte)):
		mkdir source; pref, post, succ = save(Path.Combine(source, 'Logae'), naming, bytes)
		return "Logae\\$pref", post, succ
# -------------------- #
class CUI():
	final out_link	= Storage(INI.root_dir)
	final in_link 	= MailBox(INI.mail_server, INI.mail_port, INI.mail_user, INI.mail_pass, out_link)
	property shot_count = 0

	# --Methods goes here.
	def out(text, color):
		Console.ForegroundColor = color; Console.Write(text)

	def communicate(text, color):
		out("$text\n", color cast ConsoleColor)

	def communicate_block(prefix, text, color):
		out("[", color); out(prefix, (color cast int + 8) % 16); communicate("]> $text", color)

	def delim_out():
		communicate("-" * 60, ConsoleColor.DarkGray)

	def constructor():
		Console.Title = "[.Demagnifier.]"; communicate(INI.header[2:], ConsoleColor.Green)
		if in_link.fail:
			communicate_block("/FAULT/", "Unable to connect pop3 server: $(in_link.fail.Message).", ConsoleColor.Red)
			cycle = { return self }

	def destructor():
		delim_out(); out("<Exiting in 5 seconds>", ConsoleColor.Yellow); System.Threading.Thread.Sleep(5000) 

	public cycle = def():
		delim_out()
		for header in in_link.tick():
			try:
				if in_link.check_current_msg():
					machinae = join(header.Split((INI.delim,), StringSplitOptions.None)[0:2], "[►►]")
					for naming, bytes in in_link.dump_current_msg():
						if Path.GetExtension(naming).ToLower() == ".txt":	proc = out_link.save_log 
						else:												proc = out_link.save
						pref, post, succ = proc(machinae, naming, bytes)
						communicate_block(pref, post, (ConsoleColor.Cyan if succ else ConsoleColor.Magenta))
				else: communicate_block("SKIP", header, ConsoleColor.Yellow)
			except ex: 
				communicate_block("/FAULT/", "Unable to load '$header': $(ex.Message).", ConsoleColor.Red)
		communicate_block("-->$(out_link.dump_counter)<--", "file(s) were received.", ConsoleColor.DarkGreen)

# ----Main code---- #
AppDomain.CurrentDomain.AssemblyResolve += def(sender, e):
		return Reflection.Assembly.LoadFrom("lib/$(Reflection.AssemblyName(e.Name).Name).dll")
CUI().cycle()