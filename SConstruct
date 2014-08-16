import os

EnsurePythonVersion(2, 7)
EnsureSConsVersion(2, 2)

#Variable for reuse- '#' means "directory where scons was called and found the
#initial SConstruct." SCons has it's own platform-independent File and Dir objects
#called Nodes. Note that you don't HAVE to use these.
lib_src_path = Dir('#/SRC')
inc_src_path = Dir('#/SRC')
root_dir = Dir('#')

#This also tests include and library paths
env = Environment(tools = ['watcom', 'nasm'], CPPPATH=lib_src_path)
debug = ARGUMENTS.get('DEBUG', 0)

if debug:
	env.Prepend(ASFLAGS='-DDEBUG')
env.Append(ASFLAGS='-f obj -l ' + str(lib_src_path) + os.sep + \
	'${TARGET.filebase}.lst -i ' + str(lib_src_path) + os.sep)	

#Create target-specific environments
int_env = env.Clone()
dos_env = env.Clone()

dos_env.Prepend(ASFLAGS='-DHOST_ENV=INT21H -DCPU_TARGET=8086')
int_env.Prepend(ASFLAGS='-DHOST_ENV=INT10H -DCPU_TARGET=8086')


Export('env', 'dos_env', 'int_env', 'lib_src_path', 'root_dir', 'debug')
SConscript('SRC/SConscript')
SConscript('TEST/SConscript')

