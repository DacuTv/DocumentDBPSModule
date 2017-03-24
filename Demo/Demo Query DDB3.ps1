$AccountName = '<acc>'
$Key = '<DDBKey>'
$Database = '<db>'
$Collection = '<coll>'
$id = '622046c70210ae5c13dee9e3bc2f0ff2'

$Query = @"
{      
    "query": "SELECT * FROM $collection r WHERE r.id = @id",     
    "parameters": [          
        { "name": "@id", "value": $id }         
    ] 
}
"@

$temp = New-DocDBQuery -DBName $Database -accountName $AccountName -key $key -collection $Collection -JSONQuery $Query -EnableCrossPartitionQuery
$temp

