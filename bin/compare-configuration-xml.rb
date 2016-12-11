#!/usr/bin/env ruby
require 'tempfile'

if __FILE__ == $PROGRAM_NAME

  input_a = ARGV[0]
  input_b = ARGV[1]

  unless File.exist?(input_a.to_s) && File.exist?(input_b.to_s)
    STDERR.printf("Input files not provided!\n" +
                  "Usage: ./bin/compare-configuration-xml <first> <second>\n")
    exit(-1)
  end

  temp_files = []

  [input_a, input_b].each do |input_file|
    lines = File.read(input_file).lines

    keys = lines
      .select{ |l| l.include?('<name>') }
      .map{ |l| l.gsub(/.*>(.*)<.*\n?/, '\\1') }

    unless lines.select{ |l| l.include?('configuration.xsl') }.length > 0
      STDERR.printf("\nWarning: " + input_file +
                    " does not reference configuration.xsl.\n" +
                    "This does not look like a valid *site.xml file!\n\n")
    end

    temp_file = Tempfile.new('compare-configuration-xml')

    keys.sort.each do |key|
      temp_file.write("#{key}\n")
    end

    temp_file.close
    temp_files.push(temp_file)
  end

  pid = spawn('diff', temp_files[0].path, temp_files[1].path,
              :close_others => false,
              :out => STDOUT,
              :err => STDERR)
  Process.wait(pid)

end
