require "curb"
require "json"

# extracts catalogs belonging to the "ckan" group from datacatalogs.org 
# outputs results as JSON into all_datasets.json
# 
# requires the curb gem (https://rubygems.org/gems/curb)


SEARCH_API = "/search/dataset"

# default assumption for guessing the catalog's API base URI is
# catalog_uri + "/api/". However, this is not always correct, so this
# Hash maps catalog_uris to API base URIs

API_MAPPINGS = {
  "http://data.gov.uk/data" => "http://data.gov.uk/api",
  "http://thedatahub.org" => "http://datahub.io/api",
  "http://datospublicos.org" => "http://datospublicos.org/api",
  "http://www.healthdata.gov" => "http://hub.healthdata.gov/api",
  "http://datakilder.no" => "http://no.ckan.net/api",
  "http://data.gv.at" => "http://www.data.gv.at/katalog/api",
  "http://dados.novohamburgo.rs.gov.br" => "https://dados.novohamburgo.rs.gov.br/api",
  "http://data.qld.gov.au" => "https://data.qld.gov.au/api",
  "http://offenedaten.de" => "https://offenedaten.de/api",
}

def get_api_base(catalog_uri) 
  if (API_MAPPINGS[catalog_uri])
    api_base = API_MAPPINGS[catalog_uri]
    puts "mapping #{catalog_uri} to #{api_base}"
  else
    api_base = catalog_uri + "/api"
    puts "guessing api base: #{api_base}"
  end
  return api_base
end

def create_query_uri(api_base, query)
  query_uri = api_base + SEARCH_API + "?" + query
  puts "\tquery_uri: #{query_uri}"
  return query_uri
end

def run_query(uri)
  curl = Curl::Easy.new(uri)
  curl.perform
  return curl.body_str
end

def number_of_datasets(api_base, query)
  uri = create_query_uri(api_base, query)
  result = JSON.parse(run_query(uri))
  return result["count"].to_i
end

meta_catalog = "http://datacatalogs.org"
query = "q=groups:ckan"
api_base = get_api_base(meta_catalog)
count = number_of_datasets(api_base, query)
puts "found #{count} data catalogs"
query = "q=groups:ckan&rows=#{count}&fl=name,title,url"
uri = create_query_uri(api_base, query)
catalogs = JSON.parse(run_query(uri))

all_datasets = Array.new

catalogs["results"].each do |catalog|
  catalog_hash = Hash.new
  catalog_uri = catalog["url"].strip.chomp("/")
  catalog_name = catalog["name"].strip
  catalog_title = catalog["title"].strip
  catalog_hash["name"] = catalog_name
  catalog_hash["title"] = catalog_title
  catalog_hash["url"] = catalog_uri
  puts "trying #{catalog_name}"
  api_base = get_api_base(catalog_uri)
  catalog_hash["success"] = Hash.new
  catalog_hash["success"]["value"] = TRUE
  begin
    count = number_of_datasets(api_base, "")
  rescue JSON::ParserError=>e
    reason = "no API endpoint found"
    puts "\tnot successful: #{reason}"
    catalog_hash["success"]["value"] = FALSE
    catalog_hash["success"]["reason"] = reason
  rescue Errno::ECONNREFUSED=>e
    reason = "connection refused"
    puts "\tnot successful: #{reason}"
    catalog_hash["success"]["value"] = FALSE
    catalog_hash["success"]["reason"] = reason
  rescue Curl::Err::ConnectionFailedError=>e
    reason = "connection refused"
    puts "\tnot successful: #{reason}"
    catalog_hash["success"]["value"] = FALSE
    catalog_hash["success"]["reason"] = reason
  rescue Errno::ETIMEDOUT=>e
    reason = "timeout"
    puts "\tnot successful: #{reason}"
    catalog_hash["success"]["value"] = FALSE
    catalog_hash["success"]["reason"] = reason
  else
    puts "\tsuccess, found #{count} datasets"
    catalog_hash["success"] = {
      "value" => TRUE
    }
    catalog_hash["api_endpoint"] = api_base
    
    # paging through results, 1000 results at a time
    start = 0
    rows = 1000
    datasets = Array.new
    while (start < count)
      query = "start=#{start}&rows=#{rows}&fl=name,title,license_id,license"
      uri = create_query_uri(api_base, query)
      page = JSON.parse(run_query(uri))["results"]
      start += rows
      datasets = datasets + page
    end
    catalog_hash["datasets"] = datasets
  end
  all_datasets << catalog_hash
end

# output JSON

generator_opts = {
  :indent => "  ", 
  :object_nl => "\n", 
  :array_nl => "\n", 
  :space => " ", 
  :space_before => " ",
}

json_out = File.open("all_datasets.json", "w")
json_out.puts JSON.generate(all_datasets, generator_opts)
json_out.close

