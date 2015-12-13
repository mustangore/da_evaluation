#!/bin/sh

rm runMDXQueries.tar.gz
rm runSQLQueries.tar.gz

tar -czvf runMDXQueries.tar.gz runMDXQuery*
tar -czvf runSQLQueries.tar.gz runSQLQuery*

rm runMDXQuery*
rm runSQLQuery*
