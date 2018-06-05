# Apigee OPDK ansible (Under construction)

Centralize Edge operation tasks using one inventory file as reference for all tasks.

This project use as reference the following projects:
- [Apigee opdk playbook setup ansible](https://github.com/carlosfrias/apigee-opdk-playbook-setup-ansible) 
- [etp](https://github.com/yuriylesyuk/etp). 

# Table of contents
1. [Requirements](#requirements)
1. [Getting ready](#getting-ready)
    1. [Configuration file](#config-file)
    1. [Topology definition](#topology-defintion)
    1. [Generate Anisble inventory](#inventory)
    1. [Generate response files](#gen-response)
1. [Apigee Edge Ops Tasks](#ops-tasks)
    1. [Install prereqs and the apigee-setup utility](#prereqs)
    1. [Port checking report](#port-check)
    1. [Install Edge](#install)
    1. [Update Edge](#update)
    1. [Edge onboarding](#onboarding)
    1. [Create keystore in Edge and upload keystore certs](#keystore)
    1. [Create a VirtualHost](#vhost)
    1. [Run apigee-service commands accross planet](#apigee-service)
    1. [Create Edge custom role](#custom-role)
    1. [Create user](#user)
    1. [Fetch planet logs](#logs)
    1. [Run planet scan](#planet-scan)
    1. [Ansible Ad-Hoc commands](#ad-hoc)
1. [Author](#author)

## Requirements <a name="requirements" />

Clone this repo:
```
# Move to your working path
git clone https://github.com/maurogonzalez/apigee-opdk-ansible.git
cd apigee-opdk-ansible.git
```

- ansible >= 2.2
- etp (to create topology diagram)

Go to the [Installation wiki](https://github.com/maurogonzalez/apigee-opdk-ansible/wiki/Install-requirements).

## Getting ready <a name="getting-ready" />
### Configuration file <a name="config-file" />
Under project root there's an _env.yml_, fill the required variables. 

Property | Example | Description
--- | --- | ---
license_path* | /home/gump/license.txt |  License file absolute path including license file name.
apigee_user* | bubbagump | software.apigee.com user.
apigee_pwd* | mygumppassword | software.apigee.com password.
ssh_user | mgump | ssh user.
ssh_key | /home/gump/.ssh/gumptron.key | ssh key absolute path.
ssh_pwd | gumpsecret | ssh password. If not needed, leave the original value.
ssh_bastion_host | 35.0.0.3 | ssh bastion/jumpbox host. If not needed, leave the original value.
ssh_bastion_user | runforest | ssh bastion/jumbox user. If not needed, leave the original value.
ssh_bastion_key | /home/gump/runforest.key | ssh bastion/jumpbox key absolute path. If not needed, leave the original value.
pg_ram_in_mb* | 4096 | Postgresql machine memory required to set memory adjustments.
edge_version* | 4.17.09 |  Edge version. At this point is 4.17.09.
opdk_admin_email** | forest@gump.com |  Edge installation admin email.
opdk_admin_password** | forestpwd | Edge installation admin password.
opdk_smtp_mail_from** | forest@smtp.com | SMTP from.
opdk_smtp_skip** | n | "y" to skip SMTP configuration or "n".
opdk_smtp_user** | forest@user.com | SMTP user.
opdk_smtp_password** | forestpwd | SMTP password.
opdk_smtp_host** | smtp.gump.com | SMTP host.
opdk_smtp_port** | 25 | SMTP port.
opdk_smtp_ssl** | n | "y" or "n".
onboard_org_name*** | BubbaGump | organization name for onboarding. If not needed, leave the original value. 
onboard_admin_username*** | forest@gump.com | org admin username (email format) for onboarding. If not needed, leave the original value. 
onboard_admin_name*** | Forest | org admin name for onboarding. If not needed, leave the original value. 
onboard_admin_lastname*** | Gump | org admin lastname for onboarding. If not needed, leave the original value. 
onboard_admin_pwd*** | forestpwd | org admin password for onboarding. If not needed, leave the original value. 
onboard_env*** | test | environment name for onboarding. If not needed, leave the original value. 
onboard_vhost_alias*** | api.forest.com  | virtualhost alias for onboarding. If not needed, leave the original value.

\* Required.

** Required if _opdk_smtp_skip=n_.

*** Required for onboarding.

**Note:** If you want to encrypt sensitive data: [vault wiki](https://github.com/maurogonzalez/apigee-opdk-ansible/wiki/Encrypting-sensitive-data).

### Topology definition <a name="topology-defintion"/>

First create an [etp edge topology definition json file](https://github.com/yuriylesyuk/etp) (example _examples/topology-1dc-5n.json_).
This is the only file that you need to create.

### Generate Anisble inventory <a name="inventory">

Ansible inventory file based on [apigee-opdk-inventory-file](https://github.com/carlosfrias/apigee-opdk-playbook-setup-ansible/blob/master/README-INVENTORY-FILE.md).

Create an inventory file used by all Ansible playbooks and operation tasks:
```
$ ansible-playbook -e "topology_src=PATH_TO_TOPOLOGY_FILE" inventory.yml
```
Optionally, you can create the topology diagram in the same run setting the diagram variable to any value*:
```
$ ansible-playbook -e "topology_src=PATH_TO_TOPOLOGY_FILE diagram=1" inventory.yml
```
Create only the diagram*:
```
$ ansible-playbook -e "topology_src=PATH_TO_TOPOLOGY_FILE" diagram.yml
```

Variable | Example | Description
--- | --- | ---
topolgy_src* | examples/topology.json | Path to topology json file.
diagram | 1 | Set to some value if you want to generate the diagram in the inventory play.

\* Required

Find the files under:
  - _inventory/inventory\_PLANET.INI_
  - _reports/topology-PLANET.svg_

**Notes:** 
  - \* Diagram tasks, require nodejs and etp ([Installation wiki](https://github.com/maurogonzalez/apigee-opdk-ansible/wiki/Install-requirements)).
  - Do not modify the inventory file.

### Generate response files <a name="gen-response" />

Generate response file per region used by the installation, upgrade and other ops tasks. Also
create the onboarding response file:
```
$ ansible-playbook -e -i inventory/INVENTORY_FILE response_files.yml
```
Find the response files under:
  - _reports/PLANET/response_files/response_PLANET_REGION.cfg_

## Apigee Edge Ops Tasks <a name="ops-tasks" />

### Install prereqs and the apigee-setup utility <a name="prereqs" />
Install the prerequisites described [here](https://docs.apigee.com/private-cloud/latest/install-edge-apigee-setup-utility) and some more
useful tools.

Installs the following packages across the planet:
- wget
- curl
- telnet
- nc  
- nmap  
- java-1.8.0-openjdk-devel
- apigee-service
- apigee-setup
- apigee-provision in management nodes

Uploads the license file, the response and onboarding files. 

Sets Cassandra, Message Processor and Postgresql memory settings.

```
$ ansible-playbook -i inventory/INVENTORY_FILE prerequisites.yml
```

### Port checking report <a name="port-check" />

Create port report for a whole planet. This will test ports between nodes and create two CSV files:
- Connectivity report grouped by edge component.
- Compact report grouped by host.
```
$ ansible-playbook -i inventory/INVENTORY_FILE port_report.yml
```
Find the report files under: 
  - _reports/port_connectivity_report_PLANET.csv_
  - _reports/port_compact_PLANET.csv_

**Note:** The hosts require _nmap_, it is installed in the above prerequisites playbook.

### Install Edge <a name="install" />
Install Edge components in the planet:

```
$ ansible-playbook -i inventory/INVENTORY_FILE -e "cmd=setup" setup.yml
```

### Update Edge <a name="update" />
Update Edge components in the planet, only if current version >= 4.16.09.

Set the value of the target version in your _env.yml_:
```
# filename: env.yml
...
edge_version: 4.17.09
...
```
And run:

```
$ ansible-playbook -i inventory/INVENTORY_FILE update.yml
```

### Edge onboarding <a name="onboarding" />
Onboarding: create organization, environment, org admin user and default virtual host.

```
$ ansible-playbook -i inventory/INVENTORY_FILE onboard.yml
```

### Create keystore in Edge and upload keystore certs <a name="keystore" />
[Apigee Keystores and Truststores](https://docs.apigee.com/api-services/content/keystores-and-truststores).

Create a jar Keystore from key/cert pair, an Apigee Keystore in Edge and upload the JAR to Edge:

```
$ ansible-playbook -i inventory/INVENTORY_FILE \
  -e "keyalias=KEY_ALIAS keystore=KEYSTORE_NAME \
  ks_cert=PATH_TO_CERT ks_key=PATH_TO_KEY \
  ks_org=EDGE_ORG ks_env=EDGE_ENV" \
  keystore.yml
```

Variable | Example | Description
--- | --- | ---
keyalias* | my_key_alias | Key alias. 
keystore* | keystore | Keystore name.
ks_cert* | tls/server.crt  | Path to cert file.
ks_key* | tls/server.key | Path to key file.
ks_org* | BubbaGump | Edge Org where the Keystore is going to be created.
ks_env* | test | Edge Env where the Keystore is going to be created.

\* Required.

### Create a VirtualHost <a name="vhost"/>
Create virtual host in an existing Edge Org/Env. Optionally TLS could be enabled with an existing keystore.

```
$ ansible-playbook -i inventory/INVENTORY_FILE \
  -e "keyalias=KEY_ALIAS keystore=KEYSTORE_NAME \
  vhost_name=VHOST_NAME vhost_aliases=COMMA_SEPARATED_ALIASES \
  org=EDGE_ORG env=EDGE_ENV tls_enabled=true" \
  vhost_tls.yml
```

Variable | Example | Description
--- | --- | ---
vhost_name* | tls/server.crt  | Path to cert file.
vhost_aliases* | tls/server.key | Path to key file.
org* | BubbaGump | Edge Org where the Keystore is going to be created.
env* | test | Edge Env where the Keystore is going to be created.
tls_enabled* | true | Enable TLS. 
keyalias** | my_key_alias | Existing key alias. 
keystore** | keystore | Existing keystore name.

\* Required.

** Required if tls_enabled is set to any value.

### Run apigee-service commands accross planet <a name="apigee-service" />

Run an apigee-service command in particular components or across the planet.

```
$ ansible-playbook -i inventory/INVENTORY_FILE -e "cmd=COMMAND component=COMPONENT" setup.yml
```

Values for **cmd**:
- status
- start
- wait_for_ready
- stop
- restart

Values for **component**:
- zk      (Zookeeper)
- cs      (Cassandra)
- ds      (Zookeeper and Cassandra)
- ldap    (OpenLDAP)
- ms      (Management Server)
- msldap  (Management Server and OpenLDAP)
- r       (Router)
- mp      (Message Processor)
- rmp     (Router and Message Processor)
- qs      (QPIDD and Qpid Server)
- pg      (Postgreql and Postgres Server)
- all     (All Edge components)

### Create Edge custom role <a name="custom-role">
[Edge Roles](https://docs.apigee.com/api-services/content/managing-roles-api).

Create custom role in an Edge Org.

```
$ ansible-playbook -i inventory/INVENTORY_FILE \
  -e "api_action=roles org=ORG role=ROLE_NAME \
  customrole_path=ROLE_PATH" adminapi.yml
```

Variable | Example | Description
--- | --- | ---
api_action* | roles | This must be _roles_ to create new roles.
org* | BubbaGump | Edge Org where the role is going to be created.
role* | newrol | Role name.
customrole_path* | examples/customrole.json | Path to role in JSON format. 

\* Required.

Each Edge Org has some [built-in roles](https://docs.apigee.com/api-services/content/edge-built-roles):
- **Organization Administrator**: Super user. Has full CRUD access to resources in the organization. In an Edge 
for Private Cloud installation, the most powerful role is the System administrator role, which also has access 
to system-level functions that the Organization Administrator doesn't.
- **Operations Administrator**: Deploys and tests APIs; has read-only access to other resources.
- **Business User**: Creates and manages API products, developers, developer apps, and companies; 
creates custom reports on API usage; has read-only access to other resources.
- **User**: Creates API proxies and tests them in the test environment; has read-only access to other resources.

### Create user <a name="user" />
[Edge Users](https://docs.apigee.com/private-cloud/latest/managing-users-roles-and-permissions).

Create user and add to an existing role.

```
$ ansible-playbook -i inventory/INVENTORY_FILE \
  -e "api_action=users org=ORG role=ROLE_NAME \
  user_email=USER_EMAIL user_password=USER_PASSWORD \
  user_name=USER_NAME user_lastname=USER_LASTNAME" \
  adminapi.yml
```

Variable | Example | Description
--- | --- | ---
api_action* | users | This must be _users_ to create new user.
org* | BubbaGump | Edge Org where the role is going to be created.
role | User | Edge role.
user_email* | forest@gump.com | User email (used as _username_).
user_password* | mypassword | User password. 
user_name* | Forest | User name. 
user_lastname* | Gump | User last name.

\* Required.

### Fetch planet logs <a name="logs" />
Tar all the edge logs from each node.

```
$ ansible-playbook -i inventory/INVENTORY_FILE logs.yml
```

### Run planet scan <a name="planet-scan"/>
Run check commands across the planet:

- _Edge pods_: List servers for each Pod.
    - Central pod.
    - Gateway pod.
    - Analytics pod.

- _Zookeeper_: Run Zookeeper status commands.
    - _ruok_.
    - _stat_.
    - Zookeeper tree.

- _Cassandra_: Run Cassandra nodetool commands.
    - ring.
    - status.
    - statusthrift

- _Postgres_: Check master/standby nodes.

- _Management ports check (self status)_: Get info from each Edge component.
    - Management Server (8080).
    - Router (8081).
    - Message Processor (8082).
    - Qpid Server (8083).
    - Postgres Server (8084).

- _Analytics groups_: List the Analytics groups and servers.

- Fetch _customer/application_ files across the planet.

- Memory and disk usage.

```
$ ansible-playbook -i inventory/INVENTORY_FILE planet_scan.yml
```

Find the scan files:
  - _reports/scan_:

### Ansible Ad-Hoc commands <a name="ad-hoc" />
[Ansible Ad-Hoc commands](http://docs.ansible.com/ansible/latest/intro_adhoc.html)

Example: 
```
$ ansible -i inventory/INVENTORY_FILE HOST_GROUP -m shell -a '/opt/apigee/apigee-service/bin/apigee-all status'
```
Script for inventory group hosts:
Run _echo "Hello node!"_ command example:
```
$ ./service.sh -i inventory/INVENTORY_FILE -g HOST_GROUP -c "echo 'Hello node!'"
```
Where:
- **-h**: help
- **-i**: ansible inventory path. **Required**
- **-c**: command to run in the node.
- **-g**: ansible inventory group

Default values:
- If not _-c_ option provided, the default command is: _/opt/apigee/apigee-service/bin/apigee-all status_
- If not _-g_ option provided, the default group is: _planet_
```
$ ./service.sh -i inventory/INVENTORY_FILE -g HOST_GROUP -c "echo 'Hello node!'"
```

\* _/opt/apigee/apigee-service/bin/apigee-all start|restart_ are not recommended since the start order is important: [Starting apigee components](https://docs.apigee.com/private-cloud/latest/starting-stopping-and-restarting-apigee-edge)

