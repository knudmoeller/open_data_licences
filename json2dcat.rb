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

# some licences appear with different licence ids
# when no license_id is given, we assume 'notspecified'
LICENCE_ID_MAPPING = {
  nil => "notspecified",
  "" => "notspecified",
  "cc-nc" => "cc-by-nc",
  "ukcrown-withrights" => "ukcrown",
  "ukclickusepsi" => "uk-clickuse",
  "CreativeCommonsAttributionCCBY25" => "cc-by",
  "None" => "notspecified",
  "Other::License%20Not%20Specified" => "notspecified",
  "License%20Not%20Specified" => "notspecified",
  "Public%20Sector%20INSPIRE%20WMS%20End%20User%20Licence" => "inspire-wms-end-user",
  "OS%20Open%20Data%20Licence" => "uk-os",
  "Ordnance%20Survey%20Open%20Government%20Licence" => "uk-os",
  "DERM_OPEN_SHORT" => "aus-derm-open-short",
  "Non-Commercial%20Government%20Licence%20v1.0" => "uk-nc",
}

# some datasets have no license_id, but a human-readable "licence" attribute instead
# we need a mapping from those to license_ids
LICENCE_NAME_MAPPING = {
  "License Not Specified" => "notspecified",
  "Non OKD Compliant: Non-Commercial Other" => "other-nc",
  "Non OKD Compliant: Other" => "other",
  "Non-OKD Compliant::Creative Commons Non-Commercial (Any)" => "cc-by-nc",
  "Non-OKD Compliant::Other (Non-Commercial)" => "other-nc",
  "Non-OKD Compliant::Other (Not Open)" => "other-closed",
  "OKD Compliant: Other (Attribution)" => "other-at",
  "OKD Compliant: UK Click Use PSI" => "uk-clickuse",
  "OKD Compliant::Creative Commons Attribution" => "cc-by",
  "OKD Compliant::Creative Commons Attribution Share-Alike" => "cc-by-sa",
  "OKD Compliant::Creative Commons CCZero" => "cc-zero",
  "OKD Compliant::Open Data Commons Open Database License (ODbL)" => "odc-odbl",
  "OKD Compliant::Open Data Commons Public Domain Dedication and Licence (PDDL)" => "odc-pddl",
  "OKD Compliant::Other (Attribution)" => "other-at",
  "OKD Compliant::Other (Open)" => "other-open",
  "OKD Compliant::Other (Public Domain)" => "other-pd",
  "OKD Compliant::UK Crown Copyright with data.gov.uk rights" => "ukcrown",
  "OKD Compliant::UK Open Government Licence (OGL)" => "uk-ogl",
  "OSI Approved::Attribution Assurance Licenses" => "other-at",
  "OSI Approved::GNU General Public License (GPL)" => "gpl",
  "OSI Approved::GNU General Public License version 3.0 (GPLv3)" => "gpl-3.0",
  "Other::License Not Specified" => "notspecified",
}


RDF::Writer.for(:ntriples).open("results/all_datasets.nt") do |writer|
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
          
          license_id = "notspecified"
          if (dataset['license'])
            licence_name = dataset['license'].strip
            license_id = LICENCE_NAME_MAPPING[licence_name]
          elsif (dataset["license_id"])
            license_id = URI.escape(dataset['license_id'].strip)
          end
          license_id = LICENCE_ID_MAPPING[license_id] if LICENCE_ID_MAPPING[license_id]
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