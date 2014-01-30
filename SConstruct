EnsurePythonVersion(2, 7)
EnsureSConsVersion(2, 2)

#Variable for reuse- '#' means "directory where scons was called and found the
#initial SConstruct." SCons has it's own platform-independent File and Dir objects
#called Nodes. Note that you don't HAVE to use these.
lib_src_path = Dir('#/SRC')
root_dir = Dir('#')

#This also tests include and library paths
env = Environment(tools = ['watcom'], CPPPATH=lib_src_path)
env.Append(ASFLAGS='-bt=dos')
env['MEMMODEL16']='s'
Export('env', 'lib_src_path', 'root_dir')
SConscript('SRC/SConscript')
SConscript('TEST/SConscript')
#env['LIST']='wdis'

#strdos_lib = env.Library(shared_base_path.File('STRDOS_' + env['MEMMODEL16'].upper() + '.LIB'), src_files_SCons_nodes)
#env.Default(strdos_lib)
#Execute(Copy('#', strdos_lib))

"""app_env = lib_env.Clone()
app_env['LIBPATH'] = shared_base_path 
app_env['LIBS'] = 'STRDOS.LIB'
app_env.Append(LINKFLAGS = 'system dos option map=${TARGET.base}.map')

app_path = []
for app in app_names:
	curr_app_dir = Dir('#' + app)
	curr_app_target = curr_app_dir.File(app + '.ASM')
	app_path.append(curr_app_target)
	app_env.Clean(curr_app_target, curr_app_dir.File(app + '.sym'))
	
app_env.Program(app_path)
#app_env.Program('static_app.c')"""
