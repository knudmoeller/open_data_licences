SPARQL Queries for External Endpoint
====================================

These queries were written so that I can run them from the command line through JENA's `sparql` tool (http://jena.apache.org/). Since they query an external endpoint (I use dydra.com), I have to use the `SERVICE` keyword. If I would query locally, those queries could be simplified by ditching the `SERVICE` bit.

`sparql` requires the user to always specify a datasource (file), even if you're querying a remote endpoint. That's what the `empty.nt` file is for. The way to run a query which outputs results as CSV would be as follows:

```
sparql --data=empty.nt --query=licence_count.rq --results=CSV
```

To install Jena and its command line tools, just pick a binary distribution from http://www.apache.org/dist/jena/binaries/ and add its `/bin` subfolder to your PATH.