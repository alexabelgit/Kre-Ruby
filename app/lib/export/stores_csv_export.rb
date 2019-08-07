module Export
  class StoresCsvExport
    def write_to_stream(stream)
      connection = ActiveRecord::Base.connection_pool.checkout.raw_connection
      query = "SELECT * FROM store_summaries"
      connection.copy_data "COPY ( #{query} ) TO STDOUT WITH CSV DELIMITER ',' HEADER;" do
        while row = connection.get_copy_data
          stream.write row
        end
      end
    ensure
      stream.close
    end
  end
end