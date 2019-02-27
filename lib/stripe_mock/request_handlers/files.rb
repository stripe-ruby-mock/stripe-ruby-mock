module StripeMock
  module RequestHandlers
    module Files

      def Files.included(klass)
        klass.add_handler 'post /v1/files',            :new_file
        klass.add_handler 'get /v1/files/(.*)',        :get_file
        klass.add_handler 'get /v1/files',             :list_files
      end

      def new_file(route, method_url, params, headers)
        id = new_id('file')
        files[id] = Data.mock_file(params.merge :id => id)
      end

      def get_file(route, method_url, params, headers)
        route =~ method_url
        assert_existence :files, $1, files[$1]
        files[$1] ||= Data.mock_file
      end

      def list_files(route, method_url, params, headers)
        Data.mock_list_object(files.values, params)
      end
    end
  end
end
