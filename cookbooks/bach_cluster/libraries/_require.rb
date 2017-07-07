# Poise/Halite-ish style but by hand

raise 'Please set no_lazy_load true in your Chef configuration file.' unless Chef::Config[:no_lazy_load]
$LOAD_PATH << File.expand_path('../../files/gem/lib', __FILE__)
