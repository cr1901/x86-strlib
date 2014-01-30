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
