CKAN Open Data Licences
=======================

2013, Knud Möller

Creates RDF data from http://datacatalogs.org

This is a little project to research **which Open Data licences are being used across the world, and where**. The source data for finding out comes from http://datacatalogs.org (a meta catalog of open data catalogs or data portal), which is queried through its API endpoint at http://datacatalogs.org/api, using the CKAN Search API (http://docs.ckan.org/en/ckan-1.8/api-v2.html#search-api).

Only those catalogs that belong to the `ckan` group are extracted. For each catalog, the code then attempts to query it again through its search API. If the API can be found, information about dataset titles and licences (`license_id`) is extracted. The results are exported as RDF data, using the DCAT vocabulary (http://www.w3.org/TR/vocab-dcat/).

datacatalogs.org contains a number of meta catalogs, which harvest other catalogs (e.g., http://publicdata.eu/). This means that many datasets will appear several times. To get around this, the code makes the assumption that datasets with the same `name` attribute are identical. This is only an approximation, because there might well be several different datasets called `expenses`. If there is a better way to determine dataset identity, please let me know.

Similary, licences with the same `license_id` attribute are considered identical. The code also tries to extract a human-readable lincence name by querying for `licence`. However, this field is not always present.
