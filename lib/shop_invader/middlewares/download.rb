module ShopInvader
  module Middlewares
    class Download < Locomotive::Steam::Middlewares::ThreadSafe

      include Locomotive::Steam::Middlewares::Helpers

      def _call
        if path.start_with?('_store/download/')
          attachment_path = path.match(/_store\/download\/(.*)/)[1]
          filename        = File.basename(path)

          if response = service.download(attachment_path)
            @next_response = [
              200,
              {
                'Content-Type'        => response.headers['content-type'],
                'Content-Length'      => response.headers['content-length'],
                'Content-Disposition' => "attachment; filename=\"#{filename}\""
              },
              [response.body]
            ]
          end
        end
      end

      private

      def service
        services.erp
      end

    end
  end
end
