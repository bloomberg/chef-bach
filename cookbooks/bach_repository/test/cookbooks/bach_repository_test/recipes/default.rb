package 'git'

# Setup node.run_state hashes for the Apt repos
node.run_state['bach'] = node.run_state.fetch(['bach'], {})
node.run_state['bach']['repository'] = node.run_state['bach'].fetch('repository', {})
node.run_state['bach']['repository']['gpg_private_key'] = <<-EOF
lQNTBFo9LkARCACOiHsP252+O1B8bG1CIBEuMr/7GOiD2NlsOH4x0RvM/119
cUh8hEAzQjT7uWd5KvmB0ogImKiPx9V1QU3VqPAPIMtP8IlWTEjPITi88V/I
MjVgjKEoC4duckaCMAx39GU87E6zHbc5ceWkBqkKJ0f0/meLfSM/IQF7X9n1
Gtv/P94qM3CkR27fPLVzbafF0LFCh0DCxIWrNkwRCD1iM4VWCnJpEx8J637H
QH6EKEmaTRzU/F6uQDMPrHBcaG+TNntsNzTHI79ffOnvoPE2KWsdR5j0TIKe
+h76j8yZu/swLoyx3t6MPErmLD87Q6EJsrAHIYhUJiiLEjFW0yJpOOJLAQCK
LUiy/2L86Ax0JEBHOkNYxsd3OzrKonKM8GbujTSULwf+MOfxnEBTPD7TR/Xq
YNejeiEgGW6fVy+SuzBfyKfPCR6OaZhZGZe/Hc9XUr4O9/wBHJr7tUDt1HjM
Ht+nNuiJte4DTGEG2ropLN1wVTGeMwcZPQUA53BbOUAzT6kDCDK55KW+rKtb
9c0z/dONrXxpPPW2bRO42IDhRVQlBQ3L+dvkaerj5hSHkt+K1zkaSWtFXcRV
DoaWfF1QbD25aEKlZHO6r1pXTj85CGgXpXHUPGiKu+gMO5G8twznr6BGCb/q
MyHB7Nd6Lz2MUAg9GJfesO2CImmSEmtdcFC2uxQKod4I3u2X3pn0CeSkWK2g
nKc6G3v5+pFEH/seVZkOVduV+Qf6A3yEKNN205uT5Q1O5y0LfeWQlFMqTi1Y
Bac1MzuEZFEVgY3zKow85Ou5G+14TcrdREH9VqkFZg88k/3Opn/StZBRFnRc
L2Qn1KtQlks6KB9salpfdJbFCyAduBbNmb3Fn0ZPhOMZGxJLndvLZDCSc8qg
R9NHf/DEN+etNUwkcOJn85Gh+X2q1qEAu+eFv6b/GDkOUUwM2GNtSi8eonJR
0smVm03h6VCJADdLnJe0dwd6iRPnfX7cTRJKinELR0HXmeUtVdNPMW9RyX/B
so52wrRfFci1Lwkg/lQurlfEHv0mlvmoc3BW8+mq3OxqBHcXRVesYSuXD8C2
sxFWwD8sigAA/2a8i+haXy2dvjHADh1Bc664rm4d2KJusdfeE+DaikPfEgu0
J0xvY2FsIEJBQ0ggUmVwbyAoRm9yIGRwa2cgcmVwbyBzaWduaW5nKYh6BBMR
CAAiBQJaPS5AAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRBGD69S
9IDl0u1+AP0eWQmJ907omuerEycRVLRuGog+zF5cPbK++XiA965VMgD/etvT
Kcn4bCVhvEXNJJT9fWQuZhNjjPaYkqFrx3GzMEo=
EOF

node.run_state['bach']['repository']['gpg_public_key'] = <<-EOF
mQMuBFo9LkARCACOiHsP252+O1B8bG1CIBEuMr/7GOiD2NlsOH4x0RvM/119
cUh8hEAzQjT7uWd5KvmB0ogImKiPx9V1QU3VqPAPIMtP8IlWTEjPITi88V/I
MjVgjKEoC4duckaCMAx39GU87E6zHbc5ceWkBqkKJ0f0/meLfSM/IQF7X9n1
Gtv/P94qM3CkR27fPLVzbafF0LFCh0DCxIWrNkwRCD1iM4VWCnJpEx8J637H
QH6EKEmaTRzU/F6uQDMPrHBcaG+TNntsNzTHI79ffOnvoPE2KWsdR5j0TIKe
+h76j8yZu/swLoyx3t6MPErmLD87Q6EJsrAHIYhUJiiLEjFW0yJpOOJLAQCK
LUiy/2L86Ax0JEBHOkNYxsd3OzrKonKM8GbujTSULwf+MOfxnEBTPD7TR/Xq
YNejeiEgGW6fVy+SuzBfyKfPCR6OaZhZGZe/Hc9XUr4O9/wBHJr7tUDt1HjM
Ht+nNuiJte4DTGEG2ropLN1wVTGeMwcZPQUA53BbOUAzT6kDCDK55KW+rKtb
9c0z/dONrXxpPPW2bRO42IDhRVQlBQ3L+dvkaerj5hSHkt+K1zkaSWtFXcRV
DoaWfF1QbD25aEKlZHO6r1pXTj85CGgXpXHUPGiKu+gMO5G8twznr6BGCb/q
MyHB7Nd6Lz2MUAg9GJfesO2CImmSEmtdcFC2uxQKod4I3u2X3pn0CeSkWK2g
nKc6G3v5+pFEH/seVZkOVduV+Qf6A3yEKNN205uT5Q1O5y0LfeWQlFMqTi1Y
Bac1MzuEZFEVgY3zKow85Ou5G+14TcrdREH9VqkFZg88k/3Opn/StZBRFnRc
L2Qn1KtQlks6KB9salpfdJbFCyAduBbNmb3Fn0ZPhOMZGxJLndvLZDCSc8qg
R9NHf/DEN+etNUwkcOJn85Gh+X2q1qEAu+eFv6b/GDkOUUwM2GNtSi8eonJR
0smVm03h6VCJADdLnJe0dwd6iRPnfX7cTRJKinELR0HXmeUtVdNPMW9RyX/B
so52wrRfFci1Lwkg/lQurlfEHv0mlvmoc3BW8+mq3OxqBHcXRVesYSuXD8C2
sxFWwD8sirQnTG9jYWwgQkFDSCBSZXBvIChGb3IgZHBrZyByZXBvIHNpZ25p
bmcpiHoEExEIACIFAlo9LkACGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheA
AAoJEEYPr1L0gOXS7X4A/R5ZCYn3Tuia56sTJxFUtG4aiD7MXlw9sr75eID3
rlUyAP9629MpyfhsJWG8Rc0klP19ZC5mE2OM9piSoWvHcbMwSg==
EOF

directory 'repo directory' do
  path node['bach']['repository']['repo_directory']
  recursive true
  action :create
end

git 'chef-bach' do
  destination node['bach']['repository']['repo_directory']
  repository node['bach']['repository_test']['chef-bach']['uri'] 
  branch node['bach']['repository_test']['chef-bach']['branch'] 
  depth 1
  action :checkout
end

execute 'chown repo dir' do
  command lazy { "chown -R #{node['bach']['repository']['build']['user']} #{node['bach']['repository']['repo_directory']}" }
end
