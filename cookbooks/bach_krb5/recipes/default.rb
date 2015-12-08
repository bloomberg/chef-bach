# Set master passwords
make_bach_krb5_config("krb5-master-password", secure_password)
make_bach_krb5_config("krb5-admin-password", secure_password)

# Override password related node attributes
node.override['krb5']['master_password'] = get_bach_krb5_config("krb5-master-password")
node.override['krb5']['admin_password'] = get_bach_krb5_config("krb5-admin-password")
