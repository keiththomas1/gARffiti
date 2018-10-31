import subprocess

print subprocess.check_output(['zip','-r','Server.zip','.','-x','"*.DS_Store"'])
