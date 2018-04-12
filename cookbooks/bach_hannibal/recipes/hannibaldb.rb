# Create Kinfe vault enteries
hanDBUserKey='hannibal-db-user'
hanDBPaswdKey='hannibal-db-password'
hanDBUser='hannibal'
hanDBPaswd=make_config(hanDBPaswdKey, secure_password)
make_config(hanDBUserKey, hanDBUser)

mySqlHost =  node['bcpc']['management']['vip'] 

node.force_default['hannibal']['db']['type']='mysql'
node.force_default['hannibal']['db']['user'] = hanDBUser
node.force_default['hannibal']['db']['driver'] = 'com.mysql.jdbc.Driver'
node.force_default['hannibal']['db']['password'] = hanDBPaswd
node.force_default['hannibal']['db']['url'] = '"jdbc:mysql://' + mySqlHost + '/hannibal?characterEncoding=UTF-8"'

# Create DB, User and configure permissions for hannibal
ruby_block "hannibal-database-creation" do
  mySqlRootPaswd=get_config!('password','mysql-root','os')
  mySqlRootUser=get_config('mysql-root-user')
  block do
    puts %x[
      mysql -u#{ mySqlRootUser } -p#{ mySqlRootPaswd } -e "CREATE DATABASE #{hanDBUser} CHARACTER SET UTF8;"
      mysql -u#{ mySqlRootUser } -p#{ mySqlRootPaswd } -e "GRANT ALL ON #{hanDBUser}.* TO '#{hanDBUser}'@'%' IDENTIFIED BY '#{hanDBPaswd}';"
      mysql -u#{ mySqlRootUser } -p#{ mySqlRootPaswd } -e "GRANT ALL ON #{hanDBUser}.* TO '#{hanDBUser}'@'localhost' IDENTIFIED BY '#{hanDBPaswd}';"
      mysql -u#{ mySqlRootUser } -p#{ mySqlRootPaswd } -e "FLUSH PRIVILEGES;"
    ]
  end
  not_if "mysql -u#{mySqlRootUser} -p#{mySqlRootPaswd} -e \"SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \'#{hanDBUser}\'\" | grep #{hanDBUser}"
end
