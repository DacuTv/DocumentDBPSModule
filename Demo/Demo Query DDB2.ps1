$AccountName = '<acc>'
$Key = '<DDBKey>'
$Database = '<db>'
$Collection = '<coll>'

$Query = @"
{
"query": "select * from $collection coll"
}
"@

$temp = New-DocDBQuery -DBName $Database -accountName $AccountName -key $key -collection $Collection -JSONQuery $Query
$temp

