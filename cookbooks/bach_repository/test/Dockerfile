FROM ubuntu:12.04
<% if @proxy %>
RUN echo 'Acquire::http::Proxy "<%= @proxy %>";' >  /etc/apt/apt.conf
<% end %>
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y sudo openssh-server openssh-client wget git
RUN rm /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN mkdir -p /var/run/sshd
RUN useradd -d /home/<%= @username %> -m -s /bin/bash <%= @username %>
RUN echo <%= "#{@username}:#{@password}" %> | chpasswd
RUN echo '<%= @username %> ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
<% if @proxy %>
RUN https_proxy=<%= @proxy %> wget --no-check-certificate https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/10.04/x86_64/chef_12.3.0-1_amd64.deb
<% else %>
RUN wget https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/10.04/x86_64/chef_12.3.0-1_amd64.deb
<% end %>
RUN dpkg -i chef*amd64.deb
