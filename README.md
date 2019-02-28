# Automation_Webinar
Repository for F5 Automation Webinar Series

# Deploy a Virtual BIG-IP
ansible-playbook deploy_bigip.yaml --vault-password-file ./group_vars/vault_pass.txt

# Create application
ansible-playbook create_app.yaml -e "@app_inputs/App1.yaml"

# Deploy application
ansible-playbook push_config.yaml --vault-password-file ./group_vars/vault_pass.txt

# Manage node state
ansible-playbook node_mgmt.yaml --vault-password-file ./group_vars/vault_pass.txt --extra-vars "state=enabled"
ansible-playbook node_mgmt.yaml --vault-password-file ./group_vars/vault_pass.txt --extra-vars "state=disabled"

# Delete a Virtual BIG-IP
ansible-playbook delete_bigip.yaml --vault-password-file ./group_vars/vault_pass.txt
