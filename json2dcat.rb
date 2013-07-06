require 'json'
require 'rdf'
require 'rdf/ntriples'

include RDF

# takes JSON output from extract_datasets.rb and creates
# an RDF representation, using the DCAT vocabulary in n-triples syntax
# 
# requires the RDF gem (http://rubygems.org/gems/rdf)


base_uri = "http://data.datalysator.com/datacatalogs_crawl/"
CATALOGS = RDF::Vocabulary.new(base_uri + "catalog/")
DATASETS = RDF::Vocabulary.new(base_uri + "dataset/")
LICENCES = RDF::Vocabulary.new(base_uri + "licence/")
DCAT = RDF::Vocabulary.new("http://www.w3.org/ns/dcat#")
DCTYPE = RDF::Vocabulary.new("http://purl.org/dc/dcmitype/")

all_datasets = JSON.parse(File.read("all_datasets.json"))

RDF::Writer.for(:ntriples).open("all_datasets.nt") do |writer|
  writer << RDF::Graph.new do |graph|
    all_datasets.each do |catalog|
      puts catalog['name']
      rdf_catalog = CATALOGS[URI.escape(catalog['name'])]
      graph << [ rdf_catalog, RDF.type, DCAT.Catalog ]
      graph << [ rdf_catalog, DC.title, RDF::NTriples::Writer.escape(catalog['title'].strip) ]
      graph << [ rdf_catalog, FOAF.homepage, RDF::URI.new(catalog['url'].strip) ]
      datasets = catalog["datasets"]
      if datasets
        datasets.each do |dataset|
          # puts "\t#{dataset['name']}"
          rdf_dataset = DATASETS[URI.escape(dataset['name'].strip)]
          # rdf_dataset = RDF::URI.new(rdf_catalog.to_s + "/" + URI.escape(dataset['name'].strip) )
          graph << [ rdf_catalog, DCAT.dataset, rdf_dataset ]
          graph << [ rdf_dataset, RDF.type, DCAT.Dataset ]
          graph << [ rdf_dataset, DC.title, RDF::NTriples::Writer.escape(dataset["title"].strip) ] if dataset["title"]
          if (dataset["license_id"])
            license_id = URI.escape(dataset['license_id'].strip)
            if (license_id != "")
              rdf_licence = LICENCES["#{license_id}"]
              graph << [ rdf_dataset, DC.license, rdf_licence ]
              graph << [ rdf_licence, RDF.type, DCTYPE.LicenseDocument ]
              graph << [ rdf_licence, DC.identifier, license_id ]
              graph << [ rdf_licence, RDFS.label, dataset['license'].strip ] if (dataset['license'])
            end
          end
        end
      end
    end
  end
end