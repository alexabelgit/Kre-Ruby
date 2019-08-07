module CsvHeaders
  extend ActiveSupport::Concern

  def set_csv_headers
    response.headers['Content-Disposition'] = 'attachment; filename="stores.csv"'
    response.headers['Content-Type'] = 'text/csv'
  end
end