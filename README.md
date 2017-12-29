# ansible
Ansible Playbooks for Installation of SmartHomeNG and/or Tools

## Usage

Add your computers to /etc/ansible/hosts like in this example:
```
[public]
image ansible_port=22 ansible_host=10.0.0.31 ansible_user=pi ansible_password=raspberry become=true become_method=sudo
```

Run a playbook with ansible-playbook <playbookname>
