# Ensure we can SSH
import paramiko

# Ensure we can create a VM
from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
from libcloud.compute.deployment import MultiStepDeployment, ScriptDeployment, SSHKeyDeployment
import os

RACKSPACE_USER = os.environ['CLOUD_SERVERS_USERNAME']
RACKSPACE_KEY = os.environ['CLOUD_SERVERS_API_KEY']

Driver = get_driver(Provider.RACKSPACE)
conn = Driver(RACKSPACE_USER, RACKSPACE_KEY)

# read your public key in
# Note: This key will be added to the authorized keys for the root user
# (/root/.ssh/authorized_keys)
sd = SSHKeyDeployment(open(os.path.expanduser("~/.ssh/id_rsa.pub")).read())
# a simple script to install puppet post boot, can be much more complicated.
script = ScriptDeployment("apt-get update")

images = conn.list_images()
sizes = conn.list_sizes()
image = [image for image in images if image.id == '104'][0]
size = [ size for size in sizes if size.id == '2'][0]

# deploy_node takes the same base keyword arguments as create_node.
node = conn.deploy_node(name='oh-restore', image=image, size=size, deploy=sd)
# <Node: uuid=..., name=test, state=3, public_ip=['1.1.1.1'], provider=Rackspace ...>
# the node is now booted, with your ssh key and puppet installed.
ip = node.public_ip[0]

OLD_RESTORE_CONF_SH_LINES = open('restore.conf.sh', 'r').readlines()
NEW_RESTORE_CONF_SH_LINES = [x for x in OLD_RESTORE_CONF_SH_LINES.rstrip()
                             if 'REMOTE_IP=' not in x]
NEW_RESTORE_CONF_SH_LINES.append('REMOTE_IP="%s"' % (ip,))
fd = open('restore.conf.sh', 'w')
fd.write('\n'.join(NEW_RESTORE_CONF_SH_LINES))
fd.close()

