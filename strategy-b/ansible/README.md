# Strategy B - Ansible Playbook

After cloud-init completes, run this playbook:

```bash
cd /opt/ansible-playbooks
ansible-playbook site.yml
```

Or if using from local machine:

```bash
ansible-playbook -i inventory.ini site.yml
```
