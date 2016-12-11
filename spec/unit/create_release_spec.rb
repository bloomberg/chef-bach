require 'spec_helper'

describe File.expand_path("bin/create_release.rb") do
  begin
    require File.expand_path("bin/create_release.rb")
  rescue NameError => ex
    raise("Failed to load: #{ex}")
  end

  context 'tags and branches git repo' do
    let(:branches_n_tags_repo_with_spurious) do
      double(
        tags: [
          double(to_s: '1',
                 name: '1'),
          double(to_s: '2.0.1',
                 name: '2.0.1'),
          double(to_s: '8.2',
                 name: '8.2'),
          double(to_s: 'v8.invalid',
                 name: 'v8.invalid'),
          double(to_s: 'vSerious',
                 name: 'vSerious'),
          double(to_s: 'v6.0.2',
                 name: 'v6.0.2'),
          double(to_s: 'v6.0.3',
                 name: 'v6.0.3'),
          double(to_s: 'v8',
                 name: 'v8')],
        branches: [double(to_s: 'master',
                      name: 'master'),
               double(to_s: 'release-6.0',
                      name: 'release-8.0')]
      )
    end
    let(:no_branches_or_tags_repo) do
      double(
        branches: [],
        tags: []
      )
    end

    describe '#latest_revision' do
      it 'returns 0.0 for repo with no tags or branches' do
        expect(latest_revision(no_branches_or_tags_repo)).to eq(['0.0', '0.0'])
      end

      it 'returns latest version ignoring master and spurrious tags ' do
        expect(latest_revision(branches_n_tags_repo_with_spurious)).to \
          eq(['8.0', '8'])
      end
    end
  end

  context 'simple chef repo' do
    # a mock location for a repo
    let(:mock_location) { '/my_test_cookbook_repo' }

    # a mock Chef git repo
    let(:simple_chef_repo) do
      double(
        ls_files: {
          'Berksfile' => {'file metadata' => 'does not exist'},
          'README.md' => {'file metadata' => 'not populated'},
          'metadata.json' => {'no metadata' => 'odd for a metadata file'},
          'metadata' => {'false flag' => 'not a Chef metadata file'},
          'data.json' => {'false flag' => 'not a Chef metadata file'},
          'recipes/default.rb' => {'file metadata' => 'not populated'},
          'test/cookbooks/test_cb/metadata.rb' => {'still no md' => 'for this'},
          'test/cookbooks/test_cb/README.md' => {'mode_index' => '100644'}
        },
        dir: mock_location
      )
    end

    describe '#find_metadatas' do
      require 'chef/cookbook/metadata'

      # a mock Chef::Cookbook::Metadata object
      let(:simple_metadata) { double() }

      it 'returns both metadata.json and metadata.rb files' do
        expect(Chef::Cookbook::Metadata).to receive(:new) { simple_metadata }
        expect(simple_metadata).to receive(:from_file). \
          with(File::join(mock_location, 'metadata.json'))
        expect(simple_metadata).to receive(:name) { 'my_cookbook' }

        expect(Chef::Cookbook::Metadata).to receive(:new) { simple_metadata }
        expect(simple_metadata).to receive(:from_file). \
          with(File::join(mock_location, 'test/cookbooks/test_cb/metadata.rb'))
        expect(simple_metadata).to receive(:name) { 'my_test_cookbook' }

        expect(find_metadatas(simple_chef_repo)).to \
          eq({'test/cookbooks/test_cb/metadata.rb' => 'my_test_cookbook',
              'metadata.json' => 'my_cookbook'})
      end
    end

    describe '#rewrite_dependencies' do
      require 'chef/cookbook/metadata'

      let(:initial_dependencies) do
        {'dependencies' => {'eggs' => '>= 0.1.0',
                            'xanthan_gum' => '=5.0',
                            'chickpea_flour' => '<7.9',
                            'milk' => '~>100.75.2'}}
      end

      let(:rewritten_dependencies) do
        {'dependencies' => {'eggs' => '=900.0',
                            'xanthan_gum' => '=5.0',
                            'chickpea_flour' => '<7.9',
                            'milk' => '=900.0'}}
      end

      let(:metadata_fields) do
        {'name'        => 'my_cookbook',
         'description' => 'makes this test work'}
      end
      # a mock Chef::Cookbook::Metadata object
      let(:parsed_metadata) do
        double(
          name: 'my_cookbook',
          to_hash: metadata_fields.merge(initial_dependencies)
        )
      end

      it 'updates expected cookbooks for a metadata.json' do
        md_path = File::join(mock_location, 'metadata.json')
        expect(Chef::Cookbook::Metadata).to receive(:new) { parsed_metadata }
        expect(parsed_metadata).to receive(:from_file).with(md_path)

        mock_file = Tempfile.new('rspec_test_of_rewrite_dependencies')
        begin
          expect(File).to receive(:open).with(md_path, 'w').and_yield(mock_file)
          expect(mock_file).to receive(:write).with(JSON.pretty_generate(
            metadata_fields.merge(rewritten_dependencies)))
          expect(mock_file).to receive(:flush)
          expect(simple_chef_repo).to receive(:add).with('metadata.json')

          expect(rewrite_dependencies(simple_chef_repo, 'metadata.json',
                                      '900.0', ['eggs', 'milk'])).to \
            eq('my_cookbook')
        ensure
          mock_file.close
          mock_file.unlink
        end
      end
    end
  end

end
