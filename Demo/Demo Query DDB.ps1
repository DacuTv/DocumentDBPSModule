$AccountName = '<acc>'
$Key = '<DDBKey>'
$Database = '<db>'
$Collection = '<coll>'

$Query = @"
{
"query": "select * from $collection coll
where coll.FirstName = 'Robert' and coll.Surname = 'Burks'"
}
"@

$temp = New-DocDBQuery -DBName $Database -accountName $AccountName -key $key -collection $Collection -JSONQuery $Query
$temp|ConvertTo-Json

