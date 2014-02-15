EnsurePythonVersion(2, 7)
EnsureSConsVersion(2, 2)

#Variable for reuse- '#' means "directory where scons was called and found the
#initial SConstruct." SCons has it's own platform-independent File and Dir objects
#called Nodes. Note that you don't HAVE to use these.
lib_src_path = Dir('#/SRC')
root_dir = Dir('#')

#This also tests include and library paths
env = Environment(tools = ['watcom'], CPPPATH=lib_src_path)

#A bit of work to convert input command line arguments dictionary from string to int.
if int(ARGUMENTS.get('TEST_WASM', False)) == 1:
	env['USEWASM']=True
env['MEMMODEL16']=ARGUMENTS.get('MEMMODEL', 's')
	
if env.subst('$AS') == 'jwasm':
	#print 'JWASM detected... using in place of WASM.'
	env = env.Clone(tools = ['masm'])
	env['AS'] ='jwasm'
	env.Append(ASFLAGS='/Zi3')
elif env.subst('$AS') == 'wasm':
	env.Append(ASFLAGS='-d2')

#Create target-specific environments
int_env = env.Clone()
dos_env = env.Clone()

if env.subst('$AS') == 'jwasm':
	dos_env.Prepend(ASFLAGS='/D__STRDOS__')
elif env.subst('$AS') == 'wasm':
	dos_env.Prepend(ASFLAGS='-D__STRDOS__')
	dos_env.Append(ASFLAGS='-bt=dos')
	
#env.Append(ASFLAGS='-bt=dos')
#env['MEMMODEL16']='s'
Export('env', 'dos_env', 'int_env', 'lib_src_path', 'root_dir')
SConscript('SRC/SConscript')
SConscript('TEST/SConscript')
