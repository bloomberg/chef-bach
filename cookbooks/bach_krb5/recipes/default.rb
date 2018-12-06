include_recipe 'bach_krb5::admin'

# Override password related node attributes
node.override['krb5']['master_password'] = get_config("krb5-master-password")
node.override['krb5']['admin_password'] = get_config("krb5-admin-password")
