require "net/http"
require "uri"
require "pp"
require "csv"
require "set"
require "json"

# usage: ruby extract_datacatalogs.rb OUTFILE GROUP_1 GROUP_2 ... GROUP_N
#
# query datacatalogs.org for a list of catalogs belonging to the specified groups
# result written as CSV to OUTFILE
#
# example: extract all catalogs that belong to groups "ckan" and "eu_official"
#
#   ruby extract_datacatalogs.rb ckan_eu.csv ckan eu_official


out_file = ARGV[0]
filter_groups = Set.new
if (ARGV.count > 1)
  filter_groups = ARGV[1..ARGV.count-1].to_set
end

api_base = "http://datacatalogs.org/api/rest/"
api_dataset = api_base + "dataset/"

uri = URI.parse(api_dataset.chomp("/"))

response = Net::HTTP.get_response(uri)

catalogs = JSON.parse(response.body)
count = 0

CSV.open(out_file, "w") do |csv|
  csv << ['name', 'title', 'author', 'url', 'group']
  catalogs.each do |catalog_id|
    catalog_uri = api_dataset + catalog_id
    uri = URI.parse(catalog_uri.chomp("/"))
    response = Net::HTTP.get_response(uri)
    catalog = JSON.parse(response.body)
    puts "#{count.to_s.rjust(3, '0')} of #{catalogs.count}: #{catalog['name']}"
    groups = catalog['groups'].to_set
    if (filter_groups.subset?(groups))
      entry = Array.new
      entry << catalog['name']
      entry << catalog['title']
      entry << catalog['author']
      entry << catalog['url']
      csv << entry.concat(catalog['groups'])
    end
    count += 1
  end
end
